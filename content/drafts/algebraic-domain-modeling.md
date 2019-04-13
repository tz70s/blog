+++
title = "Note on Algebraic Domain Modeling"
date = "2019-02-18"
slug = "algebraic-domain-modeling" 
tags = []
categories = []
+++

<script type="text/javascript" async
  src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/latest.js?config=TeX-MML-AM_CHTML">
</script>

# Algebra?

Algebraic 這個詞以中譯來講就是"代數(的)"，以前一直沒有認真理解這個形容詞帶給 application/business level 的關聯性以及跟一些 functional programming 裡設計的連貫性，
直到最近看了幾篇文章 [1][2] 和 haskell from the first principle 有點感悟所以在這紀錄一下。

先從 ADT (algebraic data type) 開始，現在一些新興語言 (Rust, Kotlin, Swift) 都有將 ADT 內建在 language 中，很大原因都是為了導入 Option, Result (rust) 這些類型來解決工業上的痛點。
然而，ADT 除了與 ADT (abstract data type) 不同、可以搭配 pattern matching 以外，到底代表什麼？

Abstract algebra (抽象代數)，是在 generalize 一些代數上的數學關係，例如我們常見的數值運算 (1 + 1)，只是用符號來研讀而已，這在離散數學後面的章節有教裡面的一些部分。
而我們在這會看到的就是 algebraic structure，來看一下 wiki 上的定義：

> In mathematics, and more specifically in abstract algebra, an algebraic structure on a set A (called carrier set or underlying set) is a collection of finitary operations on A; the set A with this structure is also called an algebra.

下一段：

> Examples of algebraic structures include groups, rings, fields, and lattices. More complex structures can be defined by introducing multiple operations, different underlying sets, or by altering the defining axioms. Examples of more complex algebraic structures include vector spaces, modules, and algebras.

另外照 [1] 的方式解讀：An algebraic structure consists of:

* One or more sets.
* A set of operations.
* A collection of axioms (which the operators are required to satisfy)

舉最簡單的 Group (更嚴格的 Monoid / Semigroup):

$$ denote \ a \ set \ and \ operator \ as \ (G, \circ)$$
$$ closure : \forall a, b \in G \Rightarrow a \circ b \in G$$
$$ associativity : \forall a, b, c\in G \Rightarrow a \circ (b \circ c) = (a \circ b) \circ c $$
$$ identity: \exists e \in G : \forall a \in G \Rightarrow e \circ a = a = a \circ e $$
$$ inverse: \forall a \in G : \exists b \in G \Rightarrow a \circ b = e = b \circ a $$

例如一個例子是，整數 (Set) 和加法 (+) 就是一個 Group：

* Closure: 1 + 1 = 2 ∈ G
* Associativity: 1 + (2 + 3) = (1 + 2) + 3
* Identity: 1 + 0 = 1 = 0 + 1
* Inverse: 1 + (-1) = 0 = (-1) + 1

Ok，這件事情的意義的存在會進階影響很多個層次，以我們專注在 programming 的角度來講，定義一系列的這些代數結構可以讓我們用數學來解讀 programming 或是真實世界的現象。
例如：associative 讓我們在做 composition (monoidal) 的彈性，
commutative property 在 concurrent / distributed system 裡非常重要 (i.e. CRDT [3])，還有像 lattice [4]。

> 回過來看 ADT，所以我們常聽到的所謂 sum type, product type [5] 其實本質上就是在描述**集合 (set)**，而 operator 則是利用 **typeclass (ad-hoc polymorphism) or trait (subtype or ad-hoc polymorphism)** 來去定義的！

例如以下：

```haskell
-- An infinite set on a + a Nothing element.
-- { Nothing, Just 1, Just 2, ... }
data Maybe a
  = Just a
  | Nothing
  deriving (Eq, Show)

-- As you wish, a '<>' operator.
instance Semigroup a => Semigroup (Maybe a) where
  (<>) Nothing b = b
  (<>) a Nothing = a
  (<>) (Just a) (Just b) = Just (a <> b)

-- Then, we can proof the correctness on whether it's satisfied law/axiom.
```

換位思考一下，在 domain modeling 時，我們同樣會有 entity / value object (type) 及行為 (operators) [1][2]，所以我們也可以自己定義要遵守的 axiom!
這就是 algebraic design 的本質。

引述[一段話](http://dev.stephendiehl.com/hask/#eightfold-path-to-monad-satori)：

> The only path to understanding monads is to read the fine source, fire up GHC, and write some code. Analogies and metaphors will not lead to understanding.

類比對這邊說實話沒什麼幫助，我建議可以從 algebraic structure 了解一下來去思考一下這些帶來的意義是什麼。(例如：我不喜歡有些文章會類比 interface 來描述 algebraic design)

# Prove Your Laws!

先來個定義：

> Property tests test the formal properties of programs without requiring formal proofs by 
allowing you to express a truth-valued, universally quantified (that is, will apply to all cases) function.

換言之，property tests 就是讓你去驗證你的公式 (total function)，基於隨機暴力的方法來取代 formal proof。

Property(-based) testing 的大老爸 Haskell 裡最常用的就是 QuickCheck:

```haskell
> :t quickCheck
quickCheck :: Testable prop => prop -> IO ()
```

# Reference

1. https://typelevel.org/blog/2019/02/06/algebraic-api-design.html
2. https://www.youtube.com/watch?v=BskNvfNjU_8
3. https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type
4. N. Conway, W. R. Marczak, P. Alvaro, J. M. Hellerstein, and D. Maier, “Logic and lattices for distributed programming,” in Proceedings of the Third ACM Symposium on Cloud Computing - SoCC ’12, 2012.
5. https://en.wikipedia.org/wiki/Algebraic_data_type 