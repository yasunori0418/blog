{
  description = "my blog management";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, flake-parts-lib, ... }:
      let
        # ref: https://flake.parts/dogfood-a-reusable-module.html?highlight=imports#example-with-importapply
        importApply =
          nixPath:
          let
            inherit (flake-parts-lib) importApply;
          in
          importApply nixPath { inherit withSystem; };
      in
      {
        imports =
          let
            devenv.default = importApply ./devenv.nix;
          in
          [
            # To import a flake module
            # 1. Add foo to inputs
            # 2. Add foo as a parameter to the outputs function
            # 3. Add here: foo.flakeModule
            inputs.devenv.flakeModule
            devenv.default
          ];
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
      }
    );
}
