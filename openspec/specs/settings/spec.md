## 新增需求

### 需求：详细日志设置持久化并在启动时应用

系统应当在 SQLite 中存储 `verbose_logging` 布尔设置项（DB 键：`verbose_logging`，默认 `false`）。启动时，当 `verbose_logging` 为 `true` 时日志级别应当设为 DEBUG，否则为 INFO，且在任何其他应用初始化之前执行。

#### 场景：默认值为 false

- **当** 应用首次运行且无现有设置
- **则** `verbose_logging` 为 `false`，日志级别为 INFO

#### 场景：详细日志跨重启持久化

- **当** 用户启用详细日志并重启应用
- **则** 从第一条日志起日志级别即为 DEBUG

---

---

### 需求：语言设置

系统应当在设置数据库中存储 `language` 设置项，默认值为 `'auto'`。值应当为 `'auto'` 或受支持的 IETF BCP 47 语言标签（`'en'`、`'es'`、`'fr'`、`'de'`、`'ja'`）。`Settings` 结构体应当暴露 `language: String` 字段，`types.ts` 应当镜像该字段。

#### 场景：默认语言为 auto

- **当** 新用户首次启动应用
- **则** `language` 设置应当为 `'auto'`

#### 场景：语言设置跨重启持久化

- **当** 用户将 `language` 设为 `'de'` 并重启应用
- **则** 重启后 `language` 设置应当为 `'de'`

#### 场景：语言设置对现有用户的迁移

- **当** 现有用户从不包含 `language` 设置的版本升级
- **则** MIGRATION_3 应当插入 `language = 'auto'` 作为默认行

---

### 需求：详细日志可在运行时通过设置 → 高级切换

系统应当在设置 → 高级中提供"详细日志"开关。切换后应当立即生效（通过 `log::set_max_level()` 改变全局日志级别），无需重启应用，并将新值持久化到数据库。

#### 场景：启用详细日志立即生效

- **当** 用户启用详细日志
- **则** 后续日志条目包含 DEBUG 级别消息，无需重启

#### 场景：禁用详细日志立即生效

- **当** 用户禁用详细日志
- **则** 后续日志条目中 DEBUG 级别消息被抑制，无需重启

#### 场景：切换变更记录到日志

- **当** 详细日志被启用或禁用
- **则** 一条 INFO 级别的日志记录该变更（如"详细日志已启用 — 日志级别设为 DEBUG"）

---

### 需求：重置所有设置操作位于设置 → 系统

系统应当在设置 → 系统中提供"重置所有设置"操作。该操作应当使用内联两步确认：第一次交互显示确认提示，包含取消和重置控件；只有第二次（重置）交互才触发 `settings_reset_defaults`。在任何时刻取消都应当恢复原始按钮而不执行重置。该操作将所有设置全局重置（所有 26 个键）为出厂默认值，包括清除磁盘上的任何自定义提示音文件和音频引擎内存中的状态。

#### 场景：取消关闭确认而不重置

- **当** 用户点击"重置所有设置"然后点击"取消"
- **则** 不应更改任何设置，且行应恢复到初始按钮状态

#### 场景：确认触发全局重置

- **当** 用户点击"重置所有设置"然后点击"确认"
- **则** 应当调用 `settings_reset_defaults`，所有设置恢复为出厂默认值，且行恢复到初始按钮状态

#### 场景：重置时清除自定义提示音

- **当** 用户确认全面设置重置
- **则** 任何自定义提示音文件应当从磁盘删除，音频引擎内存中的自定义路径应当被清除

#### 场景：关于部分没有重置按钮

- **当** 用户导航到设置 → 关于
- **则** 该部分不应存在重置按钮

---

### 需求：计时器时长 DB 键存储整数秒

系统应当将计时器时长存储从分钟精度键（`time_work_mins`、`time_short_break_mins`、`time_long_break_mins`）迁移到秒精度键（`time_work_secs`、`time_short_break_secs`、`time_long_break_secs`）。MIGRATION_2 应当将现有分钟值转换为秒，以新键插入，并删除旧键。`load()` 函数应当从新键读取，无需 `* 60` 转换。首次启动时播种的默认值应当以秒为单位表示。

#### 场景：现有安装非破坏性迁移

