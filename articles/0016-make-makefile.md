---
title: 職場のプロジェクトに必ず配置しちゃうMakefileの話
emoji: 🫖
type: tech # tech: 技術記事 / idea: アイデア
topics:
  - lgtechblogsprint
  - makefile
  - awk
  - 正規表現
  - platformengineer
published: true
published_at: 2025-07-07 12:00
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

## makeの各タスクに対するドキュメント自動生成

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

![`make`と`make init`の実行](/images/0016/auto_doc_make.png)

<!-- markdownlint-enable MD010 MD013 -->

> コピペで試してもらいやすく全て`echo`コマンドにしておきました。

これによってタスクが増えても各種タスクに対するドキュメントが自動で生成されるので、どのタスクが何をしてくれるのか把握できるようになりました。
「さぁ、これでタスク増やしまくっても一安心」…とはならないんですよね。

### 大量に定義されたタスクは認知負荷を生み出す

以下に、開発環境に使いそうな大量のタスクを定義したMakefileを用意しました。
とても長いので、ちょっと開いてみて **「なっっが…！」** と思ってもらえれば大丈夫です。

<!-- textlint-disable -->

:::details 大量のタスクが追加されたMakefile
<!-- markdownlint-disable MD010 MD013 MD037 -->
```make
.DEFAULT_GOAL := help
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' \
		| less -R

## 初期設定・環境構築 ##
init: docker-up aws-local-up db-setup backend-setup front-setup ## 初回限定: 全環境の構築
	@echo "echo 'All environments are ready!'"

init-minimal: docker-up db-setup ## 初回限定: 最小構成での環境構築
	@echo "echo 'Minimal environment is ready!'"

backend-setup: ## バックエンド初期設定
	@echo "./gradlew build"
	@echo "./gradlew downloadDependencies"

front-setup: ## フロントエンド開発環境初回構築
	@echo "cd frontend && npm install"
	@echo "cd frontend && npm run build"

install-tools: ## 開発ツールのインストール
	@echo "brew install postgresql redis minio awscli"
	@echo "npm install -g @aws-amplify/cli"

## Docker関連 ##
docker-up: ## Docker環境の構築
	@echo "docker compose up -d"

docker-down: ## Docker環境の終了
	@echo "docker compose down"

docker-restart: docker-down docker-up ## Docker環境の再起動

docker-build: ## Dockerイメージのビルド
	@echo "docker compose build --no-cache"

docker-logs: ## Dockerコンテナのログ表示
	@echo "docker compose logs -f"

docker-ps: ## Dockerコンテナの状態確認
	@echo "docker compose ps"

docker-clean: ## Docker環境の完全クリーンアップ
	@echo "docker compose down -v --rmi all"

docker-exec-db: ## DBコンテナにログイン
	@echo "docker compose exec postgres bash"

docker-exec-redis: ## Redisコンテナにログイン
	@echo "docker compose exec redis bash"

docker-build-app: ## アプリケーションのDockerイメージビルド
	@echo "docker build -t myapp:latest -f Dockerfile ."

docker-build-frontend: ## フロントエンドのDockerイメージビルド
	@echo "docker build -t frontend:latest -f frontend/Dockerfile ./frontend"

## AWS ローカル環境 (LocalStack/MinIO) ##
aws-local-up: ## LocalStackとMinIOの起動
	@echo "docker compose -f docker-compose.aws-local.yml up -d"

aws-local-down: ## LocalStackとMinIOの停止
	@echo "docker compose -f docker-compose.aws-local.yml down"

minio-create-bucket: ## MinIOバケットの作成
	@echo "mc alias set myminio http://localhost:9000 minioadmin minioadmin"
	@echo "mc mb myminio/dev-bucket"

s3-local-ls: ## ローカルS3の内容確認
	@echo "aws --endpoint-url=http://localhost:4566 s3 ls"

s3-local-create-bucket: ## LocalStackでS3バケット作成
	@echo "aws --endpoint-url=http://localhost:4566 s3 mb s3://test-bucket"

dynamodb-local-create-table: ## LocalStackでDynamoDBテーブル作成
	@echo "aws --endpoint-url=http://localhost:4566 dynamodb create-table --cli-input-json file://dynamodb-table.json"

sqs-local-create-queue: ## LocalStackでSQSキュー作成
	@echo "aws --endpoint-url=http://localhost:4566 sqs create-queue --queue-name test-queue"

## フロントエンド (Next.js/TypeScript) ##
front-dev: ## フロントエンド開発サーバーの起動
	@echo "cd frontend && npm run dev"

front-build: ## フロントエンドのビルド
	@echo "cd frontend && npm run build"

front-start: ## フロントエンドの本番サーバー起動
	@echo "cd frontend && npm run start"

front-lint: ## フロントエンドのLint実行
	@echo "cd frontend && npm run lint"

front-lint-fix: ## フロントエンドのLint自動修正
	@echo "cd frontend && npm run lint:fix"

front-type-check: ## TypeScriptの型チェック
	@echo "cd frontend && npm run type-check"

front-test: ## フロントエンドのテスト実行
	@echo "cd frontend && npm run test"

front-test-watch: ## フロントエンドのテスト監視モード
	@echo "cd frontend && npm run test:watch"

front-test-coverage: ## フロントエンドのカバレッジ測定
	@echo "cd frontend && npm run test:coverage"

front-storybook: ## Storybookの起動
	@echo "cd frontend && npm run storybook"

front-build-storybook: ## Storybookのビルド
	@echo "cd frontend && npm run build-storybook"

front-analyze: ## バンドルサイズの分析
	@echo "cd frontend && npm run analyze"

## バックエンド (Kotlin/Spring Boot) ##
backend-dev: ## バックエンド開発サーバーの起動
	@echo "./gradlew bootRun"

backend-dev-debug: ## デバッグモードでバックエンド開発サーバーの起動
	@echo "./gradlew bootRun --debug-jvm"

backend-hot-reload: ## ホットリロード付きでバックエンド開発サーバーの起動
	@echo "./gradlew bootRun -Dspring-boot.run.jvmArguments='-Dspring.devtools.restart.enabled=true'"

backend-prod: ## 本番モードでバックエンド開発サーバーの起動
	@echo "java -jar -Dspring.profiles.active=prod build/libs/myapp.jar"

## ビルド関連 ##
build: ## アプリケーションのビルド
	@echo "./gradlew build"

build-jar: ## JARファイルの作成
	@echo "./gradlew bootJar"

build-all: build front-build ## フロントエンドとバックエンドのビルド

clean: ## ビルド成果物のクリーンアップ
	@echo "./gradlew clean"
	@echo "cd frontend && rm -rf .next out node_modules/.cache"

clean-all: clean cache-clear ## 全てのキャッシュとビルド成果物をクリーン

compile: ## Kotlinコードのコンパイル
	@echo "./gradlew compileKotlin"

compile-test: ## テストコードのコンパイル
	@echo "./gradlew compileTestKotlin"

## データベース関連 ##
db-setup: docker-up ## データベースの初期化
	@echo "sleep 5"
	@echo "./scripts/db-setup.sh"

db-migrate: ## データベースマイグレーションの実行
	@echo "./gradlew flywayMigrate"

db-migrate-clean: ## データベースのクリーンマイグレーション
	@echo "./gradlew flywayClean flywayMigrate"

db-migrate-info: ## マイグレーション状態の確認
	@echo "./gradlew flywayInfo"

db-migrate-validate: ## マイグレーションの検証
	@echo "./gradlew flywayValidate"

db-migrate-repair: ## マイグレーションの修復
	@echo "./gradlew flywayRepair"

db-seed: ## テストデータの投入
	@echo "./gradlew bootRun --args='--spring.profiles.active=seed'"

db-backup: ## データベースのバックアップ
	@echo "pg_dump -h localhost -U myuser mydb > backup_$(date +%Y%m%d_%H%M%S).sql"

db-restore: ## データベースのリストア
	@echo "psql -h localhost -U myuser mydb < backup.sql"

db-reset: db-migrate-clean db-seed ## データベースのリセット（クリーン＋シード）

db-console: ## データベースコンソールの起動
	@echo "psql -h localhost -U myuser mydb"

## テスト関連 ##
test: ## 全テストの実行（バックエンド＋フロントエンド）
	@echo "./gradlew test"
	@echo "cd frontend && npm run test"

test-backend: ## バックエンドテストの実行
	@echo "./gradlew test"

test-unit: ## 単体テストの実行
	@echo "./gradlew test --tests '*UnitTest'"

test-integration: ## 統合テストの実行
	@echo "./gradlew test --tests '*IntegrationTest'"

test-e2e: ## E2Eテストの実行
	@echo "cd frontend && npm run test:e2e"

test-api: ## APIテストの実行
	@echo "./gradlew test --tests '*ApiTest'"

test-coverage: ## テストカバレッジレポートの生成
	@echo "./gradlew jacocoTestReport"
	@echo "cd frontend && npm run test:coverage"

test-watch: ## ファイル変更を監視してテストを自動実行
	@echo "./gradlew test --continuous"

test-report: ## テストレポートを開く
	@echo "open build/reports/tests/test/index.html"
	@echo "open frontend/coverage/lcov-report/index.html"

## 静的解析・フォーマット ##
lint: ## 全体のLint実行
	@echo "./gradlew ktlintCheck"
	@echo "cd frontend && npm run lint"

lint-fix: ## 全体のLint自動修正
	@echo "./gradlew ktlintFormat"
	@echo "cd frontend && npm run lint:fix"

format: ## コードフォーマット
	@echo "./gradlew spotlessApply"
	@echo "cd frontend && npm run format"

format-check: ## コードフォーマットのチェック
	@echo "./gradlew spotlessCheck"
	@echo "cd frontend && npm run format:check"

detekt: ## Detektによるコード品質チェック
	@echo "./gradlew detekt"

sonar: ## SonarQubeによるコード解析
	@echo "./gradlew sonarqube"

## 依存関係管理 ##
deps-update: ## 依存関係の更新チェック
	@echo "./gradlew dependencyUpdates"
	@echo "cd frontend && npm outdated"

deps-tree: ## 依存関係ツリーの表示
	@echo "./gradlew dependencies"
	@echo "cd frontend && npm ls"

deps-refresh: ## 依存関係のリフレッシュ
	@echo "./gradlew --refresh-dependencies"
	@echo "cd frontend && rm -rf node_modules package-lock.json && npm install"

deps-lock: ## 依存関係のロック
	@echo "./gradlew dependencies --write-locks"
	@echo "cd frontend && npm ci"

deps-audit: ## 依存関係のセキュリティ監査
	@echo "./gradlew dependencyCheckAnalyze"
	@echo "cd frontend && npm audit"

## デプロイ関連 ##
deploy-dev: ## 開発環境へのデプロイ
	@echo "./scripts/deploy.sh dev"

deploy-staging: ## ステージング環境へのデプロイ
	@echo "./scripts/deploy.sh staging"

deploy-prod: ## 本番環境へのデプロイ
	@echo "./scripts/deploy.sh prod"

deploy-rollback: ## デプロイのロールバック
	@echo "./scripts/rollback.sh"

deploy-status: ## デプロイステータスの確認
	@echo "./scripts/deploy-status.sh"

## ドキュメント生成 ##
docs-api: ## API仕様書の生成
	@echo "./gradlew generateOpenApiDocs"

docs-kdoc: ## KDocドキュメントの生成
	@echo "./gradlew dokkaHtml"

docs-frontend: ## フロントエンドドキュメントの生成
	@echo "cd frontend && npm run docs:build"

docs-serve: ## ドキュメントサーバーの起動
	@echo "python -m http.server 8080 --directory build/docs"

## ログ・監視関連 ##
logs-app: ## アプリケーションログの確認
	@echo "tail -f logs/application.log"

logs-error: ## エラーログの確認
	@echo "tail -f logs/error.log"

logs-access: ## アクセスログの確認
	@echo "tail -f logs/access.log"

logs-frontend: ## フロントエンドログの確認
	@echo "cd frontend && pm2 logs"

logs-search: ## ログの検索
	@echo "grep -r 'ERROR' logs/"

monitoring-start: ## 監視ツールの起動
	@echo "docker compose -f docker-compose.monitoring.yml up -d"

monitoring-stop: ## 監視ツールの停止
	@echo "docker compose -f docker-compose.monitoring.yml down"

## キャッシュ・クリーンアップ ##
cache-clear: ## アプリケーションキャッシュのクリア
	@echo "redis-cli FLUSHALL"

cache-gradle: ## Gradleキャッシュのクリア
	@echo "rm -rf ~/.gradle/caches/"

cache-npm: ## npmキャッシュのクリア
	@echo "npm cache clean --force"

cache-next: ## Next.jsキャッシュのクリア
	@echo "cd frontend && rm -rf .next/cache"

cache-build: ## ビルドキャッシュのクリア
	@echo "./gradlew cleanBuildCache"

## セキュリティ関連 ##
security-check: ## セキュリティ脆弱性チェック
	@echo "./gradlew dependencyCheckAnalyze"
	@echo "cd frontend && npm audit"

security-update: ## セキュリティアップデートの確認
	@echo "./gradlew dependencyCheckUpdate"

security-fix: ## セキュリティ脆弱性の自動修正
	@echo "cd frontend && npm audit fix"

## パフォーマンス関連 ##
perf-test: ## パフォーマンステストの実行
	@echo "./gradlew gatlingRun"

perf-profile: ## プロファイリングの実行
	@echo "java -agentlib:hprof=cpu=samples,file=cpu.hprof -jar build/libs/myapp.jar"

perf-lighthouse: ## Lighthouseによるフロントエンドパフォーマンス測定
	@echo "cd frontend && npm run lighthouse"

## その他ユーティリティ ##
shell-db: ## データベースシェルの起動
	@echo "psql -h localhost -U myuser mydb"

shell-redis: ## Redisシェルの起動
	@echo "redis-cli"

shell-app: ## アプリケーションコンテナのシェル
	@echo "docker exec -it myapp /bin/bash"

version: ## バージョン情報の表示
	@echo "./gradlew --version"
	@echo "cd frontend && npm --version"
	@echo "cd frontend && node --version"

health-check: ## ヘルスチェック
	@echo "curl http://localhost:8080/actuator/health"
	@echo "curl http://localhost:3000/api/health"

open-app: ## アプリケーションをブラウザで開く
	@echo "open http://localhost:3000"

open-api: ## APIドキュメントをブラウザで開く
	@echo "open http://localhost:8080/swagger-ui.html"

open-storybook: ## Storybookをブラウザで開く
	@echo "open http://localhost:6006"
```

