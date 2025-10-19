{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkIf optionalString;

  steamFHS = pkgs.steam.override {
    extraPkgs = p:
      with p; [
        gamemode
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
      after = ["network.target" "sound.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart = "${steamFHS}/bin/steam -bigpicture";
        Restart = "on-failure";
        RestartSec = "5s";

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

    environment.systemPackages = with pkgs; [
      gamemode
      mangohud
    ];
  };
}
