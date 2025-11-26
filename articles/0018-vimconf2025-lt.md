---
title: "VimConf 2025 SmallのLTを振り返っていく"
emoji: "🫖"
type: "idea" # tech: 技術記事 / idea: アイデア
topics:
  - Vim
  - VimConf
published: true
publication_name: loglass
published_at: 2025-12-05 17:00
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

### map/filterという破壊的な関数について

`vim script`に組み込まれている`map`や`filter`などの関数は元の値を破壊的に変更する関数です。

```vim
let s:hoge_list = [1, 2, 3, 4, 5, 6]
echo s:hoge_list->filter({_, v -> v % 2 == 0})->map({_, v -> $'item: {v}'}) " ['item: 2', 'item: 4', 'item: 6']
echo s:hoge_list " ['item: 2', 'item: 4', 'item: 6']
```

上記のサンプルコードでは、数値型の配列に対して、`map`関数で文字列と連結し、文字列の配列に変化しています。

破壊的な操作は意図しないバグを生む可能性があるため、回避した方が良いでしょう。
組込みの関数には`mapnew`や`copy`といった非破壊的な関数があるため、これらを活用した方が良いでしょう。

```vim
let s:hoge_list = [1, 2, 3, 4, 5, 6]
let s:fuga_list = s:hoge_list->copy()->filter({_, v -> v % 2 == 0})
let s:piyo_list = s:fuga_list->mapnew({_, v -> $'item: {v}'}) 
echo s:hoge_list " [1, 2, 3, 4, 5, 6]
echo s:fuga_list " [2, 4, 6]
echo s:piyo_list " ['item: 2', 'item: 4', 'item: 6']
```

ここでVim9 scriptの話に戻しますが、Vim9 scriptは静的型付けの言語であるため、宣言しておいた型から変化はできません。
最初に提示したサンプルコードのような操作はできないため、後述したコードのように非破壊的な値操作を心掛ける必要があります。
後述したコードをVim9 scriptで記述すると以下のようになります。

```vim
vim9script

const hoge_list = [1, 2, 3, 4, 5, 6]
const fuga_list = hoge_list->copy()->filter((_, v: number) => v % 2 == 0)
const piyo_list = fuga_list->mapnew((_, v: number) => $'item: {v}') 
echo hoge_list # [1, 2, 3, 4, 5, 6]
echo fuga_list # [2, 4, 6]
echo piyo_list # ['item: 2', 'item: 4', 'item: 6']
```

ちなみに、変数宣言に`const`を使っているのは好みの問題です。
Vim9 scriptでは`var`でも問題ありませんが、`const`で宣言すれば値の変更ができなくなるので、意図しないデータの上書きや変更を防げてとても便利です。

### foreachに渡すlambda式の引数省略できない問題

foreach関数において、lambda式を第2引数に渡すときは以下のようになっています。

<!-- markdownlint-disable MD010 -->
```vimdoc
foreach({expr1}, {expr2})				*foreach()* *E1525*

		中略

		{expr2} が |Funcref| の場合 2 つの引数を取る必要がある:
			1. 現在の項目のキーまたはインデックス。
			2. 現在の項目の値。
```
<!-- markdownlint-enable -->

これはちゃんとドキュメントを読んでおけば回避できた話ではありますが、私は第1引数で現在の項目の値が取れると思い、以下のようにコードを書いていました。

```vim
vim9script

hoge_list->foreach((v) => fuga(v)) # E1106: One argument too many
```

これによって`hoge_list`の各値が`fuga`関数に渡されて処理されると思っていましたが、`E1106`というエラーが発生しました。
これを読んでみると次のような内容になっています。

<!-- markdownlint-disable MD010 -->
```vimdoc
							*E1106*
引数は、他の言語と同様に、"a:" なしで名前でアクセスされる。"a:" 辞書や "a:000"
リストはない。
```
<!-- markdownlint-enable -->

> 当時の私「????? Vim9 scriptはa:のパフォーマンス悪いとかで廃止してなかったか?????」

ここでもう一度、foreachのドキュメントを読んでみましょう。

<!-- markdownlint-disable MD010 -->
```vimdoc
foreach({expr1}, {expr2})				*foreach()* *E1525*

		中略

		{expr2} が |Funcref| の場合 2 つの引数を取る必要がある:
			1. 現在の項目のキーまたはインデックス。
			2. 現在の項目の値。
		旧来のスクリプトの lambda では引数を 1 つだけ受け入れてもエラー
		は発生しないが、Vim9 の lambda では "E1106: One argument too
		many" になり、引数の数は一致する必要がある。
		関数が値を返した場合、その値は無視される。
```
<!-- markdownlint-enable -->

> Vim9 の lambda では "E1106: One argument too many" になり、引数の数は一致する必要がある。

…ということです。
ですので、以下のように書き直しましょう。

```vim
vim9script

hoge_list->foreach((_, v) => fuga(v))
```

困ったらhelpを見るのは大事ですが、このforeachのようなヒントにならないようなエラーも出て混乱するときもあります。
これを読んだ皆さんは、ぜひともforeachを使うときは`:h foreach`でドキュメントをよく確認しましょう。

## 良かった部分

冒頭で話をした通り、今回のLTは公式にプロポーザルが採択されて登壇に至ります。
2023年の突発の非公式LTと違い、ちゃんとVimConfの歴史に自分の登壇記録が残るというのは、一人のVimmerとしてうれしい物です。

また、話すことがないと少し諦め気味だった状態からプロポーザルを出せたのは、ちゃんと良いチャレンジができたと思っています。

登壇の練習も事前に社内の10分勉強会で行っていたり、前日の段階でも数名に発表内容を見てもらったりして、フィードバッグをもらえていたため、当日は**とても丁寧**な発表ができました。
**ちゃんと5分の枠に収まって、** LTという範囲で話せる範囲の発表になりました。

## 改善すべき部分

前項の「とても丁寧」や「ちゃんと5分の枠に収まって」という強調に関して、LTとは多少時間オーバーになってドラを鳴らされた方が会場のウケが良いということを発表後に知りました。

もちろん伝えたいことを伝えきるのも大事ではありますが、登壇したら自分の発表で会場は盛り上がってほしい物です。
反省とまでは言いませんが、そういうネタ的な要素も含めていたら「もっと良くなっていたかも」という経験でした。

また、この記事の中で`Vim9 script`の表記を統一している理由として、vimのhelpを日本語翻訳されている方からの[リプライ](https://x.com/YKirin0418/status/1984892220122808582)で正式な表記についての指摘があったためです。
これはドキュメントの読み込みが足りなかった部分でもあったと反省点となります。

そもそも今回のVim9 scriptの発表は、「LTの枠に収めるにはもったいない程のテーマだったのでは？」という意見を懇親会やイベント後にもらっていました。
スピーカーセッションとしてプロポーザルを投稿したらもっといろいろ話せたかもしれないと思いました。
当日の補足内容として記事内にVim9 scriptの解説も混ぜてみましたが、まだまだ話せることはあったので、見積もりミスだったと感じてます。

## 次回以降のVimConfに向けて

## `:q!`
