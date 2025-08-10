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

## 実際に移行していく

主な変更点を確認できたところで、実際に移行作業をやっていきます。

### nvim-treesitter

```diff lua
-require("nvim-treesitter.configs").setup({
-  -- 中略
-})
+require("nvim-treesitter").setup({
+  install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
+})
```

`master`までは`setup`関数内に大量の項目を設定するようになっていましたが、`main`において設定項目は`install_dir`しかありません。\
現状の設定項目自体もデフォルトの値を設定しているだけですが、私は明示的に設定しています。

`setup`関数呼び出し後、パーサのインストールが可能になります。

```lua
require("nvim-treesitter").install({
  "bash",
  "markdown",
  "kotlin",
  --[[
    この辺に使う言語を列挙していってください。
    @see https://github.com/nvim-treesitter/nvim-treesitter/blob/main/SUPPORTED_LANGUAGES.md
  ]]
}, {
  force = false, -- force installation of already installed parsers
  generate = true, -- generate `parser.c` from `grammar.json` or `grammar.js` before compiling.
  max_jobs = 4, -- limit parallel tasks (useful in combination with {generate} on memory-limited systems).
  summary = false, -- print summary of successful and total operations for multiple languages.
} --[[@as InstallOptions]])
```

`install`関数の呼び出しによって、パーサのインストールが始まりますが、インストール先は`setup`関数内で設定した`install_dir`に以下のようなディレクトリ構成でパーサがインストールされます。

```text
~/.local/share/nvim/site
│
├── parser/
│   └── *.so
├── parser-info/
│   └── *.revision
└── queries/
    └── */ nvim-treesitter内の`runtime/queries`からのsymlink
        ├── folds.scm
        ├── highlights.scm
        ├── indents.scm
        ├── injections.scm
        └── locals.scm
```

queries内の物がnvim-treesitterの本体と言っても良いほど重要なデータであり、素敵なハイライト・インデント・折り畳みを提供するためのクエリ達です。\
各言語毎にこれらのファイルがある訳ではないため、あくまで一例となります。\
nvim-treesitterとしてどこまでサポートされているかは、[`SUPPORT_LANGUAGES.md`][support_languages]を参照してください。

ちなみに[tree-sitter]本体をインストールしておかないと、インストール処理だけが始まったように見えて、完了しない現象が発生します。\
私は[tree-sitter]本体のインストールを忘れて、小一時間ほど悩んでいました。

また、これまで`setup`関数で有効化していたハイライト・インデント・折り畳みはどのように設定するかと言うと、以下のような記述が必要です。

```lua
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = {"bash", "markdown", "kotlin"},
  callback = function()
    -- syntax highlighting, provided by Neovim
    vim.treesitter.start()
    -- folds, provided by Neovim
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    -- indentation, provided by nvim-treesitter
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
```

***ーー お分かりいただけただろうか？***

これまで明示せずとも、勝手にtreesitterが各FileTypeで適応されていたのが、特定のFileTypeにだけ適応されるようになったのです！\
これはもしや、『**設定させていただきありがとうございます**』の精神をNeovim本体も理解しだしたように見えないでしょうか？

今回の例では`bash`を開いたときはtreesitterが有効になりますが、同じようなsyntaxをしている`sh`や`zsh`でもtreesitterが有効になってほしいというパターンがあると思います。\
その場合、`autocmd`の`pattern`にFileTypeを追加するだけでなく、以下のような宣言も追加で必要になります。

```lua
vim.treesitter.language.register("bash", { "sh", "zsh" })
```

これにより、`bash`のクエリを使って`sh`と`zsh`も同じようにハイライトするという振る舞いに変わります。

<!-- textlint-disable -->
{{< admonition details="true" type="quote" title=":h vim.treesitter.language.register()" >}}

```vimdoc
register({lang}, {filetype})              *vim.treesitter.language.register()*
    Register a parser named {lang} to be used for {filetype}(s).

    Note: this adds or overrides the mapping for {filetype}, any existing
    mappings from other filetypes to {lang} will be preserved.

    Parameters: ~
      • {lang}      (`string`) Name of parser
      • {filetype}  (`string|string[]`) Filetype(s) to associate with lang
```

{{< /admonition >}}
<!-- textlint-enable -->

ここで気がついてほしいのは、nvim-treesitterというプラグインの役割はパーサの管理とクエリ集になっているのです。\
パーサの管理自体は別にすることだって事実上可能ではないでしょうか？

### nvim-treesitter-textobjects

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
[support_languages]: https://github.com/nvim-treesitter/nvim-treesitter/blob/main/SUPPORTED_LANGUAGES.md
