---
title: "Git sync upstream"
date: 2017-06-04T19:38:22+08:00
draft: false
---
記一下 git 與 upstream sync 的操作。

1. 查看目前與 remote(upstream) 來源
```bash
git remote -v
```

2. 預設應該只會有 origin 這個 remote
```bash
origin https://github.com/user/repo.git (fetch)
origin https://github.com/user/repo.git (push)
```

3. 加入 upstream 來源
```bash
$ git remote add upstream https://github.com/otheruser/repo.git
# checkout
$ git remote -v
```

4. 切到要更新的 branch
```bash
git checkout master(<branch>)
```

5. Pull upstream
```bash
# 順便做 rebase
$ git pull --rebase upstream master
```

6. 更新自己的 remote fork
```bash
$ git push origin master
```

**記錄一下**
