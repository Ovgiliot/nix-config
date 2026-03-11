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
    # Instantiate nixpkgs for a given system with allowUnfree enabled globally.
    # Used for all imperative pkgs references (formatter, checks, apps, installer).
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

    # Build a headless NixOS installer ISO for a given system architecture.
    # Includes NetworkManager (nmtui), disko, alejandra, a full diagnostic
    # toolset, and a bootstrap script that clones the dotfiles repo and runs
    # install.sh.
    # Usage: nix build .#installMedia-x86_64
    mkInstaller = system:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          {nixpkgs.config.allowUnfree = true;}
          ({
            pkgs,
            lib,
            ...
          }: {
            # Enable flakes + nix command so the live env can run `nix build .#…`
            # without extra flags. The minimal installer image does not set this.
            nix.settings.experimental-features = ["nix-command" "flakes"];

            # The base installer profile (installation-device.nix) already
            # enables NetworkManager. The NM module itself sets
            # networking.wireless.enable = true with dbusControlled = true,
            # which is how it registers and manages its own wpa_supplicant
            # backend. Do NOT override wireless.enable — doing so breaks WiFi.

            environment.systemPackages = with pkgs; [
              # ── installer essentials ──────────────────────────────────────
              alejandra
              inputs.disko.packages.${system}.default
              whois # provides mkpasswd (used by install.sh for password hashing)

              # ── WiFi ─────────────────────────────────────────────────────
              # wpa_supplicant is NM's WiFi backend (default). NM's module
              # enables it via networking.wireless with dbusControlled = true.
              # Listed here explicitly for clarity; NM adds it automatically.
              wpa_supplicant
              iw # show / configure wireless interfaces
              wirelesstools # iwconfig, iwlist, iwpriv

              # ── network diagnostics ───────────────────────────────────────
              ethtool # NIC statistics and low-level settings
              nmap # network scanner + host discovery
              wget
              curl
              lsof # open files / sockets per process

              # ── disk / partitioning ───────────────────────────────────────
              lvm2 # LVM volume management
              e2fsprogs # mkfs.ext4, e2fsck, tune2fs
              btrfs-progs # mkfs.btrfs, btrfs subvolume …
              dosfstools # mkfs.fat, fsck.fat
              xfsprogs # mkfs.xfs, xfs_repair
              f2fs-tools # mkfs.f2fs

              # ── hardware info ─────────────────────────────────────────────
              dmidecode # SMBIOS / DMI (board, memory, BIOS)
              lshw # comprehensive hardware lister
              lm_sensors # CPU / board temps and voltages
              inxi # system info summary

              # ── UEFI ──────────────────────────────────────────────────────
              efitools # inspect and sign EFI binaries

              # ── system / debug ────────────────────────────────────────────
              htop
              btop
              strace # syscall tracer
              file # identify file types by magic bytes
              tree # directory listing
              nano # second editor alongside vim (already in base)

              # ── one-shot install helper ───────────────────────────────────
              # Clone dotfiles from GitHub then hand off to install.sh.
              (writeShellScriptBin "bootstrap" ''
                set -euo pipefail
                DEST="/home/ethel/dotfiles/nix"
                if [ ! -d "$DEST" ]; then
                  mkdir -p /home/ethel/dotfiles
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
      x86_64-linux = (mkPkgs "x86_64-linux").alejandra;
      aarch64-darwin = (mkPkgs "aarch64-darwin").alejandra;
      x86_64-darwin = (mkPkgs "x86_64-darwin").alejandra;
    };

    # NixOS hosts
    # Build:  sudo nixos-rebuild switch --flake .#<hostname>
    nixosConfigurations = {
      nixos = mkNixosHost "nixos";
      nixpad = mkNixosHost "nixpad";
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

    # Flash helper: writes the installer ISO directly to a USB drive with dd.
    # Usage: nix run .#flash -- /dev/sdX
    apps = let
      pkgs = mkPkgs "x86_64-linux";
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
          ISO=$(ls ${x86_iso}/iso/*.iso | head -1)
          [[ -f "$ISO" ]] || { echo "err: no ISO found in ${x86_iso}/iso/"; exit 1; }
          echo "==> Writing $(basename "$ISO") to $DEVICE..."
          sudo dd if="$ISO" of="$DEVICE" bs=4M status=progress conv=fsync
          echo "==> Done. Boot from $DEVICE on any x86_64 UEFI machine."
        '');
      };
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
          test -f ${./home/ethel/ghostty/config}                 || exit 1
          test -e ${./home/ethel/ghostty/shaders}                || exit 1
          test -f ${./home/ethel/matugen/config.toml}                        || exit 1
          test -f ${./home/ethel/matugen/templates/ghostty-colors.conf}      || exit 1
          test -f ${./home/ethel/matugen/templates/mako.conf}                || exit 1
          test -f ${./home/ethel/matugen/templates/wofi-colors.css}          || exit 1
          test -f ${./home/ethel/matugen/templates/niri-colors.kdl}          || exit 1
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
          test -f ${./home/ethel/quickshell/StatusPoller.qml}          || exit 1
          test -f ${./home/ethel/quickshell/WifiMonitor.qml}           || exit 1
          test -f ${./home/ethel/quickshell/Colors.qml}                || exit 1
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
          nodes.server = {...}: {
            imports = [./profiles/server.nix];
            # Inject testSpecialArgs so profile modules receive inputs,
            # dotfilesDir, etc. as function arguments via the module system.
            _module.args = testSpecialArgs;
            networking.hostName = "test-server";
            system.stateVersion = "25.11";
            users.users.ethel = {isNormalUser = true;};
          };
          testScript = ''
            server.wait_for_unit("multi-user.target")
            server.succeed("id ethel")
            server.succeed("systemctl is-active NetworkManager")
          '';
        };

        # ── Install pipeline test ────────────────────────────────────────────
        # Runs install.sh --unattended --skip-disko inside a VM.
        # Exercises: template generation for disko.nix / default.nix,
        # flake.nix patching, passwordFile stripping, and alejandra formatting.
        # Disko partitioning is skipped (requires internet in the VM to build
        # the partitioning script).  Actual partitioning is implicitly tested
        # by server-build.
        install-server-test = pkgs.testers.runNixOSTest {
          name = "install-server";
          nodes.installer = {pkgs, ...}: {
            environment.systemPackages = with pkgs; [
              alejandra
              whois # provides mkpasswd (used by install.sh for password hashing)
            ];
            # Copy the flake source tree into the VM (read-only in nix store).
            environment.etc."test-flake".source = ./.;
            virtualisation.memorySize = 2048;
          };
          testScript = ''
            installer.wait_for_unit("multi-user.target")

            # Copy flake to a writable location.
            # -L dereferences symlinks (environment.etc creates symlink trees
            # pointing into the read-only nix store).
            # --no-preserve=all ensures copies get default writable permissions.
            installer.succeed("cp -rL --no-preserve=all /etc/test-flake /tmp/test-flake")

            # Run install.sh in unattended mode, skipping disko + install.
            installer.succeed(
                "cd /tmp/test-flake && "
                "PROFILE=server "
                "TARGET_HOST=installtest "
                "SYSTEM_DISK=/dev/vda "
                "SEPARATE_HOME=false "
                "ROOT_SIZE=4G "
                "LUKS_PASSPHRASE=testpassword "
                "INITIAL_PASSWORD=testpass123 "
                "bash install.sh --unattended --skip-disko"
            )

            # ── Verify generated files exist ───────────────────────────────
            installer.succeed("test -f /tmp/test-flake/hosts/installtest/disko.nix")
            installer.succeed("test -f /tmp/test-flake/hosts/installtest/hardware.nix")
            installer.succeed("test -f /tmp/test-flake/hosts/installtest/default.nix")

            # ── Verify formatting is clean ─────────────────────────────────
            installer.succeed("alejandra --check /tmp/test-flake/hosts/installtest/")

            # ── Verify flake.nix was patched with new host ─────────────────
            installer.succeed("grep -q 'installtest = mkNixosHost' /tmp/test-flake/flake.nix")

            # ── Verify passwordFile lines were stripped from disko.nix ─────
            installer.succeed("! grep -q 'passwordFile' /tmp/test-flake/hosts/installtest/disko.nix")

            # ── Verify disko.nix has a disk device configured ──────────────
            installer.succeed("grep -q 'device =' /tmp/test-flake/hosts/installtest/disko.nix")

            # ── Verify default.nix imports disko module and disko.nix ──────
            installer.succeed("grep -q 'disko.nixosModules.disko' /tmp/test-flake/hosts/installtest/default.nix")
            installer.succeed("grep -q './disko.nix' /tmp/test-flake/hosts/installtest/default.nix")

            # ── Verify default.nix has correct profile and hostname ────────
            installer.succeed("grep -q 'server.nix' /tmp/test-flake/hosts/installtest/default.nix")
            installer.succeed("grep -q 'installtest' /tmp/test-flake/hosts/installtest/default.nix")

            # ── Verify password is hashed (no plaintext initialPassword) ───
            installer.succeed("grep -q 'initialHashedPassword' /tmp/test-flake/hosts/installtest/default.nix")
            installer.succeed("! grep -q 'initialPassword' /tmp/test-flake/hosts/installtest/default.nix")
          '';
        };
      };
    };
  };
}
