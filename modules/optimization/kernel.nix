{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkOption mkIf types;
in {
  options.services.steam-on-demand.optimize.kernel = mkOption {
    type = types.enum ["standard" "zen" "xanmod" "cachyos"];
    default = "standard";
    description = "Kernel variant optimized for gaming";
  };

  config = mkIf cfg.enable {
    boot.kernelPackages = mkIf (cfg.optimize.kernel != "standard") (
      if cfg.optimize.kernel == "zen"
      then pkgs.linuxPackages_zen
      else if cfg.optimize.kernel == "xanmod"
      then pkgs.linuxPackages_xanmod_latest
      else pkgs.linuxPackages_cachyos
    );
  };
}
