{ config, pkgs, ... }:

{
  home.username = "josh";
  home.homeDirectory = "/home/josh";

  home.file = {
    ".bashrc".source = ./dotfiles/.bashrc;

    ".config/nvim/init.lua".source = ./dotfiles/nvim/init.lua;
    ".config/nvim/lua" = {
      source = ./dotfiles/nvim/lua;
      recursive = true;
    };

    ".config/kitty/current-theme.conf".source = ./dotfiles/kitty/current-theme.conf;

    ".gitconfig".source = ./dotfiles/.gitconfig;
  };

  home.packages = with pkgs; [
    cascadia-code
    gimp
  ];

  fonts.fontconfig.enable = true;

  programs.git.enable = true; # config in dotfiles/.gitconfig

  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./dotfiles/kitty/kitty.conf;
  };

  home.stateVersion = "25.05";

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
	user = "git";
	identityFile = "~/.ssh/gh_ed25519";
      };
    };
  };

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
