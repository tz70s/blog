+++
title = "Reactive Programming - Revisiting Abstraction"
date = "2019-02-12"
slug = "reactive-programming" 
tags = []
categories = []
+++

<script type="text/javascript" async
  src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/latest.js?config=TeX-MML-AM_CHTML">
</script>

Reactive Programming 在現代基於事件驅動程式設計及架構來講，根本上來講以去除副作用 (side-effect) 的 declarative 方式來建構事件的轉換及組合，可以有效降低在 concurrency 下的錯誤和增強組合性 (composability)。這衍伸在工業界如 ReactiveX (RxJava, RxJS, etc)、Reactive Stream Specification 或是如 Future 的建構都有其**影子**。

然而，他的定義從各個出處仍十分模糊且難以讓人理解，例如：

1. Reactive Programming is a programming with asynchronous data stream. [1]
2. Reactive programming is a declarative programming paradigm concerned with data streams and the propagation of change. [2]
3. Reactive programming is a programming paradigm that is built around the notion of continuous time-varying values and propagation of change. [3]

在加上網路上基於各種**感悟**和**體會**的文章衍伸的不嚴謹考究，讓 Reactive Programming 逐漸成為 buzzword。

除了定義以外，他的多種建構模型也會同樣的讓人困惑：`Observable`, `Var`, `Signal`, `Behavior`?

這篇文章重新檢視一下這些概念，整理一下幾篇不同但具代表性的文獻而來的資料，並區別且歸類各處的定義 [3][4][5]。最後，示意一段實現 Reactive Programming 的 prototype。

[3] 是 reactive programming 中最為重量級的 survey，涵蓋更全面於本篇內容 (包含六個 dimension 的探討)，但礙於篇幅，survey paper 的讀者對於特定建構往往很難有深刻的體會。然而，這六個 dimension 可以帶出本篇所要探討的內容：

* Basic Abstraction: 在 reactive programming 中基礎的抽象。
* Evaluation Model: reactive programming 執行的模型。
* Glitch Avoidance: 於更新傳遞時所造成的不一致性。
* Lifting Operations: 將 computation 轉移為抽象 context。
* Multidirectional: 單向或多向的更新。
* Distributed reactive：於分散式系統內的行為。

在本篇所關注的僅為 Basic Abstraction 和 Lifting Operations 的精確定義和組合方法來區別較為模糊的 reactive programming 名詞。

