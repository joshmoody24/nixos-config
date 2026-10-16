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
    inherit (nixpkgs) lib;
    system = "x86_64-linux";
    pkgs = import nixpkgs ({ inherit system; } // import ./shared/nixpkgs.nix);

    hosts = import ./hosts.nix;
    running = os: lib.filterAttrs (_: host: host.os == os) hosts;
  in {
    packages.${system} = { inherit (pkgs) deque; };

    # How the Ubuntu scripts turn `hostname` back into a host in this repo.
    hostNames = lib.mapAttrs' (name: host: lib.nameValuePair host.hostname name) hosts;

    nixosConfigurations = lib.mapAttrs (name: host: lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/${name}/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.josh = import ./hosts/${name}/home.nix;
        }
      ];
    }) (running "nixos");

    # Ubuntu gets home-manager on its own, so these are named the way
    # `home-manager switch` looks them up: user@hostname.
    homeConfigurations = lib.mapAttrs'
      (name: host: lib.nameValuePair "josh@${host.hostname}"
        (home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./hosts/${name}/home.nix ];
        }))
      (running "ubuntu");
  };
}
