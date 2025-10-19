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
  }: let
    system = "aarch64-darwin"; # or "x86_64-darwin", "aarch64-darwin"
  in {
    devShells.${system}.default = dev-templates.lib.${system}.mkDevShell {
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
}
