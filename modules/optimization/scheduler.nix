{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkOption mkIf types;
in {
  options.services.steam-on-demand.optimize.scheduler = mkOption {
    type = types.nullOr (types.enum ["scx_rusty" "scx_rustland" "scx_lavd"]);
    default = null;
    description = "sched-ext scheduler (requires kernel 6.12+ and chaotic-nyx)";
  };

  config = mkIf (cfg.enable && cfg.optimize.scheduler != null) {
    services.scx.enable = true;
    services.scx.scheduler = cfg.optimize.scheduler;
  };
}
