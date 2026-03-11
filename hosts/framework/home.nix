{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../shared/home.nix
    ../../shared/work.nix
  ];

  targets.genericLinux.nixGL.packages = inputs.nixgl.packages;
  targets.genericLinux.nixGL.defaultWrapper = "mesa";
  targets.genericLinux.nixGL.installScripts = ["mesa"];

  home.packages = with pkgs; [
  ];
}
