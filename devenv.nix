# The importApply argument. Use this to reference things defined locally,
# as opposed to the flake where this is imported.
localFlake:

# Regular module arguments; self, inputs, etc all reference the final user flake,
# where this module was imported.
_: {
  perSystem =
    {
      config,
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
            pnpm
          ]
          ++ mdformatAndPlugins;
        processes = {
          hugo-server = {
            exec = ''
              cd $REPO_ROOT/hugo-blog
              hugo server --buildFuture --buildDrafts
            '';
          };
          zenn-server = {
            exec = ''
              cd $REPO_ROOT
              zenn preview
            '';
          };
        };
        scripts = {
          list =
            let
              inherit (pkgs) lib;
            in
            {
              exec = ''
                echo
                echo 🦾 Helper scripts you can run to make your development richer:
                echo 🦾
                ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF \
                | ${pkgs.util-linuxMinimal}/bin/column -t | ${pkgs.gnused}/bin/sed -e 's|^|🦾 |' -e 's|••| |g'
                ${lib.generators.toKeyValue { } (
                  lib.mapAttrs (name: value: value.description) config.devenv.shells.default.scripts
                )}
                EOF
                echo
              '';
              description = "devenvで定義したのscripts一覧";
            };
          hugo-new-content = {
            exec = ''
              cd $REPO_ROOT/hugo-blog
              hugo new content content/post/$1/index.md
            '';
            description = "hugo-blog執筆用: 新規の記事作成";
          };
        };
        enterShell = ''
          hugo version
          echo zenn v$(zenn --version)
          list
        '';
      };
    };
}
