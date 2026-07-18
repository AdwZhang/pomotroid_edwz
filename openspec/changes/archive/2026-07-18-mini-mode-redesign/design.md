# Mini 模式重设计 — 设计文档

## 窗口管理

### 模式状态
前端新增响应式状态 `isMiniMode`（存储在内存中，不持久化）。切换时通过 Tauri window API 调整窗口：

| 属性 | 标准模式 | Mini 模式 |
|------|---------|----------|
| 尺寸 | 360 × 478 | 250 × 56 |
| always_on_top | false | true |
| 装饰 | 无（自定义 titlebar） | 无 |
| 可调整大小 | 是 | 否 |
| 圆角 | 默认 | 较大圆角 |

### 切换流程
```
标准 → Mini:
  1. 记录当前窗口位置
  2. setAlwaysOnTop(true)
  3. setResizable(false)
  4. setSize(250, 56)
  5. isMiniMode = true（触发 UI 切换）

Mini → 标准:
  1. setAlwaysOnTop(false)
  2. setResizable(true)
  3. setSize(360, 478)
  4. isMiniMode = false
```

## 组件结构

### +page.svelte 变更
```
{#if isMiniMode}
  <MiniView />
{:else}
  <Titlebar />          ← 新增切换按钮
  <main>
    <Timer />
  </main>
{/if}
```
Mini 模式下不渲染 Titlebar 和 Timer，完全切换到 MiniView。

### MiniView.svelte（新组件）
整个胶囊条的容器。固定 56px 高度，整体 `data-tauri-drag-region` 可拖动。

布局结构：
```
┌─────────────────────────────────────────────────┐
│  上行: 轮次标签 (小字, 淡色, 居左偏移对齐文本区)   │
│  下行: [进度环+按钮] [任务文本 ✏] [⏹?] [时间]    │
│  悬浮层: [切换] [关闭]  (右上角, 绝对定位)         │
└─────────────────────────────────────────────────┘
```

CSS 使用 flex 布局：
- 外层 flex-direction: column
- 下行 flex-direction: row, align-items: center
- 任务文本区域 flex: 1, overflow: hidden（跑马灯容器）
- 时间 flex-shrink: 0

### MiniProgressRing.svelte（新组件）
32px 的圆形进度环 + 内嵌播放/暂停按钮。

- 使用 SVG `<circle>` 绘制背景环和进度弧
- 进度弧颜色：`var(--color-focus-round)`（工作）/ `var(--color-short-break-round)` / `var(--color-long-break-round)`
- stroke-dasharray + stroke-dashoffset 表示进度
- 中心放置播放/暂停 SVG 图标按钮
- 点击中心按钮触发 toggleTimer

### 跑马灯文本
任务文本超出容器宽度时，CSS animation 实现水平滚动：
```css
@keyframes marquee {
  0%   { transform: translateX(0); }
  100% { transform: translateX(-100%); }
}
```
- 检测文本是否溢出（scrollWidth > clientWidth），仅溢出时启用动画
- 文本不溢出时静态显示
- 滚动速度：约 50px/s

### 任务编辑（✏ 按钮）
- 仅在 `task_notes_enabled && round_type == 'work'` 时显示
- 点击 ✏ 后，文本区域变为 inline `<input>`（复用 compact 模式的 TaskNoteInput 逻辑）
- 失焦或回车后保存，回到跑马灯显示模式

### 暂停时重置按钮（⏹）
- 仅在计时器暂停时显示
- 方块图标，点击调用 `restartTimer()`
- 位于任务文本和时间之间

### 悬浮控件
鼠标进入 MiniView 后启动 500ms 定时器，到时后显示右上角控件：
- 切换按钮（回到标准模式图标）
- 关闭按钮（✕）
- 鼠标离开后延迟 300ms 隐藏
- 使用绝对定位，半透明背景，不影响主布局
- 按钮尺寸 16×16px

## 标准模式 Titlebar 变更
在设置和统计按钮旁边新增模式切换按钮：
- 图标：一个缩小/窗口图标（表示"切换到 mini"）
- 位置：Win/Linux 在左侧（⚙ 📊 后面），macOS 在右侧
- 点击后执行切换流程

## 旧 compact 模式处理
- 保留 `isCompact` 的窗口缩放逻辑（uiScale 计算），但移除 MiniControls 组件
- mini 模式下不再触发 compact 逻辑（isMiniMode 时跳过 resize 计算）
- MiniControls.svelte 可以删除

## 主题适配
所有颜色通过 CSS 变量：
- 背景：`var(--color-background)`
- 文字：`var(--color-foreground)`
- 淡色文字：`var(--color-foreground-darker)`
- 进度环：`var(--color-focus-round)` / `var(--color-short-break-round)` / `var(--color-long-break-round)`
- 悬浮按钮背景：`color-mix(in oklch, var(--color-background) 80%, transparent)`
