{
  description = "Josh's multi-machine config (NixOS + Ubuntu)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
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

    # Standalone home-manager (Ubuntu)
    homeConfigurations."josh@joshm-thinkpad" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./hosts/thinkpad/home.nix
        { home.backupFileExtension = "backup"; }
      ];
    };

    homeConfigurations."josh@joshm-framework" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./hosts/framework/home.nix
        { home.backupFileExtension = "backup"; }
      ];
    };
  };
}
