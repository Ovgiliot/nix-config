{
  description = "Suckless NixOS configuration with Flakes and Home Manager";

  nixConfig = {
    extra-substituters = ["https://nix-community.cachix.org"];
    extra-trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri Window Manager (Wayland; Linux only)
    niri.url = "github:sodiboo/niri-flake";

    # Zen Browser (Linux only)
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    ...
  } @ inputs: let
    # Build a NixOS system from hosts/<hostname>/default.nix.
    # The host file is a function { inputs }: { system, specialArgs, modules }.
    mkNixosHost = hostname: let
      cfg = import ./hosts/${hostname} {inherit inputs;};
    in
      nixpkgs.lib.nixosSystem {
        inherit (cfg) system specialArgs modules;
      };

    # Build a nix-darwin system from hosts/<hostname>/default.nix.
    # Same host file convention as mkNixosHost.
    mkDarwinHost = hostname: let
      cfg = import ./hosts/${hostname} {inherit inputs;};
    in
      nix-darwin.lib.darwinSystem {
        inherit (cfg) system specialArgs modules;
      };
  in {
    # `nix fmt` support for all platforms in use.
    formatter = {
      x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
      aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
      x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.alejandra;
    };

    # NixOS hosts
    # Build:  sudo nixos-rebuild switch --flake .#<hostname>
    nixosConfigurations = {
      nixos = mkNixosHost "nixos";
      # <<NIXOS_HOSTS>>
    };

    # macOS hosts (nix-darwin)
    # First run:   nix run nix-darwin -- switch --flake .#<hostname>
    # Subsequent:  darwin-rebuild switch --flake .#<hostname>
    darwinConfigurations = {
      # <<DARWIN_HOSTS>>
    };

    # `nix flake check` targets — run all with `nix flake check`, or target
    # individual checks with `nix build .#checks.x86_64-linux.<name>`.
    #
    # Quick  (seconds): *-eval, dotfiles-integrity, fmt
    # Full   (minutes): nixos-build, *-build, server-vm-test
    checks = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      # Stub specialArgs used for profile eval/build tests.
      # Real values are host-specific; these are sufficient for evaluation.
      testSpecialArgs = {
        inherit inputs;
        dotfilesDir = ./home/ovg;
        # Placeholder UUID — only consumed by laptop/boot.nix and power.nix,
        # neither of which is imported by server or workstation profiles.
        swapLuksUuid = "00000000-0000-0000-0000-000000000000";
        # kanata.kbd must be a real file so builtins.readFile can evaluate.
        kanataConfig = ./home/ovg/kanata.kbd;
      };

      # Minimal NixOS host module shared by all profile tests.
      testHostModule = {
        networking.hostName = "test";
        system.stateVersion = "25.11";
        users.users.ovg = {isNormalUser = true;};
      };

      # Eval-only profile check. Forces the full module graph to be evaluated
      # at Nix eval time via string interpolation; the build step is trivial.
      # Catches type errors, bad imports, and missing specialArgs without
      # building the full system closure.
      evalProfile = name: profile: let
        sys = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = testSpecialArgs;
          modules = [profile testHostModule];
        };
      in
        pkgs.runCommand "eval-${name}" {} "echo '${sys.config.networking.hostName}' > $out";
    in {
      x86_64-linux = {
        # ── Full builds ───────────────────────────────────────────────────────
        # The active host: equivalent to `nixos-rebuild build`. Cached by nix
        # when inputs are unchanged, so this is usually a no-op.
        nixos-build = self.nixosConfigurations.nixos.config.system.build.toplevel;

        # Full system closures for profiles not deployed on this machine.
        # Run explicitly: `nix build .#checks.x86_64-linux.server-build`
        server-build =
          (nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = testSpecialArgs;
            modules = [./profiles/server.nix testHostModule];
          })
        .config.system.build.toplevel;

        workstation-build =
          (nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = testSpecialArgs;
            modules = [./profiles/workstation.nix testHostModule];
          })
        .config.system.build.toplevel;

        # ── Eval-only checks ──────────────────────────────────────────────────
        # Fast: no packages built. Used by `/test` for quick feedback.
        server-eval = evalProfile "server" ./profiles/server.nix;
        workstation-eval = evalProfile "workstation" ./profiles/workstation.nix;

        # ── Dotfiles integrity ────────────────────────────────────────────────
        # All paths referenced via dotfilesDir in modules/home/ must exist.
        # Nix resolves path literals at build time; a missing path fails here
        # before it can produce a broken xdg.configFile symlink at activation.
        dotfiles-integrity = pkgs.runCommand "dotfiles-integrity" {} ''
          test -e ${./home/ovg/nvim}                           || exit 1
          test -f ${./home/ovg/ranger/rc.conf}                 || exit 1
          test -f ${./home/ovg/ranger/rifle.conf}              || exit 1
          test -f ${./home/ovg/ranger/scope.sh}                || exit 1
          test -f ${./home/ovg/opencode/agents/talk.md}        || exit 1
          test -e ${./home/ovg/niri}                           || exit 1
          test -f ${./home/ovg/ghostty/config}                 || exit 1
          test -e ${./home/ovg/ghostty/shaders}                || exit 1
          test -f ${./home/ovg/mako/config}                    || exit 1
          test -f ${./home/ovg/waybar/scripts/cpu-mem.sh}         || exit 1
          test -f ${./home/ovg/waybar/scripts/info-box.sh}      || exit 1
          test -f ${./home/ovg/waybar/scripts/language.sh}      || exit 1
          test -f ${./home/ovg/waybar/scripts/status.sh}        || exit 1
          test -f ${./home/ovg/waybar/scripts/cycle-power-profile.sh} || exit 1
          test -f ${./home/ovg/quickshell/shell.qml}            || exit 1
          test -f ${./home/ovg/quickshell/Clock.qml}            || exit 1
          test -f ${./home/ovg/quickshell/Workspaces.qml}       || exit 1
          test -f ${./home/ovg/quickshell/CpuMem.qml}           || exit 1
          test -f ${./home/ovg/quickshell/InfoBox.qml}          || exit 1
          test -f ${./home/ovg/quickshell/Language.qml}         || exit 1
          test -f ${./home/ovg/quickshell/StatusIcons.qml}      || exit 1
          test -f ${./home/ovg/wofi/config}                     || exit 1
          test -f ${./home/ovg/wofi/style.css}                 || exit 1
          test -f ${./home/ovg/wofi/scripts/wifi-menu.sh}      || exit 1
          test -f ${./home/ovg/wofi/scripts/bluetooth-menu.sh} || exit 1
          test -f ${./home/ovg/wofi/scripts/power-menu.sh}     || exit 1
          test -f ${./home/ovg/kanata.kbd}                     || exit 1
          test -f ${./home/ovg/scripts/power-monitor.sh}       || exit 1
          touch $out
        '';

        # ── Format check ──────────────────────────────────────────────────────
        # Fails if any .nix file in the repo is not formatted with alejandra.
        # Enforces the "format before commit" rule mechanically.
        fmt = pkgs.runCommand "alejandra-check" {nativeBuildInputs = [pkgs.alejandra];} ''
          alejandra --check ${./.} && touch $out
        '';

        # ── VM test ───────────────────────────────────────────────────────────
        # Boots the server profile in a QEMU VM and asserts: multi-user.target
        # reached, user ovg exists, NetworkManager is active.
        server-vm-test = pkgs.testers.runNixOSTest {
          name = "server-profile";
          nodes.server = {...}: {
            imports = [./profiles/server.nix];
            # Inject testSpecialArgs so profile modules receive inputs,
            # dotfilesDir, etc. as function arguments via the module system.
            _module.args = testSpecialArgs;
            networking.hostName = "test-server";
            system.stateVersion = "25.11";
            users.users.ovg = {isNormalUser = true;};
          };
          testScript = ''
            server.wait_for_unit("multi-user.target")
            server.succeed("id ovg")
            server.succeed("systemctl is-active NetworkManager")
          '';
        };
      };
    };
  };
}
