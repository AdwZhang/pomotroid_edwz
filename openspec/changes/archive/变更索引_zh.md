# OpenSpec 变更归档索引（中文）

本文件汇总了 `openspec/changes/archive/` 目录下所有已归档的变更记录。每个变更代表一次功能开发的完整 spec 修改。

---

## 变更时间线

| 日期 | 变更名称 | 涉及的 Spec 模块 |
|------|---------|-----------------|
| 2026-02-26 | 自动浅色和深色模式 | theme-mode |
| 2026-02-27 | 添加本地化 | settings, localization |
| 2026-02-27 | 构建版本 | build-version |
| 2026-02-27 | 日志记录到文件 | settings, diagnostic-logging |
| 2026-02-27 | 迷你控件 | mini-controls |
| 2026-02-27 | 整理默认值和重置 | settings |
| 2026-02-28 | macOS 快捷键 | shortcuts, macos-shortcuts |
| 2026-03-01 | 统计可视化 | statistics |
| 2026-03-03 | 计时器设置键盘输入 | timer-duration-keyboard-entry, settings |
| 2026-03-04 | Linux 代码签名 | linux-package-signing |
| 2026-03-04 | Mona Sans 字体 | variable-font-typography |
| 2026-03-04 | WebSocket 计时器事件 | websocket-protocol |
| 2026-03-05 | 托盘计时器控件 | tray-timer-controls |
| 2026-03-05 | 土耳其语支持 | localization |
| 2026-03-11 | 自动更新 | autoupdate, settings |
| 2026-03-13 | 清除计时器事件和数据管理 | settings, session-history-management |
| 2026-03-14 | 全局快捷键开关 | shortcuts, settings |
| 2026-03-16 | 可选休息 | timer-sequence, settings |
| 2026-03-26 | UI 工具提示 | tooltips, localization |
| 2026-03-29 | 主题选择重设计 | theme-selection-ui, theme-mode |
| 2026-04-02 | 本地快捷键 | shortcuts, local-shortcuts |
| 2026-04-26 | 记忆窗口位置 | window-position, settings |

---

## 变更详情

### 2026-02-26: 自动浅色和深色模式
- 引入三态主题模式（auto/light/dark）
- 添加独立的浅色/深色主题选择
- 实时响应操作系统配色方案变更

### 2026-02-27: 添加本地化
- 引入 Paraglide JS v2 消息目录
- 支持 8 种语言（en, es, fr, de, ja, zh, pt, tr）
- 自动语言检测和手动覆盖
- 设置中添加语言选择

### 2026-02-27: 构建版本
- 编译时从 git 信息生成 semver 版本字符串
- 通过 IPC 命令暴露版本
- 设置 → 关于中显示版本
- 启动时记录完整提交 SHA

### 2026-02-27: 日志记录到文件
- 持久化日志写入 OS 常规目录
- 5MB 轮转限制，保留一个归档
- 所有 Rust 错误路径插桩
- JS 端日志转发到同一文件
- 设置 → 关于中的"打开日志文件夹"

### 2026-02-27: 迷你控件
- 紧凑模式（<300px）下显示精简控件行
- 重启/播放暂停/跳过三个图标按钮
- 独立于表盘缩放的固定尺寸

### 2026-02-27: 整理默认值和重置
- 重置所有设置移至设置 → 系统
- 两步内联确认模式
- 重置清除所有 26 个键和自定义提示音

### 2026-02-28: macOS 快捷键
- macOS 辅助功能权限检测
- 快捷键设置中的权限提示
- 窗口获焦时重新检查权限状态

### 2026-03-01: 统计可视化
- 专用统计窗口（820×540）
- 三标签导航：今天/本周/全部时间
- 今天：统计卡片 + 逐小时时间线
- 本周：每日柱状图 + 连续天数
- 全部时间：年度热力图 + 终身总计
- 实时响应计时器事件

### 2026-03-03: 计时器设置键盘输入
- 时长徽章可编辑为 MM:SS 输入框
- 支持 MM:SS 和纯整数分钟格式
- 有效范围 1:00-90:00，无效输入回退
- 滑块和徽章保持同步
- 空闲时表盘立即反映新时长

### 2026-03-04: Linux 代码签名
- CI 中对 .deb/.rpm/.AppImage 进行 GPG 签名
- 签名文件随 Release 分发
- 公钥提交到仓库
- SECURITY.md 验证说明

### 2026-03-04: Mona Sans 字体
- 嵌入 Mona Sans 可变字体为主要字体
- 启用光学尺寸自动适应
- 快捷键显示使用 Mona Sans Mono

### 2026-03-04: WebSocket 计时器事件
- 新增 started/paused/resumed/reset 广播事件
- 不破坏现有 roundChange/state 协议
- 无客户端时静默丢弃

### 2026-03-05: 托盘计时器控件
- 托盘菜单添加切换/跳过/重置轮次
- 切换标签反映计时器状态
- 空闲时禁用跳过和重置

### 2026-03-05: 土耳其语支持
- 添加土耳其语（tr）到支持的语言列表
- 所有 i18n 键的土耳其语翻译

### 2026-03-11: 自动更新
- latest.json 清单 + Ed25519 签名
- check_update / install_update 命令
- 设置 → 关于中的更新 UI
- check_for_updates 开关

### 2026-03-13: 清除计时器事件和数据管理
- sessions_clear 命令清除所有会话历史
- 设置 → 系统中的"数据"子部分
- 两步确认的清除会话历史操作
- 关于部分不再包含破坏性操作

### 2026-03-14: 全局快捷键开关
- global_shortcuts_enabled 设置（默认 false）
- 启用/禁用立即注册/注销快捷键
- 禁用时快捷键字段不可编辑

### 2026-03-16: 可选休息
- short_breaks_enabled 设置（可独立禁用短休息）
- long_breaks_enabled 设置（可独立禁用长休息）
- TimerSnapshot 携带 previous_round_type
- 上下文感知的工作通知
- session_work_count 跨循环计数器

### 2026-03-26: UI 工具提示
- 可复用 Tooltip.svelte 组件
- TooltipInfo.svelte 信息图标组件
- 计时器窗口 7 个控件的工具提示
- 设置窗口 3 个设置的信息图标
- 所有语言的工具提示 i18n 键

### 2026-03-29: 主题选择重设计
- 可折叠手风琴式主题选择器
- 触发行预览（主题名 + 色彩色块）
- 活跃模式指示器
- 选中主题勾选标记
- 交互隔离（不意外改变主题）

### 2026-04-02: 本地快捷键
- 7 个窗口聚焦时的本地快捷键
- 默认绑定：Space/方向键/m/F11
- 音量增减/静音/全屏等动作
- 设置中可重新映射
- 重置恢复默认绑定

### 2026-04-26: 记忆窗口位置
- 移动/调整大小时持久化位置和尺寸
- 启动时恢复窗口位置
- 验证保存位置是否在当前显示布局中
- 显示器断开时回退到默认位置
- 重置所有设置时清除几何键
