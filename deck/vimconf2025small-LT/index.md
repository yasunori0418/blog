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

<!-- {"layout": "contents_custom", "freeze": true} -->

## pros

### Let's try writing `vim9script`!!

- Syntax from popular languages is being adopted. (see `:h vim9-rationale`)
  - A lambda expression declared like a JavaScript/TypeScript arrow function.
  - Comments starting with `#` and function declarations were adopted to mimic Python.
- Change from dynamic typing to static typing. (see `:h vim9-types`)
  - Strict type specification is required for arguments and return values. (see `:h E1096`)
  - Changes in how variable length arguments are declared.<br>  (see `:h vim9-variable-arguments`)
  - Generics functions can be declared and flexible typing is possible.<br>   (see `:h generic-functions`)

---

<!-- {"layout": "contents_only", "freeze": true} -->

- When continuing a line,<br>a backslash is no longer required at the beginning of the continuation line.<br>   (see `:h vim9-line-continuation`)
  - In addition to arrays and dictionaries, function arguments,<br>method chains using `->` and `.` no longer require continuation.
- All functions are defined script local. (see `:h vim9script`)
  - Functions declared using `export` or `import` can be called from outside.
- Object-oriented programming is now possible with the addition of `class`.
  - Since you can use `abstract class` and `interface class`,<br>you can create various objects.
- Classes and functions can now be compiled,<br>and execution speed can be expected to be improved by 10 to 100 times. (see `:h Vim9-script`)
  - Functions and classes that are called externally can be compiled with `defcompile`.<br>   (see `:h :defcompile`)

---

<!-- {"layout": "contents_custom", "freeze": true} -->

## cons

### But `vim9script` is not perfect either.

- It does not work with Neovim.
  - Neovim official also states that `vim9script` is not supported.<br>   (see `:h Vim9script` in Neovim)
- Can only be used after Vim9 and is not backward compatible.
  - Use the **latest Vim!**
  - **LATEST!!** You can solve everything by using the latest version!!
  - Check with `echo has('vim9script')`!!!
- LSP implementation does not exist.
  - Even if you declare a class,<br>    it's painful because you can't complement the internal methods and properties.
  - If you can input the declared class structure into your brain, in a sense,<br>    does this mean ***awaken to the text editor...?***

---

<!-- {"layout": "contents_custom", "freeze": true} -->

## points to note

### Make sure to also check `:h vim9`

- `vim9script` is a practical but still under **development feature**.
  - `:h vim9class.txt` also includes `To be done later`.
  - `:h :++` also includes `in an expression is not supported yet.`.
  - etc...
- Must be write `vim9script` at first line. (see `:h E1170`)
  - It runs as `vim9script` from the line below where you written `vim9script`.
- Handling of `null_<type>` of each type is special. (see `:h null`)
  - There's a lot of documentation about `null`, so feel free to read it ;-)

---

<!-- {"layout": "contents_only", "freeze": true} -->

- `call` and `eval` are no longer required for function calls. (see `:h E1190`)
  - Using `call` is deprecated.
  - Using `eval` is also deprecated and will result in an error in some situations. (see `:h E1207`)
- Destructive array operations result in an error. (see: `:h E1206`)
  - For functions such as `map` and `filter`,<br>operations that change from the original type will result in an error.
  - Avoid changing the original type using `mapnew` or `copy()->filter()`.
- When using Funcref as an argument in `foreach` etc.,<br>the lambda expression argument cannot be omitted.<br>   (see`:h foreach()`)
  - I was quite distressed by this issue.

---

<!-- {"layout": "section", "freeze": true} -->

## Conclusion

---

<!-- {"layout": "contents_custom", "freeze": true} -->

## conclusion

- `vim9script` is the best configuration element available in the **LATEST Vim!!**
- Read lots of help! (see `:h help`)
- Some parts are still under development!!
- It has its awkward parts, but if you keep using it, **awaken to the text editor...?**
- **Thank you for making the configuration available!!!!**

---

<!-- {"layout": "EOF", "freeze": true} -->
