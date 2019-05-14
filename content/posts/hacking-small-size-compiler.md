+++
title = "Hacking a Small Size OSS Compiler"
date = "2019-05-14"
slug = "hacking-small-size-oss-compiler" 
tags = []
categories = []
+++

Compiler is a well-known complex software to build, 
but also plays a significant role on computer science history
and attracts many programmers to explore the mystery.
Both of theory foundation and engineering of compiler construction
is hard, and I'm not an expert (even not a _compiler engineer_) at all.
However, in this post, I would like to show my experience to
hacking **PureScript** compiler.

Strictly speaking, this is a transpiler instead of machine code generation.
We're almost talking about the **frontend** of compiler, 
including _lexical analysis_, _parsing_, _semantic analysis (scope, type checking)_
and a relative simple, one pass code generation to Javascript.

Some **pre-requisition** might be needed here:

* Ability to read (and write) Haskell (in Haskell Programming from First Principle or Real World Haskell level.)
* Maybe some undergraduate level compiler knowledge (i.e. regular expression, context free grammar, abstract syntax tree and simple code generation).

Note that you don't actually needs to know every theory foundation
in dragon book or others.
But theory makes you more confident to correctly construct compiler though.

I would recommend [Crafting Interpreters](http://craftinginterpreters.com), [Stanford CS143](http://web.stanford.edu/class/cs143/index2018.html) and [Engineering a Compiler](https://www.amazon.com/Engineering-Compiler-Keith-Cooper/dp/012088478X).

For some advanced knowledge, I'll link them when we reach out.

# PureScript

PureScript is a language transpiled into Javascript for web frontend (almost) programming.
The syntax is similar to Haskell as well as the powerful type system,
including typeclasses, higher kinded types, higher rank polymorphism, 
and row polymorphism and extensible records, etc.
At the first glance, it wires up rich features here,
however, the purescript compiler is well engineered and relative **small**!
(You can compare to GHC as well as Haskell-based compiler.)

```bash
git clone https://github.com/purescript/purescript.git
cd purescript
loc .

--------------------------------------------------------------------------------
 Language             Files        Lines        Blank      Comment         Code
--------------------------------------------------------------------------------
 Haskell                206        41216         5007         5744        30465
 PureScript             707         9229         2572          497         6160
 Markdown                 8         1077          224            0          853
 JSON                    12          829            0            0          829
 CSS                      2         1142           85          278          779
 Yacc                     1          746          113            0          633
 Less                     1          875          160          111          604
 YAML                     2          193            6            1          186
 JavaScript              10          133            8            9          116
 Bourne Shell             5          177           38           40           99
 Plain Text               2           42            7            0           35
 Makefile                 1           59           15           11           33
 HTML                     1           10            0            0           10
 Batch                    1            3            0            0            3
--------------------------------------------------------------------------------
 Total                  959        55731         8235         6691        40805
--------------------------------------------------------------------------------

# The nested main source of compiler.
cd src
loc .

--------------------------------------------------------------------------------
 Language             Files        Lines        Blank      Comment         Code
--------------------------------------------------------------------------------
 Haskell                167        35737         4334         5381        26022
 Yacc                     1          746          113            0          633
--------------------------------------------------------------------------------
 Total                  168        36483         4447         5381        26655
--------------------------------------------------------------------------------
```

I won't go through the usage and syntax on PureScript, 
but you can easily go through it by the really awesome [document](https://leanpub.com/purescript/read).

# Structure of PureScript Compiler

To build up purescript compiler, all you need is `stack` and it's well engineered to setup all things easily.

```
git clone https://github.com/purescript/purescript.git
cd purescript

# Build project.
make build
# Or stack build.

# Run the compiler executable.
make run
# Or stack exec purs
```

The important directory in the main repository:

* **app**: main entry point of purescript compiler.
* **src**: the core compiler code.
* **tests**: unit and integration tests.

You can also dive into the makefile for common utilities for faster development (i.e. ghcid).
