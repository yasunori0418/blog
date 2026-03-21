RULE_REGEX := ^[a-zA-Z_][a-zA-Z0-9_-]+:
RULE_AND_DESC_REGEX := $(RULE_REGEX).*?## .*$$
EXTRA_COMMENT_REGEX := ^## .* ##$$
.ONESHELL:
.DEFAULT_GOAL := help
.PHONY: all test clean
.PHONY: $(shell grep -E $(RULE_REGEX) $(MAKEFILE_LIST) | cut -d: -f1)

REPO_ROOT := $(CURDIR)

# INFO: 参考サイト - https://postd.cc/auto-documented-makefile/
help: ## subcommand list and description.
	@grep -E -e $(RULE_AND_DESC_REGEX) -e $(EXTRA_COMMENT_REGEX) $(MAKEFILE_LIST) \
	| ./scripts/help.awk | less -R

help-fzf: ## Search for fzf and run the target rule
	@grep -E -e $(RULE_AND_DESC_REGEX) $(MAKEFILE_LIST) \
	| ./scripts/help.awk \
	| fzf --ansi \
	| cut -d ' ' -f1 \
	| xargs -I{} make {}

## Hugo Blog ##
hugo-server: ## Hugo開発サーバーを起動
	cd $(REPO_ROOT)/hugo-blog && hugo server --buildFuture --buildDrafts

hugo-new-content: ## 新しいHugo記事を作成 (使い方: make hugo-new-content name=<記事名>)
	cd $(REPO_ROOT)/hugo-blog && hugo new content content/post/$(name)/index.md

## Zenn ##
zenn: ## Zennプレビューサーバーを起動
	cd $(REPO_ROOT) && zenn preview

## Text Linting ##
textlint: ## textlintをすべてのコンテンツに実行
	npm run textlint

textlint-fix: ## textlintの問題を自動修正
	npm run textlint:fix

## Utility ##
credential4deck: ## k1Low/deckで使用するGoogleCloudのcredentials.jsonをダウンロード
	declare -r deck_data="$$HOME/.local/share/deck"
	mkdir -p $$HOME/.local/share/deck
	op item list \
	| rg 'k1Low-deck\/credentials\.json' \
	| cut -d ' ' -f1 \
	| xargs -I{} op item get {} --format json \
	| jq -r '"op://\(.vault.name)/\(.id)/\(.files[0].name)"' \
	| xargs -I{} op read --out-file $$deck_data/credentials.json {}

laminate-cache-clean: ## laminateのキャッシュを削除
	rm -rf ~/.cache/laminate/cache/*
