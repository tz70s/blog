+++
title = "Use Scala.js with OpenWhisk"
date = "2018-07-22"
slug = "use-scalajs-with-openwhisk" 
tags = []
categories = []
+++

Use your favorite language in OpenWhisk faster.

Recently, I've explored using Scala.js for lightweight tooling and small prototypes. Scala.js is a transpiler to Javascript in a type-safe and elegant way. It gave me excellent experiences and currently close to 1.0 version for maturity.

By inspiration from [gcf-scalajs](https://github.com/2m/gcf-scalajs.g8), an scala seed template for generating serverless function on google cloud function. Although this is still far from production-based serverless function, i.e. web action (in OpenWhisk word), we may already see some potentials provided there.

* Type-safe (it's not really type-safe in this template, b.c. using lots of dynamic type in Scala.js)
* Continous build and execution with sbt.

How about running in OpenWhisk nature? Let's experiment!
