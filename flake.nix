{
  description = "rbw-menu flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rbw-menu = {
      url = "github:rbuchberger/rbw-menu";
      flake = false;
    };
  };

  outputs =
    inputs@{ ... }:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs { inherit system; };
        rbw-menu = pkgs.writeShellApplication {
          name = "rbw-menu";
          text = inputs.rbw-menu.outPath + "/bin/rbw-menu";
          runtimeInputs = [
            pkgs.rbw
            pkgs.jq
            pkgs.wofi
          ];
        };

        module =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          with lib;

          let
            cfg = config.programs.rbw-menu;
          in
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
                "${cfg.package}/bin/${pkgs.getName cfg.package} ${cfg.args}"
              );
            };
          };
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        packages = rec {
          inherit rbw-menu;
          default = rbw-menu;
        };
        apps.rbw-menu = {
          type = "app";
          program = "${rbw-menu}/bin/rbw-menu";
        };
        nixosModules = rec {
          inherit module;
          default = module;
        };
      }
    );
}
