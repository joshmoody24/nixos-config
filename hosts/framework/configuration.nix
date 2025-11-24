{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../shared/configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "joshm-framework";

  services.tailscale.enable = true;

  programs.seahorse.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  environment.systemPackages = lib.mkAfter (with pkgs; [
    gnome-tweaks # helpful for UI tweaks
    steam-run
  ]);
  
  # Enable fractional scaling
  services.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverrides = ''
      [org.gnome.mutter]
      experimental-features=['scale-monitor-framebuffer']
    '';
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries here
  ];

  services.envfs.enable = true;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      "selinux-enabled" = false;
      default-ulimits = {
        nofile = {
          Hard = 262144;
          Soft = 262144;
          Name = "nofile";
        };
      };
    };
  };
  users.users.josh.extraGroups = [ "docker" ];

  # Make Docker socket world-writable for Bazel subprocess compatibility
  # This allows Docker access from Bazel tests which don't properly inherit group membership
  systemd.services.docker.serviceConfig.ExecStartPost = [
    "${pkgs.coreutils}/bin/chmod 666 /var/run/docker.sock"
  ];

  # See the commented-out swap lines in hardware-configuration.nix
  swapDevices = [
    {
      device = "/swapfile";
      size = 8192; # MB → 8 GiB; adjust as you like
    }
  ];

  security.lsm = lib.mkForce [ ];

  system.stateVersion = "25.05"; # Did you read the comment? (TL;DR doesn't need to change after first install)
}