claude codeに「大量にグルーピングしながらタスク作って」とお願いしたらいっぱいタスクを定義してくれました。
ここまで読んでくれた方、本当にありがとうございます。m(_ _;)m
<!-- markdownlint-enable MD010 MD013 MD037 -->
:::
<!-- textlint-enable -->

![とても長いmakeのタスクリスト](/images/0016/many_long_long_make_tasks.png)

長すぎたので、さすがに`less`を使ってページングできるようにしました。
ですが見えている行だけで43行、全体109行。
いささか過剰ではありますが、思うままにタスクを追加していったらこうなる可能性はゼロではありません。
ここまでのタスクがコメント行を使いながらグルーピングされていますが、ページングしながらローカルにモックしているaws環境の操作したいと思ったとき、サッと見つけられるでしょうか？

少なくともプロジェクトに参画したての人は、見つけるのに一苦労するのは確実です。
検索を使ってもらうというのも作戦ではありますが、ドキュメントの目的は次の通りです。

- **そのタスクは何をする物か把握できること**
- **各タスクの関係性が分かりやすい状態になっていること**
- **誰でも理解できる**

現状の大量にタスクと説明が並んでいるだけの状態は、 **「認知負荷が高くなっている」** と言えそうです。

### awkを使って整形

この大量のタスクですが、すでにMakefile内のコメントでグルーピングできています。
タスクの後のコメントをドキュメントとして利用できているので、次はこのグルーピングコメントを有効活用してみましょう。

