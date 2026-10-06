{ config, pkgs, ... }:

let
  # Vulkan decodes ~38% faster than ROCm at long context on RDNA 3.
  llamaCpp = pkgs.llama-cpp.override { vulkanSupport = true; };
in
{
  imports = [../../shared/home.nix];

  home.packages = with pkgs; [
    google-chrome
    firefox

    remmina
    (blender.override { rocmSupport = true; })
    pciutils # for gnome extension Astra Monitor
    lm_sensors # temperature monitoring
    amdgpu_top
    llamaCpp
    pi-coding-agent

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
  ];

  # The router idles at ~1 GiB (nothing loaded until pi's /llama picks a model),
  # so leaving it up costs no VRAM and pi never has to be told where to connect.
  systemd.user.services.llama-router = {
    Unit.Description = "llama.cpp router for local coding models";
    Service = {
      ExecStart = "${config.home.homeDirectory}/.local/bin/llm-serve";
      Environment = "PATH=${llamaCpp}/bin:${pkgs.coreutils}/bin:${pkgs.gawk}/bin:${pkgs.findutils}/bin:${pkgs.curl}/bin";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.stateVersion = "25.05";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
