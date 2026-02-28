{
  description = "Suckless NixOS configuration with Flakes and Home Manager";

  # Optimal Nix settings for performance and caching
  nixConfig = {
    extra-substituters = ["https://nix-community.cachix.org"];
    extra-trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
  };

  # External Repository Inputs
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Niri Window Manager
  inputs.niri.url = "github:sodiboo/niri-flake";

  # Zen Browser
  inputs.zen-browser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      home-manager.follows = "home-manager";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    niri,
    ...
  } @ inputs: {
    # Expose alejandra as the canonical formatter so `nix fmt` works.
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations = {
      # Machine name: 'nixos'
      # Build with: sudo nixos-rebuild switch --flake .#nixos
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          # LUKS UUID for the swap/hibernate partition.
          # Defined here once; used in boot.nix and power.nix.
          swapLuksUuid = "9de9918d-99aa-4f0d-8a35-22af09cf8049";
          # Kanata config path resolved from the flake root (more robust than
          # the ../../ relative path inside the module).
          kanataConfig = ./home/ovg/kanata.kbd;
        };
        modules = [
          # Hardware configuration (Machine-specific)
          ./hosts/nixos/hardware-configuration.nix

          # Global NixPKGS configuration
          {
            nixpkgs.overlays = [niri.overlays.niri];
            nixpkgs.config = {
              allowUnfree = true;
              chromium.enableWideVine = true; # Needed for music/video DRM
            };
          }

          # Core System Modules
          niri.nixosModules.niri
          ./modules/system/boot.nix
          ./modules/system/networking.nix
          ./modules/system/locale.nix
          ./modules/system/desktop.nix
          ./modules/system/audio.nix
          ./modules/system/services.nix
          ./modules/system/power.nix
          ./modules/system/input.nix
          ./modules/system/gaming.nix
          ./modules/system/nix.nix

          # Home Manager Bridge
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ovg = import ./home/ovg;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.backupFileExtension = "bak";
          }

          # Host-specific tweaks
          ./hosts/nixos/configuration.nix
        ];
      };
    };
  };
}
