{ config, pkgs, ... }:

{
  imports = [../../shared/home.nix];

  home.packages = with pkgs; [
    remmina
    (blender.override { rocmSupport = true; })
    pciutils # for gnome extension Astra Monitor
    lm_sensors # temperature monitoring
    amdgpu_top
    llama-cpp
    ollama-rocm
    godot
    obsidian
    gqrx
    rtl-sdr
    krita
    aseprite
    ardour

    # for old windows games
    lutris
    wineWowPackages.full
    winetricks
    cdrtools
    gamescope

    prismlauncher

    fennel-ls
    lua54Packages.fennel
    lua54Packages.luarocks
    fnlfmt

    claude-code

    discord

    mgba
    (retroarch.withCores (cores: with cores; [ mupen64plus ]))

    vintagestory
  ];

  home.stateVersion = "25.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
