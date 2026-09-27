# Codex Windows 浏览器 `nodeRepl.fetch request failed` 代理修复

这是一个面向 Windows Codex / ChatGPT Desktop Browser Use 的社区修复项目。

典型故障：Chrome、Edge 或浏览器扩展看起来正常，但 Codex 一读取标签页、执行 `cua.getState()` 或读取网页内容，就报：

```text
nodeRepl.fetch request failed
```

本项目整理的是其中一种已实机验证的根因：**Codex CUA 的 Node 浏览器控制运行时没有正确继承本机代理，导致 Node 对外请求直连失败。**

> 这不是 OpenAI 官方修复，也不是所有同名报错的通用答案。Codex 更新后运行时可能被替换，需要重新检查。

## 适用特征

如果你的情况同时满足下面几项，这个方案值得优先验证：

- Windows Codex Desktop；
- Chrome / Edge 已安装，扩展也正常；
- Native Messaging 或基础 Computer Use 管道正常；
- `cua.getState()` / 列标签页 / 读页面时报 `nodeRepl.fetch request failed`；
- 本机使用 Xray、Clash/Mihomo、sing-box、V2Ray 等本地代理；
- 直连 OpenAI 相关地址超时，但通过本地 HTTP/mixed 代理可以收到 HTTP 响应。

## 原理

现代 Node.js 支持通过：

```text
NODE_USE_ENV_PROXY=1
HTTP_PROXY
HTTPS_PROXY
NO_PROXY
```

让 Node 的网络请求读取环境代理。

在已验证案例中，Codex 上层虽然能使用代理，但 CUA / `node_repl` 没有正确继承这些变量。将代理环境变量在 `cua_repl.launch()` 之前注入，使随后启动的浏览器控制子进程继承代理，完整重启 Codex 后恢复。

## 快速使用

### 1）先诊断，不要直接改

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\Diagnose-CodexBrowserProxy.ps1 -ProxyUrl http://127.0.0.1:10808
```

`10808` 只是示例。必须换成你电脑上真实的 **HTTP/mixed 代理端口**。

如果结果是：

```text
直连：超时/失败
代理：能收到 401 / 403 / 其他正常 HTTP 状态码
```

说明“CUA 需要显式走代理”这个方向很值得继续。

注意：401/403 只证明网络能到达服务器，不代表账号登录成功。

### 2）应用补丁

```powershell
.\scripts\Fix-CodexBrowserProxy.ps1 -ProxyUrl http://127.0.0.1:10808 -Apply
```

脚本会：

- 自动寻找当前 `unified-computer-use` 插件元数据；
- 自动寻找当前 CUA Runtime 的 `cua-repl.mjs`；
- 修改前自动做时间戳备份；
- 只在 `cua_repl.launch()` 前注入代理环境变量；
- 调用当前 Runtime 自带的 `node.exe --check` 做语法检查；
- 如果语法检查失败，自动恢复备份。

### 3）必须彻底退出 Codex 再打开

不能只新开对话。要把 Codex 主程序、托盘/后台进程彻底退出，再重新启动。

### 4）验收

至少依次验证：

```text
cua.getState()
Chrome 标签页枚举
Edge 标签页枚举
读取公开网页标题和正文
连续多次调用
```

真正恢复后才算成功。

## 为什么 `NO_PROXY` 单独设置没有用？

`NO_PROXY` 的作用是“哪些地址不要走代理”。

如果 Node 根本没有启用环境代理，那么单独写：

```text
NO_PROXY=localhost,127.0.0.1,::1
```

并不会让公网请求自动开始走代理。

关键是同时让 Node 使用环境代理：

```text
NODE_USE_ENV_PROXY=1
HTTP_PROXY=http://127.0.0.1:你的端口
HTTPS_PROXY=http://127.0.0.1:你的端口
```

同时保留：

```text
NO_PROXY=localhost,127.0.0.1,::1
```

避免本地 IPC / 浏览器桥接请求被代理出去。

## 更新后又坏了怎么办？

Codex 更新可能创建新的：

```text
%LOCALAPPDATA%\OpenAI\Codex\runtimes\cua_node\<新ID>\...
```

旧 Runtime 里的补丁仍然存在，但新版本已经不用旧路径，因此故障可能再次出现。

重新运行诊断和修复脚本即可。不要手工照抄旧的绝对路径。

## 回滚

```powershell
.\scripts\Restore-CodexBrowserProxyFix.ps1
```

## 修复思路出处 / 鸣谢

本修复思路来自公开抖音教程：

- **作者：灵感提示官**
- **抖音号：89687306917**

本仓库维护者**不是该抖音账号本人**，也不主张原始修复思路的首创权。本项目是在公开教程思路基础上，结合实机排障结果，重新整理成便于 GitHub / 搜索引擎 / AI 检索的文档、诊断流程、回滚说明和辅助脚本。

本仓库不转载原视频、不复制视频素材、不声称与原作者存在合作或授权关系。若原作者希望调整署名表述，可以提交 Issue。

## 已验证实机案例

本仓库不是只整理理论方法。2026-09-27 的实际 Windows 故障中，`cua.getState()` 持续报 `nodeRepl.fetch request failed`；直连 OpenAI 端点超时，而经本机 Xray `127.0.0.1:10808` 可收到 HTTP `401`。给当前 CUA Runtime 注入 Node 环境代理并完整重启 Codex 后，`cua.getState()`、Chrome 标签页读取和公开网页读取均恢复。详见 [docs/VERIFIED_CASE.md](docs/VERIFIED_CASE.md)。

## 安全说明

本方案不需要：

- 关闭 Windows 防火墙；
- 关闭杀毒；
- 关闭 TLS 验证；
- 导出浏览器 Cookie / Token；
- 删除 Chrome/Edge 用户数据；
- 关闭 Codex 沙箱。

只建议使用你本人信任和有权使用的本地代理。

## 技术参考

- Node.js 环境代理支持（`NODE_USE_ENV_PROXY` / `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY`）：https://nodejs.org/api/cli.html#--use-env-proxy
- Node.js Built-in Proxy Support：https://nodejs.org/api/http.html#built-in-proxy-support
- OpenAI Codex GitHub 中与本方案同类的 Windows/代理修复讨论：https://github.com/openai/codex/issues/44364
- 其他同样报 `nodeRepl.fetch request failed`、但根因可能不同的 Windows 报告：https://github.com/openai/codex/issues/47123
