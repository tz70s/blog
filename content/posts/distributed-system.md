+++
title = "Distributed Systems for Fun and Profit"
date = "2017-06-07"
slug = "distributed-systems-for-fun-and-profit" 
tags = []
categories = []
+++

[Distributed Systems for Fun and Profit](http://book.mixu.net/distsys/) 是本分散式系統的書，短小精悍目標是涵蓋所有分散式系統的概念和點出一些關鍵的演算法，然後這是我的筆記。

## Basics

基本電腦系統可以分為兩種 task 需要去完成

* storage
* computation

分散式系統的目標是要解決當我們系統 scale up 去處理這些 task ，並且而後發生的種種 trade-off。

### Scalability
> is the ability of a system, network, or process, to handle a growing amount of work in a capable manner or its ability to be enlarged to accommodate that growth

**Growth** 可以從很多面向來看，但最重要相關的觀點用以來量測就是`performance and availability`

### Performance (and latency)
> is characterized by the amount of useful work accomplished by a computer system compared to the time and resources used

從字面上的意思來看就是工作完成/花的時間&用了多少 resource，而這當然在不同 context 下會有不同的樣子，如 `response time, throughput, utilization` 都可以視為 performance 的 metrics，只不過當然這些彼此都可能有 tradeoff 存在，例如 low response time 和 high throughput 不一定同時成立。

### Availability (and fault tolerance)
> the proportion of time a system is in a functioning condition. If a user cannot access the system, it is said to be unavailable

`Availability = uptime / (uptime + downtime)`

而 **Fault tolerance** 代表的是
> ability of a system to behave in a well-defined manner once faults occur

簡單明瞭，略

### Abstraction and Models

**Abstraction**

* 分散式系統的目標就是想要變成一個**像是單一系統**的系統

**Model**

* System model (asynchronous / synchronous)
* Failure model (crash-fail, partitions, Byzantine)
* Consistency model (strong eventual)

### Design techniques: partition and replicate

![Partition and Replication](https://i.imgur.com/Eh9aQr6.jpg)

**Partitioning** 主要是把 dataset 分成不同的獨立 set，降低 dataset growth 所造成的影響。

* 可以增進 performance ，利用相關的 data 被分割到相同的 partition (概念有點像 locality )
* 可以增進 availability ，利用分割的 failure 可視為獨立的。(不會有相依 failure?)

但 partitioning 是 apllication-specific，所以在處理上得設計好 access 的方式，**處理好因為去除相依性所帶來的限制**，所以比較多還是會考慮在 replication。

**Replication** 則是 make copies 。

* 一樣可以增進 performance，因為有額外的運算資源可以處理 copy of data，也可以 cache。
* 也可以增進 availability，**bj4**

但 replication 可以讓我們達到 scalability, performance, faultolerance，但則要考慮到 **consistency** 的問題，選擇怎麼樣的 consistency model 是很殘酷的問題。

第一章都在講廢話...。

## Up and down the level of abstraction

**Abstraction** 是基於忽略一些系統的面向來做出的 **fake** ，所以 system model 是規格讓我們知道可以做到的事情，與沒辦法做到的事情。

### A system model

Programs 在分散式系統中

* 同時可能會跑在不同的 node 上
* 利用可能會不穩定的網路連接
* 沒有使用 shared memory 或 shared clock

會有一些延伸的 properties

* 每個 node 會執行 program
* state 是 local 的，且 global state 有可能會過期
* nodes 會 fail 和 recover
* 訊息會掉包
* 每個 node 的 clock 可能不同步

**System model**

> a set of assumptions about the environment and facilities on which a distributed system is implemented

1. **Nodes** 是個 host 做 computation and storage，並且擁有

* Ability to execute a program
* Ability to store data into volatile memory and into stable state(persistent)
* a clock

目前主流是用 **crash-recovery failure model**，當一個 node fail 時，他有可能會在某個點 recover。**Byzantine fault tolerance** 則是 cost 太高，比較不常見。

2. **Communication links** 是連接 nodes，而 reliable transfer 是我們所要考量的。

**A Network Partition** 在這是指網路斷掉了 (雖然 node 仍舊會運作)，在這狀況下，傳遞的訊息就會丟包，被分割的點可能會有別人 access ，或是被當成 crash node。


![](https://i.imgur.com/X18C8Nn.jpg)
**node fail vs network partition**

3. **Timing / ordering**

* Synchronous system model

給定了 timing / ordering 的假設

1. Processes execute in lock-step;
2. there is a know uppper bound on message transmission delay;
3. each process has an accurate clock

* Asynchronous system model

No timing assumptions

1. no bound on message transimission delay
2. no useful clocks

### The consensus problem

Consensus problem 其實主要是在講**同意**這件事情

1. Agreement : 全部正確的 process 都要同意相同的值。
2. Integrity : 全部正確的 process 只能決定最多一個值，且是由某些 process 提出的。
3. Termination : 全部的 process 最終會得出一個 decision 。
4. Validity : 如果全部的 process 提出相同的值 V，則決定 V。

### The FLP impossibility result
假設

* Asynchrouns system model (no timing assumtion)
* No communication failure (reliable network)
* Nodes can only fail by crashing

結論 : **不要浪費時間在異步系統上解決consensus problem**，即便是在以上這麼小的假設。

### The CAP theorem

* Consistency : 這裡指的是 Strong consistency
* Availability : 整個系統可以持續讀寫(自然是不包含 consistency )
* Partition tolerance: 系統會有分區的情況，也就是網路會在有限時間/無限時間內斷線，也就是長延遲也算在內。

![](https://i.imgur.com/ZYitpZB.jpg)

**CAP** 說中間 intersection，也就是三者都成立的狀況是不可能滿足的。

因此我們會有三種不同面向的系統

1. CA(consistency + availability)
2. CP(consistency + partition tolerance)
3. AP(availability + partition tolerance)

書中寫得實在是太難懂了，我參考了其他的見解。重要觀點可以從 Partition tolerance 來起手。

![](https://i.imgur.com/l17rZ7D.png)

當網路會有分區的狀況發生時，也就是說假設今天A, B中間的網路斷線了，A和B會做出怎樣的決策。

1. 繼續分別提供讀寫服務，自然資料就會產生不一致，也就是 AP type。
2. 停止寫入服務，則資料的部分可以維持一致，但也沒有 Availability 了，這則是 CP type。
3. 而當我們今天預設狀況是網路都是保證正常，則 CA type 就可以很**理想**的完成了。

附註一下，當 Partition tolerance 的處理流程，有點像版本控制。

1. 偵測是否分區
2. 當發生分區時，進入分區模式限制住某些操作
3. 分區結束時，合併狀態

![](https://i.imgur.com/eH8o6Ur.jpg)

### Consistency models
Consistency models 可以被分為兩種 type

* Strong consistency model
    * Linearizable consistency
    * Sequential consistency
* Weak consistency model
    * Client-centric consistency model
    * Casual consistency: strongest model available
    * Eventual consistency model

**Linearizable consistency**
所有 operation 與 global real-time ordering operation 是一致的，也就是有一個**絕對時間**的存在，且這些 operation 都是按照絕對時間來排序。

**Sequential consistency**
將 global real-time ordering 放寬，允許不用按照絕對時間排序，但也保證 individual 上的順序是滿足 program oreder 的，且全部 node 看到的都是相同的順序即可。

**Casual consistency**
有因果關係存在

* 同一個 node 中的 event A 早於 B (A<B)
* 當 A 完成後會推播消息給 B
* 已知 A<B , B<C 則 A<C

Casual consistency 是要求如果兩個 event 有因果關係的話，則要求他們是順序一致的，且所有 node 都會看到相同的一致，但反之沒有因果關係的話，就不用保持一致性。

![](https://i.imgur.com/uqE9XxF.png)


P2 把 x 從 1 改成 2，因此讀取操作不允許出現 R(x)2,R(x)1 的現象。但是此例中，y 操作没有因果序，所以 P3 讀到 R(y)2, R(y)1 和 P4 讀到 R(y)1, R(y)2 的在 Causal Consistency 是允許的。

**Eventual consistency**

系統在最終會保持一致性，但是這也會引發我們需要去認知的問題。

1. How long is **eventually**?
2. How do the replicas agree on a value?




