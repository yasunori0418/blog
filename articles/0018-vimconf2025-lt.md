---
title: "VimConf 2025 SmallのLTを振り返っていく"
emoji: "🫖"
type: "idea" # tech: 技術記事 / idea: アイデア
topics:
  - Vim
  - VimConf
published: true
publication_name: loglass
---

<!-- textlint-disable -->

:::message
この記事は **[株式会社ログラス Productチーム Advent Calendar 2025](https://qiita.com/advent-calendar/2025/loglass)** のシリーズ 1、**5日目** の記事です。
:::

<!-- textlint-enable -->

## 始めに

2025年11月2日に [VimConf 2025 Small](https://vimconf.org/2025/ja/) が開催されていました。

https://vimconf.org/2025/ja/

私は2023年から連続で参加しており、毎年楽しみにしているイベントでもあります。
その2023年には[懇親会の中で突発的にLT](https://zenn.dev/vim_jp/articles/0002-engineer_with_vim)をするということもありましたが、公式の記録に残ることのない登壇でした。

今年は`Tried writing it vim9script`というタイトルでLTのプロポーザルを出して、無事採択されました。
最近Vimと言えば、Neovimと混同されたり、VSCodeやIntellijのVim拡張の話題だったりすることがほとんどですが、これは本家本元の**最新のVim**の話です。
その中でもVimのバージョン9から追加された`Vim9 script`について触れてみました。

当日の資料などは、こちらに共有しておきます。

https://speakerdeck.com/yasunori0418/tried-writing-it-vim9script

https://youtu.be/wEsQF3hWYDE?si=9dRR2871a3fiNqb0&t=467

ここでは、LTの中で話すことができなかったことや、当日の良かった部分・改善点などを振り返っていきます。

## プロポーザルについて

<!-- textlint-disable -->
:::details 今回提出したプロポーザル

```markdown
dpp.vimの読み込み部分を`vim9script`で書いてみました。
その中で`vim9script`の「良いところ、気になったところ、注意点」があるので紹介します。
https://github.com/yasunori0418/dotfiles/tree/main/home/.config/vim/autoload/user

このLTでは`vim9script`を書いたことが無い人に、`vim9script`の雰囲気が伝わるような内容にします。

- Ajenda
1. Pros
2. Cons
3. Points to note
4. Conclusion
```

:::
<!-- textlint-enable -->

実のことを言うと、LTプロポーザルを提出したのは期限最終日のことでした。
と言うのも、去年から今年にかけてVim活があまりできておらず、「自分には話すことがない」と登壇は諦めかけていました。

そんな中、vim-jpの`#event-vimconf`チャンネルでLTのプロポーザル投稿で盛り上がっているところを見て、「自分も何か喋べれることがないか」と自分のdotfilesを読み漁ってみたところ、
`Vim9 script`について話せそうと思い、ギリギリでプロポーザルを投稿しました。

過去VimConf参加した際にプロポーザルが採択されるためのコツとして、「自分だけが語れるVimのエピソード」を話してほしいというアドバイスをもらっていました。
「Vim9 scriptを設定のために書いているパターンは少なそうだな」などと思いプロポーザルを提出してみたら、無事採択されました！

## LTで話せなかったこと

今回、Vim9 scriptを書いていて一番詰まった部分は、発表資料内の「`points to note`」にまとめています。

### nullに複数の型が存在する問題(`null_<type>`)

Vim9 scriptには通常の`null`のほかに`null_<type>`という複数のnullに関する値が存在しています。
これに対して「なんで…？」と聞かれても困る部分ではあり、どうしてそんな設計になっているのかは、天国のBram氏に聞いてみないと分かりません。

以下のようなコードがあったときに明示的に`null_<type>`を使う必要があります。

https://github.com/yasunori0418/dotfiles/blob/5f93c6a3eb91305bfb28578d0d71dfa52fa35051/home/.config/vim/autoload/user/dpp.vim#L6-L9

6行目に宣言している`GetBaseDir`というlambda式によって宣言された関数は、文字列を引数として期待します。
しかし、7行目の`GetBaseDir`呼び出しには`null_string`を使用しています。

静的型付けの言語に慣れている方だと、違和感を感じるでしょう。
シグネチャは`string`しか許容していないのに、`null`に相当する値を入れたら動かないと思いますよね？

そういうときに使用するのが`null_<type>`のような特殊なnullになります。
ちなみに、引数にあえて`null`を渡すと以下のようなエラーが発生します。

```console
Error detected while processing ~/dotfiles/home/.config/vim/vimrc[8]..~/dotfiles/home/.config/vim/autoload/user/dpp.vim:
line    7:
E1013: Argument 1: type mismatch, expected string but got special
Error detected while processing ~/dotfiles/home/.config/vim/vimrc:
line    8:
E1048: Item not found in script: Setup
Press ENTER or type command to continue
```

`GetBaseDir`自体が期待するのはstring型だけど、nullにしたいというケースのときに`null_string`をセットしないとエラーになってしまうのです。
今回のケースの場合はlambda式を用いて作った関数で、デフォルト引数を宣言できません。
ですが通常通りに関数を宣言しても同じことが発生します。

https://github.com/yasunori0418/dotfiles/blob/785527ed91610b4d97e52ef0049246815308a8bb/home/.config/vim/autoload/user/dpp.vim#L6-L14

<!-- markdownlint-disable MD013 -->
```console
E1013: Argument 1: type mismatch, expected string but got special
Error detected while processing ~/dotfiles/home/.config/vim/vimrc:
line    8:
E1048: Item not found in script: Setup
```
<!-- markdownlint-enable MD013 -->

Vim9 scriptの世界観では`nullable`や`optional`といった引数を宣言するときは、その型に合った`null`をデフォルト引数としてセットしてあげる必要があると思っておいた方が良いでしょう。

詳しくは以下のヘルプを確認すると良いです。

- `:h null`
- `:h null-variables`
- `:h null-compare`
- `:h null-details`

### map/filter/foreach

## 良かった部分

## 改善すべき部分

## 次回以降のVimConfに向けて

## `:q!`
