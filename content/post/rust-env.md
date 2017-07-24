---
title: "Rust 環境建置"
date: 2017-07-05T19:38:22+08:00
draft: false
---

最近在學 Rust (蛋疼)，所以把這個開發環境建置紀錄一下。

首先是用 Visual Studio Code ，這編輯器有多好用就 bj4 了(雖然我打這個 post 是用 vim)。

### Rust 安裝

適用 Linux & Mac OSX
```bash
$ curl https://sh.rustup.rs -sSf | sh
```

### Rustup
Rust 編譯器目前有分成三種版本
1. Stable
2. Beta
3. Nightly (Experimental)

而 Rustup 是用來切換編譯器的。

### RLS
VScode 現在有在推行一個叫 Programming Language Server 的東西，主要是把程式語言的處理掛在後端，這樣就可以讓前端(編輯器用接口達到多個支援了)。
而 RLS 就是這樣的一個 Server 。

VScode 可以用套件安裝。

### Racer

racer 是 auto-complete 的核心
```bash
$ cargo install racer
```

把 source code 撈下來
```bash
$ rustup component add rust-src
```

現在已經會自動環境變數了，但還是可以加一下(看系統可以加入`.bashrc` or `.bash_profile`)。
```bash
$ export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
```

這樣基本上就可以達到 auto-complete 了。

### Other tools

基本上現在好像都自帶了。
有個 clippy (linter) 我裝不起來，主要是他不是用在目前 stable release (可能是 nightly)，所以果斷放棄。
想試的可以切換到 nightly 再 install。

```bash
$ cargo install clippy
```
