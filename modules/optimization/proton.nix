{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkOption mkIf types concatMapStringsSep;
  homeDir = "/home/${cfg.user}";
in {
  options.services.steam-on-demand.extraProtonPackages = mkOption {
    type = types.listOf types.package;
    default = [];
    description = "Additional Proton packages to install";
    example = lib.literalExpression "[ nix-gaming.packages.x86_64-linux.proton-ge ]";
  };

  config = mkIf (cfg.enable && cfg.extraProtonPackages != []) {
    systemd.services.steam-on-demand.preStart = ''
      compatDir="${homeDir}/${cfg.directory}/compatibilitytools.d"
      mkdir -p "$compatDir"
      ${concatMapStringsSep "\n" (package: ''
        ln -sf ${package} "$compatDir/$(basename ${package})"
      '') cfg.extraProtonPackages}
    '';
  };
}
