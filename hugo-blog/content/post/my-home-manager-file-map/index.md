---
title: 俺流！ home-managerのhome.file
slug: my-home-manager-file-map
date: 2025-01-29T00:00:00+09:00
publishDate: 2025-01-29T00:00:00+09:00
draft: false
isCJKLnaguage: true
categories:
  - Tech
tags:
  - dotfiles
  - nix
  - home-manager
---

## 始めに

[Ghosttyの設定をする記事](../configured_ghostty)を書いたタイミングで、`config-file`のオプショナルな設定の読み込みを活用したいと思って、
home-managerの設定を色々触っていたらリファクタリングが止まらなくなってしまいました。

<!-- textlint-disable -->
{{< admonition type="info" title="件のコミット" >}}
[Commit 8242e73: refactor: 止まらなくなっちまったんだ、しょうがないだろ](https://github.com/yasunori0418/dotfiles/commit/8242e73)
{{< /admonition >}}
<!-- textlint-enable -->

これを機にhome-managerでのファイル配置について「俺流」の考え方や、今回のリファクタの内容を書き残しておこうと思います。

## ファイル配置の考え方

私のdotfilesの`home`ディレクトリは、ユーザーのホームディレクトリ配下に配置するファイル群と同じ階層にしています。

```bash
home
├── .config
├── .docker
├── .icons
├── .Xresources.d
├── .zsh
├── bin
└── Library
```

上記のディレクトリ一覧を確認する限り、`Library/`に関してはmacOSのみで配置が必要です。
この他にも、前回のGhosttyのようなmacOSかLinuxによって設定ファイルの配置を切り替えるパターンが、紹介は省きますがいくつかあります。

基本のディレクトリ構成はLinuxをベースとして、macOSのみで必要な対応は、都度対応するという方針にしています。

## home-managerの`home.file`

凄く雑に紹介すると、home-managerの`home.file`はユーザーディレクトリ配下にファイルを配置してくれます。

```nix
{
  home.file = {
    # ディレクトリならこんな感じ
    ".zsh" = {
      source = ./.zsh;
      recursive = true;
    };
    # ファイル単体ならこれで良い
    ".vimrc".source = ./.vimrc;
  };
}
```

ちょうど[冒頭のコミット前](https://github.com/yasunori0418/dotfiles/blob/ebdc726/home-manager/fileMap.nix)は上記のような構造体を羅列していますね。\
環境毎の切り替えにif式を書くとゴチャゴチャしそうだったので、次のようなAttrSetに包んでから使用する環境毎に展開してマージするという運用をしています。

```nix
{
  homeDirectory = {
    # LinuxとmacOS共通で$HOME直下に配置されるファイルやディレクトリの配置設定を記述
  };
  dotConfig = {
    # LinuxとmacOS共通で$XDG_CONFIG_HOME直下に配置されるファイルやディレクトリの配置設定を記述
  };
  MacOS = {
    homeDirectory = {
      # macOSのみで$HOME直下に配置されるファイルやディレクトリの配置設定を記述
    };
    library = {
      # macOSのLibraryというディレクトリ構成をいまだに理解できていない
      # つまりmacOSの気持ちになれない
    };
    dotConfig = {
      # macOSのみで$XDG_CONFIG_HOME直下に配置されるファイルやディレクトリの配置設定を記述
    };
  };
  Linux = {
    homeDirectory = {
      # Linuxのみで$HOME直下に配置されるファイルやディレクトリの配置設定を記述
    };
    dotConfig = {
      # Linuxのみで$XDG_CONFIG_HOME直下に配置されるファイルやディレクトリの配置設定を記述
    };
  };
}
```

環境毎に展開して、マージするというのは次のリンク先をご覧ください。

- [Linux](https://github.com/yasunori0418/dotfiles/blob/ebdc726/home-manager/linux/homeFile.nix)
- [macOS](https://github.com/yasunori0418/dotfiles/blob/ebdc726/home-manager/macx64/homeFile.nix)

## もうちょっとシンプルにした結果

ファイルをhome-managerで配置してもらうという部分だけ見ればこのままでもよいですが、同じ記述が多くメンテナンス性は良くないですね。

ここで改めて、私のdotfilesでは一部設定ファイルを除いて、配置元と配置先のファイル名は統一されています。\
であれば、ファイル名だけを列挙し`home.file`の構造を作って統合できればよいはずです。\
javascriptでいうところの「[reduce関数](https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce)みたいなのがあれば解決できそう」、\
ということでnix言語のマニュアルを見ていたら`foldl'`という関数を見つけました。

https://nix.dev/manual/nix/2.24/language/builtins#builtins-foldl'

そして、この`foldl'`関数を使って作ったのが次のコードです。

<!-- textlint-disable -->
{{< admonition details="false" type="quote" title="今回の主役" >}}
<!-- textlint-enable -->

```nix
# fileMap.nix
let
  fileMap =
    {
      dist,
      src,
      is_recursive,
    }:
    let
      f =
        files:
        builtins.foldl' (
          acc: file:
          let
            distFile = if dist == "" then "${file}" else "${dist}/${file}";
          in
          acc
          // {
            ${distFile} = {
              source = symlink /${src}/${file};
              recursive = is_recursive;
            };
          }
        ) { } files;
    in
    f;

  homeFileMap = fileMap {
    dist = "";
    src = homeDir;
    is_recursive = false;
  };
  homeDirMap = fileMap {
    dist = "";
    src = homeDir;
    is_recursive = true;
  };
  xdgConfigFileMap = fileMap {
    dist = ".config";
    src = xdgConfigHome;
    is_recursive = false;
  };
  xdgConfigDirMap = fileMap {
    dist = ".config";
    src = xdgConfigHome;
    is_recursive = true;
  };
in
```

{{< /admonition >}}

使い方は二段階にしていて、配置先と配置元のパス・`home.file.<name>.recursive`の値を部分適用した関数を作っておきます。\
これによってディレクトリを配置する関数や、ファイルを配置する関数、`$HOME`用と`$XDG_CONFIG_HOME`用の関数を作れるようになります。

あとは作っておいた関数を使いたい場所で使用して、配列にファイル名やディレクトリ名を列挙するだけでよくなります。

<!-- textlint-disable -->
{{< admonition details="false" type="quote" title="使っているところ" >}}
<!-- textlint-enable -->

```nix
# fileMap.nix
dotConfig =
  xdgConfigDirMap [
    "alacritty/keybinds"
    "tmux"
    "fastfetch"
    "fd"
    "git"
    "glow"
    "jj"
    "kitty"
    "luacheck"
    "neofetch"
    "nvim"
    "vim"
    "sheldon"
    "yamllint"
    "zeno"
    "wezterm"
    "direnv"
  ]
  // xdgConfigFileMap [
    "alacritty/alacritty.toml"
    "alacritty/nord.toml"
    "ghostty/config"
    "ghostty/core.conf"
    "ghostty/clipboard.conf"
    "ghostty/command.conf"
    "ghostty/font.conf"
    "ghostty/keybinds.conf"
    "ghostty/mouse.conf"
    "ghostty/quick.conf"
    "ghostty/resize.conf"
    "ghostty/theme.conf"
    "ghostty/window.conf"
  ];
```

{{< /admonition >}}

このGhosttyの設定ファイル配置の宣言に関しては、元の構造をそのまま列挙する形にしていたら大変な行数になっていたことでしょう。

## まとめ

冒頭に書いていたGhosttyのオプショナルなファイル読み込みを試すという目的のために、かなり遠回りした解決法に行き着いた`yak shaving`にはなりましたが、\
ファイル配置のマッピング部分がスッキリした記述になりました。

Nix言語でその場に便利関数を書くということができたので、今後も活用できる場面を見つけてコードをきれいにしていきたいですね。