- **当** 拥有 `time_work_mins = "30"` 的用户升级到新版本
- **则** MIGRATION_2 应当插入 `time_work_secs = "1800"` 并删除 `time_work_mins`，保留用户的 30 分钟偏好

#### 场景：默认播种使用秒精度键

- **当** 应用在全新安装上运行
- **则** 设置表应当包含 `time_work_secs = "1500"`、`time_short_break_secs = "300"`、`time_long_break_secs = "900"`，且不应包含任何 `*_mins` 键

#### 场景：亚分钟值跨重启持久化

- **当** 用户将专注时长设为 5:39（339 秒）并重启应用
- **则** 数据库中 `time_work_secs` 应当等于 `"339"`，Settings 结构体应当暴露 `time_work_secs = 339`

#### 场景：重置为默认值恢复秒精度默认值

- **当** 用户触发"重置所有设置"
- **则** 设置表应当包含 `time_work_secs = "1500"`，且不应包含 `time_work_mins`

#### 场景：迁移后旧 `*_mins` 键不存在

- **当** MIGRATION_2 在之前有 `*_mins` 键的数据库上运行后
- **则** `SELECT key FROM settings WHERE key LIKE '%_mins'` 应当返回零行

---

### 需求：`check_for_updates` 设置持久化，默认为 true

系统应当在 SQLite 中存储 `check_for_updates` 布尔设置项（DB 键：`check_for_updates`，默认 `'true'`）。新的 DB 迁移应当为全新安装和升级的现有用户插入该默认行。`Settings` 结构体应当暴露 `check_for_updates: bool` 字段，`types.ts` 应当镜像该字段。

#### 场景：全新安装时默认值为 true

- **当** 应用首次运行且无现有设置
- **则** `check_for_updates` 应当为 `true`

#### 场景：设置跨重启持久化

- **当** 用户禁用自动更新检查并重启应用
- **则** 重启后 `check_for_updates` 应当为 `false`

#### 场景：迁移为现有用户插入默认值

- **当** 现有用户从不包含 `check_for_updates` 的版本升级
- **则** 迁移应当插入 `check_for_updates = 'true'`，不修改其他设置

---

### 需求：设置 → 系统中的 `check_for_updates` 开关

系统应当在设置 → 系统中提供"自动检查更新"开关。切换后应当通过 `settings_set` 立即持久化新值，并在下次打开设置窗口时生效（无需重启）。

#### 场景：开关在系统部分可见

- **当** 用户导航到设置 → 系统
- **则** 应当可见"自动检查更新"开关

#### 场景：禁用后阻止更新检查

- **当** 用户禁用该开关并重新打开设置
- **则** 在"关于"部分挂载时不应调用 `check_update`

---

### 需求：global_shortcuts_enabled 设置

系统应当在 SQLite 中存储 `global_shortcuts_enabled` 布尔设置项（DB 键：`global_shortcuts_enabled`，默认 `'false'`）。`Settings` 结构体应当暴露 `global_shortcuts_enabled: bool` 字段，`types.ts` 应当将其镜像为 `global_shortcuts_enabled: boolean`。

#### 场景：默认值为 false

- **当** 应用首次运行且无现有设置
- **则** `global_shortcuts_enabled` 应当为 `false`

#### 场景：设置跨重启持久化

- **当** 用户启用全局快捷键并重启应用
- **则** 重启后 `global_shortcuts_enabled` 应当为 `true`

#### 场景：迁移为现有用户添加设置

- **当** 现有用户从不包含 `global_shortcuts_enabled` 设置的版本升级
- **则** 该设置应当通过 `INSERT OR IGNORE` 以值 `'false'` 插入
- **且** 用户的其他设置不受影响

---

### 需求：short_breaks_enabled 设置

系统应当在 SQLite 中存储 `short_breaks_enabled` 布尔设置项（DB 键：`short_breaks_enabled`，默认 `'true'`）。`Settings` 结构体应当暴露 `short_breaks_enabled: bool` 字段，`types.ts` 应当将其镜像为 `short_breaks_enabled: boolean`。

#### 场景：默认值为 true

- **当** 应用首次运行且无现有设置
- **则** `short_breaks_enabled` 应当为 `true`

#### 场景：设置跨重启持久化

