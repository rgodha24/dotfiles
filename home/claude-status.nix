{unstable, ...}: let
  src = ../status;
in {
  # pool view of the claude subscriptions behind cliproxyapi, on 127.0.0.1:8319 (tailnet :8319)
  systemd.user.services.claude-status = {
    Unit = {
      Description = "Claude quota pool dashboard";
      After = ["cliproxyapi.service"];
      X-Restart-Triggers = [src];
    };
    Service = {
      Type = "simple";
      ExecStart = "${unstable.python3}/bin/python3 ${src}/claude_status.py";
      Environment = [
        "STATUS_STATIC=${src}"
        "STATUS_PORT=8319"
        # journalctl backfills history from the proxy's request log
        "PATH=${unstable.systemd}/bin"
      ];
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };
}
