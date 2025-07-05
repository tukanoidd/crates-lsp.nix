{inputs, ...}: {
  perSystem = {
    pkgs,
    config,
    ...
  }: let
    crateName = "crates-lsp";
  in {
    nci = {
      toolchainConfig = ./rust-toolchain.toml;

      projects."crates-lsp" = {
        path = inputs.crates-lsp;
        export = true;
      };
      crates.${crateName} = {};
    };
  };
}
