{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkOption mkIf types concatStringsSep optionalAttrs;

  setGovernorScript = governor:
    pkgs.writeShellScript "set-cpu-governor-${governor}" ''
      for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "${governor}" > "$gov"
      done
    '';
in {
  options.services.steam-on-demand.optimize = {
    cpuGovernor = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic CPU governor switching (performance on start, powersave on stop)";
    };

    cpuCores = mkOption {
      type = types.nullOr (types.listOf types.int);
      default = null;
      description = "CPU cores to pin Steam process to";
      example = [0 1 2 3 4 5 6 7];
    };
  };

  config = mkIf cfg.enable {
    systemd.services.steam-on-demand.serviceConfig =
      {
        CPUAffinity = mkIf (cfg.optimize.cpuCores != null) (concatStringsSep " " (map toString cfg.optimize.cpuCores));
      }
      // optionalAttrs cfg.optimize.cpuGovernor {
        ExecStartPre = setGovernorScript "performance";
        ExecStopPost = setGovernorScript "powersave";
      };
  };
}
