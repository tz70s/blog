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

Something will not be included in this post and experiment:

* Kubernetes: I only do prototyping for native (docker) side.
* Throttling and Logging.
* ContainerManager backup.
* Performance optimization on message queue.

## Architecture recap

The [Future Architecture proposal](https://cwiki.apache.org/confluence/display/OPENWHISK/OpenWhisk+future+architecture) proposed by Markus Thommes integrated lots of communities' idea; play a great start to a new performant architecture.

## Steps to produce

Instead of prototyping from clean slate, I like more to establish from current codebase. It's quite more challenged, but take more advantages:

1. More accurate comparison on performance and architecture.
2. Help to explore the migration path.
3. Help me to better understanding on OpenWhisk internal implementation.

The prototyping steps as follow:

1. Cutting off invoker into container-manager and container-manager-agent.
2. Move some logics (sharding scheduler) from loadbalancer into container-manager.
3. Implement required changes.

I'll discuss these in detail below.

For cleaner naming convention, I've renamed some words from proposal, here's the mapping:

1. Container Management Agent -> WhiskAgent
2. Container Manager -> WhiskScheduler

## Whisk Agent

Prior on Kubernetes deployment in OpenWhisk, it already has an invoker-agent do some similar jobs (pause, resume and log); and hence works fine for me with some basic refactoring. 

However, this may not meet OpenWhisk requirements: 

1. One siginificant bottleneck and many folks concerned: **activation log**. We already had plenty of log store implementation, i.e. elasticsearch, docker file, etc. In general, we should not pass logs from whisk agent back to either Controller or Whisk Scheduler. Instead, directly store activation log into log store. Therefore, we can and we should reuse the codebase from implemented log store.

2. Better **integration**: Go has it's own workspace and directory convention ($GOPATH). It's neccessary if need a mature dependency management, i.e. dep. By convention, we might locate it into some kind of path: _github.com/apache/incubator-openwhisk-whisk-agent_, in other word, a separate repo; this definitely makes the project fractionized. Therefore, I vote for using scala-based implementation on WhiskAgent.

Regardless which one to be reused, WhiskAgent is not the main target I'm going to verify it. Use it is fined here, currently.

Basic functionalities of WhiskAgent:

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

That's all, there's only small changed from previous version; for more implementation detial, you can refer to [this branch](https://github.com/tz70s/incubator-openwhisk-deploy-kube/tree/refactor-invoker-agent).

## Whisk Scheduler

The WhiskScheduler is responsible for handling controller resource requisitions, monitoring and (partially) mangaging containers' lifecycle. 
In the overall design, it's similar to most logic from prior Invoker, but without pause/resume operations.
As I mentioned, I didn't deal this with Kubernetes. However, the approach may be similar and much simpler. Further, the new open source knative project might make the architecture further changed to adapt with Kubernetes.

### Whisk Agent Proxy

The WhiskAgentProxy is an actor which similar to original InvokerSupervision in loadbalancer and we move this here.
But the internal jobs are totally different, since we can **check the health state via docker/kubernetes**, instead of ping/pong via customized protocol (handshake above kafka, previously). In other words, we can monitor nodes health via Kubernetes (simple!); and we can get a live lists of running/non-running container states from docker daemon hence ensuring the node is up.

The approach will be distincted by two orchestration choices: Kubernetes and Native (Docker).

1. **Kubernetes**:
Basically, we just call kubernetes api server with 1 to 1 mapping, it'll deal with all scheduling, health check and so on. Hence, WhiskAgentProxy has only one instance, in this case.

2. **Native(Docker)**:
Contrast to indirectly calls in Kubernetes, in the native way, we'll have to deal everything by us. Quite similar to InvokerSupervision approach, the WhiskAgentProxy will have M to M supervision, but checking liveness via docker daemon checks.

Here's the signature and protocols in Native approach, full code can be found at [here]()

### Whisk Scheduling

Cutting logics from ShardingLoadBalancer, with simple sharding mechanism.

WIP

## Controller

WIP

### Container Factory Protocol

The protocol between Controller and WhiskScheduler.

In order to maximize performance, the container creation/deletion protocol is implemented via akka message passing. Protocol can be looked like this:

<script src="https://gist.github.com/tz70s/a15c32c59f17b3f4034275566484759c.js"></script>

## Demo

WIP

## Benchmarking & Profiling

WIP

## Conclusion

WIP

## Feedback to Community

WIP

## GSOC Conclusion

WIP.