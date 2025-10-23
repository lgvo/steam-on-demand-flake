{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dev-templates = {
      url = "github:lgvo/nix-dev-templates";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    dev-templates,
    ...
  }: {
    nixosModules.default = import ./modules;

    devShells = dev-templates.lib.mkDevShells {
      config = {
        assistant.opencode.enable = true;

        automation.just.enable = true;

        lang.nix = {
          enable = true;
          lsp = "nil";
          formatter = "alejandra";
          withStatix = true;
          withDeadnix = true;
        };
      };
    };
  };
}
