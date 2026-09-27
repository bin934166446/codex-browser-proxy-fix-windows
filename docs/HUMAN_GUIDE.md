# 人类阅读版：为什么这个修复有效？

## 一句话解释

你的 Codex 主程序能联网，不代表 Codex 里面负责“控制浏览器”的那个 Node 子进程也能联网。

当这个子进程直连外网失败、又没有继承你本机的代理时，最外层很可能只看到：

```text
nodeRepl.fetch request failed
```

## 为什么 Chrome/Edge 都会一起坏？

因为 Chrome/Edge 只是被控制对象。真正发起浏览器控制请求的是 Codex 的 CUA / Node 运行时。如果公共的控制层联网失败，换 Chrome、Edge、重装扩展都可能无效。

## 为什么补丁里既有 PROXY 又有 NO_PROXY？

公网请求需要走代理：

```text
HTTP_PROXY
HTTPS_PROXY
```

但本地控制链，例如 `localhost`、`127.0.0.1`、`::1`，应该继续直连，所以需要：

```text
NO_PROXY=localhost,127.0.0.1,::1
```

## 为什么一定要 `NODE_USE_ENV_PROXY=1`？

因为现代 Node.js 提供了内置环境代理支持。开启后，Node 会读取 `HTTP_PROXY`、`HTTPS_PROXY` 和 `NO_PROXY`。

只写 `HTTP_PROXY` 而运行时不启用相应代理支持，在某些版本/调用链里并不足以让 `fetch()` 实际走代理。

## 为什么要完全退出 Codex？

补丁影响的是启动 CUA/Node 控制进程时的环境。如果旧进程还活着，它不会自动重新读取你刚修改的启动脚本。

## 为什么更新后可能复发？

Codex 会把运行时放在带版本/哈希 ID 的目录中。更新后可能生成新的 Runtime，旧 Runtime 的补丁自然不会应用到新路径。

这也是为什么脚本每次都重新定位当前 Runtime，而不是把某个固定路径写死。
