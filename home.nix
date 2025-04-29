{ config, pkgs, ... }:

{
  home.username = "josh";
  home.homeDirectory = "/home/josh";

  # link the configuration file in current directory to the specified location in home directory
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # link all files in `./scripts` to `~/.config/i3/scripts`
  home.file = {
    ".bashrc".source = ./dotfiles/.bashrc;

    ".config/nvim/init.lua".source = ./dotfiles/nvim/init.lua;
    ".config/nvim/lua" = {
      source = ./dotfiles/nvim/lua;
      recursive = true; # Ensures the entire directory is copied
    };

    ".config/kitty/current-theme.conf".source = ./dotfiles/kitty/current-theme.conf;
  };

  # encode the file content in nix configuration file directly
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    blender-hip
    pciutils # for gnome extension Astra Monitor
    lm_sensors # temperature monitoring
    amdgpu_top
    llama-cpp
    ollama-rocm
    godot
    obsidian
    sdrpp
    gqrx
    rtl-sdr
    owmods-cli
    krita
    cascadia-code
    clojure
    openjdk
    clojure-lsp
    gimp
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
  ];

  fonts.fontconfig.enable = true;

  programs.git = {
    enable = true;
    userName = "joshmoody24";
    userEmail = "joshmoody24@gmail.com";
    aliases = {
      s = "status";
      amen = "commit --amend --no-edit";
      flease = "git push --force-with-lease";
    };
  };

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./dotfiles/kitty/kitty.conf;
  };

  home.stateVersion = "25.05";

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
