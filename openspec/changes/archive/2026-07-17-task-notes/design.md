# 任务备注 — 设计文档

## 数据模型

### 设置（新增字段）
| 字段 | 类型 | 默认值 | DB Key |
|------|------|--------|--------|
| `task_notes_enabled` | bool | false | `task_notes_enabled` |
| `current_task_note` | String | "" | `current_task_note` |

### 数据库迁移 (MIGRATION_7)
```sql
ALTER TABLE sessions ADD COLUMN task_note TEXT;
```
可空 — 历史 session 和休息 session 保持 NULL。

## 记录逻辑
- `TimerEvent::Complete` 触发时，若为 work 轮次：读取 `current_task_note` 当前值写入 `sessions.task_note`
- Skip 操作：同样记录（被跳过的 work session 也会获得备注）
- 休息轮次：task_note = NULL

## 前端组件

### TaskNoteInput（新组件）
- 单行 `<input type="text">`，maxlength=100，居中显示，max-width 200px
- Placeholder：国际化 "正在做什么..."
- 修改时：300ms debounce 后通过 `settingsSet("current_task_note", value)` 保存
- 可见条件：`task_notes_enabled && round_type == "work"`（仅正常模式）
- **Compact 模式下隐藏** — 窗口 <300px 时空间不足，显示会导致时钟被裁切
- **视觉状态：**
  - 默认（未聚焦）：透明背景、无边框 — 看起来像文本标签
  - 悬停：出现浅色背景
  - 聚焦（编辑中）：显示边框 + 背景 — 明确的输入框形态

### Timer.svelte 变更
- 导入并渲染 `TaskNoteInput`，位置在 `.round-label` 和 `.controls-wrapper` 之间
- 仅在非 compact 模式下显示

### DailyView.svelte 变更
- 查询返回带备注的 session 列表
- 小时柱状图下方新增会话列表区域
- 仅显示 work 类型的 session
- 没有备注的 session 用灰色斜体显示"无描述"

## IPC / 查询
- `stats_get_detailed` 响应扩展 `sessions: Vec<SessionEntry>` 字段
- 新结构体 `SessionEntry { started_at, ended_at, duration_secs, completed, task_note }`
- 查询：`SELECT * FROM sessions WHERE round_type='work' AND date(started_at, ...) = today ORDER BY started_at`

## 设置界面
- Timer 分区新增开关："任务备注"，附带描述文字
