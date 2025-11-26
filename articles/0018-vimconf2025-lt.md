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

## 良かった部分

## 改善すべき部分

## 次回以降のVimConfに向けて

## `:q!`
