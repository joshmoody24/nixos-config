{ config, pkgs, lib, ... }:

{
  home.packages = lib.mkAfter (with pkgs; [
    slack
    mongodb-compass
    dbeaver-bin

    distrobox
    docker
    awscli2
    bazelisk
    lsof
    valkey
    yarn
    ruby
    rustup

    ngrok
    mongosh
    cloudflared
    caddy
    nssTools
  ]);

  home.file = lib.mkAfter {
    ".config/kitty/redo.session".source = ./dotfiles/redo/redo.session;
    ".bashrc.local".text = ''
      alias bazel="distrobox enter redo -- bazelisk"
      source /home/josh/code/redo/tools/bazel-completion.bash
    '';
    ".aws/config".source = ./dotfiles/redo/aws-config;
  };
}
