---
title: nvim-treesitterのmainブランチ移行
slug: migrate-treesitter-main
date: 2025-08-13T00:00:00+09:00
publishDate: 2025-08-13T00:00:00+09:00
draft: false
isCJKLnaguage: true
categories:
  - tech
tags:
  - nvim
  - treesitter
---

<!-- textlint-disable -->
{{< admonition type="info" title="Vim駅伝" >}}
この記事は[Vim駅伝][ekiden]の2025-08-13向けの記事です。\
前回の記事は[mitsu-yuki][mitsu-yuki]さんの[『Vimへコピぺする時に置き換え元の文字でクリップボードを上書きしないいくつかの方法』][prev-article]です。
{{< /admonition >}}
<!-- textlint-enable -->

## 始めに

執筆時現在(2025-08-13)、[nvim-treesitter]のGitHub上のデフォルトブランチは`master`になっていますが、今後は`main`ブランチに移行するようです。

<!-- textlint-disable -->
{{< admonition type="quote" title="masterブランチのREADMEより" >}}
> The master branch is frozen and provided for backward compatibility only.
> All future updates happen on the [`main` branch](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md), which will become the default branch in the future.
>
> マスターブランチは凍結されており、後方互換性のみを提供しています。
> 今後のアップデートはすべて[`main`ブランチ](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md)で行われ、将来的にはデフォルトブランチになります。
{{< /admonition >}}
<!-- textlint-enable -->

このアナウンス自体は[2025-05-24](https://github.com/nvim-treesitter/nvim-treesitter/pull/7865)にはアナウンスされています。\
アナウンス自体は別の経路でも確認はしていましたが、nvim-treesitterの移行に対応できていないプラグインもあったので、移行作業は見送っていました。

時期を置いてあらためて確認したところ、移行できそうな雰囲気を感じたのと、最近vimの設定を育てられていないと思っていたので、リハビリがてら移行作業の内容を垂れ流そうと思います。

## 自分が使用している関連プラグイン

私が使用しているnvim-treesitter関連のプラグインは以下の通りです。

- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
- [nvim-yati](https://github.com/yioneko/nvim-yati)

nvim-treesitter本体とtextobjectsを増やしてくれるプラグインは`main`ブランチに移行してきます。\
どちらも[nvim-treesitterのorganization](https://github.com/nvim-treesitter)で管理されている物ですので、参照するブランチを`master`から`main`に変更すると対応するドキュメントを確認できます。

nvim-yatiに関しては、サードパーティ製のプラグインであり、`main`移行に対応できていない状態です。\
このプラグイン自体は、nvim-treesitterのインデント計算に不満があったころに開発された物のため、最新で不満がなければ使用しなくても大丈夫と書いてあります。\
また、このプラグイン自体の更新が1年前で停止していることもあり、今回の作業では削除しました。

## 主な変更点

`master`から`main`の変更内容はかなりドラスティックではありますが、どれも納得の行く内容だと思いました。\
ただ同時に、どうして「そうなっていなかった…」と思うほど整理されて、個人的には「とても行儀が良いプラグインになった」という感想です。

### 依存関係の変更

`master`から以下の依存関係が追加されます。

- [tree-sitter]本体
- Nodeの最新版
- Neovim v0.11.0以上のバージョン

そのほかは変わらず、CCompilerや`tar`と`curl`は必須となっています。

Nodeも必須にはなっていますが、使うことが無さそうな言語[^1]のため、なくても問題ないと思います。

[tree-sitter]本体に関しては、各言語のパーサをインストールするために必須となっています。

### 共通IFの廃止

個人的に一番うれしかった変更で、`require(nvim-treesitter.configs).setup()`というIFが廃止になりました。\
このIFの悪いところとして、マスタとなる設定の定義はnvim-treesitter本体に存在するが、別のプラグインとしてnvim-treesitterの機能を使うために、設定を拡張するようになっていました。\
今回の移行に関連するプラグイン達は同じようなIFになっており、nvim-yatiに関しては`require(nvim-treesitter.configs).setup()`のIFのままだったため、移行せず削除するという対応になりました。

### 自動起動によるtreesitterの解析を廃止

これも個人的にうれしい変更で、`master`では`require(nvim-treesitter.configs).setup()`呼び出し以降、すべてのFileTypeに対してtreesitterの利用を半強制されていました。\
無効にする方法はありますが、少々面倒な手続きをsetup内に記述する必要がありました。

後述しますが、treesitterを利用するFileTypeは明示することが可能になりました。

## nvim-treesitter

## nvim-treesitter-textobjects

## まとめ

<!-- textlint-disable -->
[^1]: [scfg]というFileTypeに対応するらしい。設定言語っぽいが知らべても使われている物が見つからなかった。

<!-- links -->
[ekiden]: https://vim-jp.org/ekiden/
[mitsu-yuki]: https://github.com/mitsu-yuki
[prev-article]: https://qiita.com/mitsu-yuki/private/566cd8634abe10a3341e
[nvim-treesitter]: https://github.com/nvim-treesitter/nvim-treesitter
[tree-sitter]: https://github.com/tree-sitter/tree-sitter
[scfg]: https://github.com/rockorager/tree-sitter-scfg
