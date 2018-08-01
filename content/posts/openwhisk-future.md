+++
title = "OpenWhisk performance improvement"
date = "2018-07-24"
slug = "openwhisk-performance-improvement" 
tags = []
categories = []
+++

**This post is still WIP.**

OpenWhisk community is nowadays getting more consistent on the new design of architecture for performance improvement. The **future architecture** of OpenWhisk requires large internal breaking changes. To fill the gap from idea into smooth migration, there might be helpful if a mid ground exist to clear more issues. Hence, I've worked on prototyping performance improvement in real, but not that comprehensive though. However, hope this prototype hold a place for deeper discussion and discover all issues might meet in the future. 

This post will be two kinds of target audiences, OpenWhisk community, GSoC mentors and reviewers:

**For OpenWhisk community:**

This objectives of this post and protoype:

* Draft an experimental prototype of OpenWhisk future architecture, for knowing all issues might meet.
* Hope to help community migrate to the futrue architecture smoothly.
* Might be a starting point for further discussion.

**For GSoC mentors (Rodric and Carlos) and reviewers:**

This will be my final result during the GSoC progress. I'll describe my exprience in the bottom or maybe another post.

## Architecture recap

The [Future Architecture proposal](https://cwiki.apache.org/confluence/display/OPENWHISK/OpenWhisk+future+architecture) proposed by Markus Thommes integrated lots of communities' idea; play a great start to a new performant architecture.

## Steps to produce

Instead of prototyping from clean slate, it's quite more challenged established via current codebase, but take more advantages:

1. More accurate comparison on performance and architecture.
2. Help to explore the migration path.
3. Help me to better understanding on OpenWhisk internal implementation.

However, OpenWhisk already provides nice infrastructure and utilities that I can easier to migrate this. As I mentioned, one of targets on this experiment can help to figure out the smooth migration path to future architecture. I've tried my best not to break up current codebase and kept rebase it with upstream. 

The prototyping steps as follow:

1. A New LoadBalancer SPI: SingletonLoadBalancer (which adapt with Container Manager)
2. Duplicate and cut off logics from Invoker into new Container Manager.
3. Re-use and refactor invoker-agent which is used by Kubernetes deployment. (contains some breaking changes, but I think it can also improve current kube deployment)
4. Implement required changes.

I'll discuss these in detail below.

For cleaner naming convention, I've renamed some words from proposal, here's the mapping:

1. Container Management Agent -> InvokerAgent
2. Container Manager -> Scheduler

## Controller

Most of Controller logic and programming semantics will not be changed, except for LoadBlancer. I've created a new LoadBalancer implementation in [future package]() and can be simply loaded with SPI infra.

The overall LoadBalancer design:

圖

In words, the roughly workflow as following:

1. Call publish activation
2. Check if there's a warmed action existed, by looking up local container list.
3. If yes and if it's belong to owned, http call for it. Else, redirect to another container with carrying http client context.
4. If not, queue in OverflowManager and put the activation in the overflow queue.
5. Request for new resource, via proxy actor to Scheduler singleton.
6. After scheduler singleton's response arrived, update local container list (which generated via scheduler).
7. If it's belong to owned, http call for it. Else, redirect to another container with carrying http client context.

There's still some problems on the design above, and we'll have to dig this with more detail:

**It's neccessary to provide a strong consistency (warmed) container lists to be kept in each controller, how do we deal with this?**

A basic thinking: we can keep only owned container lists in each in-memory store and lookup Scheduler for redirecting calls every time. But this will not only lead to additional latency between Controller and Scheduler, it can be easier to let Scheduler reach performance bottleneck.

What if we keep others record? Obviously, this will lead to in-consistent, and how do we update this?

It's pretty sure we can't make all these cache synchronized when lists get updated, it'll required large performance penalty on blocking.

To achieve this, we can only **make it in-consistent at some point; but we'll not execute once if there's inconsistent.** Iff one Controller redirect to another, we'll add timeout and retry if another Controller was offline, or using akka Cluster Event can also update this. Then we'll ask Scheduler for a new consistent list. Iff the redirect Success but not belong to itself? The in-consistent occurred, this may happened to event ordering (imagine one Controller ask for resource and Scheduler allocate to another Controller, and update list to them, the event ordering can't be guarantee here). In this case, the redirected Controller will ask again for Scheduler, and repeat the process untill it find the correct warmed container.

What about the number of Controller will receive the updates once Scheduler decide it? It's better make it with limit ranges/groups for updates to make Scheduler less burden. **WIP**

**In order to do direct http calls, how can we reach warmed container after NAT environment?**

In Kubernetes network model, the ip-per-pod model is flattened and we can easily work without this problem. But to the native mode, the warmed containers required some mechanisms to resolve with NAT environment.

There are some potential ways:

1. Use InvokerAgent as a reverse proxy: this will take some additional benefits => reduce the calls after pause/resume, since Controller will no longer managed any Container's lifecycle. However, this is quite similar to prior Invoker, may gain some latency here.

2. Forced user to use somewhat overlay/underlay network policy, to reach a similar model in Kube.

3. Port-forwarding once creation.

Obviously, it's arbitrary and not applicable for option 2. I choose 3 from now.

**How do we deal with overflow messages?**

There's no consistent here due to the unbounded topics problem. **WIP**

## Scheduler

The Scheduler is responsible for handling controller resource requisitions, monitoring and (partially) mangaging containers' lifecycle. 
In the overall design, it's similar to most logic from prior Invoker, but without pause/resume operations.
As I mentioned, I didn't deal this with Kubernetes. However, the approach may be similar and much simpler. Further, the new open source knative project might make the architecture further changed to adapt with Kubernetes.

### Container Factory Protocol

The protocol between Controller and Scheduler.

In order to maximize performance, the container creation/deletion protocol is implemented via akka message passing. Protocol can be looked like this:

<script src="https://gist.github.com/tz70s/a15c32c59f17b3f4034275566484759c.js"></script>

To guarantee strong consistency for container selection in controller. The scheduler will be (contains) a cluster singleton to resolve container selection. [Akka cluster singleton](https://doc.akka.io/docs/akka/2.5.14/cluster-singleton.html) is introduced here: ClusterSingletonManager will sits in Scheduler and ClusterSingletonProxy will sit in both Controller and Scheduler to access the singleton. You can checkout the doc for usage and [here's my example with less noise](https://github.com/tz70s/cluster-singleton-ex) compared to Akka provided, which contains a basic singleton and proxy setup with migration observation guide.

There might be two potential problems on using cluster singleton:

1. Perfromance bottleneck: **WIP**

2. Single point of failure: akka cluster singleton will automatically migrate to another scheduler node (actor-system) once the leader (oldest) getting down. This will result in short downtime, but it can be afford to us however, the ClusterSingletonProxy will buffer messages until the new singleton is up; the latency is overall make sense b.c. this is not actually the performance critical path. A more serious problem is how do we persistent singleton states: **WIP**

### Container Lifecycle Management

The InvokerAgentProxy is an actor which similar to original InvokerSupervision in loadbalancer and we move this here.
But the internal jobs are totally different, since we can **check the health state via docker/kubernetes**, instead of ping/pong via customized protocol (handshake above kafka, previously). In other words, we can monitor nodes health via Kubernetes (simple!); and we can get a live lists of running/non-running container states from docker daemon hence ensuring the node is up.

The approach will be distincted by two orchestration choices: Kubernetes and Native (Docker).

1. **Kubernetes**:
Basically, we just call kubernetes api server with 1 to 1 mapping, it'll deal with all scheduling, health check and so on. Hence, InvokerAgentProxy has only one instance, in this case.

2. **Native(Docker)**:
Contrast to indirectly calls in Kubernetes, in the native way, we'll have to deal everything by us. Quite similar to InvokerSupervision approach, the InvokerAgentProxy will have M to M supervision, but checking liveness via docker daemon checks.

Here's the signature and protocols in Native approach, full code can be found at [here]()

### Scheduling Strategy

Cutting logics from ShardingLoadBalancer, with simple sharding mechanism.

WIP

## Invoker Agent

Prior on Kubernetes deployment in OpenWhisk, it already has an invoker-agent do some similar jobs (pause, resume and log); and hence works fine for me with some basic refactoring. 

However, this may not meet OpenWhisk requirements: 

1. One siginificant bottleneck and many folks concerned: **activation log**. We already had plenty of log store implementation, i.e. elasticsearch, docker file, etc. In general, we should not pass logs from whisk agent back to either Controller or Whisk Scheduler. Instead, directly store activation log into log store. Therefore, we can and we should reuse the codebase from implemented log store.

2. Better **integration**: Go has it's own workspace and directory convention ($GOPATH). It's neccessary if need a mature dependency management, i.e. dep. By convention, we might locate it into some kind of path: _github.com/apache/incubator-openwhisk-invoker-agent_, in other word, a separate repo; this definitely makes the project fractionized. Therefore, I vote for using scala-based implementation on InvokerAgent.

Regardless which one to be reused, InvokerAgent is not the main target I'm going to verify it. Use it is fined here, currently.

Basic functionalities of InvokerAgent:

* **Suspend**: suspend/pause a specific container. 
  
GET  _http://whisk.agent.host/suspend/container_

Will return status 204 on success and 500 on failure.

* **Resume**: resume a specific container.

GET  _http://whisk.agent.host/resume/container_

Will return status 204 on success and 500 on failure.

* **Log**: read container logs and collect to a log sink file, and return back with JSON structure.

GET _http://whisk.agent.host/log/container_

Will return status 204 on success, 500 on general failure and 400 on log parsing failure.

These operations are all done by HTTP routes; but not enough here. The original pause/resume only implemented via docker commands, which isn't performant. Same as docker usage in original Invoker docker implementation, we need the optimization by using runc here.

Overall, adjust these into an extended functionality:

Extended suspend/resume implementation.

<script src="https://gist.github.com/tz70s/42d023beb999ca7bcbb614065d48bf8f.js"></script>

<script src="https://gist.github.com/tz70s/f8d353c54f876735d039755ac08df3ab.js"></script>

That's all, there's only small changed from previous version; for more implementation detial, you can refer to [this branch](https://github.com/tz70s/incubator-openwhisk-deploy-kube/tree/refactor-invoker-agent).

## Demo

WIP

## Benchmarking & Profiling

WIP

## Conclusion

Something didn't implement/discuss in this post and experiment:

* Kubernetes: I only do prototyping for native (docker) side.
* Logging.
* Performance optimization on message queue.
* Tests.

WIP

## GSOC Conclusion

WIP.