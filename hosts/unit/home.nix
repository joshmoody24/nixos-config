{ config, pkgs, ... }:

{
  imports = [
    ../../shared/home.nix
    ../../shared/llm.nix
    ../../shared/niri.nix
    ../../shared/webcam-white-balance.nix
  ];

  niri.monitors = "hosts/unit/monitor.kdl";

  webcam.whiteBalance = {
    device = "/dev/v4l/by-id/usb-USB_CAMERA_USB_CAMERA_240725172848-video-index0";
    temperature = 2800;
  };

  home.packages = with pkgs; [
    remmina
    (blender.override { rocmSupport = true; })
    pciutils # for gnome extension Astra Monitor
    lm_sensors # temperature monitoring
    amdgpu_top

    godot
    obsidian
    # gqrx # temporarily disabled - gr-osmosdr broken with Boost 1.89.0
    rtl-sdr
    krita
    aseprite
    ardour

    # for old windows games
    lutris
    wineWow64Packages.full
    winetricks
    cdrtools
    gamescope

    prismlauncher

    fennel-ls
    lua54Packages.fennel
    lua54Packages.luarocks
    fnlfmt

    discord

    mgba
    (retroarch.withCores (cores: with cores; [ mupen64plus ]))

    vintagestory
    dusklight

    # This is the only machine where josh's own session is GNOME.
    gnome-tweaks
    gnomeExtensions.clipboard-history
    gnomeExtensions.blur-my-shell
  ];

  home.stateVersion = "25.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
