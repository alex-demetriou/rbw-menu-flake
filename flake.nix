{
  description = "rbw-menu flake";

  inputs = {
	nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rbw-menu-flake = {
      url = "github:rbuchberger/rbw-menu";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rbw-menu-flake, ... }:
    let
      pkgs = import nixpkgs { inherit system; };
      system = "x86_64-linux";
    in
    {
      formatter.${system} = pkgs.nixfmt-rfc-style;
      packages.${system} = rec {
        rbw-menu = pkgs.writeShellApplication {
          name = "rbw-menu";
          text = rbw-menu-flake.outPath + "/bin/rbw-menu";
          runtimeInputs = [
            pkgs.rbw
            pkgs.jq
            pkgs.wofi
          ];
        };

        default = rbw-menu;
      };
      nixosModules.${system} = rec {
        rbw-menu =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          with lib;
          {
            options.programs.rbw-menu = {
              enable = mkEnableOption "rbw-menu";
              gui = {
                package = mkOption {
                  type = types.package;
                  default = pkgs.wofi;
                  description = "GUI package for rbw-menu.";
                };
                args = mkOption {
                  type = types.str;
                  default = "--prompt 'name'";
                  description = "Command line arguments for the GUI.";
                };
              };
            };

            config = mkIf cfg.enable {
              environment.systemPackages = [ rbw-menu ];
              environment.variables.RBW_MENU_COMMAND = mkForce (
                "${self.packages.${system}.rbw-menu}/bin/${pkgs.getName self.options.gui.package} ${self.options.gui.args}"
              );
            };
          };

        default = rbw-menu;
      };
    };
}
