{ config, pkgs, lib, inputs, ... }:

let
  # Dependencies come from the pinned flake, the code from the working clone:
  # editing a collector takes effect on the next tick, with no rebuild and no
  # restart. Point `source` at the flake instead to freeze it.
  python = lib.getExe inputs.redo-dashboard.packages.${pkgs.system}.python;
  source = "${config.home.homeDirectory}/code/redo-dashboard";
  talk = "/var/lib/redo-dashboard/dashboard.deque";

  service = { script, environment ? [ ] }: {
    Unit.Description = "redo-dashboard ${baseNameOf script}";
    Service = {
      Type = "oneshot";
      EnvironmentFile = "%h/.config/redo-dashboard/env";
      Environment = environment;
      ExecStart = "${python} ${source}/${script}";
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
    redo-dashboard-calendar = service { script = "collectors/calendar_feed.py"; };
    redo-dashboard-gitlab = service { script = "collectors/gitlab.py"; };
    redo-dashboard-slack = service { script = "collectors/slack.py"; };
    redo-dashboard-render = service {
      script = "render.py";
      environment = [ "REDO_DASHBOARD_TALK=${talk}" ];
    };
  };

  systemd.user.timers = {
    # The iCal feed is megabytes and Google serves it with no-store, so every
    # poll is a full download: fetched rarely, expanded into a window.
    redo-dashboard-calendar = timer "10m";
    redo-dashboard-gitlab = timer "2m";
    # Scoring is a local LLM call per unread message, so not too eagerly.
    redo-dashboard-slack = timer "10m";
    # render touches no network, so it can run often and keep "in 8 min" honest.
    redo-dashboard-render = timer "30s";
  };
}
