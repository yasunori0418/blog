---
title: 俺流！ home-managerのhome.file
slug: my-home-manager-file-map
date: 2025-02-01T00:00:00+09:00
publishDate: 2025-02-01T00:00:00+09:00
draft: false
isCJKLnaguage: true
categories:
  - Tech
tags:
  - nix
  - home-manager
---

## 始めに

[前回、Ghosttyの設定をする記事](../configured_ghostty)を書いたタイミングで、`config-file`のオプショナルな設定の読み込みを活用したいと思って、
home-managerの設定を色々触っていたらリファクタリングが止まらなくなってしまいました。

<!-- textlint-disable -->
{{< admonition info 件のコミット >}}
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

上記のディレクトリ一覧を確認する限り、`Library/`に関してはMacOSのみで配置が必要です。
この他にも、前回のGhosttyのようなMacOSかLinuxによって設定ファイルの配置を切り替えるパターンが、紹介は省きますがいくつかあります。

基本のディレクトリ構成はLinuxをベースとして、MacOSのみで必要な対応は、都度対応するという方針にしています。

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
    # LinuxとMacOS共通で$HOME直下に配置されるファイルやディレクトリの配置設定を記述
  };
  dotConfig = {
    # LinuxとMacOS共通で$XDG_CONFIG_HOME直下に配置されるファイルやディレクトリの配置設定を記述
  };
  MacOS = {
    homeDirectory = {
      # MacOSのみで$HOME直下に配置されるファイルやディレクトリの配置設定を記述
    };
    library = {
      # MacOSのLibraryというディレクトリ構成をいまだに理解できていない
      # つまりMacOSの気持ちになれない
    };
    dotConfig = {
      # MacOSのみで$XDG_CONFIG_HOME直下に配置されるファイルやディレクトリの配置設定を記述
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
- [MacOS](https://github.com/yasunori0418/dotfiles/blob/ebdc726/home-manager/macx64/homeFile.nix)

## もうちょっとシンプルにした結果

ファイルをhome-managerで配置してもらうという部分だけ見ればこのままでもよいですが、同じ記述が多くメンテナンス性は良くないですね。

## まとめ
