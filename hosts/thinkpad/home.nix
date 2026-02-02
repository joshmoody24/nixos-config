{ config, pkgs, lib, ... }:

{
  imports = [../../shared/home.nix];

  home.packages = lib.mkAfter (with pkgs; [
    claude-code
    slack
    mongodb-compass
    dbeaver-bin

    # bazel builds
    distrobox
    awscli2
    bazelisk
    docker
    lsof
    valkey # I don't think this does anything
    yarn
    ruby

    firefox
    ngrok
  ]);

  home.file = lib.mkAfter {
    "code/redo.ini".source = ./redo.ini;
    ".config/kitty/redo.session".source = ./redo.session;
    ".bashrc.local".text = ''
    alias bazel="distrobox enter redo -- bazelisk"
    '';
    ".local/bin/open-browser-from-container" = {
      source = ../../shared/open-browser-from-container.sh;
      executable = true;
    };
  };

  # Startup apps currently handled imperatively
}
