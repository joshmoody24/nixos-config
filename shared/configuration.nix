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
    python314
    nodejs # needed to run "npm " when installing neovim plugins
    gcc # needed to run "make" when installing neovim plugins
    jq
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

  # Keyboard remapping with keyd
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          # Tap capslock = escape, hold = home row mods + vim nav
          capslock = "overload(caps_mods, esc)";
          # Right alt = symbols/numbers layer (old capslock behavior)
          rightalt = "layer(symbols)";
          # q+r toggles half-QWERTY mode (changed from q+w to avoid gaming conflicts)
          "q+r" = "toggle(halfqwerty_mode)";
        };

        # Home row mods + vim navigation (hold capslock)
        # Left hand: modifiers | Right hand: navigation
        # Combine freely: caps+a+h = ctrl+left, caps+s+l = shift+right, etc.
        "caps_mods" = {
          a = "leftcontrol";
          s = "leftshift";
          d = "leftalt";
          f = "leftmeta";
          space = "layer(symbols)";
          h = "left";
          j = "down";
          k = "up";
          l = "right";
        };

        # Pull-down number/symbol layer (hold right alt)
        "symbols" = {
          capslock = "capslock";
          a = "!"; s = "@"; d = "#"; f = "$"; g = "%";
          h = "^"; j = "&"; k = "*"; l = "("; ";" = ")";
          apostrophe = "_";
          q = "1"; w = "2"; e = "3"; r = "4"; t = "5";
          y = "6"; u = "7"; i = "8"; o = "9"; p = "0";
          leftbrace = "-"; rightbrace = "=";
          z = "`"; x = "~"; c = "-"; v = "="; b = "[";
          n = "]"; m = "{"; "," = "}"; "." = "\\"; "/" = "|";
        };

        # Half-QWERTY mode: hold space = mirror, tap space = space (key-up)
        "halfqwerty_mode" = {
          "q+r" = "toggle(halfqwerty_mode)";
          space = "overload(mirror, space)";
          capslock = "enter";
          "`" = "backspace";
        };

        # Mirror layer (activated by holding space in halfqwerty_mode)
        "mirror" = {
          "`" = "backspace";
          q = "p"; w = "o"; e = "i"; r = "u"; t = "y";
          a = ";"; s = "l"; d = "k"; f = "j"; g = "h";
          z = "."; x = ","; c = "m"; v = "n";
          p = "q"; o = "w"; i = "e"; u = "r"; y = "t";
          ";" = "a"; l = "s"; k = "d"; j = "f"; h = "g";
          "." = "z"; "," = "x"; m = "c"; n = "v";
        };
      };
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
