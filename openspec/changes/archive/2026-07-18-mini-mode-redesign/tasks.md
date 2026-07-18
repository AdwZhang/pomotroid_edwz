# Mini 模式重设计 — 任务清单

- [x] 1. 前端: 新增 MiniProgressRing.svelte — 32px SVG 进度环 + 播放/暂停按钮
- [x] 2. 前端: 新增 MiniView.svelte — 胶囊条容器（布局、拖动、轮次标签、时间显示）
- [x] 3. 前端: MiniView 集成跑马灯任务文本 + ✏ 编辑按钮（复用 TaskNoteInput compact 逻辑）
- [x] 4. 前端: MiniView 暂停时显示 ⏹ 重置按钮
- [x] 5. 前端: MiniView 悬浮控件（500ms 延迟显示切换按钮 + 关闭按钮）
- [x] 6. 前端: Titlebar 新增 mini 模式切换按钮
- [x] 7. 前端: +page.svelte 新增 isMiniMode 状态，条件渲染 MiniView vs 标准 UI
- [x] 8. 前端: 窗口切换逻辑（resize、alwaysOnTop、resizable）
- [x] 9. 前端: mini 模式下跳过旧 compact 缩放逻辑，删除 MiniControls.svelte
- [x] 10. Tauri: capabilities/default.json 中允许 always_on_top 相关 API
- [x] 11. 国际化: 新增消息键（tooltip_mini_mode、轮次标签"专注"/"短休"/"长休"等）
