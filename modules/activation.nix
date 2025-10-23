{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkIf concatMapStringsSep;

  mkUdevRule = controller: let
    addRule = ''ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="${controller}", TAG+="systemd", ENV{SYSTEMD_WANTS}+="display-manager.service"'';
    removeRule = ''ACTION=="remove", SUBSYSTEM=="input", ATTRS{name}=="${controller}", RUN+="${pkgs.systemd}/bin/systemctl stop display-manager"'';
  in
    if cfg.activation.stopOnDisconnect
    then "${addRule}\n${removeRule}"
    else addRule;
in {
  config = mkIf cfg.enable {
    services.udev.extraRules = concatMapStringsSep "\n" mkUdevRule cfg.activation.controllers;
  };
}
