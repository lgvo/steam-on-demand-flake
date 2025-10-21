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
      after = ["systemd-user-sessions.service" "sound.target" "network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        SupplementaryGroups = "video input render audio";
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'set -euo pipefail; echo \"Starting Steam on-demand pre-start checks\"; if ! id \"${cfg.user}\" >/dev/null 2>&1; then echo \"Error: User ${cfg.user} does not exist\"; exit 1; fi'";
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
        # Ensure Steam directory exists
        mkdir -p ${steamDir}/compatibilitytools.d
        
        # Fix ownership only if directory exists and user exists
        if [ -d "${homeDir}" ] && id "${cfg.user}" >/dev/null 2>&1; then
          chown -R ${cfg.user}:users ${homeDir}
        fi
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
