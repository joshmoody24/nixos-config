{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Nix builds look for Mesa under /run/opengl-driver, which Ubuntu has no
    # reason to provide, so anything touching the GPU needs nixGL.
    (config.lib.nixGL.wrap niri)
    # X11 apps have no way to reach a Wayland-only compositor without this.
    xwayland-satellite

    (config.lib.nixGL.wrap waybar)
    mako
    fuzzel
    (config.lib.nixGL.wrap swaylock)
    swayidle
    swaybg

    cliphist
    wl-clipboard

    # Nothing in a bare niri session answers an authentication prompt.
    polkit_gnome

    brightnessctl
    playerctl
    pavucontrol

    grim
    slurp
    # niri speaks wlr-screencopy, not the newer ext-image-copy-capture.
    (config.lib.nixGL.wrap wl-screenrec)
    libnotify

    networkmanagerapplet
  ];

  home.file = {
    ".config/niri/config.kdl".source = ./dotfiles/niri/config.kdl;
    ".local/bin/screenrec" = {
      source = ./dotfiles/niri/screenrec;
      executable = true;
    };

    # The capture shortcuts are rare enough to forget, so the launcher lists
    # them with their keys in the name.
    ".local/share/applications" = {
      source = ./dotfiles/niri/applications;
      recursive = true;
    };
    ".config/waybar/config.jsonc".source = ./dotfiles/waybar/config.jsonc;
    ".config/waybar/style.css".source = ./dotfiles/waybar/style.css;
    ".config/mako/config".source = ./dotfiles/mako/config;
    ".config/fuzzel/fuzzel.ini".source = ./dotfiles/fuzzel/fuzzel.ini;
    ".config/swaylock/config".source = ./dotfiles/swaylock/config;
  };

  # The agent ships in libexec, where spawn-at-startup's bare name can't see it.
  home.file.".local/bin/polkit-agent".source =
    "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
}
