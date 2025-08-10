---
title: node2nixが謎に失敗するので直した
slug: fix-node2nix-build
date: 2025-08-11T01:54:00+09:00
publishDate: 2025-08-11T01:54:00+09:00
draft: false
isCJKLnaguage: true
categories:
  - Tech
tags:
  - nix
---

## 始めに

たけてぃが書いた[node2nixの使い方](https://www.takeokunn.org/posts/fleeting/20250622133346-how_to_use_node2nix/)を参考に、claude-codeやccusageをnode2nixで管理するようにしていた。\
理由としては、更新頻度が高かったりしていて、nixpkgsのレビューとマージのスピードに追い付かないことがままある。\
個人でパッケージのバージョン管理を楽にするためnode2nixを使っている。

最近の仕事が落ち着いたこともあって、久々に`flake.lock`の更新をしたらなぜかnode2nixでインストールしているパッケージのビルドが失敗してしまった。\
ただ、アレコレ見ていたら原因が分かったので、とりあえずメモを残しておく。

## 結論

この[9c851d25](https://github.com/yasunori0418/dotfiles/commit/9c851d258101b802571fb6f1e8775fd21e5dff0f)というコミットで解決した。

方法としては、以下の通りだ。

```diff
-  nodePkgsBuilder = pkgs: pkgs.callPackages ../node2nix { inherit pkgs; };
+  nodePkgsBuilder = pkgs: pkgs.callPackages ../node2nix {
+    inherit pkgs system;
+    nodejs = pkgs.nodejs_24;
+  };
```

雑ではあるが、`pkgs.callPackages`でnode2nixのファイルを読み込む際に、引数のAttrSetに`nodejs`を明示してあげれば良い。

## 問題解決までの流れ

### エラー内容の把握

```text
ccusage> /build/.attr-15dhb26v5nfdpwqlxzm6hnavmmp7kcjb3jivxnf2y23z897fryb3: line 4: node: command not found
```

まず上記のエラーが発生していて、どういう訳かnodeコマンドがビルド中に存在しないと言っている。

これまで発生していない現象のため、とりあえずビルドしている部分を追ってみた。

### `node-packages.nix`の内容を確認

https://github.com/yasunori0418/dotfiles/blob/9c851d258101b802571fb6f1e8775fd21e5dff0f/node2nix/node-packages.nix

とりあえず怪しんだのは、`buildInputs`に指定している`globalBuildInputs`だ。\
ファイル冒頭の引数の宣言は以下のようになっている。

```nix
  globalBuildInputs ? [ ],
```

これは`globalBuildInputs`という引数が渡されなければ、空の配列になるという物だ。\
では、この`globalBuildInputs`がどのように渡されているかを確認するため、callPackagesしている`default.nix`を読んでみた。

### `default.nix`の内容を確認

https://github.com/yasunori0418/dotfiles/blob/9c851d258101b802571fb6f1e8775fd21e5dff0f/node2nix/default.nix

ぱっと見た限りでは、`globalBuildInputs`は存在しない。\
ただ、`default.nix`という関数を読む限り、8行目に`nodejs_14`を指定しているので、これをcallPackagesのタイミングで正しく渡して上げれば解決できそうと判断した。

その後、結論に書いたコミットで実際にnix-rebuildを実施したところ、問題なくビルドに成功した。

## まとめと根本原因の解明

原因解決してから、とりあえずこの文章を書きながら、作業内容を雑に書き出してみた。

書きながら、最終的になぜ失敗するか判明した。

原因としては、`nodejs_1(4|6)`がnixpkgsで管理されなくなったことによる失敗であった。
対応するPRは以下の通り。

https://github.com/NixOS/nixpkgs/pull/264358

とりあえず安定版ではないnixpkgsを使用している場合、node2nixを使用するときは、nodejsの明示的な宣言が必要だ。
