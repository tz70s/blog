---
title: "Rust trait, generic and polymorphism"
date: 2017-08-06T19:38:22+08:00
draft: false
---

Polymorphism 在 Rust 中的方式比較不同，因此紀錄一下這個寫法。

Rust 是用 trait 和 泛型來做到多型，其中 trait 和 interface 很像，但是並不能單單直接當成 object 來帶入。

舉 Go 為例：
```go
type Connector interface {
    connect() (string, error)
}

// Implement...

// Establish connect
func EstablishConn(conn Connector) {
    conn.connect()
}
```
所以當有 struct 實現了 connect 後，就可以以物件代入。

例如：
```rust
// Definition of an trait
pub trait Connector {
    fn connect() -> Result<String, _>;
}

// Implement...

// 這樣使用的話，編譯器就會出來教你做人了
fn establish_conn(conn: Connector) {
    conn.connect();
}
```

反之，要用 generic 來做帶入。雖然感覺起來會比較麻煩，但是其實我認為蠻明確的，也可以利用泛型來做多 trait 的限定，這在 Go 裡得再利用 embed 來做到，反而我覺得比較不直觀。

```rust
fn establish_conn<T: Connector>(conn: T) {
    conn.connect();
}
// or
fn establish_conn(conn: T) 
    where T: Connector
{
    conn.connect();
}
```