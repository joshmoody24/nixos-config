{ config, pkgs, lib, inputs, ... }:

let
  dashboard = inputs.redo-dashboard.packages.${pkgs.system};
  talk = "/var/lib/redo-dashboard/dashboard.deque";

  service = package: environment: {
    Unit.Description = "redo-dashboard ${package.name}";
    Service = {
      Type = "oneshot";
      EnvironmentFile = "%h/.config/redo-dashboard/env";
      Environment = environment;
      ExecStart = lib.getExe package;
    };
  };

  timer = interval: {
    Unit.Description = "redo-dashboard every ${interval}";
    Timer = {
      OnBootSec = "30s";
      OnUnitActiveSec = interval;
      AccuracySec = "5s";
    };
    Install.WantedBy = [ "timers.target" ];
  };
in
{
  systemd.user.services = {
    redo-dashboard-calendar = service dashboard.calendar [ ];
    redo-dashboard-gitlab = service dashboard.gitlab [ ];
    redo-dashboard-render = service dashboard.render [ "REDO_DASHBOARD_TALK=${talk}" ];
  };

  systemd.user.timers = {
    # The iCal feed is megabytes and Google serves it with no-store, so every
    # poll is a full download: fetched rarely, expanded into a window.
    redo-dashboard-calendar = timer "10m";
    redo-dashboard-gitlab = timer "2m";
    # render touches no network, so it can run often and keep "in 8 min" honest.
    redo-dashboard-render = timer "30s";
  };
}
