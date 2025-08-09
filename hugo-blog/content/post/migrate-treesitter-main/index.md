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
  - vim
  - treesitter
---

<!-- textlint-disable -->
{{< admonition type="info" >}}
この記事は[Vim駅伝](https://vim-jp.org/ekiden/)の2025-08-13向けの記事です。\
前回の記事は[mitsu-yuki](https://github.com/mitsu-yuki)さんの[『Vimへコピぺする時に置き換え元の文字でクリップボードを上書きしないいくつかの方法』](https://qiita.com/mitsu-yuki/private/566cd8634abe10a3341e)です。
{{< /admonition >}}
<!-- textlint-enable -->

## 始めに

執筆時現在(2025-08-10)、[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)のGitHub上のデフォルトブランチは`master`になっていますが、今後は`main`ブランチに移行するようです。

<!-- textlint-disable -->
{{< admonition type="quote" title="masterブランチのREADMEより" >}}

> The master branch is frozen and provided for backward compatibility only.
> All future updates happen on the [`main` branch](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md), which will become the default branch in the future.
>
> マスターブランチは凍結されており、後方互換性のみを提供しています。
> 今後のアップデートはすべて[`main`ブランチ](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md)で行われ、将来的にはデフォルトブランチになります。

{{< /admonition >}}
<!-- textlint-enable -->

最近、vimの設定を育てられていないと思っていたので、リハビリがてら移行作業の内容を垂れ流そうと思います。

## まとめ
