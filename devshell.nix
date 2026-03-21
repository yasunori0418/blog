# The importApply argument. Use this to reference things defined locally,
# as opposed to the flake where this is imported.
localFlake:

# Regular module arguments; self, inputs, etc all reference the final user flake,
# where this module was imported.
_: {
  perSystem =
    {
      # self',
      inputs',
      pkgs,
      # system,
      ...
    }:
    {
      devShells.default =
        let
          myNurPkgs = inputs'.yasunori-nur.legacyPackages;
        in
        pkgs.mkShell {
          packages =
            with pkgs;
            [
              hugo
              markdownlint-cli
              zenn-cli
              pnpm
              silicon
              imagemagick
              qrencode
              mermaid-cli
              myNurPkgs.k1Low-deck
              myNurPkgs.laminate
            ];

          shellHook = ''
            hugo version
            echo zenn v$(zenn --version)
          '';
        };
    };
}
