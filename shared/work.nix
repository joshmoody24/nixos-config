{ config, pkgs, lib, ... }:

{
  # Note: rust, yarn, and caddy are intentionally not installed via nix here —
  # they are managed by the redo setup script (linux-setup.sh)
  home.packages = lib.mkAfter (with pkgs; [
    slack
    mongodb-compass
    dbeaver-bin

    awscli2
    bazelisk
    lsof
    valkey
    ruby

    ngrok
    mongosh
    cloudflared
    nssTools
  ]);

  home.file = lib.mkAfter {
    ".config/kitty/redo.session".source = ./dotfiles/redo/redo.session;
    ".bashrc.local".text = ''
      if command -v distrobox &>/dev/null; then
        alias bazel="distrobox enter redo -- bazelisk"
      else
        alias bazel="bazelisk"
      fi
      source /home/josh/code/redo/tools/bazel-completion.bash
    '';
    ".aws/config".source = ./dotfiles/redo/aws-config;
  };
}
