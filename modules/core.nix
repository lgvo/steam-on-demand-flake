{
  config,
  lib,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkEnableOption mkOption mkIf mkForce types;
in {
  options.services.steam-on-demand = {
    enable = mkEnableOption "Steam on-demand service with controller activation";

    user = mkOption {
      type = types.str;
      default = "gamer";
      description = "User account for isolated Steam environment";
    };

    bootToBigPicture = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Automatically start Steam Big Picture mode at boot.

        When enabled, the system boots to graphical.target and automatically
        logs in the gaming user to the Steam session.

        When disabled (default), the system boots to multi-user.target and
        only starts the Steam session when a controller is connected.
      '';
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
        description = ''
          Stop Steam service when controller disconnects.

          WARNING: This may stop the service in undesired situations such as:
          - Controller battery dies
          - Secondary/guest controller disconnects
          - Temporary wireless interference
          - Controller goes into power-saving mode

          Only enable if you want the display manager to stop whenever ANY
          configured controller disconnects.
        '';
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

    gamescope.args = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Arguments passed to gamescope compositor";
    };

    steam.args = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Arguments passed to Steam";
    };

    extraCompatPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional compatibility tool packages (e.g., Proton versions)";
      example = lib.literalExpression "with pkgs; [ proton-ge-bin ]";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      isNormalUser = true;
      description = "Isolated Steam gaming user";
      home = "/home/${cfg.user}";
      createHome = true;
    };

    services.displayManager = {
      sddm.enable = true;
      sddm.wayland.enable = true;
      autoLogin.enable = true;
      autoLogin.user = cfg.user;
      defaultSession = "steam";
    };

    programs.steam = {
      enable = true;
      gamescopeSession = {
        enable = true;
        inherit (cfg.gamescope) args;
        steamArgs = cfg.steam.args;
      };
      inherit (cfg) extraCompatPackages;
      remotePlay.openFirewall = cfg.remotePlay.enable && cfg.remotePlay.openFirewall;
    };

    systemd.defaultUnit = mkForce (
      if cfg.bootToBigPicture
      then "graphical.target"
      else "multi-user.target"
    );
  };
}
