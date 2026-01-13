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
    yarn
    ruby

    firefox
    ngrok
    caddy
    nssTools
  ]);

  home.file = lib.mkAfter {
    "code/redo.ini".source = ./redo.ini;
    ".config/kitty/redo.session".source = ./redo.session;
    ".bashrc.local".text = ''
    alias bazel="distrobox enter redo -- bazelisk"
    alias redoservices="distrobox enter redo -- bazelisk run services redo-cockroachdb redo-valkey temporal-server temporal-worker redo-notice-server redo-api-server redo-merchant-server redo-shopify-server redo-public-server redo-admin-server redo-merchant-app-vite redo-admin-app-vite redo-return-app-vite redo-storefront redo-shopify-extension"
    '';
    ".local/bin/open-browser-from-container" = {
      source = ./open-browser-from-container.sh;
      executable = true;
    };
  };

  # Startup apps currently handled imperatively
}