次の解説で覚えてきた多くの言語に加えて、awk(オーク)も含まれるかもしれません…。

#### まずは既存の`help`タスクを考察(これで正規表現は怖くない！)

すでにawkを使ってコマンド一覧の表示を整形しているので、あらためて`help`タスクの内容を確認してみましょう。
以下に、Makefile内ではなくシェルでも動く状態の`help`タスクのコマンドを展開してみました。

<!-- markdownlint-disable MD010 MD013 MD037 -->

```bash
grep -E '^[a-zA-Z_-]+:.*?## .*$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $1, $2}'
```

<!-- markdownlint-enable MD010 MD013 MD037 -->

**「正規表現が怖い」** そう思ってしまうかもしれませんが、落ち着いて読んでみましょう。
上記のコマンドを分解すると次のように整理できます。

<!-- markdownlint-disable MD038 -->
- `grep -E {ERE} Makefile`: 拡張正規表現を使って、対象のMakefileから絞り込みを行う
  - `^[a-zA-Z_-]+:.*?## .*$`: 基本正規表現なら`^[a-zA-Z_-]\+:.*\?## .*$`。 awkと表現がブレるので、拡張のままの方が良い
    - `^[a-zA-Z_-]+:`: 先頭からすべてのアルファベットの大文字小文字と、`_`と`-`を含む1つ以上連続する文字列の後に`:`とマッチ
      - タスク名にマッチ(例: `help:`, `docker-up:`, `Backend_Dev:`)
    - `.*?## .*$`: `:`の後に任意の文字列が0個以上連続したあと、`## `のあとに任意の文字列が0個以上行末まで連続
      - タスク名の後に依存するタスク名の列挙と、`## `から始まるコメントのある行にマッチ
      - タスク名の後に依存タスクが存在せず、`## `で始まるコメントのある行にもマッチ
