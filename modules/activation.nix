{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.steam-on-demand;
  inherit (lib) mkIf concatMapStringsSep;

  mkUdevRule = controller: let
    action =
      if cfg.activation.stopOnDisconnect
      then "add|remove"
      else "add";
  in ''
    ACTION=="${action}", SUBSYSTEM=="input", ATTRS{name}=="${controller}", TAG+="systemd", ENV{SYSTEMD_WANTS}="steam-on-demand.service"
  '';
in {
  config = mkIf cfg.enable {
    services.udev.extraRules = concatMapStringsSep "\n" mkUdevRule cfg.activation.controllers;
  };
}
