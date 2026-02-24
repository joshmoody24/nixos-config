{ config, pkgs, lib, ... }:

{
  home.packages = lib.mkAfter (with pkgs; [
    (symlinkJoin {
      name = "slack";
      paths = [ slack ];
      buildInputs = [ makeWrapper ];
      postBuild = ''wrapProgram $out/bin/slack --add-flags "--no-sandbox"'';
    })
    (symlinkJoin {
      name = "mongodb-compass";
      paths = [ mongodb-compass ];
      buildInputs = [ makeWrapper ];
      postBuild = ''wrapProgram $out/bin/mongodb-compass --add-flags "--no-sandbox"'';
    })
    dbeaver-bin

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
