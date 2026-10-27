{ config, pkgs, lib, ... }:

# uvcvideo forgets a manually set white balance whenever the last reader lets
# the camera go, and Chrome turns automatic white balance back on every time it
# reopens the stream. Either one puts the picture back to the driver default
# mid-call, so the value has to be re-asserted for as long as the session lasts
# rather than written once at plug-in, which rules out a udev rule.
let
  cfg = config.webcam.whiteBalance;

  hold = pkgs.writeShellApplication {
    name = "webcam-white-balance";
    runtimeInputs = [ pkgs.v4l-utils ];
    text = ''
      get() {
        v4l2-ctl --device ${cfg.device} --get-ctrl "$1" | cut -d' ' -f2
      }

      while :; do
        if [ "$(get white_balance_automatic)" != 0 ] ||
           [ "$(get white_balance_temperature)" != ${toString cfg.temperature} ]; then
          echo "reasserting white balance ${toString cfg.temperature} on ${cfg.device}"
          v4l2-ctl --device ${cfg.device} \
            --set-ctrl white_balance_automatic=0 \
            --set-ctrl white_balance_temperature=${toString cfg.temperature}
        fi
        sleep ${toString cfg.interval}
      done
    '';
  };
in
{
  options.webcam.whiteBalance = {
    device = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Camera to pin the white balance of, by /dev/v4l/by-id path so a
        changed enumeration order can't point this at another device. Null
        leaves the camera on automatic.
      '';
    };

    temperature = lib.mkOption {
      type = lib.types.int;
      description = ''
        Colour temperature to hold, within the range the camera reports for
        white_balance_temperature. Higher is warmer on some cameras and cooler
        on others, so this is tuned by eye per device.
      '';
    };

    interval = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Seconds between checks for the camera drifting back to auto.";
    };
  };

  config = lib.mkIf (cfg.device != null) {
    systemd.user.services.webcam-white-balance = {
      Unit.Description = "Hold the webcam's white balance against auto";
      Service = {
        ExecStart = lib.getExe hold;
        # v4l2-ctl fails outright when the camera is absent, so an unplugged
        # camera is a restart loop until it comes back.
        Restart = "always";
        RestartSec = 10;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
