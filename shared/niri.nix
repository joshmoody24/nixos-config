{ config, pkgs, lib, ... }:

let
  # Identity outside genericLinux, so this is a no-op on NixOS.
  niriWrapped = config.lib.nixGL.wrap pkgs.niri;
  standalone = config.niri.standalone;
in
{
  options.niri = {
    standalone = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether home-manager is providing the whole session itself, rather than
        a NixOS `programs.niri.enable` that already installs niri, its systemd
        units and its portal config.
      '';
    };

    monitors = lib.mkOption {
      type = lib.types.str;
      description = ''
        Path within this checkout to the host's monitor.kdl. A repo-relative
        string rather than a path, because it is symlinked out of the store so
        nwg-displays can write to it.
      '';
    };
  };

  config = {
  home.packages = with pkgs; [
    # X11 apps have no way to reach a Wayland-only compositor without this.
    xwayland-satellite

    (config.lib.nixGL.wrap waybar)
    mako
    fuzzel
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
  ]
  # On NixOS these come from programs.niri.enable and the system's PAM.
  ++ lib.optional standalone niriWrapped
  ++ lib.optional (!standalone) pkgs.swaylock;

  home.file = {
    ".config/niri/config.kdl".source = ./dotfiles/niri/config.kdl;

    # nwg-displays rewrites this when you drag monitors around, so it points at
    # the checkout rather than the store: a store copy would be read-only, and
    # the edits are what we want to commit.
    ".config/niri/monitor.kdl".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/code/nixos-config/${config.niri.monitors}";
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

    # The agent ships in libexec, where spawn-at-startup's bare name can't see it.
    ".local/bin/polkit-agent".source =
      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  }
  # Portal backends declare Requisite=graphical-session.target and refuse to
  # start until it is active. niri.service is what binds that target; a bare
  # `niri --session` never reaches it, which leaves every GTK app hanging on the
  # portal at startup. NixOS installs these units itself.
  // lib.optionalAttrs standalone {
    ".config/systemd/user/niri.service".source =
      "${niriWrapped}/share/systemd/user/niri.service";
    ".config/systemd/user/niri-shutdown.target".source =
      "${niriWrapped}/share/systemd/user/niri-shutdown.target";
  };
  };
}
