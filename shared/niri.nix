{ config, pkgs, lib, ... }:

let
  niriWrapped = config.lib.nixGL.wrap pkgs.niri;
in
{
  home.packages = with pkgs; [
    # Nix builds look for Mesa under /run/opengl-driver, which Ubuntu has no
    # reason to provide, so anything touching the GPU needs nixGL.
    niriWrapped
    # X11 apps have no way to reach a Wayland-only compositor without this.
    xwayland-satellite

    (config.lib.nixGL.wrap waybar)
    mako
    fuzzel
    # swaylock is deliberately Ubuntu's, not ours: nix's libpam only looks for
    # modules inside its own store path, so a nix swaylock cannot load the
    # system's pam_unix and rejects every password. framework.sh apt-installs it.
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

    # Drag-and-drop display arrangement, which writes monitor.kdl for us.
    nwg-displays
    wlr-randr
  ];

  home.file = {
    ".config/niri/config.kdl".source = ./dotfiles/niri/config.kdl;

    # nwg-displays rewrites this when you drag monitors around, so it points at
    # the checkout rather than the store: a store copy would be read-only, and
    # the edits are what we want to commit.
    ".config/niri/monitor.kdl".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/code/nixos-config/shared/dotfiles/niri/monitor.kdl";
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

  # Ubuntu's portal backends declare Requisite=graphical-session.target, so they
  # refuse to start until something activates it. niri.service is what binds that
  # target; `niri --session` on its own never reaches it, which left every GTK app
  # hanging on the portal at startup.
  home.file.".config/systemd/user/niri.service".source =
    "${niriWrapped}/share/systemd/user/niri.service";
  home.file.".config/systemd/user/niri-shutdown.target".source =
    "${niriWrapped}/share/systemd/user/niri-shutdown.target";

  # The agent ships in libexec, where spawn-at-startup's bare name can't see it.
  home.file.".local/bin/polkit-agent".source =
    "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
}
