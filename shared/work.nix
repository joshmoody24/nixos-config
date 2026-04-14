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
    (pkgs.writeShellScriptBin "bazel" "exec bazelisk \"$@\"")
    lsof
    valkey
    ruby

    ngrok
    mongosh
    pnpm
    cloudflared
    nssTools
  ]);

  home.file = lib.mkAfter {
    ".config/kitty/redo.session".source = ./dotfiles/redo/redo.session;

    # Wrapper so `corepack enable` is a no-op (Nix store is immutable)
    ".local/bin/corepack" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        if [[ "''${1:-}" == "enable" ]]; then
          exit 0
        fi
        exec "$(dirname "$(readlink -f "$(which nodejs)")")/corepack" "$@"
      '';
    };
    ".bashrc.local".text = ''
      source /home/josh/code/redo/tools/bazel-completion.bash
    '';
    ".aws/config".source = ./dotfiles/redo/aws-config;
  };
}
