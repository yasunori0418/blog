# My Blogs

- [blog.yasunori0418.com](https://blog.yasunori0418.dev/)
- [zenn.dev/yasunori_kirin](https://zenn.dev/yasunori_kirin)

## blog.yasunori0418.com

hugoで作成して、`Cloudflare pages`を使ってデプロイしている。

対象のディレクトリは`hugo-blog`。

## zenn.dev/yasunori_kirin

zennで公開している記事を管理。
zenn-cliとzenn.devの仕様上ディレクトリ構成をリポジトリルートから動かすことができない。

対象ディレクトリは次のとおり。

- ./articles
- ./books
- ./images

## 使用するツールの管理

`flake.nix`で`flake-parts`から`devenv`を使って使用するツールを宣言している。
