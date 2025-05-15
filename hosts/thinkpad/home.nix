{ config, pkgs, lib, ... }:

{
  imports = [../../shared/home.nix];

  home.packages = lib.mkAfter (with pkgs; [
    claude-code
  ]);
}
