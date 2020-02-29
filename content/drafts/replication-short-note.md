+++
title = "Replication Short Note"
date = "2018-09-07"
slug = "replication-short-note"
tags = []
categories = []
+++

This is a short note for replication on distributed system.

The content is only noting replication mechanism and any sort of consistency problems,
but without introducing comprehensive strong/eventual consistency & conflict resolution mechanism.

Can refer to the book Designing Data-Intensive Application for more details.

The consistency models/guarantees can refer to [this site](https://jepsen.io/consistency).

## System Model

Before understanding any circumstances/problems occurred in replication, we need to clearly identify the system models we're using, and actually following three types cover all possibilities in distributed system world.

* **Master-Slave Architecture**: master-slave architecture is the most widely used architecture (and can be extended to further stronger model), including MySQL, etc., the master is responsible for writing data, and user can choose to read data from master or slaves. The replication mechanism is basically synchronizing data from master to slaves.

* **Multi-Masters Architecture**: multi-masters architecture in general is built for serving system/data geographically, for reducing latencies and also providing disaster handling if any data centers is broken, e.g. CouchDB, etc. Each master can accept writes, and they all have regional slaves for read, the synchronizations between them are typically expensive due to the high network cost (and also unreliable).

* **Decentralized Architecture**: 

## Types of Replications

Consider Client C perform a write to any backend data system, when should the backend data system responding back to client if a write success or not?

* **Synchronous Replication**: respond to client when all replication are writing into slaves, via acks from slaves.

* **Asynchronous Replication**: respond to client when master perform the write, but without waiting replication to slaves.

* **Semi-Synchronous Replication**: respond to client when master perform the write, but ensuring part of slaves have done the write, part of slaves haven't. This is useful when you need to ensure part of slaves can be handover when master crashed without any lags.

