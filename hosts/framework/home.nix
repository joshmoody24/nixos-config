{ config, pkgs, lib, ... }:

{
  imports = [
    ../../shared/home.nix
    ../../shared/work.nix
  ];

  home.packages = with pkgs; [
    distrobox
    docker
  ];
}
