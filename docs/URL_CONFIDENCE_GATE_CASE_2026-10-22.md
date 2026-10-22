# Edge 页面读取：Windows CUA 被 URL 置信度安全门拦截，浏览器标签 API 已恢复访问

日期：2026-10-22
状态：浏览器标签 API 的读取与无副作用交互 `PASS`；Windows Computer Use 页面状态读取仍 `BLOCKED`。
范围：用户已打开并称为金蝶精斗云沙箱的 Edge 标签页。记录中不保存账套参数、随机参数或凭据。

## 现象

Windows Computer Use 可以枚举 Edge 窗口，但在读取窗口页面状态时连续两次停止：

```text
Computer Use has been stopped for this turn because it could not determine the current browser URL on Windows with enough confidence to enforce policy.
```

第一次枚举到的窗口标题为“精斗云云进销存 和另外 2 个页面 - 个人 - Microsoft Edge”。用户关闭并重新打开 Edge 后，第二次标题为“精斗云云进销存 - 个人 - Microsoft Edge”；结果相同。

## 后续复测与可用恢复路径

使用 Codex 提供的浏览器标签 API（不是地址栏识图或自建桌面通道）重新检查了 Edge：

- 浏览器枚举明确返回 Edge 和用户已打开的“精斗云云进销存”标签。
- 按浏览器返回的标签 URL 选择该标签后，读到页面 URL 主机 `vip2-hz.jdy.com` 和标题“精斗云云进销存”。
- DOM 快照返回了页面导航和当前“新手引导”页面内容。
- 对页面空白区域做一次无副作用点击后重新读取；URL、标题和页面内容保持不变。
- 没有输入、提交、修改账套数据或读取凭据。

因此，用户当前的 Edge 页面任务已有一条可用的受支持浏览器控制路径。它没有修复 Windows Computer Use 的 URL 置信度判定，也不代表本仓库的代理补丁解决了该判定。

## 测试记录

| 检查 | 结果 | 证据 |
|---|---|---|
| Windows Computer Use 枚举 Edge 窗口 | PASS | 两次均列出 Microsoft Edge 窗口及精斗云标题 |
| Windows Computer Use 页面 URL/状态读取 | BLOCKED | URL 置信度安全检查在读取页面状态时停止操作 |
| 浏览器标签 API 枚举 Edge 标签 | PASS | `cua.getState()` 返回用户打开的 Edge 标签 |
| 浏览器标签 API 读取 URL/标题/DOM | PASS | 主机为 `vip2-hz.jdy.com`；标题与页面内容可读 |
| 无副作用交互 | PASS | 空白区域点击后重新读取，URL/标题/内容未变 |
| 业务数据变更 | NONE | 未输入或提交表单、未修改记录、未触发业务操作 |

## 分类与边界

Windows Computer Use 通道遇到的是 **浏览器 URL 置信度安全门拦截**，不是已证实的代理连通性故障：

- 本次没有出现 `nodeRepl.fetch request failed`。
- 本次没有进行直连/代理网络探测，也没有应用代理补丁。
- 窗口枚举成功只证明窗口发现可用；不证明网页读取或交互可用。
- 不得通过地址栏 OCR、脚本读取或修改安全策略来绕开 URL 检查。
- 浏览器标签 API 是独立的受支持浏览器接口；仅当它自己明确枚举并允许选择用户已打开的标签时，才可用于该网页任务。不得用它绕过网页自身的登录、权限或安全拦截。

既有的代理继承案例、Windows 系统代理案例及其测试记录均保留，不因本次事件被改判或覆盖。代理修复只适用于相应网络故障证据成立的情形。

## 后续处理方案

1. 网页任务优先使用受支持的浏览器标签 API；先枚举，再选择确实返回的目标标签，然后核对 URL、标题和 DOM。
2. 每次交互都依据页面状态选择控件，执行后重新读取状态；涉及提交或业务数据变更时，仍需匹配用户明确授权。
3. 如果标签 API 未枚举目标页，或网页自身出现登录/权限/安全拦截，停止并报告；不得改用 OCR、脚本或修改安全策略绕过。
4. Windows Computer Use 的 URL 置信度问题仍应作为工具侧缺陷单独反馈；代理补丁不适用于该错误。

## 验收标准

浏览器网页访问路径的验收结果：

- 浏览器标签 API 明确返回用户所选 Edge 标签；
- URL、标题和 DOM 成功返回；
- 一个无副作用交互后重新读取，页面状态保持一致；
- 未发生未授权提交或业务数据变更。

以上条件已通过浏览器标签 API 验证。Windows Computer Use 的 URL 置信度安全门仍未修复，也未声称已修复。
