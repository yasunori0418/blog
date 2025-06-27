# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code) への指針を提供します。

## リポジトリ概要

このリポジトリでは2つのブログプラットフォームを管理しています。

- **個人ブログ** (Hugoベース): https://blog.yasunori0418.com/
- **技術記事** (Zenn): https://zenn.dev/yasunori_kirin

## 開発環境

このプロジェクトは再現可能な開発環境のためにNix Flakesとdevenvを使用しています。

```bash
nix develop  # すべてのツールが含まれた開発シェルに入る
```

## よく使うコマンド

### Hugoブログ用コマンド

```bash
hugo-server                    # Hugo開発サーバーを起動
hugo-new-content <name>        # 新しいHugo記事を作成
cd hugo-blog && hugo           # Hugoサイトをビルド
```

### Zenn用コマンド

```bash
zenn-server                    # Zennプレビューサーバーを起動
cd .. && npx zenn new:article  # 新しいZenn記事を作成 (プロジェクトルートから実行)
```

### テキストリンティング

```bash
npm run textlint              # すべてのコンテンツにtextlintを実行
npm run textlint:fix          # textlintの問題を自動修正
```

### そのほかのコマンド

```bash
list                          # 利用可能なdevenvコマンドをすべて表示
```

## プロジェクト構造

- `/hugo-blog/` - Hugo個人ブログ
  - `/content/post/` - ブログ記事（各記事は独自のディレクトリ内）
  - `/themes/hugo-theme-stack/` - ブログテーマ
  - `hugo.yaml` - Hugo設定ファイル
- `/articles/` - Zenn技術記事（番号付きマークダウンファイル）
- `/books/` - Zenn書籍
- `/images/` - Zenn用画像

## コンテンツ作成

### Hugo記事

1. `hugo-new-content` コマンドを使用するか、`/hugo-blog/content/post/` 内にディレクトリを作成
2. 各記事は `index.md` を含む独自のディレクトリを持つ
3. 画像は記事と同じディレクトリに配置

### Zenn記事

1. `/articles/` 内に番号付きマークダウンファイルを作成（例: `001-title.md`）
2. Zennのfrontmatter形式に従う
3. 画像は `/images/` に配置

## テキスト品質

このプロジェクトは日本語技術文書用プリセットを含むtextlintを使用しています。公開前にすべてのコンテンツがtextlintチェックに合格する必要があります。

- 設定内容：
  - 技術文書ガイドライン (preset-ja-technical-writing)
  - JTFスタイルガイド (preset-jtf-style)
  - 用語の一貫性 (prh)

## deploy

- Hugoブログ: CloudFlare Pagesに自動デプロイ
- Zenn記事: Zennプラットフォームで管理

