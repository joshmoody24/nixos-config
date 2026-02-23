{ config, pkgs, lib, ... }:

{
  imports = [../../shared/home.nix];

  home.packages = lib.mkAfter (with pkgs; [
    slack
    mongodb-compass
    dbeaver-bin

    awscli2
    bazelisk
    lsof
    valkey # I don't think this does anything
    yarn
    ruby

    ngrok
  ]);

  home.file = lib.mkAfter {
    ".config/kitty/redo.session".source = ./redo.session;
  };

  # Startup apps currently handled imperatively
}
