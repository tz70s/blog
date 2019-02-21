+++
title = "Note on Algebraic Domain Modeling"
date = "2019-02-18"
slug = "algebraic-domain-modeling" 
tags = []
categories = []
+++

Algebraic 這個詞以中譯來講就是"代數(的)"，以前一直沒有認真理解這個形容詞帶給 application/business level 的關聯性以及跟一些 functional programming 裡設計的連貫性，
直到最近看了幾篇文章和 haskell from the first principle 有點感悟所以在這紀錄一下。

Functional programming 其實我個人認為阻擋多數 developer 深究的最大原因是動機這件事，學這件事情能對開發者/企業怎樣有幫助？難不難我倒認為是次要的事情。
最常見的傳教士起手式是：容易 reasoning code、ease on concurrency 等針對開發者的傳教手法。

Property(-based) testing (性質測試) 在 Scala 偏好 typelevel 的使用者中一般來說不會陌生 (ScalaCheck)，但我一直沒有去用過就是了，
雖然有 Functional Programming in Scala 裡有專門一個章節在講這個。

一般來說單元測試會去測試行為上的正確性，也盡力滿足各種 edge cases，也是大部分人熟悉的方式。

Informal definition: **Property tests test the formal properties of programs without requiring formal proofs by 
allowing you to express a truth-valued, universally quantified (that is, will apply to all cases) function.**

Example on validation:

<script src="https://gist.github.com/tz70s/ec22142cff52ec510e3a19abb9b17058.js"></script>