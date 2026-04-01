{ config, lib, pkgs, ... }:

let
  ollamaEnv = lib.strings.splitString "\n" (builtins.readFile ./ollama.env);
  parseEnvLine = line:
    let parts = lib.strings.splitString "=" line;
    in if builtins.length parts == 2
       then { name = builtins.elemAt parts 0; value = builtins.elemAt parts 1; }
       else null;
  ollamaEnvVars = builtins.listToAttrs (builtins.filter (x: x != null) (map parseEnvLine ollamaEnv));
in
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
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gedit
    xterm
    simple-scan
  ]);

  # Enable CUPS to print documents.
  services.printing.enable = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    neovim
  ];

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  # Keyboard remapping with keyd (config lives in dotfiles/keyd/default.conf)
  services.keyd.enable = true;
  environment.etc."keyd/default.conf".source = ./dotfiles/keyd/default.conf;

  services.ollama = {
    enable = true;
    environmentVariables = ollamaEnvVars;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
