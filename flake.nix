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

    # Declarative disk partitioning — used by install.sh on fresh installs.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
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

    # Build a headless NixOS installer ISO for a given system architecture.
    # Includes NetworkManager (nmtui), git, alejandra, and a bootstrap script
    # that clones the dotfiles repo and runs install.sh.
    # Usage: nix build .#installMedia-x86_64
    mkInstaller = system:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({
            pkgs,
            lib,
            ...
          }: {
            # Enable flakes + nix command so the live env can run `nix build .#…`
            # without extra flags. The minimal installer image does not set this.
            nix.settings.experimental-features = ["nix-command" "flakes"];

            # NetworkManager (includes nmtui). Disable the installer's default
            # wpa_supplicant so the two wifi stacks don't conflict.
            networking.networkmanager.enable = true;
            networking.wireless.enable = lib.mkForce false;

            environment.systemPackages = [
              pkgs.alejandra
              pkgs.git
              inputs.disko.packages.${system}.default
              # One-shot helper: clone dotfiles from GitHub, then run install.sh.
              (pkgs.writeShellScriptBin "bootstrap" ''
                set -euo pipefail
                DEST="/home/ovg/dotfiles/nix"
                if [ ! -d "$DEST" ]; then
                  mkdir -p /home/ovg/dotfiles
                  git clone https://github.com/Ovgiliot/nix-config.git "$DEST"
                else
                  git -C "$DEST" pull
                fi
                cd "$DEST"
                bash install.sh
              '')
            ];

            # Hint displayed at the login prompt after boot.
            services.getty.helpLine =
              lib.mkForce
              "\nRun 'bootstrap' to clone the config and start installation.";
          })
        ];
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
      installer-x86_64 = mkInstaller "x86_64-linux";
      # <<NIXOS_HOSTS>>
    };

    # macOS hosts (nix-darwin)
    # First run:   nix run nix-darwin -- switch --flake .#<hostname>
    # Subsequent:  darwin-rebuild switch --flake .#<hostname>
    darwinConfigurations = {
      # <<DARWIN_HOSTS>>
    };

    # Installer USB images.
    # Build:  nix build .#installMedia-x86_64
    # Flash:  nix run .#flash -- /dev/sdX  (installs Ventoy + copies ISO)
    packages = {
      x86_64-linux = {
        installMedia-x86_64 =
          self.nixosConfigurations.installer-x86_64.config.system.build.isoImage;
      };
    };

    # Flash helper: installs Ventoy on a USB drive and copies the installer ISO.
    # Usage: nix run .#flash -- /dev/sdX
    apps = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      x86_iso = self.nixosConfigurations.installer-x86_64.config.system.build.isoImage;
    in {
      x86_64-linux.flash = {
        type = "app";
        program = toString (pkgs.writeShellScript "flash-usb" ''
          set -euo pipefail
          DEVICE=''${1:?Usage: nix run .#flash -- /dev/sdX}
          echo "==> This will ERASE $DEVICE. Continue? [y/N]"
          read -r yn
          [[ "$yn" =~ ^[Yy]$ ]] || exit 1
          echo "==> Installing Ventoy on $DEVICE..."
          sudo ${pkgs.ventoy}/bin/ventoy -I "$DEVICE"
          sudo udevadm settle
          MNT=$(mktemp -d)
          # Ventoy puts the ISO data partition first (/dev/sdX1).
          sudo mount "''${DEVICE}1" "$MNT"
          echo "==> Copying NixOS installer ISO..."
          sudo cp ${x86_iso}/iso/*.iso "$MNT/"
          sudo umount "$MNT"
          rmdir "$MNT"
          echo "==> Done. Boot from USB on any x86_64 UEFI machine."
          echo "    Select the NixOS ISO from the Ventoy menu."
          echo "    Then: nmtui  ->  bootstrap"
        '');
      };
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
        # Swap resume device — empty disables hibernate (laptop profile only).
        swapDevice = "";
        # kanata.kbd must be a real file so builtins.readFile can evaluate.
        kanataConfig = ./home/ovg/kanata.kbd;
        # Placeholder device path — consumed by input.nix (workstation + laptop).
        kanataDevice = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        # No Intel hardware in test environments; skip VA-API packages.
        videoAcceleration = "none";
        # Placeholder primary user for greetd autologin (display.nix).
        primaryUser = "ovg";
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
