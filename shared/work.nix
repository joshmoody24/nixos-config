{ config, pkgs, lib, ... }:

{
  home.packages = lib.mkAfter (with pkgs; [
    slack
    mongodb-compass
    dbeaver-bin

    awscli2
    bazelisk
    lsof
    valkey
    yarn
    ruby

    ngrok
    mongosh
    cloudflared
    caddy
    nssTools
  ]);

  home.file = lib.mkAfter {
    ".config/kitty/redo.session".source = ./dotfiles/redo/redo.session;
  };
}
