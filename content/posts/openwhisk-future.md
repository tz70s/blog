+++
title = "OpenWhisk performance improvement"
date = "2018-07-24"
slug = "openwhisk-performance-improvement" 
tags = []
categories = []
+++

OpenWhisk community is nowadays getting more consistent on the new design of architecture for performance improvement. The **future architecture** of OpenWhisk requires large internal breaking changes. To fill the gap from idea into smooth migration, there might be helpful if a mid ground exist to clear more issues. Hence, I've worked on prototyping performance improvement in real, but not that comprehensive though. However, hope this prototype hold a place for deeper discussion and discover all issues might meet in the future. 

This post will have two kinds of target audiences, OpenWhisk community, GSoC mentors and reviewers:

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

1. A New LoadBalancer SPI: SingletonLoadBalancer.
2. Container Manager who manages container resources.
3. Re-use and refactor invoker-agent which is used by Kubernetes deployment.
4. In-detail implementation.

I'll discuss these in detail below.

For cleaner naming convention, I've renamed some words from proposal, here's the mapping:

1. Container Management Agent -> InvokerAgent
2. Container Manager -> Scheduler

## Controller

Most of Controller logic and programming semantics will not be changed, except for LoadBlancer. I've created a new LoadBalancer implementation in [future package](https://github.com/tz70s/incubator-openwhisk/tree/whisk-future-rebase/core/controller/src/main/scala/whisk/core/loadBalancer/future) and can be simply loaded with SPI infra. I've not done the protocols with multiple Controllers, there's still some problems need to clarify that I'll point out below.

The overall LoadBalancer design:

圖

In words, the roughly workflow as following:

1. Call publish activation
2. Check if there's a warmed action existed, by looking up local container list.
3. If yes and if it's belong to owned, http call for it. (Else, redirect to another controller with carrying http client context.)
4. If not, queue in OverflowProxy and put the activation in the overflow queue.
5. Request for new resource, via proxy actor (sub actor in OverflowProxy actor) to Scheduler singleton.
6. After scheduler singleton's response arrived, update local container list (which generated via scheduler).
7. If it's belong to owned, http call for it. (Else, redirect to another controller with carrying http client context.)

The code module contains:

#### Singleton LoadBalancer

SingletonLoadBalancer implements LoadBalancer trait for SPI infra. Contrast to prior ShardingContainerLoadBalancer, we'll contain nothing about scheduling logic; it'll simply look up and pass requests. When a request come in, it'll lookup container lists, which contains some context related to container and in-flight concurrent requests. There will be some larger value once concurrent activation processing got finished, but current, the in-flight concurrent request can be only 0 or 1. That is, if a request reach 0 concurrency value, it reuse the existed free container and send request into ContainerProxy, or else, it'll send message to OverflowProxy for resource requisition.

<script src="https://gist.github.com/tz70s/1223bdb0e61543ece861e306c9fb50ca.js"></script>

#### Overflow Proxy

Once OverflowProxy get message, it'll queue into Overflow Buffer. I didn't take external shared queue here, which many folks may concerned. But for Controller HA mode, it'll be required and can open up work-stealing capability. Anyway, the current implementation when receiving OverflowActivationMessage, queue in OverflowBuffer with some sendor and tracing context, and proxy to SingletonScheduler; and once it gets back with ContainerAllocation message, it'll pipe back to SingletonLoadBalancer.

#### Container Proxy

ContainerProxy is similar to prior invoke one, but I'll only manage with Suspend/Resume states and face to a warmed container. Therefore, the mission on ContainerProxy will operate suspend/resume (depends on pauseGrace settings) and call /run route of containers. Finally, pipe back result to SingletonLoadBalancer.

I've done this via Akka FSM module as previous did. There might be unreliable and not performant (i.e. use pause/unpause to avoid causing terminated when handling requests, or we need to introduce some synchronized value here); but using actor and FSM is nice here that we can hold states for remote containers.

#### ShareStates Proxy

Concerned some proposal didn't mention, the real Scheduling algorithm; We don't have any workload-dispatch related logics in Controller side, and make Scheduler holds all logics. However, what states Scheduler should know?

Consider building the prior busy/free/prewarmed pooling model:

* How do we know that which Container is busy and which is free?
* How do we know that which Container is safe to delete and notify deletion?

ShareStatesProxy do this: when Container gets pause/suspend, it'll notify Scheduler that container is busy or free. Once a deletion is being taken, it'll choose up from free pool (see more in Scheduler section) and notify back with ShareStatesProxy. Hence, ShareStatesProxy take an eval sharable container lists (actually a TrieMap) for updating and sharing with main SingletonLoadBalancer.

#### Container Factory Protocol

Overall for interacting with Scheduler, the messages between Controller and Scheduler. You can see that the relations between Controller and Scheduler.

In convenient, I've used Akka message passing, but this might not be ideal.

<script src="https://gist.github.com/tz70s/a15c32c59f17b3f4034275566484759c.js"></script>

## Scheduler

