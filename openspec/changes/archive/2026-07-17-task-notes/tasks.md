# 任务备注 — 任务清单

- [x] 1. Rust: 新增 MIGRATION_7（ALTER TABLE sessions ADD COLUMN task_note TEXT）
- [x] 2. Rust: 新增设置字段（task_notes_enabled, current_task_note）+ 默认值 + 加载/保存
- [x] 3. Rust: 更新 complete_session 接受并存储 task_note
- [x] 4. Rust: 更新计时器事件监听器，完成时传递 current_task_note
- [x] 5. Rust: 扩展统计查询，返回带备注的 session 列表
- [x] 6. 前端: 更新类型定义（Settings 字段、SessionEntry）
- [x] 7. 前端: 创建 TaskNoteInput.svelte 组件
- [x] 8. 前端: 集成到 Timer.svelte
- [x] 9. 前端: 设置页面新增开关
- [x] 10. 前端: 更新 DailyView 显示会话列表
- [x] 11. 国际化: 添加所有语言的消息键
- [x] 12. 修复: 文本框居中、编辑/静态视觉状态区分、compact 模式下隐藏