- `awk`: grepによる絞り込み結果を`awk`で加工
  - `BEGIN {FS = ":.*?## "};`: FS(Field Separator)として`:.*?## `という正規表現のパターンを定義
  - `{printf "\033[36m%-30s\033[0m %s\n", $1, $2}`: タスク名の文字列をエスケープシーケンスでシアン色にしつつ、左寄せ30文字の後に`## `以降のコメントと改行し標準出力
    - FSに正規表現(`:.*?## `)を定義しているため、タスク名が`$1`になり、コメントが`$2`となる
<!-- markdownlint-disable MD037 -->

いかがでしょうか？
これで複雑そうに見える正規表現も怖くないですね。
Makefile上に記述するとき、`$`は`$$`に置き換えておきましょう。

ちなみに、こういう正規表現がマッチするかの確認に、`vim`で`set hlsearch`の状態で正規表現を書いてみるのが分かりやすかったりします。
vim正規表現なら「`\v^[a-zA-Z_-]+:.{-}## .*$`」こんな感じですね。

#### グルーピングしているコメントを良い感じにする

もう複雑な正規表現の話は出てきません。
前述した長いMakefileを見ていると、定期的に`## .* ##`のパターンでコメント行があるはずです。
タスク名にマッチしている行と、このコメントの行にマッチした物をawkに渡すことができれば解決できます。

