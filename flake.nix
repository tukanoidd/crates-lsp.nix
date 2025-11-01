{
  description = "crates-lsp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";

    crates-lsp = {
      url = "github:MathiasPius/crates-lsp";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    crane,
    rust-overlay,
    flake-utils,
    ...
  }:
    (flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [(import rust-overlay)];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain (p: p.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml);

        commonArgs = {
          src = craneLib.cleanCargoSource inputs.crates-lsp;
          strictDeps = true;
        };

        crates-lsp = craneLib.buildPackage (
          commonArgs
          // {
            cargoArtifacts = craneLib.buildDepsOnly commonArgs;
          }
        );
      in {
        checks = {
          inherit crates-lsp;
        };

        packages = {
          inherit crates-lsp;
          default = crates-lsp;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = crates-lsp;
        };
      }
    ))
    // {
      homeModules = {
        default = {
          config,
          pkgs,
          lib,
          ...
        }: let
          crates-lsp-program = config.programs.crates-lsp;
        in
          with lib; {
            options = {
              programs.crates-lsp = {
                enable = mkEnableOption "crates-lsp";
                package = mkOption {
                  description = "Package for crates-lsp";
                  example = false;
                  type = types.package;
                };
              };
            };
            config = {
              home = {
                packages = (
                  if crates-lsp-program.enable
                  then [crates-lsp-program.package]
                  else []
                );
              };
            };
          };
      };
    };
}
