{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkOption types;

  gameOptions = types.submodule {
    options = {
      proton.version = mkOption {
        type = types.nullOr types.package;
        default = null;
        description = "Proton version for this game";
      };

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for this game";
        example = lib.literalExpression ''
          {
            RADV_PERFTEST = "nggc";
            DXVK_ASYNC = "1";
          }
        '';
      };

      gamescope = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable gamescope for this game";
        };

        args = mkOption {
          type = types.str;
          default = "";
          description = "Gamescope command-line arguments";
          example = "-w 1920 -h 1080 -W 2560 -H 1440 -F fsr --fsr-sharpness 2";
        };
      };
    };
  };
in {
  options.services.steam-on-demand.games = mkOption {
    type = types.attrsOf gameOptions;
    default = {};
    description = "Per-game configuration overrides";
    example = lib.literalExpression ''
      {
        "Counter-Strike 2" = {
          proton.version = pkgs.proton-ge-bin;
          environment = {
            RADV_PERFTEST = "nggc";
          };
        };
      }
    '';
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.mkIf (builtins.any (game: game.gamescope.enable) (builtins.attrValues cfg.games)) [
      pkgs.gamescope
    ];
  };
}
