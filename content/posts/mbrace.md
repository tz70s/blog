+++
title = "Note - MBrace: Cloud Computing with Monads"
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
  return html.Split('\n')
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

MBrace also provides some combination operators for parallel processing:

* `Cloud.Parallel : Cloud<'T> [] -> Cloud<'T []>`
* `<||> : Cloud<'T> -> Cloud<'U> -> Cloud<'T * U>`
* `Cloud.Choice : Cloud<'T option> [] -> Cloud<'T option>`

Here's some example code snippet in paper, 

### MapReduce

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

### Nondeterministic Computation

```F#
let exists (f : 'T -> Cloud<bool>) (inputs: 'T []) =
  cloud {
    let pick (x : 'T) =
      cloud {
        let! result = f x
        return if result then Some x else None
      }
    # In Scala words: Cloud.Choice inputs.map(pick)
    # Similar to forall operation.
    let! result = Cloud.Choice <| Array.map pick inputs
    return result.IsSome
  }
```

### Local Parallelism

There are cases where constraining the execution of a cloud workflow in the context of single worker, i.e. useful to manage computation granularity.

* `Cloud.ToLocal : Cloud<'T> -> Cloud<'T>`

The local combiantor transforms any given cloud workflow into an equivalent expression that executes in a strictly local context.

```F#
let rec fib n depth =
  cloud {
    if depth = 0 then return! Cloud.ToLocal <| fib n depth
    else
      match n with
      | 1 | 2 -> return 1
      | n ->
        let! (left, right) = fib (n - 1) (depth - 1) <||> fib (n - 2) (depth - 1)
        return left + right
  }
```

## Distributed Data

This is not represented as ddata in Akka (CRDT) or any other else. It's an abstraction to manage data in a more global and massive scale. In the above example, we've limited data distribution, which is inherently local and almost certainly do not scale to the demands of modern big data application. Hence, MBrace introduced a data entities known as cloud ref, `CloudRef<'T>`.

It's an trivial abstraction for modern application handling large blob size entity, i.e. in serverless manner, we can only pass references that point to blob storage.

```F#
let getRef () : Cloud<CloudRef<string []>> =
  cloud {
    let! data = download "http://a-big-data-place"
    let! ref = CloudRef.New data
    return ref
  }

# Compute a cloud ref.
let r = runtime.Run <@ getRef () @>
# Dereference locally
let data : string [] = r.value
```

MBrace transparently manages storage, while it also aggressively caches local copies to select worker nodes, within an affinity manner. Hence, there are two types of CloudRef design: 

* Immutable: eliminates synchronization (from cache to storage), resulting efficient caching and enhanced access speeds.
* Mutable: also a powerful abstraction for defining synchronization mechanisms such as distributed lock and semaphores. You can think it as volatile semantic in JVM, that it's not cacheable to ensure visibility.

What more: scoped resources, offerring a mechanism for performing deallocations in a scope. The data constructs that implement the `CloudDisposable` interface which bind to `use!` keyword.

```F#
cloud {
  # Ensure deallocation from the global store as soon as the workflow has exited its scope!
  use! cref = CloudRef.New [| 1 .. 10000000 |]
  try
    if cref.Value.Length > 1000 then
      return failwith "error"
  with e ->
    do! Cloud.Logf "error in cloudRef %0" cref
    return raise e
}
```

## The MBrace Runtime

An execution engine that include facilities for managing, monitoring and debugging cloud processes. The execution model follows a scheduler/worker hierarchy: when a cloud workflow is uploaded to the runtime for execution, a scheduler instance is initialized that interprets the monadic structure of the workflow, disseminating continuations to worker nodes as required. It's also inherently load distributed, fault tolerant for any jobs.

## Critics

This paper gives a well-started introduction for using monad in distributed programming. It's easy and powerful like everything you may familiar with, i.e. IO effect, Task effect or Future. Can be fluently composed into complex functiona transformation workflow. More thankfully, its [open sourced](https://github.com/mbraceproject/MBrace.Core)! Research papers are usually restricted for describing more detail about implementation, however, we can go deeper here.

For my own further readings: F# async, CloudHaskell and free continuation monad! I'll revisit this paper for more concern about side-effect and failure handling.