The Scheduler is responsible for handling controller resource requisitions, monitoring and (partially) mangaging containers' lifecycle. 
In the overall design, it's similar to most logic from prior Invoker, but without pause/resume operations.
I didn't deal this with Kubernetes. However, the approach may be similar and much simpler. Further, the new open source knative project might make the architecture further changed to adapt with Kubernetes.

To guarantee strong consistency for container selection in controller. The scheduler will be (contains) a cluster singleton to resolve container selection. [Akka cluster singleton](https://doc.akka.io/docs/akka/2.5.14/cluster-singleton.html) is introduced here: ClusterSingletonManager will sits in Scheduler and ClusterSingletonProxy will sit in both Controller and Scheduler to access the singleton. You can checkout the doc for usage and [here's my example with less noise](https://github.com/tz70s/cluster-singleton-ex) compared to Akka provided, which contains a basic singleton and proxy setup with migration observation guide. This enabled us to use with some convenience, i.e. failure recovery, message buffering, etc.

### Container Pool Model

Basically, I didn't change the model of container pool: busy/free/prewarm model. Simply review on this model with additional context introduce from new LoadBalancer design:

1. Once the scheduler start, it'll create prewarm containers (via stem cell config).
2. A new request come in, it'll first match if there is a free and warmed container.
3. If yes, take it.
4. If not, match the prewarm with structural matching (kind, mem, etc.); If yes, take it.
5. If not, checkout there's enough slots, if yes, create one and take it.
6. If not, remove one container from free pool, create new one and take it.
7. Else, all containers are busy, we'll reject this request.

The free and busy states are notified via ShareStatesProxy we have described above, caused by Container's suspend and resume.

<script src="https://gist.github.com/tz70s/c7be15f3ce5ebc7d92d3846d4de42e60.js"></script>

The algorithm is definitely not optimal, but we can first leave out previous problem: invokers have no visibility with each other.

### Container Orchestration 

The approach will be distincted by two orchestration choices: Kubernetes and Native (Docker).

1. **Kubernetes**:
Basically, we just call kubernetes api server with 1 to 1 mapping, it'll deal with all scheduling, health check and so on. Hence, InvokerAgentProxy has only one instance, in this case.

2. **Native(Docker)**:
Contrast to indirectly calls in Kubernetes, in the native way, we'll have to deal everything by us. Quite similar to InvokerSupervision approach, the InvokerAgentProxy will have M to M supervision, but checking liveness via docker daemon checks.

Here's the signature and protocols in Native approach, full code can be found at [here]()

There might be two potential problems on using cluster singleton:

1. Perfromance bottleneck: **WIP**

2. Single point of failure: akka cluster singleton will automatically migrate to another scheduler node (actor-system) once the leader (oldest) getting down. This will result in short downtime, but it can be afford to us however, the ClusterSingletonProxy will buffer messages until the new singleton is up; the latency is overall make sense b.c. this is not actually the performance critical path.

**In order to do direct http calls, how can we reach warmed container after NAT environment?**

In Kubernetes network model, the ip-per-pod model is flattened and we can easily work without this problem. But to the native mode, the warmed containers required some mechanisms to resolve with NAT environment.

There are some potential ways:

1. Use InvokerAgent as a reverse proxy: this will take some additional benefits => reduce the calls after pause/resume, since Controller will no longer managed any Container's lifecycle. However, this is quite similar to prior Invoker, may gain some latency here.

2. Forced user to use somewhat overlay/underlay network policy, to reach a similar model in Kube.

3. Port-forwarding once creation.

Obviously, it's arbitrary and not applicable for option 2. I choose 3 from now.

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

## Discussion

#### Issues
**It's neccessary to provide a strong consistency (warmed) container lists to be kept in each controller, how do we deal with this?**

A basic thinking: we can keep only owned container lists in each in-memory store and lookup Scheduler for redirecting calls every time. But this will not only lead to additional latency between Controller and Scheduler, it can be easier to let Scheduler reach performance bottleneck.

What if we keep others record? Obviously, this will lead to in-consistent, and how do we update this?

It's pretty sure we can't make all these cache synchronized when lists get updated, it'll required large performance penalty on blocking.

To achieve this, we can only **make it in-consistent at some point; but we'll not execute once if there's inconsistent.** Iff one Controller redirect to another, we'll add timeout and retry if another Controller was offline, or using akka Cluster Event can also update this. Then we'll ask Scheduler for a new consistent list. Iff the redirect Success but not belong to itself? The in-consistent occurred, this may happened to event ordering (imagine one Controller ask for resource and Scheduler allocate to another Controller, and update list to them, the event ordering can't be guarantee here). In this case, the redirected Controller will ask again for Scheduler, and repeat the process untill it find the correct warmed container.

What about the number of Controller will receive the updates once Scheduler decide it? It's better make it with limit ranges/groups for updates to make Scheduler less burden. **WIP**


**How do we deal with overflow messages?**

There's no consistent here due to the unbounded topics problem. **WIP**


Something didn't implement/discuss in this post and experiment:

* Kubernetes: I only do prototyping for native (docker) side.
* Logging.
* Performance optimization on message queue.
* Tests.

WIP

## GSOC Conclusion

WIP.