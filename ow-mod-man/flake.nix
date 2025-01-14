{
  description = "Standalone flake for ow-mod-man";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ow-mod-man.url = "github:ow-mods/ow-mod-man";
  };

  outputs = { self, nixpkgs, ow-mod-man }: {
    packages.x86_64-linux = {
      owmods-cli = ow-mod-man.packages.x86_64-linux.owmods-cli;
      owmods-gui = ow-mod-man.packages.x86_64-linux.owmods-gui;
    };
  };
}

