{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkIf concatStringsSep;

  steamFHS = config.programs.steam.package.override {
    extraPkgs = p:
      with p; [
        mangohud
      ];
  };

  homeDir = "/home/${cfg.user}";
  steamDir = "${homeDir}/${cfg.directory}";
in {
  config = mkIf cfg.enable {
    systemd.services.steam-on-demand = {
      description = "Steam on-demand gaming service";
      wantedBy = [];
      conflicts = ["getty@tty1.service"];
      after = ["systemd-user-sessions.service" "sound.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart =
          if cfg.gamescope.enable
          then "${pkgs.gamescope}/bin/gamescope ${concatStringsSep " " cfg.gamescope.args} -- ${steamFHS}/bin/steam -bigpicture"
          else "${steamFHS}/bin/steam -bigpicture";
        Restart = "on-failure";
        RestartSec = "5s";

        TTYPath = "/dev/tty1";
        StandardInput = "tty-fail";
        StandardOutput = "journal";
        StandardError = "journal";

        PrivateTmp = true;
        NoNewPrivileges = false;

        Environment = [
          "HOME=${homeDir}"
          "STEAM_RUNTIME=1"
          "STEAM_EXTRA_COMPAT_TOOLS_PATHS=${steamDir}/compatibilitytools.d"
        ];
      };

      preStart = ''
        mkdir -p ${steamDir}/compatibilitytools.d
        chown -R ${cfg.user}:users ${homeDir}
      '';
    };

    environment.systemPackages =
      with pkgs;
        [
          mangohud
        ]
        ++ lib.optional cfg.gamescope.enable gamescope;
  };
}
