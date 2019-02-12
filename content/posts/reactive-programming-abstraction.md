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

Reactive Programming 在現代基於事件驅動程式設計及架構來講，根本上來講以去除副作用 (side-effect) 的 Declarative 方式來建構事件的轉換及組合，可以有效降低在 concurrency 下的錯誤和增強組合性 (composability)。這衍伸在工業界如 ReactiveX (RxJava, RxJS, etc)、Reactive Stream Specification 或是如 Future 的建構都有其**影子**。

然而，他的定義在網路上的文章仍十分模糊，例如：

1. Reactive Programming is a programming with asynchronous data stream. [1]
2. Reactive programming is a declarative programming paradigm concerned with data streams and the propagation of change. [2]
3. Reactive programming is a programming paradigm that is built around the notion of continuous time-varying values and propagation of change. [3]

除此之外，他的建構模型也會同樣的讓人困惑：`Observable`, `Var`, `Signal`, `Behavior`?

這篇文章重新檢視一下這些概念，整理一下從不同文獻而來的資料，並區別且歸類各處的定義 [3][4][5]。最後，示意一段實現 Reactive Programming 的 prototype。

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

Disclaimer: 誠實的說，我不認為我完整理解這裡面精確的內涵，因此警告一下誤觸本篇的讀者請再三思考一下！或請透過 footer 列的 email 來更正及指教。

## Recap - Why Reactive Programming?

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

## Basic Abstraction

所有 reactive programming 都是由 [4] 所發展而來的變形，以前述 6 個 dimension 上會有不同的變化，並且詮釋到 programming language 或是 framework 上; 但最基礎的抽象不外乎下列兩種：

1. Behaviors: 為隨著**連續**時間所變化的值 (continuous time-varying value) 的抽象。這最根本的抽象動機是在於 reactive programming [4] 最早的出發點是在於做 animation 或是 robotics，較為關注連續時間(仿類比)的訊號處理。
2. Events: 為 streams of value changes 的抽象，相對於 Behaviors 為離散的時間點。換言之，這也是於現代更常用到的事件驅動架構下的抽象。

這兩項抽象分別對應到了 [2][3] 上所定義的 continuous time-varying 和 data stream。

### C1 - Functional Reactive Animation 

Reactive Programming 的根源即時從此篇論文，Fran 所延展而來的，如前面所說的，Fran 的目的在於降低 programming in animation 所需要的 boilerplate，包含：

1. 手動 framing (基於離散時間)，即便 animation 是 conceptual continuous 的。
2. 手動捕捉和處理序列的動作輸入 (motion input) 事件。
3. 手動切割時間並且更新每個隨時間變化的參數。

有鑑於此，Fran 認為如果能自動化 **how** of its representation (presentation)，讓使用者專注於 **what** of an interactive animation (modeling)，會是很大的貢獻。進而產生四項對應用的好處：(a) Authoring: programmer 不用專精於底層的 presentation detail，使之可以更有創造力；(b) Optimizability: model-based 所建構的高層資訊可以使得底層 presentation 有 optimization 的機會；(c) Regulation: 一致性的抽象層次管理；(d) Mobility and safety: model-based 可以是 platform independence 的。

Fran 結構了基本的抽象如下 (polymorphic Behavior 和 polymorphic Event)：

$$at: Behavior_a \to Time \to a$$
$$occ: Event_a \to Time \times a$$

### C2 - Deprecating Observer Pattern

### C3 - ReactiveX & Monix

## Lifting Operations

Lifting Operations 顧名思義就是將 computation 提升到 reactive 的 context 中，簡單類比可以思考為 Optional、Either、Future、IO 等 effect 的計算方式。舉例來說：

```scala
// Lift a computation into behavior context.
def lift1[A, B](f: A => B): Behavior[A] => Behavior[B] = ???
```

簡單來說：**這邊就是在講 abstraction 如何 compose**。只是這裡面會有點歷史因素，因為 [4] 所開始時，並沒有現今常用的 typeclasses (i.e. functor, monad, applicative)。

## TL;DR

### Q1 - What is Functional Reactive Programming?

### Q2 - Reactive Programming v.s. Stream Processing?

### Q3 - What is Reactive Programming?

## Taste

```Scala
case class Behavior[+T](t: T)

// Lift a computation into behavior context.
// Note: this is not an ap in applicative functor.
// TODO: The newer version of construction with standard typeclass.
def lift1[A, B](f: A => B): Behavior[A] => Behavior[B] = ???
```

## References

1. https://gist.github.com/staltz/868e7e9bc2a7b8c1f754
2. https://en.wikipedia.org/wiki/Reactive_programming
3. E. Bainomugisha, A. L. Carreton, T. van Cutsem, S. Mostinckx, and W. de Meuter, “A survey on reactive programming,” ACM Computing Surveys, vol. 45, no. 4, pp. 1–34, Aug. 2013.
4. C. Elliott and P. Hudak, “Functional reactive animation,” ACM SIGPLAN Notices, vol. 32, no. 8, pp. 263–273, Aug. 1997.
5. I. Maier and M. Odersky, "Deprecating the Observer Pattern with Scala.React," EPFL-REPORT-176887, 2012.