- **当** 用户禁用短休息并重启应用
- **则** 重启后 `short_breaks_enabled` 应当为 `false`

#### 场景：迁移为现有用户播种设置

- **当** 现有用户从不包含 `short_breaks_enabled` 的版本升级
- **则** 该设置应当通过 `INSERT OR IGNORE` 以值 `'true'` 插入
- **且** 用户的其他设置不受影响

---

### 需求：long_breaks_enabled 设置

系统应当在 SQLite 中存储 `long_breaks_enabled` 布尔设置项（DB 键：`long_breaks_enabled`，默认 `'true'`）。`Settings` 结构体应当暴露 `long_breaks_enabled: bool` 字段，`types.ts` 应当将其镜像为 `long_breaks_enabled: boolean`。

#### 场景：默认值为 true

- **当** 应用首次运行且无现有设置
- **则** `long_breaks_enabled` 应当为 `true`

#### 场景：设置跨重启持久化

- **当** 用户禁用长休息并重启应用
- **则** 重启后 `long_breaks_enabled` 应当为 `false`

#### 场景：迁移为现有用户播种设置

- **当** 现有用户从不包含 `long_breaks_enabled` 的版本升级
- **则** 该设置应当通过 `INSERT OR IGNORE` 以值 `'true'` 插入
- **且** 用户的其他设置不受影响

---

### 需求：window_x 和 window_y 设置

系统应当在设置数据库中存储可选的整数设置 `window_x` 和 `window_y`（物理像素坐标）。这些键在全新安装时不存在，仅在用户首次移动窗口后才写入。键不存在应当被视为"无保存位置"。

#### 场景：首次运行时键不存在

- **当** 应用首次运行且无现有设置
- **则** 设置数据库中不应存在 `window_x` 和 `window_y`

#### 场景：窗口移动后写入键

- **当** 用户移动主窗口
- **则** 设置数据库中应当存在 `window_x` 和 `window_y`，包含新坐标

---

### 需求：window_width 和 window_height 设置

系统应当在设置数据库中存储可选的无符号整数设置 `window_width` 和 `window_height`（物理像素）。这些键在全新安装时不存在，在首次移动或调整大小后与 `window_x`/`window_y` 一起写入。

#### 场景：首次运行时键不存在

- **当** 应用首次运行且无现有设置
- **则** 设置数据库中不应存在 `window_width` 和 `window_height`

#### 场景：窗口调整大小后写入键

- **当** 用户调整主窗口大小
- **则** 设置数据库中应当存在 `window_width` 和 `window_height`，包含新尺寸

---

### 需求：重置所有设置时清除窗口位置和尺寸

当用户触发"重置所有设置"时，四个窗口几何键（`window_x`、`window_y`、`window_width`、`window_height`）应当连同所有其他设置一起从数据库中删除。重置在下次启动时生效 — 当前会话的窗口位置不受干扰。在随后的启动中，窗口在系统默认位置和尺寸打开。

#### 场景：重置所有设置删除几何键

- **当** 用户触发"重置所有设置"
- **则** 设置数据库中不应存在 `window_x`、`window_y`、`window_width` 和 `window_height`

#### 场景：重置后窗口在系统默认位置打开

- **当** 应用在执行"重置所有设置"后启动
- **则** 主窗口应当在系统默认位置和尺寸打开

---

### 需求：任务备注设置字段

系统应当在 `Settings` 结构体和 `types.ts` 中提供以下字段：

| 字段 | 类型 | DB 键 | 默认值 | 说明 |
|------|------|-------|--------|------|
| `task_notes_enabled` | bool | `task_notes_enabled` | `false` | 是否显示任务备注输入框 |
| `current_task_note` | String | `current_task_note` | `""` | 当前任务备注文本（最大 100 字符） |

设置 → 计时器部分应当提供"任务备注"开关，开启后主界面在 work 轮次显示备注输入框。

#### 场景：任务备注默认关闭

- **当** 新安装的应用首次启动
- **则** `task_notes_enabled` 为 `false`

#### 场景：当前备注保存到数据库

- **当** 用户在备注输入框中输入 "写文档" 并停止输入 300ms
- **则** `current_task_note` 的值通过 `settings_set` 保存为 "写文档"
