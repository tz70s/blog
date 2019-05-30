+++
title = "Play LLVM with Haskell"
date = "2019-05-29"
slug = "play-llvm-with-haskell" 
tags = []
categories = []
+++

最近玩了一下 Haskell 的 LLVM binding，對照著這強烈推薦精美的 [Post](http://www.stephendiehl.com/llvm/) 來實作，
覺得蠻有趣。只不過雖然這篇文章寫的精巧又完整，但內容有點過時，例如類型錯誤、以及使用低抽象的 binding APIs，所以我大致紀錄一下我修改過的版本。

# Setup

我使用的 Haskell 版本是 GHC 8.6.5，然後 LLVM 的相依我是直接用 Homebrew 裝，
雖然我本身已經有用 Homebrew 裝 LLVM 了，但 llvm-hs 有提供一個加版本號的 formula，自動幫你 build dynamic library，
適用懶人也沒遇到什麼衝突的問題。但這有一個問題就是有點過肥，所以最好還是乖乖改一下 formula 或是自己 cmake build 一下。可以參考一下[完整的指令](https://github.com/llvm-hs/llvm-hs#installing-llvm)。

剩下就是把 dependency 拉一拉：

#### stack.yaml
```yaml
extra-deps:
- llvm-hs-8.0.0
- llvm-hs-pure-8.0.0
```

#### *.cabal
```
build-depends: base >= 4.7 && < 5
             , llvm-hs
             , llvm-hs-pure
             , ...
```

完整可以參考[這裡](https://github.com/tz70s/hsllvm)。

# Kaleidoscope

Kaleidoscope 是 LLVM Tutorial 的語言，有各種版本，那我的實作也是用這個來實驗，主要前端是用 Parsec 嚕的，
這相對找得到資源，所以我就不贅述了，可以直接參考這些文章：[Post](http://www.stephendiehl.com/llvm/), [Write You a Haskell](http://dev.stephendiehl.com/fun/002_parsers.html) 以及其他我沒看過的 [link](https://github.com/haskell/parsec)。

所以我們直接從 AST 開始看：我有延伸一些類型，讓 evaluation 會稍微有趣一點，但也沒有差太多。
Root 是在 Expr，往下有 literal expression, variable expression, binary expression, call expression 和 statement (Stmt)。Stmt 理則是 function definition 和 extern。
大致差不多，可以看一下原文對照一下。

```haskell
module Syntax (..) where

type Name = String

-- | Root of AST.
data Expr
  = LitExpr Literal
  | Var Name
  | BinExpr Op Expr Expr
  | Call Name [Expr]
  | Statement Stmt
  deriving (Eq, Ord, Show)

data Stmt = Function Name [Expr] Expr | Extern Name [Expr] deriving (Eq, Ord, Show)

data Literal = IntL Integer | DoubleL Double | StringL String deriving (Eq, Ord, Show)

data Op = Plus | Minus | Mult | Divide deriving (Eq, Ord, Show)
```

接下來就直接切入正題。

# LLVM

