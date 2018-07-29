+++
title = "OpenWhisk performance improvement"
date = "2018-07-24"
slug = "openwhisk-performance-improvement" 
tags = []
categories = []
+++

**WIP**

OpenWhisk community is nowadays getting more consistent on the new design of architecture for performance improvement. To fill all the gaps from idea into implementation, there might be helpful if a mid ground exist to clear more issues. Hence, I've worked on prototyping performance improvement in real, but not that comprehensive though. However, hope this prototype hold a place for deeper discussion and discover all issues might meet in the future. 

Objectives:

* Draft as an experimental prototype of OpenWhisk future architecture, for knowing all issues might meet.
* Might be a place for discussion.

## Architecture recap

The [Future Architecture proposal](https://cwiki.apache.org/confluence/display/OPENWHISK/OpenWhisk+future+architecture) proposed by Markus Thommes integrated lots of communities' idea; play a great start to a new performant architecture.

## Steps to produce

Instead of prototyping from clean slate, I like more to establish from current codebase. It's quite more challenged, but take more advantages:

1. More accurate comparison on performance and architecture.
2. Help to clarify the migration path.
3. Help me to better understanding on OpenWhisk internal implementation.

The prototyping steps as follow:

1. Cutting off invoker into container-manager and container-manager-agent.
2. Move some logics (sharding scheduler) from loadbalancer into container-manager.
3. Implement required changes.

I'll discuss these below.

For cleaner naming convention, I've renamed some words from proposal, here's the mapping:

1. Container Management Agent -> WhiskAgent
2. Container Manager -> WhiskScheduler

## Whisk Agent

Previous at Kubernetes deployment, already has an invoker-agent do some similar things (pause, resume and log); and currently works fine for me with some basic refactoring. 

However, this may not be suitable to OpenWhisk requirements: 

1. One siginificant bottleneck and many folks concerned: **activation log**. We already had plenty of log store implementation, i.e. elasticsearch, etc. In general, we should not pass back logs from whisk agent back to either Controller or Whisk Scheduler, instead, directly store activation log into log store. Therefore, we can and we should reuse the codebase from implemented log store.

2. Better **integration**: Go has it's own workspace and directory convention ($GOPATH). It's neccessary if need a mature dependency management, i.e. dep. By convention, we might locate it into some kind of path: _github.com/apache/incubator-openwhisk-whisk-agent_; but this definitely makes the project fractionized. Therefore, I vote for using scala-based implementation on WhiskAgent.

Regardless which one to be reused, WhiskAgent is not the main target I'm going to verify it. Use it is fined here, currently.

Basic functionalities of WhiskAgent:

1. Pause: pause a specific container. 
  
GET  _http://whisk.agent.host/pause/container_

2. Resume: resume a specific container.

GET  _http://whisk.agent.host/resume/container_

3. Log: read container logs and collect to a log sink file, and return back with JSON structure.

GET _http://whisk.agent.host/log/container_

These operations are all done by HTTP routes; but not enough here. We should further support some health check with either container manager or controllers. Further, the original pause/resume only implemented via docker commands, with poor performance. Same as docker usage in original Invoker docker implementation, we need the optimization by using runc here.

Overall, adjust these into extended functionalities:

1. Extended suspend/resume implementation.
```Go
// Interface for polymorphic supports either docker suspend/resume or runc-based.
type SuspendResumeOps interface {
	Suspend(w http.ResponseWriter, r *http.Request)
	Resume(w http.ResponseWriter, r *http.Request)
}
```

2. Health check and states report, via route: 

GET _http://whisk.agent.host>/health_

This will return a list of current states of containers.

## Whisk Scheduler

WIP

### Whisk Agent Proxy

The WhiskAgentProxy is an actor which similar to original InvokerSupervision in loadbalancer. But we move this here.
WIP

## Controller

WIP

## Protocols

In this section, we'll discuss the internal protocol design in the new architecture.

### Container Factory Protocol

The protocol between Controller and WhiskScheduler.

In order to maximize performance, the container creation/deletion protocol is implemented via akka message passing. Protocol can be looked like this:

```Scala
object ContainerFactoryProtocol {

  /** Wraps an endpoint of container that controller can directly achieve. */
  case class ContainerEndpoint(id: ContainerId, address: ContainerAddress)

  /** Request a container with activation message for a more sophisticated decision. */
  case class RequestContainer(activeMsg: ActivationMessage)

  /** Return a list of warmed containers to a specific controller */
  case class ResponseContainerList(list: List[Container])
}
```

