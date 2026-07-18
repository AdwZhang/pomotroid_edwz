## 目的

定义 `SequenceState` 的行为 —— 该组件负责决定下一个轮次类型，并在一个会话内跟踪轮次计数器。

---

## 需求

### 需求：短休息可以独立禁用

系统应当（SHALL）支持 `short_breaks_enabled` 设置项（默认 `true`）。当为 `false` 时，序列应当完全跳过短休息轮次：原本会进入短休息的工作轮次应当直接进入下一个工作轮次，并将 `work_round_number` 加一。其他所有序列行为（长休息、在长休息点重置计数器）不受影响。

#### 场景：短休息禁用 — 工作轮次直接连续

- **当** `short_breaks_enabled` 为 `false`
- **且** 一个工作轮次在长休息点之前完成
- **则** 下一个轮次应当为工作轮次，且 `work_round_number` 加一
- **且** 不会出现短休息轮次

#### 场景：短休息禁用 — 长休息仍然触发

- **当** `short_breaks_enabled` 为 `false`
- **且** 一个工作轮次在长休息点完成（`work_round_number >= work_rounds_total`）
- **且** `long_breaks_enabled` 为 `true`
- **则** 下一个轮次应当为长休息

#### 场景：短休息重新启用 — 循环恢复正常

- **当** `short_breaks_enabled` 被改为 `true`
- **则** 下一次工作到休息的转换应当根据当前轮次位置产生短休息或长休息

---

### 需求：长休息可以独立禁用

系统应当支持 `long_breaks_enabled` 设置项（默认 `true`）。当为 `false` 时，序列永远不会进入长休息轮次。在长休息点，序列应当改为进入短休息（如果 `short_breaks_enabled` 为 `true`），或直接进入 Work(1)（如果 `short_breaks_enabled` 也为 `false`）。在两种情况下，`work_round_number` 都应当在该边界重置为 1，以保留循环结构。

#### 场景：长休息禁用 — 在长休息点替换为短休息

- **当** `long_breaks_enabled` 为 `false`
- **且** `short_breaks_enabled` 为 `true`
- **且** 一个工作轮次在长休息点完成
- **则** 下一个轮次应当为短休息
- **且** 该短休息完成后 `work_round_number` 应当重置为 1

#### 场景：长休息禁用 — 两种休息都禁用时循环重置

- **当** `long_breaks_enabled` 为 `false`
- **且** `short_breaks_enabled` 为 `false`
- **且** 一个工作轮次在长休息点完成
- **则** 下一个轮次应当为工作轮次，且 `work_round_number` 重置为 1

#### 场景：长休息禁用 — 在长休息点之前短休息仍然触发

- **当** `long_breaks_enabled` 为 `false`
- **且** `short_breaks_enabled` 为 `true`
- **且** 一个工作轮次在长休息点之前完成
- **则** 下一个轮次应当照常为短休息

#### 场景：两种休息都禁用 — 纯工作循环

- **当** `short_breaks_enabled` 为 `false`
- **且** `long_breaks_enabled` 为 `false`
- **则** 序列应当完全由工作轮次组成
- **且** `work_round_number` 每轮递增，到达 `work_rounds_total` 时重置为 1

---

### 需求：TimerSnapshot 携带前一轮次类型

`TimerSnapshot` 应当包含 `previous_round_type: String` 字段，记录当前轮次开始前活跃的轮次类型。值应当为 `"work"`、`"short-break"` 或 `"long-break"` 之一。

在会话的第一个轮次（或重置后），`previous_round_type` 应当为空字符串 `""`，表示没有前置轮次。

该字段使前端能够区分上下文不同的转换 — 例如，休息后的工作轮次（"休息结束 — 专注时间！"）与另一个工作轮次后的工作轮次（短休息禁用时的"专注时间！"）。

#### 场景：previous_round_type 反映前一个轮次

- **当** 一个短休息轮次转换到工作轮次
- **则** 发出的 `TimerSnapshot` 中 `previous_round_type` 应当为 `"short-break"`

#### 场景：短休息禁用时工作到工作的转换

- **当** `short_breaks_enabled` 为 `false`
- **且** 一个工作轮次直接转换到下一个工作轮次
- **则** 发出的 `TimerSnapshot` 中 `previous_round_type` 应当为 `"work"`

#### 场景：第一个轮次时 previous_round_type 为空

- **当** 计时器刚启动或被重置
- **且** 第一个轮次开始
- **则** `previous_round_type` 应当为 `""`

---

### 需求：上下文感知的工作通知

前端应当使用 `TimerSnapshot` 中的 `previous_round_type` 来选择工作轮次开始时的适当通知文本：

- 如果 `previous_round_type` 为 `"short-break"` 或 `"long-break"`：使用休息结束的通知文案（如"休息结束 — 专注时间！"）
- 如果 `previous_round_type` 为 `"work"` 或 `""`：使用中性的工作开始通知文案（如"专注时间！"）

两种消息变体应当是不同的本地化键，以便可以独立翻译。

#### 场景：休息后的通知

- **当** 一个工作轮次在短休息或长休息之后开始
- **则** 桌面通知应当使用休息结束的标题和正文

#### 场景：工作到工作转换时的通知

- **当** 一个工作轮次在另一个工作轮次之后开始（短休息禁用）
- **则** 桌面通知应当使用工作开始的标题和正文（而非休息结束文案）

#### 场景：第一个工作轮次的通知

- **当** 会话的第一个工作轮次开始（`previous_round_type` 为 `""`）
- **则** 桌面通知应当使用工作开始的标题和正文

---

### 需求：会话工作计数

`SequenceState` 应当暴露一个 `session_work_count: u32` 字段，初始为 1，每次 `advance()` 进入工作轮次时加 1。与 `work_round_number` 不同，它在循环边界时永远不会重置 — 只有调用 `reset()` 才将其恢复为 1。它包含在 `TimerSnapshot` 中，并在前端作为会话计数器展示。

#### 场景：session_work_count 跨循环边界递增

- **当** `long_breaks_enabled` 为 `false`
- **且** 多个工作轮次跨越了本应是长休息边界的位置完成
- **则** `session_work_count` 应当继续递增而不重置

#### 场景：计时器重置时 session_work_count 重置

- **当** 用户触发计时器重置
- **则** `session_work_count` 应当重置为 1

#### 场景：轮次计数器显示根据 long_breaks_enabled 自适应

- **当** `long_breaks_enabled` 为 `true`
- **则** 轮次计数器应当显示 `work_round_number / work_rounds_total`
- **当** `long_breaks_enabled` 为 `false`
- **则** 轮次计数器应当使用 `session_work_count` 显示本地化的"第 N 轮"标签
