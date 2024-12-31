{
  description = "my blog management";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
        inputs.devenv.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          # config,
          # self',
          # inputs',
          pkgs,
          # system,
          ...
        }:
        {
          devenv.shells.default = {
            packages =
              let
                mdformatAndPlugins = with pkgs.python312Packages; [
                  mdformat
                  mdformat-frontmatter
                  mdformat-tables
                ];
              in
              with pkgs;
              [
                hugo
                markdownlint-cli
                zenn-cli
              ]
              ++ mdformatAndPlugins;
            enterShell = ''
              which hugo
              hugo version
            '';
          };
        };
    };
}
