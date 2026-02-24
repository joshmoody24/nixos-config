{
  description = "Josh's multi-machine config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    thinkpadPkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ (import ./hosts/thinkpad/overlay.nix) ];
    };
  in {
    # NixOS
    nixosConfigurations.unit = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/unit/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.josh = import ./hosts/unit/home.nix;
        }
      ];
    };

    nixosConfigurations."joshm-framework" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/framework/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.josh = import ./hosts/framework/home.nix;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };

    # Standalone home-manager (Ubuntu)
    homeConfigurations."josh@joshm-thinkpad" = home-manager.lib.homeManagerConfiguration {
      pkgs = thinkpadPkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./hosts/thinkpad/home.nix
      ];
    };
  };
}
