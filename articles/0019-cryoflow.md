---
title: "Polars LazyFrame製、プラグインで拡張できる列指向データ処理CLI「cryoflow」を作った"
emoji: "🫖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - lgtechblogsprint
  - polars
  - parquet
  - python
  - cli
published: true
published_at: 2026-09-28 12:00
publication_name: loglass
---

<!-- textlint-disable -->
:::message
この記事は毎週必ず記事がでるテックブログ [Loglass Tech Blog Sprint](https://zenn.dev/topics/lgtechblogsprint) の163週目の記事です！
:::
<!-- textlint-enable -->

## ざっくりまとめ

- parquetファイルをTOMLの設定ファイルで処理できるCLIツール「cryoflow」を作った
- Polarsを採用したのは、SQLを使わずにメソッドチェインでデータ処理を積み重ねられるのが技術的におもしろかったから
- DuckDBでもparquetは扱えるが、SQL文字列ではなく「1つのことをうまくやる」式をプラグインとして組み合わせたかった
- 入力・変換・出力の3種類のプラグインを設定ファイルに並べるだけで、処理を組み立てられる
- `check`コマンドで、データを読み込まずにスキーマの検証ができる

https://github.com/yasunori0418/cryoflow

## 始めに

ログラスでは、社内のエンジニアがparquetについて触れている記事がいくつかあります。
その中でも[龍島さん](https://x.com/hryushm)の記事を読んで、parquetというファイル形式に興味を持ったのが切っ掛けです。

https://zenn.dev/loglass/articles/0f3c7c0eb59dff

S3上のparquetファイルから、メタデータを使って必要な部分だけを取得する。
「ファイルなのにDBっぽいことをしている…！」と思いながら読んでいました。

ただ、いざ手元でparquetファイルの中身を見ようとすると、これが意外とたいへんです。
parquetはバイナリ形式のため、vimなどのテキストエディタで開いても中身を読むことはできません。
私にとってparquetファイルを開いて、中身の閲覧・編集がやりやすいツールに出会えなかったのが、cryoflowを作る一番の動機です。

「そうだ、プラグイン拡張できて、 ***設定させていただける*** parquet操作のCLIを作ろう。」

## cryoflowとは

cryoflowは、Polarsの`LazyFrame`を中心にしたプラグイン駆動の列指向データ処理CLIツールです。
parquetとApache Arrow IPC(ついでにCSV)を入力として、設定ファイルに並べたプラグインの順番でデータを処理します。

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

### 名前の由来

Polarsというライブラリには、ホッキョクグマのモチーフが多く使われています。
そこから連想して、次のように名付けました。

> 北極ってことは冷たい(cryo)っていう感じだな。
> データソースになるparquetファイルがその冷たい中を通り抜けながら処理されていく(flow)

## なぜPolarsなのか

parquetファイルを読み書きする方法はいくつかありますが、今回はPolarsを採用しました。
これは性能比較をして選んだというよりも、 **技術的におもしろい** という観点で選んでいます。

### SQLを書かずにデータを処理する

他のデータ操作系のツールでは、SQLを書いてDBっぽく操作することがほとんどです。
一方でPolarsは、SQLを使わずにメソッドをチェインしながら処理内容を積み重ねてデータを処理します。

```python
import polars as pl

(
    pl.scan_parquet("sample_sales.parquet")
    .filter(pl.col("is_returned").not_())
    .with_columns((pl.col("total_amount") * 2).alias("total_amount"))
    .sink_parquet("output.parquet")
)
```

まるでRDBの中身を簡易的ですが、明示的に操作しているような感覚です。
そして処理がメソッド単位で分かれているので、**部分的にデータ処理の振る舞いをテストできる** という部分にもおもしろさを感じました。

### LazyFrameとscan/sink

上の例で使っている`scan_parquet`は、この時点ではデータを読み込みません。
`LazyFrame`というクエリプランを返すだけで、`filter`や`with_columns`もプランに処理を積み重ねていくだけです。
最後の`sink_parquet`(または`collect`)を呼んだ時点で、初めてプランが最適化されて実行されます。

龍島さんの記事にあるpushdownも、この遅延評価があるからこそです。
必要な列や行だけを読み込むように最適化されるので、ファイル全体を読み込む必要がありません。
さらに`sink_parquet`はストリーミングで書き出すため、メモリに載せ切れないサイズでも扱えます。

### DuckDBではなかった理由

parquetを読み書きする処理と言えば、DuckDBを思い浮かべる方も多いと思います。
DuckDBでもparquetファイルは直接扱えますし、正直に言えばSQLで済む話ではあります。

ただ、cryoflowでやりたかったのは、SQL文字列で処理を書くことではありません。
Pythonのメソッドチェインで書いた式を **プラグイン単位で組み合わせる** ことです。
SQLだと処理の単位が1つのクエリ文字列にまとまってしまい、部分的に切り出して組み合わせるのが難しくなります。
ですので、ここではSQLを使わない選択をしました。

## 設定ファイル駆動なプラグイン拡張

Polarsの式を部分的に書けるということは、UNIX哲学的に **「1つのことをうまくやる処理」** をプラグインにできます。
そのプラグインを組み合わせられたら、お手軽にparquetを操作できるツールができそうだと考えました。

parquetというファイルの特性上、各列のデータにはドメイン的な要素が強く出ます。
そのため、ドメイン固有のデータ処理ツールは乱立しやすくなります。
これを一般化する方法として、次の2つを組み合わせることにしました。

- 振る舞いがテスト済みのプラグイン(組込み・ローカル)
- 手続き書としての設定ファイル

設定ファイルをコミットしておけば、再現性があり部分的なデータの振る舞いを記述しやすい、フレームワーク的な操作ができるはずです。
Vimと同じように、使う人が自分で **「設定させていただける」** CLIを目指しています。

### 設定ファイル

ここからは、リポジトリの`examples/`に置いている`sample_sales.parquet`を例にします。
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
設定ファイルとデータをまとめて移動しても壊れないので、手続き書としてコミットしておきやすい作りです。

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
つまりcryoflowのパイプライン自体が、Polarsの遅延評価をそのまま設定ファイルで組み立てる形になっています。

戻り値が`Result`になっているのは、[returns](https://github.com/dry-python/returns)というライブラリを使っているためです。
どこかのプラグインで失敗したら、以降の処理は実行されずにエラーがそのまま伝わっていきます。

### `check`コマンドによるdry-run

各プラグインには`execute`とは別に、`dry_run`というメソッドがあります。
これはデータを処理せずに、スキーマ(列名と型)だけを受け取って検証するための物です。
Polarsの`LazyFrame`は`collect_schema()`で、データを読み込まずにスキーマを取得できます。

試しに先程の設定ファイルで、`column_name`を文字列の列である`region`に変えて`check`コマンドを実行してみます。

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

文字列の列を2倍にはできないので、実行前にエラーとして検出できました。
大きなparquetファイルを処理する前に、設定ファイルの間違いに気付けるのはうれしいですね。

### 技術スタック

ここまで出てきた物も含めて、cryoflowの技術スタックは次の通りです。

| 用途 | ライブラリ |
| --- | --- |
| データ処理 | Polars(`LazyFrame`) |
| CLI | Typer |
| プラグイン機構 | pluggy + importlib |
| 設定ファイル | Pydantic + TOML |
| エラーハンドリング | returns(`Result`) |

ちなみに開発にはClaude Codeを使っていて、実装計画のドキュメント作成から一緒に進めていました。

## 今後の展望

ここまで紹介しておいてなんですが、同梱しているプラグインはまだ最低限です。
入力はparquet・Arrow IPC・CSVの読み込み、変換は列を定数倍するだけ、出力はparquetの書き出しだけです。

一番の動機だった「parquetファイルを開いて中身を閲覧・編集する」ことは、まだ実現できていません。
今後は閲覧・編集系のプラグインを増やして、parquetをお手軽に操作できるツールにしていきたいと思っています。

## 最後に

龍島さんの記事からparquetに興味を持ち、Polarsのおもしろさに惹かれてcryoflowを作ってみました。
SQLを書かずにメソッドチェインでデータ処理を積み重ねていく感覚は、設定ファイルとプラグインで組み立てるCLIと相性が良いと感じています。

parquetファイルを扱う機会がある方は、ぜひ触ってみてください。
プラグインを書いて、自分好みに設定させていただければ幸いです！
