+++
title = "Local Mac OSX Setup for Engineering Data"
date = "2018-08-20"
slug = "local-mac-setup-for-data-engineering" 
tags = []
categories = []
+++

紀錄本地端 Mac 對 Hadoop Ecosystem 相關開發的設定。

# Hadoop

Homebrew 

以 brew 安裝後，會有安裝的 location 和方便使用的 script (`start-all.sh`) 的位置是需要 tuning 的，基本上設定為 [Pseudo Distributed](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SingleCluster.html) 的模式。

* `/usr/local/Cellar/hadoop/<version>/libexec/etc/hadoop`: configuration files (xml files)，設定參考官網即可。
* `/usr/local/sbin`: symlink 的 start-up, tear-down scripts。

所以基本上每次要重開的時候都 refer 到 `/usr/local/sbin` 找 script 來把 daemon 打開 (e.g. hdfs, yarn, etc.)
然後預設的 Web UI 介面的位置為：

* Name Node: http://localhost:9870/
* Resource Manager: http://localhost:8088/

# Spark

Spark 基本上本地開發就直接 Link Library 即可，沒特別需要把 build 好的 package 撈下來，以 test driven 的方式 + interactive SBT 是最佳模式。
需要注意的點為有些版本 (Scala or JVM) 會不相容，注意一下主線的需求版本。

另外，Spark Executor 在 SBT 跑完後會出現殺不掉的問題，因為兩個跑在同一個 JVM 上，注意一下將 fork apply 到所有 sbt tasks 中：

```scala
fork := true

// Or specify some tasks, but not recommended.
fork in run := true
```