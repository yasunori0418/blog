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

## helpの自己ドキュメント生成について

https://postd.cc/auto-documented-makefile/

## まとめ
