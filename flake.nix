{
  description = "NixOS configuration with flakes and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake";

    emacs-overlay.url = "github:nix-community/emacs-overlay";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = { self, nixpkgs, home-manager, niri, zen-browser, emacs-overlay, ... }@inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Hardware configuration
          ./hosts/nixos/hardware-configuration.nix

          # Overlays and global config
          {
            nixpkgs.overlays = [
              niri.overlays.niri
              emacs-overlay.overlay
            ];

            nixpkgs.config = {
              allowUnfree = true;
              chromium.enableWideVine = true;
            };
          }

          # Window manager and services
          niri.nixosModules.niri

          # System modules
          ./modules/system/boot.nix
          ./modules/system/networking.nix
          ./modules/system/locale.nix
          ./modules/system/desktop.nix
          ./modules/system/audio.nix
          ./modules/system/services.nix
          ./modules/system/power.nix
          ./modules/system/input.nix
          ./modules/system/nix.nix

          # Home manager configuration
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ovg = import ./home/ovg;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "bak";
          }

          # Host specific configuration
          ./hosts/nixos/configuration.nix
        ];
      };
    };
  };
}