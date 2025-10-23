{
  config,
  lib,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkOption mkIf types;
in {
  options.services.steam-on-demand.security = {
    preventPowerManagement = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Prevent the gaming user from powering off, rebooting, suspending,
        or hibernating the system from within the Steam session.

        This uses polkit rules to deny power management actions for the
        configured gaming user, preventing accidental system shutdown
        from the Steam interface.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.security.preventPowerManagement) {
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.power-off" ||
             action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id == "org.freedesktop.login1.reboot" ||
             action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
             action.id == "org.freedesktop.login1.suspend" ||
             action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
             action.id == "org.freedesktop.login1.hibernate" ||
             action.id == "org.freedesktop.login1.hibernate-multiple-sessions") &&
            subject.user == "${cfg.user}") {
          return polkit.Result.NO;
        }
      });
    '';
  };
}
