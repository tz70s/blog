+++
title = "Critics - MBrace: Cloud Computing with Monads"
date = "2018-09-07"
slug = "mbrace" 
tags = ["critics"]
categories = []
+++

Programming large-scale distributed systems is difficult and requires expert programmers orchestrating concurrent processes across various physical places (nodes), and potentially required to be scalable, resilient, etc. Choosing a well abstraction framework can reduce such efforts and make system performant and resilient. 

For example,

1. MapReduce
2. Akka
3. CloudHaskell[[1]](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/07/remote.pdf) and HdpH[[2]](http://www.macs.hw.ac.uk/cs/techreps/docs/files/HW-MACS-TR-0091.pdf)

However, problematics on MapReduce model: less expressive and not suitable for streaming, iterative and incremental algorithms. (NOTE: the motivation is less persuasive, IMHO)

## MBrace - programming model and execution framework for cloud

Features:

* Compositional and declarative approach to describing distributed computations, by **monad**.

```F#
# a fork-join pattern
cloud {
  let job1 = cloud { return 1 }
  let job2 = cloud { return 2 }
  let! [| result1 ; result2 |] =
    Cloud.Parallel [| job1 ; job2 |]
  return result1 + result2
}
```

* Scalable MBrace runtime that enables distributed abstract machine execution for cloud workflows (enable location transparency).
* Rich client tooling, cloud workflow libraries, REPL and IDE integration.

# Programming Model - Cloud Workflows

The programming model provides the ability to declare abstract and modal expressions in a fluent, integrated manner, to be subsequently executed in the cloud, powered by monad.

## Preliminary - F# Async Workflows

Asnychronous workflows avoid the need of explicit callbacks, 

```F#
let download (url : Uri) = async {
  let http = new System.Net.WebClient()
  # The let! denotes the callback passed to the right-hand-side operation.
  # let! : monadic bind, return : monadic unit
  let! html = http.AsyncDownloadString(url)
  # Original paper miss a ! here.
  return! html.Split('\n')
}
```

Composition,

```F#
let workflow = async {
  let! results =
    Async.Parallel
      [
        download "http://www.google.com";
        download "http://www.facebook.com"
      ]
  return Seq.concat results |> Seq.length
}
```

Async expressions have deferred execution semantics: evaluted by a scheduler that tranparently allocates pending jobs to the underlying .NET thread pool.

## The Cloud Workflow Programming Model

Similar to F# async workflows, the `Cloud<'T>` represented a deferred cloud computation that returns a result of type 'T once executed. The closure can be also passed transparently, that we can descirbe higher-order functions to compose cloud workflow. An important feature offered by cloud workflows is exception handling: the symbolic execution stack winds across multiple machines, the computation stack is un-winded across multiple machines as well. (Implement via free continuation monad[[3]](http://blog.higher-order.com/assets/trampolines.pdf))

Example, MapReduce:

```F#
let rec mapReduce (map: 'T -> Cloud<'R>)
                  (reduce: 'R -> 'R -> Cloud<'R>)
                  (identity: 'R)
                  (input: 'T list) =
  cloud {
    match input with
    | [] -> return identity
    | [value] -> return! map value
    | _ ->
      let left, right = List.split input
      let! r1, r2 = 
        (mapReduce map reduce identity left)
          <||>
        (mapReduce map reduce identity right)

      return! reduce r1 r2
  }
```