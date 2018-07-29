+++
title = "OpenWhisk performance improvement"
date = "2018-07-24"
slug = "openwhisk-performance-improvement" 
tags = []
categories = []
+++

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

We'll discuss these below.

## Container Management Agent

WIP

## Container Manager

WIP

## Controller

WIP