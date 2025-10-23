{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  secCfg = cfg.security.shutdownInterception;
  inherit (lib) mkOption mkEnableOption mkIf types optionals concatMapStringsSep optionalString;

  blockedActions =
    (optionals (secCfg.onPowerOff == "block") [
      "org.freedesktop.login1.power-off"
      "org.freedesktop.login1.power-off-multiple-sessions"
    ])
    ++ (optionals (secCfg.onReboot == "block") [
      "org.freedesktop.login1.reboot"
      "org.freedesktop.login1.reboot-multiple-sessions"
    ])
    ++ (optionals (secCfg.onSuspend == "block") [
      "org.freedesktop.login1.suspend"
      "org.freedesktop.login1.suspend-multiple-sessions"
    ])
    ++ (optionals (secCfg.onHibernate == "block") [
      "org.freedesktop.login1.hibernate"
      "org.freedesktop.login1.hibernate-multiple-sessions"
    ]);

  needsMonitor =
    secCfg.onPowerOff == "stop-display-manager"
    || secCfg.onReboot == "restart-display-manager";
in {
  options.services.steam-on-demand.security = {
    shutdownInterception =
      {
        enable =
          mkEnableOption "shutdown interception for gaming session"
          // {
            default = true;
          };

        onReboot = mkOption {
          type = types.enum ["restart-display-manager" "allow" "block"];
          default = "restart-display-manager";
          description = ''
            How to handle reboot attempts from the gaming session:
            - "restart-display-manager": Intercept and restart display-manager instead
            - "allow": Allow system reboot
            - "block": Block reboot with polkit
          '';
        };

        onPowerOff = mkOption {
          type = types.enum ["stop-display-manager" "allow" "block"];
          default = "stop-display-manager";
          description = ''
            How to handle poweroff attempts from the gaming session:
            - "stop-display-manager": Intercept and stop display-manager instead
            - "allow": Allow system poweroff
            - "block": Block poweroff with polkit
          '';
        };

        onSuspend = mkOption {
          type = types.enum ["allow" "block"];
          default = "block";
          description = ''
            How to handle suspend attempts from the gaming session:
            - "allow": Allow system suspend
            - "block": Block suspend with polkit
          '';
        };

        onHibernate = mkOption {
          type = types.enum ["allow" "block"];
          default = "block";
          description = ''
            How to handle hibernate attempts from the gaming session:
            - "allow": Allow system hibernate
            - "block": Block hibernate with polkit
          '';
        };
      };
  };

  config = mkIf (cfg.enable && secCfg.enable) {
    security.polkit.extraConfig = mkIf (blockedActions != []) ''
      polkit.addRule(function(action, subject) {
        if (subject.user == "${cfg.user}") {
          ${concatMapStringsSep "\n          " (action: ''if (action.id == "${action}") return polkit.Result.NO;'') blockedActions}
        }
      });
    '';

    systemd.services.steam-shutdown-monitor = mkIf needsMonitor {
      description = "Monitor Steam shutdown attempts and manage display manager";
      partOf = ["display-manager.service"];
      after = ["display-manager.service"];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 5;

        ExecStart = pkgs.writeShellScript "monitor-shutdown" ''
          echo "Monitoring system D-Bus for shutdown attempts..."

          ${pkgs.dbus}/bin/dbus-monitor --system \
            "type='method_call',interface='org.freedesktop.login1.Manager'" | \
          while read -r line; do
            ${optionalString (secCfg.onPowerOff == "stop-display-manager") ''
              if echo "$line" | grep -q "PowerOff"; then
                echo "PowerOff detected! Stopping display-manager..."
                ${pkgs.systemd}/bin/systemctl stop display-manager
                sleep 1
              fi
            ''}
            ${optionalString (secCfg.onReboot == "restart-display-manager") ''
              if echo "$line" | grep -q "Reboot"; then
                echo "Reboot detected! Restarting display-manager..."
                ${pkgs.systemd}/bin/systemctl restart display-manager
                sleep 1
              fi
            ''}
          done
        '';
      };
    };

    systemd.services.display-manager = mkIf needsMonitor {
      wants = ["steam-shutdown-monitor.service"];
    };
  };
}
