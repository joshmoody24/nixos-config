{ config, pkgs, lib, ... }:

{
  # Note: rust and caddy are intentionally not installed via nix here —
  # they are managed by the redo setup script (linux-setup.sh)
  home.packages = lib.mkAfter (with pkgs; [
    slack
    (config.lib.nixGL.wrap mongodb-compass)
    dbeaver-bin

    awscli2
    bazelisk
    (pkgs.writeShellScriptBin "bazel" "exec bazelisk \"$@\"")
    lsof
    valkey
    ruby

    # ngrok is wrapped below so the declarative theme config is always merged.
    mongosh
    clickhouse
    pnpm
    cloudflared
    nssTools

    # Wrap ngrok to merge the Nix-managed theme config (later --config wins).
    (pkgs.writeShellScriptBin "ngrok" ''
      args=()
      default="$HOME/.config/ngrok/ngrok.yml"
      theme="$HOME/.config/ngrok/theme.yml"
      [ -f "$default" ] && args+=(--config "$default")
      [ -f "$theme" ] && args+=(--config "$theme")
      exec "${pkgs.ngrok}/bin/ngrok" "''${args[@]}" "$@"
    '')
  ]);

  home.file = lib.mkAfter {
    ".config/kitty/redo.session".source = ./dotfiles/redo/redo.session;
    ".config/ngrok/theme.yml".source = ./dotfiles/redo/ngrok-theme.yml;

    # Wrapper so `corepack enable` is a no-op (Nix store is immutable).
    # All shims reference pkgs.nodejs directly so they update automatically
    # when Node is upgraded via the flake — no stale nix store symlinks.
    ".local/bin/corepack" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        if [[ "''${1:-}" == "enable" ]]; then
          exit 0
        fi
        exec "${pkgs.nodejs}/bin/corepack" "$@"
      '';
    };
    ".local/bin/yarn" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        exec "${pkgs.nodejs}/bin/corepack" yarn "$@"
      '';
    };
    ".local/bin/yarnpkg" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        exec "${pkgs.nodejs}/bin/corepack" yarnpkg "$@"
      '';
    };
    ".bashrc.local".text = ''
      source /home/josh/code/redo/tools/bazel-completion.bash
    '';
};
}
