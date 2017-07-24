---
title: "Go & Makefile"
date: 2017-06-06T19:38:22+08:00
draft: false
---
現在還是蠻多專案利用 Makefile 來做 go 的編譯、安裝、測試，由於 go 有 GOPATH 的問題，在設定上如果有用 Makefile 來幫助的話方便許多。

大致寫法跟以前寫 C/C++ 的 Makefile 沒什麼分別，只是把 gcc, g++ 等編譯器換成 go tool ，如：

```makefile
# Set the output file name
OUTPUT = gomn

# Build binary
.PHONY: build
build:
	@go build -o $(OUTPUT)

# Install pkg
.PHONY: install
install:
	@go install

# Clean up
.PHONY: clean
clean:
	@if [ -f $(OUTPUT) ]; then rm $(OUTPUT); fi

```

但有一些有趣的部分，可以 pass variable 到 Go 的 runtime 中，不確定 C/C++ 有沒有，但至少以前沒看過。

* **Sample Go**

```go
package main

var (
    Version string
    Commit string
)
```

利用 `-ldflags -X` 就可以把 variable 傳進去 `importpath.name=value`

* **Sample Makefile**

```makefile

# Set the output file name
OUTPUT = gomn

VERSION = 1.0.0
COMMIT = First build

# Set LDFLAGS
LDFLAGS = -ldflags "-X main.Version=$(VERSION) -X main.Commit=$(COMMIT)"

# Build binary
.PHONY: build
build:
	@go build $(LDFLAGS) -o $(OUTPUT)

# Install pkg
.PHONY: install
install:
	@go install

# Clean up
.PHONY: clean
clean:
	@if [ -f $(OUTPUT) ]; then rm $(OUTPUT); fi

```

然後 markdown 也有 `makefile` 的 syntax highlight!
## 挺神奇的
**記錄一下**
