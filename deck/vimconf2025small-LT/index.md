---
presentationID: 1j5LBMOnUlNFhtVfyOmEYsyM4G8Xkjvk5Eloti9AnhjU
---

<!-- textlint-disable -->

<!-- {"layout": "front_cover_custom", "freeze": true} -->

# Tried writing it `vim9script`

## pros&cons, points to note.

---

<!-- {"layout": "head_title", "freeze": true} -->

## self-intro

```yaml
name: yasunori
company: Loglass Inc.
likes:
  - Linux
  - Vim/Neovim
  - dotfiles
links:
  - https://github.com/yasunori0418
  - https://blog.yasunori0418.dev
  - https://x.com/YKirin0418
memo: |
  Always, everyday, everyone, a memorial year of linux desktop!!
  And my dotfiles 5500commit over!!
```

![icon](https://github.com/yasunori0418.png)

---

<!-- {"layout": "section", "freeze": true} -->

## Motivation

---

<!-- {"layout": "2column_contents_custom", "freeze": true} -->

## motivation

### Why writing `vim9script`

- The Neovim I use daily is fairly customized.
- I want to customize the original Vim for minimalist use.
  - skkeleton only <br>for VIME(Vim Input Method Editor)
  - other temporary use etc...
- `vim9script` is apparently <br>faster than `vim script`.
- I wanted to configure `dpp.vim` <br>with `vim9script`

### BTW, <br>dpp is "Dark Powered Plugin manager".<br>And to use dpp.vim.

- `denops.vim` is required
- Building a minimal plugin manager
  - Plugin download
  - Add plugin path to `runtimepath`
- Multiple autocmd declarations
- ***other a lot of configuration...***
  - TypeScript
  - vimrc in Vim or Neovim

---

<!-- {"layout": "center", "freeze": true} -->

## Because,<br><br>Just For Fun!!

---

<!-- {"layout": "center", "freeze": true} -->

## And...

---

<!-- {"layout": "center", "freeze": true} -->

## Thank you for making <br>                  the configuration available!

---

<!-- {"layout": "section", "freeze": true} -->

## pros, cons, and points to note of `vim9script`<br>when compared to `vim script`.

---

<!-- {"layout": "contents_custom", "freeze": false} -->

## pros

### Let's try writing `vim9script`!!

---

<!-- {"layout": "contents_custom", "freeze": false} -->

## cons

### But `vim9script` is not perfect either.

---

<!-- {"layout": "contents_custom", "freeze": false} -->

## points to note

### Make sure to also check `:h vim9`

- Must be write `vim9script` at first line
  - It runs as `vim9script` from the line below where you written `vim9script`.

---
