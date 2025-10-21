{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkOption mkIf types concatStringsSep;
in {
  options.services.steam-on-demand.optimize = {
    cpuCores = mkOption {
      type = types.nullOr (types.listOf types.int);
      default = null;
      description = "CPU cores to pin Steam process to";
      example = [0 1 2 3 4 5 6 7];
    };
  };

  config = mkIf cfg.enable {
    systemd.services.steam-on-demand.serviceConfig = {
      CPUAffinity = mkIf (cfg.optimize.cpuCores != null) (concatStringsSep " " (map toString cfg.optimize.cpuCores));
    };
  };
}
