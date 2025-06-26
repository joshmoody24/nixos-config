{ config, lib, pkgs, ... }:

{
  time.timeZone = "America/Denver";
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.josh = {
    isNormalUser = true;
    description = "Josh Moody";
    extraGroups = [ "networkmanager" "wheel" "plugdev" "docker" ];
    packages = with pkgs; [];
  };
  
  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;
  
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable GNOME Desktop Environment
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gedit
    xterm
    simple-scan
  ]);

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    ripgrep
    xclip
    git
    wget
    google-chrome
    unzip
    python314Full
    nodejs # needed to run "npm " when installing neovim plugins
    gcc # needed to run "make" when installing neovim plugins
  ];

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Directory-specific environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
