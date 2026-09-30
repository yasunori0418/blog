---
title: "Polars LazyFrameを関数としてつなぐデータ処理CLI「cryoflow」を、あえて作ってみた"
emoji: "🫖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - lgtechblogsprint
  - polars
  - parquet
  - python
  - cli
published: true
published_at: 2026-09-30 12:00
publication_name: loglass
---

<!-- textlint-disable -->
:::message
この記事は毎週必ず記事がでるテックブログ [Loglass Tech Blog Sprint](https://zenn.dev/topics/lgtechblogsprint) の163週目の記事です！
4年間連続達成まで残り49週となりました！
:::
<!-- textlint-enable -->

## 先に結論

- Polarsの`LazyFrame`を「`LazyFrame`を受け取って`LazyFrame`を返す関数」としてつなぎ、TOMLの設定ファイルで組み立てるCLI「cryoflow」を作ってみた
- parquetの単発の加工ならDuckDBのSQLで済む。今回は実用性よりも、Polarsの遅延評価と関数合成の相性を確かめたくて、あえてプラグイン機構まで作った
- 作ってみて、returnsの`Result`型でパイプラインを合成する便利さと、プラグイン単位でテストを書ける開発者体験が得られた。一方で、プラグイン機構の構築と、プラグインごとに観点が変わる`dry_run`の設計には手間がかかった
- 同梱プラグインはまだ最小限で、変換は列の定数倍だけ

https://github.com/yasunori0418/cryoflow

## 始めに

ログラスのテックブログには、parquetを扱った記事がいくつかあります。
その中でも[龍島さん](https://zenn.dev/hryushm)の記事を読んで、parquetというファイル形式に興味を持ったのがきっかけです。

https://zenn.dev/loglass/articles/0f3c7c0eb59dff

龍島さんの記事では、S3上のparquetファイルのメタデータを使って、必要なデータだけを読み取るしくみを掘り下げています。
「ただのファイル形式なのに、インデックスを引くみたいに必要な部分だけ読めている…！」と思いながら読んでいました。

ただ、いざ手元でparquetファイルの中身を触ろうとすると、これが意外とたいへんです。
parquetはバイナリ形式のため、テキストエディタで開いても読めません。
閲覧だけなら[`parquet-tools`](https://github.com/ktrueda/parquet-tools)や[`pqrs`](https://github.com/manojkarthick/pqrs)のようなツールで足ります。
そこで、特定の列の値の一括変換や、列の追加・削除といった列単位の編集も、手軽にできるようにしたいと考えました。

とはいえ、parquetの加工はDuckDBなら1行のSQLで済みますし、pandasやPyArrowでもできます。
実用だけを考えれば、新しくツールを作る必要はありません。
それでも作ったのは、Polarsを触るうちに、メソッドチェインで積み重ねる処理を小さな関数に切り出して設定ファイルでつないだらおもしろいのでは、と思うようになったからです。

「そうだ、プラグイン拡張できて、**設定させていただける**[^1] parquet操作のCLIを作ろう。」

この記事は、足りないツールを埋めた話というより、その思いつきをCLIとして形にしてみた記録です。

[^1]: vim-jpコミュニティで、自分で設定を書いて使い込めることを指して使われる言い回しです。

## cryoflowとは

cryoflowは、Polarsの`LazyFrame`を中心にしたプラグイン駆動の列指向データ処理CLIツールです。
入力はparquetとApache Arrow IPCで、CSVも読み込めます。
設定ファイルに並べたプラグインの順番でデータを処理します。

PyPIにも公開しているので、`uv`があればすぐに試せます。

```bash
uv tool install cryoflow
# インストールせずに試すなら
uvx cryoflow --help
```

Nixを使っている方は、`nix run`で直接実行もできます。

```bash
nix run github:yasunori0418/cryoflow -- --help
```

本記事の内容はcryoflow 0.2.4で動作確認しています(対応はPython 3.11以上)。

### 名前の由来

Polarsというライブラリは、ホッキョクグマをロゴにしています。
北極から「冷たい(cryo)」を連想しました。
データソースになるparquetファイルが、その冷たい中を通り抜けながら処理されていく(flow)という意味で名付けています。

## 試したかったこと：LazyFrameを関数としてつなぐ

parquetファイルを読み書きする方法はいくつかありますが、今回はPolarsを採用しました。
これは性能比較をして選んだというよりも、**技術的におもしろい** という観点で選んでいます。

### SQLを使わなくてもデータを処理できる

SQLを使わずに、メソッドチェインで処理内容を積み重ねていけるのがPolarsのおもしろいところです。
例として、後述のサンプルデータを処理するコードを示します。

```python
import polars as pl

(
    pl.scan_parquet("sample_sales.parquet")
    .filter(pl.col("is_returned").not_())
    .with_columns((pl.col("total_amount") * 2).alias("total_amount"))
    .sink_parquet("output.parquet")
)
```

SQLなら1つのクエリにまとまる処理が、Polarsではメソッド1つずつに分かれて並びます。
処理がメソッド単位で分かれているので、**データ処理の振る舞いを部分的にテストできる** ところにもおもしろさを感じました。

### LazyFrameとscan/sink

上の例で使っている`scan_parquet`は、この時点ではデータを読み込みません。
`LazyFrame`というクエリプランを返すだけで、`filter`や`with_columns`もプランに処理を積み重ねていくだけです。
最後の`sink_parquet`(または`collect`)を呼んだ時点で、初めてプランが最適化されて実行されます。

Polarsは遅延評価でクエリ全体を把握できるため、龍島さんの記事にあるようなparquetのメタデータを使ったpushdown(必要な列・行だけを読む最適化)を、プランの最適化として自動で適用できます。
使う列や絞り込みの条件がクエリから分かるので、ファイル全体を読み込まずに済みます。
さらに`sink_parquet`はストリーミングで書き出します。
ストリーミング実行できる処理の範囲であれば、メモリに載せ切れないサイズでも扱えます。

### 変換を小さな関数として合成する

Polarsの処理をメソッド単位で書けるということは、変換処理を「`LazyFrame`を受け取って`LazyFrame`を返す小さな関数」として切り出せるということです。
関数型プログラミングの関数合成のように、その小さな関数をつないで1本のパイプラインにできれば、手早くparquetを操作できるツールができそうだと考えました。
部品になる関数は、UNIX哲学の「1つのことをうまくやる」に倣って小さく作れば、別の設定ファイルでも再利用できます。

業務データを列単位で扱うと、各列の処理にはドメイン固有の知識が強く出るはずです。
そうなると、読み込み・変換・書き出しの骨組みは同じなのに、列名や係数だけが違うスクリプトがドメインごとに乱立するのではないか、とも考えました。
これは実際に検証したわけではなく、こうなったら便利そうだという設計上の仮説です。
処理の本体をプラグインに、ドメイン固有の値を設定ファイルに切り出せば、ドメインが変わっても書き換えるのは設定ファイルの`options`だけになります。
利用者が用意するのは次の2つです。

- 振る舞いがテスト済みのプラグイン(組込み・ローカル)
- 手順書としての設定ファイル

設定ファイルをコミットしておけば、処理の再現性を保てます。
Vimと同じように、使う人が自分で **「設定させていただける」** CLIを目指しています。

SQLでもCTEやビューで処理を分割はできますが、分割した各部分をPythonの型付きオブジェクトとしてユニットテストし、組み合わせる形にはなりません。
そのため、SQLではなくPythonのメソッドチェインで組むことにしました。
なお、DuckDBにもPythonからメソッドチェインで書けるRelational APIがあるので、DuckDBでも同じ設計はできるはずです。
今回はPolarsを触りたかったので、DuckDBとの比較はしていません。

また、Pythonの関数ライブラリにして、Polarsの`LazyFrame.pipe`でつないでも同じことはできます。
それをCLIと設定ファイルの形にしたら何が変わるかを試したかった、というのが正直なところです。

## 作ったもの：設定ファイルと3種類のプラグイン

### 設定ファイル

ここからは、リポジトリの`examples/data/`に置いている`sample_sales.parquet`を例にします。
架空の売上データで、全50行・12列あります。
この記事で使うのは、次の3列です。

| 列名 | 型 | 内容 |
| --- | --- | --- |
| `region` | String | 地域 |
| `total_amount` | Int64 | 合計金額 |
| `is_returned` | Boolean | 返品されたか |

ほかの列を含めたスキーマの全体は、リポジトリの[`examples/data/README.md`](https://github.com/yasunori0418/cryoflow/blob/main/examples/data/README.md)を参照してください。

設定ファイルはTOMLで書きます。
`input_plugins`・`transform_plugins`・`output_plugins`にそれぞれプラグインを並べていくだけです。

```toml
[[input_plugins]]
name = "parquet-scan"
module = "cryoflow_plugin_collections.input.parquet_scan"
[input_plugins.options]
input_path = "data/sample_sales.parquet"

[[transform_plugins]]
name = "column-multiplier"
module = "cryoflow_plugin_collections.transform.multiplier"
[transform_plugins.options]
column_name = "total_amount"
multiplier = 2

[[output_plugins]]
name = "parquet-writer"
module = "cryoflow_plugin_collections.output.parquet_writer"
[output_plugins.options]
output_path = "data/output.parquet"
```

これを`cryoflow run -c config.toml`で実行すると、`sample_sales.parquet`の`total_amount`列を2倍にした`output.parquet`が出力されます。
設定ファイル内のパスは、カレントディレクトリではなく **設定ファイルのあるディレクトリからの相対パス** で解決されます。
設定ファイルとデータをまとめて移動しても壊れないので、手順書としてコミットしておきやすい作りです。

`module`にはPythonのモジュールパスだけではなく、`./plugins/my_plugin.py`のようなローカルの`.py`ファイルのパスも指定できます。
ドメイン固有の処理は、自分のリポジトリにプラグインを置いて設定ファイルから呼び出せば良いわけです。

### 3種類のプラグイン

プラグインは、入力・変換・出力の3種類の抽象クラスを継承して作ります。

<!-- markdownlint-disable MD013 -->

```python
class InputPlugin(BasePlugin):
    def execute(self) -> Result[FrameData, Exception]: ...
    def dry_run(self) -> Result[dict[str, pl.DataType], Exception]: ...


class TransformPlugin(BasePlugin):
    def execute(self, df: FrameData) -> Result[FrameData, Exception]: ...
    def dry_run(self, schema: dict[str, pl.DataType]) -> Result[dict[str, pl.DataType], Exception]: ...


class OutputPlugin(BasePlugin):
    def execute(self, df: FrameData) -> Result[None, Exception]: ...
    def dry_run(self, schema: dict[str, pl.DataType]) -> Result[dict[str, pl.DataType], Exception]: ...
```

<!-- markdownlint-enable MD013 -->

`FrameData`は`pl.LazyFrame | pl.DataFrame`の型エイリアスです。
`InputPlugin`が`scan_parquet`で`LazyFrame`を作り、`TransformPlugin`がそこに処理を積み重ねていきます。
最後に`OutputPlugin`が`sink_parquet`を呼んだ時点で、初めて実際の処理が走ります。
同梱プラグインはすべて`LazyFrame`のまま受け渡します。
そのため、cryoflowのパイプライン自体が、Polarsの遅延評価をそのまま設定ファイルで組み立てる形になっています。

戻り値が`Result`になっているのは、[returns](https://github.com/dry-python/returns)というライブラリを使っているためです。
どこかのプラグインで失敗したら、以降の処理は実行されずにエラーがそのまま伝わっていきます。
言い換えると、cryoflowのパイプラインは、`Result`を返す関数を`bind`(前段が成功したときだけ次の関数を適用する)でつないだ合成です。
設定ファイルは、その合成順を宣言したものにあたります。

## `check`コマンドによるdry-run

各プラグインには`execute`とは別に、`dry_run`というメソッドがあります。
これはデータを処理せずに、スキーマ(列名と型)だけを受け取って検証するためのものです。
Polarsの`LazyFrame`は`collect_schema()`で、データを読み込まずにスキーマを取得できます。
入力プラグインの`dry_run`はこれでスキーマを取り出します。

試しに先ほどの設定ファイルで、`column_name`を文字列の列である`region`に変えて`check`コマンドを実行してみます。

<!-- markdownlint-disable MD013 -->

```console
$ cryoflow check -c config.toml
[CHECK] Config loaded: /path/to/config.toml
[CHECK] Loaded 3 plugin(s) successfully.

[CHECK] Running dry-run validation...
INFO: Validating 1 transformation plugin(s)...
INFO:   [1/1] column_multiplier (label: default)
ERROR:     Validation failed: Column 'region' has type String, expected numeric type
[ERROR] Validation failed: Column 'region' has type String, expected numeric type
```

<!-- markdownlint-enable MD013 -->

出力にある`(label: default)`の`label`は、変換・出力プラグインがどの入力プラグインのデータを処理するかを対応付ける設定で、省略すると`default`になります。
また、設定ファイルでは`name = "column-multiplier"`と書いていますが、出力の`column_multiplier`はプラグイン側で定義している名前です。
文字列の列を2倍にはできないので、実行前にエラーとして検出できました。
大きなparquetファイルを処理する前に、設定ファイルの間違いに気付けるのはうれしいですね。

### dry_runをプラグインごとに実装した理由

`LazyFrame`のまま受け渡しているので、積み重ねたプランに`collect_schema()`を呼ぶだけでも、スキーマは確かめられます。
それでも各プラグインに`dry_run`を実装させているのは、プラグインによって実行前に確認したい観点が変わるためです。
たとえば`column-multiplier`なら「指定した列が存在し、数値型であること」を確かめたいですが、別のプラグインでは確認したいことが違ってきます。
そのため、単純に`collect_schema()`でチェックすれば良いだけではないと判断しました。

一方で、この設計には限界もあります。
`dry_run`が返す出力スキーマは、プラグインの作者が手で書くものです。
実際、`column-multiplier`の`dry_run`は入力スキーマをそのまま返しています。
そのため`multiplier = 1.5`のように小数を指定すると、実行結果の`total_amount`はFloat64になるのに、`check`上はInt64のまま扱われます。
手書きのスキーマ推論は、実装とずれうるということです。

## 技術スタック

ここまで出てきたものも含めて、cryoflowの技術スタックは次のとおりです。

| 用途 | ライブラリ |
| --- | --- |
| データ処理 | Polars(`LazyFrame`) |
| CLI | Typer |
| プラグイン機構 | pluggy + importlib |
| 設定ファイル | tomllib(標準ライブラリ) + Pydantic |
| エラーハンドリング | returns(`Result`) |

## 作って分かったこと

### 得られたこと

データの変換パイプラインにreturnsを使ってみて、`Result`型の便利さをPythonで体験できたのは良かったです。
前段が失敗したら以降を実行せずにエラーをそのまま伝える、という振る舞いを、パイプラインの合成そのものとして書けます。

また、変換を個別のプラグインとして実装したことで、プラグインごとにテストコードを用意しやすくなりました。
これは、開発者体験の向上を優先した結果の設計です。

### たいへんだったこと

手間がかかったのは、まずプラグイン機構の構築です。
pluggyとimportlibで、Pythonのモジュールパスとローカルの`.py`ファイルの両方からプラグインを読み込めるようにしています。

`dry_run`の設計にも手間がかかりました。
前節のとおり、確認したい観点がプラグインごとに違うため`collect_schema()`だけには任せられず、その代わりに出力スキーマを手で書く必要が出てきました。

## 到達点とこれから

同梱しているプラグインは、まだ最低限です。
入力はparquet・Arrow IPC・CSVの読み込み、変換は列を定数倍するだけ、出力はparquetの書き出しだけです。

試したかった「`LazyFrame`を関数としてつなぎ、設定ファイルで組み立てる」ことは、3種類のプラグインと`check`コマンドまで形にできました。
一方で、きっかけだった列の追加・削除のような編集は、まだプラグインがありません。
今後は編集系の変換プラグインを増やして、parquetを手軽に操作できるツールにしていきたいと思っています。

## 最後に

龍島さんの記事からparquetに興味を持ち、Polarsのおもしろさに惹かれて、あえてcryoflowを作ってみました。
SQLで済む処理ではありますが、`LazyFrame`を関数としてつなぎ、設定ファイルとプラグインで組み立てる形は、Polarsの遅延評価と相性が良いと感じています。

parquetファイルを扱う機会がある方は、ぜひ触ってみてください。
プラグインを書いて、自分好みに設定させていただければ幸いです！
