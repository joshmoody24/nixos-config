{ config, pkgs, lib, ... }:

{
  imports = [../../shared/home.nix];

  home.packages = lib.mkAfter (with pkgs; [
    claude-code
    slack
    mongodb-compass

    # bazel builds
    distrobox
    awscli2
    bazelisk
    docker
    lsof
    valkey # I don't think this does anything
  ]);

  home.file = lib.mkAfter {
    "code/redo.ini".source = ./redo.ini;
    ".config/kitty/redo.session".source = ./redo.session;
    ".bashrc.local".text = ''
    alias bazel="distrobox enter redo -- bazelisk"
    '';
  };

  # Startup apps currently handled imperatively
}