如這個 [talk](https://begriffs.com/posts/2016-07-27-tikhon-on-frp.html) 所講的，以下會依照兩種面向來談：

1. Specification (concise definition)
2. Why it is interesting (motivation/use cases)

Disclaimer: 我不敢保證精準且無誤的解釋，因此警告一下誤觸本篇的讀者請再三思考或透過本文列的相關文獻進行參考，有任何想法歡迎且希望能透過我的 email <su3g4284zo6y7@gmail.com> 來更正及指教。

## Recap - Why Reactive Programming? (Influence on Modern Software Development)

現代的應用趨於互動性 (interactive) 的型態，由應用內部或外在環境所產生的事件去觸發處理邏輯。因此，這些事件驅動的應用會維持著連續性的與環境互動、處理事件和作出相應的工作如狀態更新等。最常見的如 GUI 應用等等。

傳統在處理事件驅動的模型，往往以異步的 callbacks (event handler) 來實現，最常見如 Javascript 就是標準的模型，這會衍伸出數項問題：

1. Side-effects: callbacks 沒有 return value，所以必須依靠 side-effect 來協同，會造成很多 concurrency 上的開發負擔以及破壞 encapsulation。
2. Unpredictable and uncontrollable event ordering: 程式的控制是以 Inversion-of-Control 的模式建構，開發者在模型上沒有定義事件順序的表達能力，僅能依靠額外基於副作用的狀態管理來處理。
3. Composability: callbacks 沒有 return value，在相依執行的情境只能嵌套執行進而發生 callback hell。

Reactive Programming 其實發展亦很早 (1997?)，只是近年逐漸受到重視，因為可以解決基於 callback 所建構的事件驅動模型帶來的問題：

1. 提供抽象來表達對於事件的反應。
2. 自動的管理時間、資料和計算的相依性。
3. 基於 synchronous dataflow programming model.

例如如下示例：

```
var1 = 1
var2 = 2
var3 = var1 + var2
```

在 general programming language 來講，var3 即便 var1 改變了仍會一直是 3 的值；而在 reactive programming 來說，var1 或 var2 的更新會觸發 recalculation，使得 var3 也隨之更新，i.e. $$var1 \leftarrow 2 \Rightarrow var3 = 4$$

這邊可以看出狀態的改變會自動地傳播到計算所構成的網路 (network of dependent computations)。

第一次聽到應該會覺得非常抽象，這邊也沒有很精確的定義，更精確的定義需要有相應的模型和 feature 分類來佐證，這邊要闡述的點在於 Reactive Programming 對於現代事件驅動架構 (Event-first Microservice, IoT applications, etc) 的好處：**開發者不用手動處理事件及計算的順序和相依性，提高組合性與降低副作用所帶來的問題**。這也是為什麼 ReactiveX 或其他 Reactive Programming Library 在 web frontend、android 乃至於 web backend 都逐漸受到歡迎。

但這邊需要記住一件事：這是 Reactive Programming 的**好處**，而不是原始設計的 **Motivation**，所以這邊無法給出精確的定義。

Ok，那這樣的結構中，我們要怎麼表示 `var`? 這就是 **Basic Abstraction** 的部分，那要怎麼表示 `+`? 這就是 **Lifting Operations** 的部分。

# Basic Abstraction

所有 reactive programming 都是由 [4] 所發展而來的變形，以前述 6 個 dimension 上會有不同的變化，並且詮釋到 programming language 或是 framework 上; 但最基礎的抽象不外乎下列兩種：

1. Behaviors: 為隨著**連續**時間所變化的值 (continuous time-varying value) 的抽象。這最根本的抽象動機是在於 reactive programming [4] 最早的出發點是在於做 animation 或是 robotics，較為關注連續時間(仿類比)的訊號處理。
2. Events: 為 streams of value changes 的抽象，相對於 Behaviors 為離散的時間點。換言之，這也是於現代更常用到的事件驅動架構下的抽象。

這兩項抽象分別對應到了 [2][3] 上所定義的 continuous time-varying 和 data stream。

但是，**Time** 這個抽象扮演了 reactive programming 中許多不一致的抽象區別 [6]。

## C1 - Functional Reactive Animation 

Reactive Programming 的根源即是從此篇論文，Fran 所延展而來的，如前面所說的，Fran 的目的在於降低 programming in animation 所需要的 boilerplate，包含：

1. 手動 framing (基於離散時間)，即便 animation 是 conceptual continuous 的。
2. 手動捕捉和處理序列的動作輸入 (motion input) 事件。
3. 手動切割時間並且更新每個隨時間變化的參數。

有鑑於此，Fran 認為如果能自動化 **how** of its representation (presentation)，讓使用者專注於 **what** of an interactive animation (modeling)，會是很大的貢獻。進而產生四項對應用的好處：(a) Authoring: programmer 不用專精於底層的 presentation detail，使之可以更有創造力；(b) Optimizability: model-based 所建構的高層資訊可以使得底層 presentation 有 optimization 的機會；(c) Regulation: 一致性的抽象層次管理；(d) Mobility and safety: model-based 可以是 platform independence 的。

Fran 結構了基本的抽象如下 (semantic function)：

$$at: Behavior_a \to Time \to a$$
$$occ: Event_a \to [\ Time \times a\ ]$$

以 Haskell 表達即為:

```haskell
type Behavior a = Time -> a
type Event a = [(Time, a)]
```

所以簡單來說，Behavior 就是一個 function of time 並吐出一個值，而 event 是一個 list of time/value pairs 來表達 occurrences。
Time 在原本論文中有一些嚴格定義的數學 property (i.e. lower bound, partial/total ordering)，但簡單來說就是一個以實數 (real number) 來表達的數字，例如 12345。([definition in reactive banana](https://github.com/HeinrichApfelmus/reactive-banana/blob/880c9469f95493b9ff19fd5811c3751b5f81fef7/reactive-banana/src/Reactive/Banana/Prim/Types.hs#L198))

```haskell
-- Time definition in reactive-banana.
newtype Time = T Integer deriving (Eq, Ord, Show, Read)
```

可見得是很簡單的定義，事實上 Behavior 的結構也是 functional reactive programming 最重要且**唯一**的基礎，剩餘探討的變化事實上都是在**組合**上面。在 [Conal Elliott 2015 年的 talk](https://begriffs.com/posts/2015-07-22-essence-of-frp.html) 中，再次強調了 Functional Reactive Programming 即是包含了重要的兩項原則：(1) Continuous time (2) Precise, simple denotation。他 argue 很多號稱 FRP 的 library or system 都沒有 address 到這兩項原則。第二項原則比較是 general 的 argument，而第一項則是貫穿了 FRP 與其餘 sibling 的最大差別。

看一下示例就會對這個 continuous time 的抽象有感覺:

```haskell
-- Built in `time` behavior is basically an identity function map from time value.
time :: Behavior Time
time = \t -> t

-- For example, the wiggle reactive variable is the value varied cyclically between -1 and +1.
wiggle :: Behavior Double
wiggle = sin (pi * time)
```

Event 則是代表 occurrence，可以注意到一件事情是它是 product (tuple) with time value，這跟常見的 event-driven programming 不同，反而類似於 stream processing 中 tuple 的 signature：

```haskell
-- Submit event with time and a value.
-- In the original paper, this is called constEv.
once :: Time -> a -> Event a
```

回過頭來看，Fran 在設計期時，根本壓根沒有考量事件驅動、Observer Pattern 等前述 Reactive Programming 的**好處**，因此 FRP 他的動機和結構模型其實是非常單純的，他們只共享了一件重要的事實，就是 modeling concurrency programming。

註：這邊的語法交叉參考了 [4][9][10]，所以會跟原始論文有些不同，最主要 align Conal Elliott 後來更新的 API 名稱。

## C2 - Deprecating Observer Pattern

TODO

# Lifting Operations

Lifting Operations 顧名思義就是將 computation 提升到 reactive 的 context 中，簡單類比可以思考為 Optional、Either、Future、IO 等 higher-kinded types 的計算方式。舉例來說：

```scala
// Lift a computation into behavior context.
def lift1[A, B](f: A => B): Behavior[A] => Behavior[B] = ???
```

簡單來說：**這邊就是在講 abstraction 如何 compose**。只是這裡面會有點歷史因素，因為 [4] 所開始時，並沒有現今常用的 typeclasses (i.e. functor, monad, applicative) [8]。

這在 [3] 的 survey 中分為三種 strategy: (1) implicit lifting: 隱式且自動的 lifting，往往發生於 dynamic type language 的實現 [7] (2) explicit lifting: 顯式的 call lifting method，多數為 static type language 所需要的 (3) manual lifting: 壓根沒提供。

這邊我主要探討的點是在於 lifting 的 signature 和相關的組合 pattern，主要是在於 static type language (Haskell, Scala, Java) 上的 construction。因此面向與 [3] 所探討的有所不同。

## C1 - Functional Reactive Animation

Fran 的 host language 是 Haskell，因此 lifting operation 必須 explicit 的給出，這些 lifting 在後來 (C3) 利用 monadic 的 typeclass 來取代了，但當初設計的時候並沒有這些一般性的抽象。

Lifting 其實是很直覺的樣子，利用不同 ary 來 lift variable or function 到 Behavior context 中：

```haskell
-- Lift a constant value into behavior context.
lift0 :: a -> Behavior a
-- A similar construction to fmap.
-- Lift a function into behavior context.
lift1 :: (a -> b) -> Behavior a -> Behavior b
lift2 :: (a -> b -> c) -> Behavior a -> Behavior b -> Behavior c
```

Time transformation 可以將時間的推移改變：

```haskell
timeTrans :: Behavior a -> Behavior Time -> Behavior a

-- Applying time is simply an identity function.
timeTrans a time == a
-- Slow down time with factor 2.
timeTrans a (time / 2)
-- Delay time by 2 seconds.
timeTrans a (time - 2)
```

Integration 顧名思義就是積分：

```haskell
-- a should be an instance of vector space typeclass.
integral :: VS a => Behavior a -> Time -> Behavior a

-- Integral behavior b by starting time t0.
integral b t0
```

$$\int_{t_0}^tb$$

Event 的組合方法：

```haskell
-- The OR logic.
(.|.) :: Event a -> Event a -> Event a
-- Simply said, an fmap.
(=>) :: Event a -> (a -> b) -> Event b
-- When an behavior becomes true `after` a specific time (initial time), raise an event.
predicate :: Behavior Bool -> Time -> Event ()
-- `Snapshot` a behavior with event a.
snapshot :: Event a -> Behavior b -> Event (a, b)
```

Reactivity 則是與 event 的交互 -> 當某個 event 發生時，轉換 behavior!：

```haskell
switcher :: Behavior a -> Event (Behavior a) -> Behavior a

-- For example,
-- Transform to blue triggering by left button press event.
color1 = red 'switcher' (lbp -=> blue)
-- Transform to blue or yellow by left button press event or key event.
color2 = red 'switcher' (lbp -=> blue) .|. (key -=> yellow)
-- Transform to blue once the time is greater than 5.
color3 = red 'switcher' (predicate (time > 5) -=> blue)

-- Composing event, an fmap.
(==>) :: Event a -> (a -> b) -> Event b
-- -=> is an derived operation (syntactic sugar) from composing event,
-- Similar to $> in functor.
(-=>) :: Event a -> b -> Event b
(-=>) e b = e ==> \_ -> b
```

註：這邊的語法也是交叉參考了 [4][9][10]，所以會跟原始論文有些不同，最主要 align Conal Elliott 後來更新的 API 名稱。
一些 example 是從 [9] 拿出來的。

小結：記住他的動機是在 animation，後面的 Yampa [11] 等更新雖在組合方法不同，也同樣著重連續時間上的應用 (simulation, robotics)，所以是貫穿這裡面的主軸。**簡單來說，FRP 跟你我想像的 RP 是完全不同的用途！**

## C2 - Deprecating Observer Pattern

TODO

## C3 - Reactive - Modern Revision via Standard Typeclasses

TODO

# TL;DR

## Q1 - What is Functional Reactive Programming?

Functional Reactive Programming 以 continuous time-varying values 和 automatically propagate value changes 來建構應用程式。
並且提出數個 combination 的方法來組合 abstraction，而這些方法起初多以 functional programming 來建構 (higher-order function, recursive data types, etc)，因此才會有 functional 為起頭，但他**並不是**單純說 ~~functional reactive programming 為以 functional programming 的方法建構 reactive programming~~。它有非常嚴格且單純的定義和特性基於：**continuous time value**。Time! Time! Time!

## Q2 - What is Reactive Programming?

TODO

## Q3 - Reactive Programming v.s. Stream Processing?

TODO

# References

1. https://gist.github.com/staltz/868e7e9bc2a7b8c1f754
2. https://en.wikipedia.org/wiki/Reactive_programming
3. E. Bainomugisha, A. L. Carreton, T. van Cutsem, S. Mostinckx, and W. de Meuter, “A survey on reactive programming,” ACM Computing Surveys, vol. 45, no. 4, pp. 1–34, Aug. 2013.
4. C. Elliott and P. Hudak, “Functional reactive animation,” ACM SIGPLAN Notices, vol. 32, no. 8, pp. 263–273, Aug. 1997.
5. I. Maier and M. Odersky, "Deprecating the Observer Pattern with Scala.React," EPFL-REPORT-176887, 2012.
6. B. Christensen, T. Nurkiewicz, "Reactive Programming with RxJava: Creating Asynchronous, Event-Based Applications," O'Reilly Media, Oct. 2016.
7. G. H. Cooper and S. Krishnamurthi, “Embedding Dynamic Dataflow in a Call-by-Value Language,” in Programming Languages and Systems, Springer Berlin Heidelberg, 2006, pp. 294–308.
8. C. M. Elliott, “Push-pull functional reactive programming,” in Proceedings of the 2nd ACM SIGPLAN symposium on Haskell - Haskell ’09, 2009.
9. Z. Wan and P. Hudak, “Functional reactive programming from first principles,” ACM SIGPLAN Notices, vol. 35, no. 5, pp. 242–252, May 2000.
10. https://begriffs.com/posts/2015-07-22-essence-of-frp.html
11. A. Courtney, H. Nilsson, and J. Peterson, “The Yampa arcade,” in Proceedings of the ACM SIGPLAN workshop on Haskell - Haskell ’03, 2003.