{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options.services.steam-on-demand = {
    enable = mkEnableOption "Steam on-demand service with controller activation";

    user = mkOption {
      type = types.str;
      default = "games";
      description = "User account for isolated Steam environment";
    };

    directory = mkOption {
      type = types.str;
      default = ".local/share/steam-games";
      description = "Steam installation directory relative to user home";
    };

    activation = {
      controllers = mkOption {
        type = types.listOf types.str;
        default = [
          "Xbox Wireless Controller"
          "Wireless Controller"
          "Steam Deck Controller"
        ];
        description = "Controller names that trigger Steam service start";
      };

      stopOnDisconnect = mkOption {
        type = types.bool;
        default = false;
        description = "Stop Steam service when controller disconnects";
      };
    };

    remotePlay = {
      enable = mkEnableOption "Steam Remote Play";

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open required firewall ports for Remote Play";
      };
    };

    gamescope = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Run Steam inside gamescope compositor on TTY1";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = ["-e" "-f" "-W" "1920" "-H" "1080"];
        description = "Arguments passed to gamescope compositor";
      };
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isNormalUser = true;
      description = "Isolated Steam gaming user";
      home = "/home/${cfg.user}";
      createHome = true;
    };

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = cfg.remotePlay.enable && cfg.remotePlay.openFirewall;
    };
  };
}
