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
    # Pinned to the commit lazy-lock.json gives the nvim plugin, so the editor
    # and the desktop cannot drift onto different versions of the same theme.
    # shared/theme.nix asserts the two agree.
    tokyonight = {
      url = "github:folke/tokyonight.nvim/cdc07ac78467a233fd62c493de29a17e0cf2b2b6";
      flake = false;
    };

    redo-dashboard = {
      url = "git+ssh://git@github.com/joshmoody24/redo-dashboard.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          deque = final.callPackage ./shared/pkgs/deque.nix { };

          # The rewritten wrap-gapps-hook needs $output in scope, which stdenv
          # only sets during fixupPhase — skipped by mongodb-compass's buildCommand.
          mongodb-compass = prev.mongodb-compass.overrideAttrs (old: {
            buildCommand = builtins.replaceStrings
              [ "wrapGAppsHook $out/bin/mongodb-compass" ]
              [ "output=out wrapGAppsHook" ]
              old.buildCommand;
          });
        })
      ];
    };
  in {
    packages.${system} = { inherit (pkgs) deque; };

    # NixOS
    nixosConfigurations.unit = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hosts/unit/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.josh = import ./hosts/unit/home.nix;
        }
      ];
    };

    # Standalone home-manager (Ubuntu)
    homeConfigurations."josh@joshm-framework" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./hosts/framework/home.nix
      ];
    };

    homeConfigurations."josh@joshm-thinkpad" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./hosts/thinkpad/home.nix
      ];
    };
  };
}
