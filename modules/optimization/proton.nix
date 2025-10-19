{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkOption mkIf types;
in {
  options.services.steam-on-demand.optimize.protonGE = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Proton-GE installation";
    };

    autoUpdate = mkOption {
      type = types.bool;
      default = true;
      description = "Allow user to manage Proton-GE versions imperatively via Steam";
    };

    pinned = mkOption {
      type = types.attrsOf types.package;
      default = {};
      description = "Per-game Proton-GE version pinning";
      example = lib.literalExpression ''
        {
          "Counter-Strike 2" = pkgs.proton-ge-bin;
          "Elden Ring" = pkgs.proton-ge-bin;
        }
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.optimize.protonGE.enable) {
    environment.systemPackages = [pkgs.proton-ge-bin];
  };
}
