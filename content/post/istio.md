---
title: "Istio 概念"
date: 2017-06-02T19:38:22+08:00
draft: false
---
[Istio](https://istio.io) 在最近 (5 月底)release 出來了，由 Google, IBM, Lyft 一起發起的 microservice 管理的專案，概念和功能與我之前所想的有所符合，架構也很彈性、完整，所以算是最近準備要 trace 的一個專案，記錄一下之前看官方文件的心得。

## Why Use Istio?
microservice 現在算是全世界都想奔往的新系統型態，隨著 docker、kubernetes 等專案的起頭，追求更簡便的管理算是各方都想要的 solution。而 Istio 就是想**解決隨著 microservice 部署的數量成長所增加的複雜度。**

需求：

* Service discovery
* Load balancing
* Failure recovery
* Metrics
* Monitoring
* A/B testing
* Canary release
* Access control

## Architecture

<img src = "https://istio.io/docs/concepts/what-is-istio/img/architecture/arch.svg" width="400px">

## Istio Design Goals
1. Maximize Transparency
2. Incrementality
  * Policy extension
3. Protability
4. Policy Uniformity

## Traffic management

Istio 在處理 traffic management 的概念與 SDN 雷同，分為 Control plane(Istio Manager) 和 Data plane(Envoy Proxy)，於是可以以簡單的 DSL 來去部署想要的 traffic 流向。
這解決了我之前有在想的 service egress 的方式，他可以**顯式**的轉換每個 service 的出口目標，而不單單只是 ingress，並且以 sidecar 的方式注入 Envoy Proxy，還增進做 failure recovery 和 fault injection 的方便性。

算是跟我之前做的垃圾概念一樣 - [kube fault injector](https://github.com/tz70s/kubernetes-fault-injector)

## Istio Manager

## Request Routing

### Service Model
由於 Istio 只關注在 Service 管理的層級，所以他還是必須要有 underlying 的 orchestration platform，如 Kubernetes, Mesos(目前只有支援 Kubernetes)。只不過在設計原則上，盡可能是與 underlying platform 獨立的，以達到 portability。

### Service Versions
API version 或 envrionment(stage, prod) 在 istio 是可以在設定的 DSL 寫入的，這可以讓 routing rules 設定在不同的 service version 上，簡化了 A/B tests 或 Canary rollouts。