grepで複数のパターンでマッチしたい場合は、`-e`オプションの後に正規表現を書いてあげれば良いです。
また、awkで特定パターンのときに処理を分けたい場合は、次のように記述できます。

```awk
/^regex pattern$/ {
  print $1, $2
}
```

とはいえ、ワンライナーで2つの処理と正規表現を書くことになるのか…と思ってしまいます。
ここまで来るとMakefile内でワンライナーを書いていくのはさすがにつらいですね。

そんなときはawkをスクリプトにして、呼び出せるようにしましょう。

https://github.com/yasunori0418/dotfiles/blob/a9cdd61e/scripts/help.awk

また、`help.awk`内では見た目の変更が用意になるように、使いそうなエスケープシーケンスを`BEGIN`の段階で変数に入れて抽象化しています。
これでエスケープシーケンスでも遊べるようにもなりました！

ちなみに私は、以下のようにスクリプト形式のawkをMakefileで呼び出しています。

https://github.com/yasunori0418/dotfiles/blob/a9cdd61e/Makefile#L10-L12

先程の大量にタスク定義されたMakefileに、このawkスクリプトを適用してみましょう。

<!-- markdownlint-disable MD010 MD013 MD037 -->
```make
help:
	@grep -E -e '^[a-zA-Z_-]+:.*?## .*$$' -e '^## .* ##$$' $(MAKEFILE_LIST) \
		| ./help.awk | less -R
```
<!-- markdownlint-enable MD010 MD013 MD037 -->

![読みやすくなった`make help`](/images/0016/readable-make-help.png)

なんということでしょう！
先程の大量に列挙されていたタスク名と説明だけの時より、各タスクの役割が明確になりました！
Makefile上の`help`の定義もawkの式をスクリプトに変えたため、多少すっきりしているようにも見えます。

この状態は、ドキュメントとしても整理できて、大量のタスクがあっても **「認知負荷が低くなっている」** と言えそうな気がします。

## これってPlatform Engineeringなのでは…？

Makefileで開発に便利なツールを呼び出しやすくするのはとても好きで、開発ツールを整理したくなったらぜひ使ってみてください。
このツールの整理やドキュメント生成を整備するのは、Platform Engineeringと言えそうな気がしているので、今回の内容とチーム開発の話を織り交ぜたプロポーザルを出しています！

https://fortee.jp/platform-engineering-kaigi-2025/proposal/646d39f9-c90d-4070-ba81-f00dba7f4a45

プロダクトがスケールしていくと、開発環境に必要な物やツールは複数必要になり、開発に走り出すだけでもコストが発生します。
私はチーム開発していく中で、こういった開発に必要なツールの準備や整備するのが好きになっています。
このプロポーザルが採択されたら、そういった背景の部分も話したいと思っています。

## 最後に

開発環境の整備をしていくのが大好きで、会社に入って最初にMakefileによるツールの呼び出しやドキュメントの整備するPRを作成しました。
こういう改善をやると開発チームのSlackチャンネルでは、「これはアプノマ(Update Normal)だ！」と言ってもらえる素敵な環境です。
タスクとは別に「改善に積極的な文化って素敵だなぁ」って思いながら最初のPRがマージされました。

もしログラスに興味を持っていただけたら、以下のリンクからカジュアル面談もセットできるので、気になった方がいらっしゃれば連絡をお待ちしています！

https://pitta.me/matches/dlarsRnSEDwx
