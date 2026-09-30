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

「そうだ、プラグイン拡張できて、***設定させていただける***[^1] parquet操作のCLIを作ろう。」

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

本記事はcryoflow 0.2.4、Python 3.11以上で動作確認しています。

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

龍島さんの記事にあるpushdown(必要な列・行だけを読む最適化)も、この遅延評価があるからこそです。
必要な列や行だけを読み込むように最適化されるので、ファイル全体を読み込む必要がありません。
さらに`sink_parquet`はストリーミングで書き出します。
ストリーミング実行できる処理の範囲であれば、メモリに載せ切れないサイズでも扱えます。

### 変換を小さな関数として合成する

Polarsの処理をメソッド単位で書けるということは、変換処理を「`LazyFrame`を受け取って`LazyFrame`を返す小さな関数」として切り出せるということです。
関数型プログラミングの関数合成のように、その小さな関数をつないで1本のパイプラインにできれば、お手軽にparquetを操作できるツールができそうだと考えました。
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
架空の売上データで、全50行・12列の次のようなスキーマになっています。

| 列名 | 型 | 内容 |
| --- | --- | --- |
| `order_id` | String | 注文ID |
| `order_date` | Date | 注文日 |
| `region` | String | 地域 |
| `category` | String | カテゴリ |
| `product_name` | String | 商品名 |
| `unit_price` | Int64 | 単価 |
| `quantity` | Int32 | 数量 |
| `discount_rate` | Float64 | 割り引き率 |
| `discount_amount` | Int64 | 割り引き額 |
| `total_amount` | Int64 | 合計金額 |
| `payment_method` | String | 支払い方法 |
| `is_returned` | Boolean | 返品されたか |

先頭の5行は次の通りです。

<!-- markdownlint-disable MD013 -->

| order_id | order_date | region | category | product_name | unit_price | quantity | discount_rate | discount_amount | total_amount | payment_method | is_returned |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ORD-0001 | 2025-02-05 | 東北 | 電子機器 | ノートPC | 61300 | 4 | 0.0 | 0 | 245200 | クレジットカード | false |
| ORD-0002 | 2025-05-10 | 北海道 | 電子機器 | ノートPC | 24100 | 4 | 0.0 | 0 | 96400 | 電子マネー | false |
| ORD-0003 | 2025-03-13 | 北海道 | 日用品 | 石鹸 | 800 | 8 | 0.1 | 640 | 5760 | 電子マネー | false |
| ORD-0004 | 2025-03-28 | 東北 | 食品 | チョコレート | 700 | 4 | 0.2 | 560 | 2240 | クレジットカード | false |
| ORD-0005 | 2025-01-12 | 九州 | 食品 | チョコレート | 2200 | 5 | 0.2 | 2200 | 8800 | クレジットカード | false |

<!-- markdownlint-enable MD013 -->

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
文字列の列を2倍にはできないので、実行前にエラーとして検出できました。
大きなparquetファイルを処理する前に、設定ファイルの間違いに気付けるのはうれしいですね。

## 技術スタック

ここまで出てきたものも含めて、cryoflowの技術スタックは次の通りです。

| 用途 | ライブラリ |
| --- | --- |
| データ処理 | Polars(`LazyFrame`) |
| CLI | Typer |
| プラグイン機構 | pluggy + importlib |
| 設定ファイル | tomllib(標準ライブラリ) + Pydantic |
| エラーハンドリング | returns(`Result`) |

## 今後の展望

同梱しているプラグインは、まだ最低限です。
入力はparquet・Arrow IPC・CSVの読み込み、変換は列を定数倍するだけ、出力はparquetの書き出しだけです。

一番の動機だった「parquetファイルの中身を手軽に編集する」ことは、まだ実現できていません。
今後は編集系の変換プラグインを増やして、parquetをお手軽に操作できるツールにしていきたいと思っています。

## 最後に

龍島さんの記事からparquetに興味を持ち、Polarsのおもしろさに惹かれてcryoflowを作ってみました。
SQLを使わなくてもメソッドチェインでデータ処理を積み重ねていく感覚は、設定ファイルとプラグインで組み立てるCLIと相性が良いと感じています。

parquetファイルを扱う機会がある方は、ぜひ触ってみてください。
プラグインを書いて、自分好みに設定させていただければ幸いです！
