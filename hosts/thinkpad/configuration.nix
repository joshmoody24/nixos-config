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

  networking.hostName = "joshm-thinkpad";

  services.tailscale.enable = true;

  programs.seahorse.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  environment.systemPackages = lib.mkAfter (with pkgs; [
    gnome-tweaks # helpful for UI tweaks
  ]);
  
  # Enable fractional scaling
  services.xserver.desktopManager.gnome = {
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

  virtualisation.docker.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment? (TL;DR doesn't need to change after first install)
}

