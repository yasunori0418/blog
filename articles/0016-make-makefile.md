---
title: 職場のプロジェクトに必ず配置しちゃうMakefileの話
emoji: "🫖"
type: "tech" # tech: 技術記事 / idea: アイデア
topics:
  - lgtechblogsprint
  - makefile
  - awk
published: true
published_at: 2025-07-07
publication_name: loglass
---

<!-- textlint-disable -->
:::message
この記事は毎週必ず記事がでるテックブログ [Loglass Tech Blog Sprint](https://zenn.dev/topics/lgtechblogsprint) の99週目の記事です！
2年間連続達成まで残り7週となりました！
:::
<!-- textlint-enable -->

## 始めに

ログラスに入社してから時間が経つのも早く、もう3ヵ月経ちました。
そんな私ですが、入社して最初に作成したPRの話をしていきます。

普段からVimやLinuxを使うのが好きではありますが、それと同時に **環境構築オタク** を自称している側面もあります。
オタクを自称する分、環境構築には多少のこだわりがあり、プロジェクトディレクトリに入ったら開発のための便利ツールがすぐ手元にある状態であってほしいのです。

プロジェクトに触って最初にやることというと環境構築ですが、必ずしも運用しやすい状態になっている訳ではありません。
その中でもログラスのプロダクトは環境構築がしやすい方ですが、より効率的にするためMakefileのブラッシュアップをしました。

## タスクランナーとしてのMakefileとの出会い

> make（メイク）は、プログラムのビルド作業を自動化するツール。コンパイル、リンク、インストール等のルールを記述したテキストファイル (makefile) に従って、これらの作業を自動的に行う。
> 引用元: [wikipedia make(UNIX)](https://ja.wikipedia.org/wiki/Make_(UNIX))

そもそも、MakefileはC言語などのプロジェクトでビルドをするためのツールです。
ただ前職で最初に関わった社内の受託プロジェクトでタスクランナーとしてMakefileを使っていました。
そこでMakefileへの考え方がビルドツールとしてではなく、タスクランナーとして使うMakefileになりました。

このころは言われたMakefileのコマンドを使うだけでしたが、実際にSESとしてプロジェクトに参画してから関連したプロジェクトにはMakefileを配るということをやりだしていました。

## helpのドキュメント自動生成について

Makefileには大量のコマンドを定義していくことになりますが、コマンドの数が多くなっていくほど各種コマンドの確認は都度Makefileを開いて確認する作業が発生してしまいます。
`help`のタスクを用意して、`echo`コマンドを並べてタスク名を並べるという作戦もありますが、これもタスクが増える度に`help`のタスク修正は面倒になっていきます。
そこでMakefile内に記述したコメントを収集して、`help`コマンド内でドキュメントを作成するという方法があります。

https://postd.cc/auto-documented-makefile/

> 上記の記事より抜粋。

<!-- markdownlint-disable MD010 MD013 -->

```make
.DEFAULT_GOAL := help
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
```

<!-- markdownlint-enable MD010 MD013 -->

ちょっと正規表現が複雑に見えますが、これをMakefileの先頭に置き、以下のようなパターンでタスクを増やしていけば何も困りません。

<!-- markdownlint-disable MD010 MD013 -->

```make
docker-up: ## Docker環境の構築
	@echo "docker compose up -d"

docker-down: ## Docker環境の終了
	@echo "docker compose down"

db-setup: docker-up ## データベースの初期化
	@echo "./scripts/db-setup.sh"

front-setup: ## フロントエンド開発環境初回構築
	@echo "npm install"

front-dev: ## フロントエンド開発のローカルサーバーの起動
	@echo "npm run dev"

init: db-setup front-setup ## 初回限定: フロントとバックの環境構築
```

<!-- markdownlint-enable MD010 MD013 -->

> コピペで試してもらいやすく全て`echo`コマンドにしておきました。

これによってタスクが増えていくことによる「各種タスクに対するドキュメント」が自動で生成することが可能になりました。
「さぁ、これでタスク増やしまくっても一安心」…とはならないんですよね。

### 大量のコマンドに対するグルーピング

## まとめ
