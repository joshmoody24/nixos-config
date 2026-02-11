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

  networking.extraHosts = ''
    127.0.0.1 app.getredo.localhost app-vite.getredo.localhost
    127.0.0.1 returns.getredo.localhost returns-vite.getredo.localhost
    127.0.0.1 admin.getredo.localhost admin-vite.getredo.localhost
    127.0.0.1 api.getredo.localhost
    127.0.0.1 merchant-server.getredo.localhost
    127.0.0.1 admin-server.getredo.localhost
    127.0.0.1 shopify-server.getredo.localhost
    127.0.0.1 customer-portal.getredo.localhost
    127.0.0.1 chat-widget.getredo.localhost chat-widget-vite.getredo.localhost chat-widget-page.getredo.localhost
    127.0.0.1 temporal.getredo.localhost
    127.0.0.1 public-server.getredo.localhost
    127.0.0.1 marketplace.getredo.localhost marketplace-server.getredo.localhost
    127.0.0.1 loop-server.getredo.localhost
    127.0.0.1 storefront.getredo.localhost
    127.0.0.1 notice-server.getredo.localhost
    127.0.0.1 effect-api.getredo.localhost
    ::1 app.getredo.localhost app-vite.getredo.localhost
    ::1 returns.getredo.localhost returns-vite.getredo.localhost
    ::1 admin.getredo.localhost admin-vite.getredo.localhost
    ::1 api.getredo.localhost
    ::1 merchant-server.getredo.localhost
    ::1 admin-server.getredo.localhost
    ::1 shopify-server.getredo.localhost
    ::1 customer-portal.getredo.localhost
    ::1 chat-widget.getredo.localhost chat-widget-vite.getredo.localhost chat-widget-page.getredo.localhost
    ::1 temporal.getredo.localhost
    ::1 public-server.getredo.localhost
    ::1 marketplace.getredo.localhost marketplace-server.getredo.localhost
    ::1 loop-server.getredo.localhost
    ::1 storefront.getredo.localhost
    ::1 notice-server.getredo.localhost
    ::1 effect-api.getredo.localhost
  '';

  # Caddy reverse proxy for local HTTPS development
  # After Caddy starts: trust the CA system-wide and make cert readable for user NSS import
  systemd.services.caddy.serviceConfig.ExecStartPost = [
    "${pkgs.caddy}/bin/caddy trust"
    # Make cert world-readable so users can import into Chrome's NSS database
    "${pkgs.coreutils}/bin/chmod 644 /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt"
  ];
  systemd.services.caddy.environment.XDG_DATA_HOME = "/var/lib/caddy/.local/share";

  services.caddy = {
    enable = true;
    globalConfig = ''
      local_certs
      grace_period 1s
    '';
    extraConfig = ''
      app.getredo.localhost {
        tls internal
        reverse_proxy localhost:3003
      }
      app-vite.getredo.localhost {
        tls internal
        reverse_proxy localhost:13003
      }
      returns.getredo.localhost {
        tls internal
        reverse_proxy localhost:3002
      }
      returns-vite.getredo.localhost {
        tls internal
        reverse_proxy localhost:13012
      }
      admin.getredo.localhost {
        tls internal
        reverse_proxy localhost:3005
      }
      admin-vite.getredo.localhost {
        tls internal
        reverse_proxy localhost:13005
      }
      api.getredo.localhost {
        tls internal
        reverse_proxy localhost:8888 {
          header_up X-Forwarded-Proto https
          header_up X-Forwarded-Host {host}
        }
      }
      merchant-server.getredo.localhost {
        tls internal
        reverse_proxy localhost:8007 {
          header_up X-Forwarded-Proto https
          header_up X-Forwarded-Host {host}
        }
      }
      admin-server.getredo.localhost {
        tls internal
        reverse_proxy localhost:8005 {
          header_up X-Forwarded-Proto https
          header_up X-Forwarded-Host {host}
        }
      }
      shopify-server.getredo.localhost {
        tls internal
        reverse_proxy localhost:8004 {
          header_up X-Forwarded-Proto https
          header_up X-Forwarded-Host {host}
        }
      }
      loop-server.getredo.localhost {
        tls internal
        reverse_proxy localhost:8006
      }
      marketplace.getredo.localhost {
        tls internal
        reverse_proxy localhost:3013
      }
      marketplace-server.getredo.localhost {
        tls internal
        reverse_proxy localhost:8018
      }
      chat-widget.getredo.localhost {
        tls internal
        reverse_proxy localhost:3008
      }
      chat-widget-vite.getredo.localhost {
        tls internal
        reverse_proxy localhost:13008
      }
      chat-widget-page.getredo.localhost {
        tls internal
        reverse_proxy localhost:3009
      }
      temporal.getredo.localhost {
        tls internal
        reverse_proxy localhost:8233
      }
      customer-portal.getredo.localhost {
        tls internal
        reverse_proxy localhost:8002 {
          header_up X-Forwarded-Proto https
          header_up X-Forwarded-Host {host}
        }
      }
      public-server.getredo.localhost {
        tls internal
        reverse_proxy localhost:8001 {
          header_up X-Forwarded-Proto https
          header_up X-Forwarded-Host {host}
        }
      }
      storefront.getredo.localhost {
        tls internal
        reverse_proxy localhost:3010
      }
      notice-server.getredo.localhost {
        tls internal
        reverse_proxy localhost:2930
      }
      effect-api.getredo.localhost {
        tls internal
        reverse_proxy localhost:3001
      }
    '';
  };

  services.ollama.enable = true;

  services.tailscale.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;

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

