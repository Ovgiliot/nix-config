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
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    ...
  } @ inputs: let
    # Instantiate nixpkgs for a given system with allowUnfree enabled globally.
    # Used for all imperative pkgs references (formatter, checks).
    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

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
      x86_64-linux = (mkPkgs "x86_64-linux").alejandra;
      aarch64-darwin = (mkPkgs "aarch64-darwin").alejandra;
      x86_64-darwin = (mkPkgs "x86_64-darwin").alejandra;
    };

    # NixOS hosts
    # Build:  sudo nixos-rebuild switch --flake .#<hostname>
    nixosConfigurations = {
      nixos = mkNixosHost "nixos";
      nixpad = mkNixosHost "nixpad";
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
      pkgs = mkPkgs "x86_64-linux";

      # Stub specialArgs used for profile eval/build tests.
      # Real values are host-specific; these are sufficient for evaluation.
      testSpecialArgs = {
        inherit inputs;
        dotfilesDir = ./home/ethel;
        # Placeholder UUID — only consumed by laptop/boot.nix and power.nix,
        # neither of which is imported by server or workstation profiles.
        swapLuksUuid = "00000000-0000-0000-0000-000000000000";
        # Swap resume device — empty disables hibernate (laptop profile only).
        swapDevice = "";
        # kanata.kbd must be a real file so builtins.readFile can evaluate.
        kanataConfig = ./home/ethel/kanata.kbd;
        # Placeholder device path — consumed by input.nix (workstation + laptop).
        kanataDevice = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        # No Intel hardware in test environments; skip VA-API packages.
        videoAcceleration = "none";
        # Placeholder primary user for greetd autologin (display.nix).
        primaryUser = "ethel";
      };

      # Minimal NixOS host module shared by all profile tests.
      testHostModule = {
        networking.hostName = "test";
        system.stateVersion = "25.11";
        users.users.ethel = {isNormalUser = true;};
        # Stub root filesystem — suppresses the NixOS assertion that fileSystems."/"
        # must be defined. Real hosts get this from hardware.nix.
        fileSystems."/" = {
          device = "/dev/null";
          fsType = "tmpfs";
        };
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
          test -e ${./home/ethel/nvim}                           || exit 1
          test -f ${./home/ethel/ranger/rc.conf}                 || exit 1
          test -f ${./home/ethel/ranger/rifle.conf}              || exit 1
          test -f ${./home/ethel/ranger/scope.sh}                || exit 1
          test -f ${./home/ethel/opencode/agents/talk.md}        || exit 1
          test -e ${./home/ethel/niri}                           || exit 1
          test -e ${./home/ethel/hypr}                           || exit 1
          test -f ${./home/ethel/hypr/hyprland.conf}             || exit 1
          test -f ${./home/ethel/hypr/hypridle.conf}             || exit 1
          test -f ${./home/ethel/hypr/hyprlock.conf}             || exit 1
          test -f ${./home/ethel/ghostty/config}                 || exit 1
          test -e ${./home/ethel/ghostty/shaders}                || exit 1
          test -f ${./home/ethel/matugen/config.toml}                        || exit 1
          test -f ${./home/ethel/matugen/templates/ghostty-colors.conf}      || exit 1
          test -f ${./home/ethel/matugen/templates/mako.conf}                || exit 1
          test -f ${./home/ethel/matugen/templates/wofi-colors.css}          || exit 1
          test -f ${./home/ethel/matugen/templates/niri-colors.kdl}          || exit 1
          test -f ${./home/ethel/matugen/templates/hyprland-colors.conf}    || exit 1
          test -f ${./home/ethel/matugen/templates/hyprlock-colors.conf}    || exit 1
          test -f ${./home/ethel/matugen/templates/qs-colors.json}           || exit 1
          test -f ${./home/ethel/matugen/templates/gtk3.css}                 || exit 1
          test -f ${./home/ethel/matugen/templates/gtk4.css}                 || exit 1
          test -f ${./home/ethel/matugen/templates/swaylock.conf}            || exit 1
          test -f ${./home/ethel/matugen/templates/qutebrowser-colors.py}    || exit 1
          test -f ${./home/ethel/matugen/templates/nvim-lualine.lua}         || exit 1
          test -f ${./home/ethel/matugen/templates/nvim-highlights.lua}      || exit 1
          test -f ${./home/ethel/qutebrowser/config.py}                      || exit 1
          test -f ${./home/ethel/quickshell/shell.qml}                  || exit 1
          test -f ${./home/ethel/quickshell/Clock.qml}                 || exit 1
          test -f ${./home/ethel/quickshell/Workspaces.qml}            || exit 1
          test -f ${./home/ethel/quickshell/CpuMem.qml}                || exit 1
          test -f ${./home/ethel/quickshell/InfoBox.qml}               || exit 1
          test -f ${./home/ethel/quickshell/Language.qml}              || exit 1
          test -f ${./home/ethel/quickshell/StatusIcons.qml}           || exit 1
          test -f ${./home/ethel/quickshell/NiriIpc.qml}               || exit 1
          test -f ${./home/ethel/quickshell/HyprlandIpc.qml}           || exit 1
          test -f ${./home/ethel/quickshell/StatusPoller.qml}          || exit 1
          test -f ${./home/ethel/quickshell/WifiMonitor.qml}           || exit 1
          test -f ${./home/ethel/quickshell/Colors.qml}                || exit 1
          test -f ${./home/ethel/quickshell/Columns.qml}               || exit 1
          test -f ${./home/ethel/quickshell/WallpaperPicker.qml}       || exit 1
          test -f ${./home/ethel/quickshell/AudioVisualizer.qml}      || exit 1
          test -f ${./home/ethel/quickshell/scripts/wifi-monitor.sh}   || exit 1
          test -f ${./home/ethel/quickshell/scripts/system-stats.sh}   || exit 1
          test -f ${./home/ethel/wofi/config}                     || exit 1
          test -f ${./home/ethel/wofi/scripts/wifi-menu.sh}      || exit 1
          test -f ${./home/ethel/wofi/scripts/bluetooth-menu.sh} || exit 1
          test -f ${./home/ethel/wofi/scripts/power-menu.sh}     || exit 1
          test -f ${./home/ethel/wofi/scripts/audio-switcher.sh} || exit 1
          test -f ${./home/ethel/kanata.kbd}                     || exit 1
          test -f ${./home/ethel/scripts/power-monitor.sh}       || exit 1
          test -f ${./home/ethel/scripts/nixos-rebuild-with-git.sh} || exit 1
          test -f ${./home/ethel/scripts/update.sh}              || exit 1
          test -f ${./home/ethel/scripts/windows-vm.sh}           || exit 1
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
        # reached, user ethel exists, NetworkManager is active.
        server-vm-test = pkgs.testers.runNixOSTest {
          name = "server-profile";
          node.specialArgs = testSpecialArgs;
          # Our core/nix.nix sets nixpkgs.config.allowUnfree, which conflicts
          # with the test framework's read-only nixpkgs module. Passing node.pkgs
          # ensures the test uses our pkgs (which already has allowUnfree), and
          # pkgsReadOnly = false re-enables the standard nixpkgs module so our
          # module's nixpkgs.config definition merges normally.
          node.pkgs = pkgs;
          node.pkgsReadOnly = false;
          nodes.server = {
            imports = [./profiles/server.nix];
            networking.hostName = "server";
            system.stateVersion = "25.11";
            users.users.ethel = {isNormalUser = true;};
            fileSystems."/" = {
              device = "/dev/null";
              fsType = "tmpfs";
            };
          };
          testScript = ''
            server.wait_for_unit("multi-user.target")
            server.succeed("id ethel")
            server.succeed("systemctl is-active NetworkManager")
          '';
        };
      };
    };
  };
}
