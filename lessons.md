# Lessons Learned

## Godot 原型开发踩坑记录

### 1. `--check-only` 需要配合 `--quit`

本项目中直接运行：

```bash
godot --headless --path . --check-only
```

曾出现进程不退出的情况。后续检查建议统一使用：

```bash
godot --headless --path . --check-only --quit
```

这样可以稳定完成工程检查并返回终端。

### 2. Headless 逻辑测试不能覆盖真实窗口输入链路

`tests/prototype_0_1_smoke.gd` 能验证：

- 内部 quest JSON / 历史原型兼容数据能加载。
- 点击目标校验逻辑能完成事件。
- `GameState` 能记录事件、奖励和家长层词汇。

但它没有覆盖真实窗口中的鼠标事件传播。之前 `library` 点击无反应，就是 headless smoke test 通过但窗口交互失败的例子。

后续凡是涉及鼠标、键盘、UI 层级、拖拽、触摸的功能，都需要补一次真实窗口手动验收，或者专门做 Godot 输入模拟测试。

### 3. `Area2D.input_event` 不一定可靠触发

最初地点点击依赖：

```gdscript
marker.input_event.connect(...)
```

实际运行时点击 `library` 没反应。原因可能是输入拾取、节点层级、Control 节点鼠标过滤或碰撞拾取配置共同影响。

当时的原型修复策略是：

- 在 `SceneClickGame` 的 `_input` 中直接读取鼠标点击。
- 用固定地图矩形判断点击落在哪个地点。
- 命中后主动发出 `target_clicked` 信号。

这比只依赖 `Area2D.input_event` 更适合当时的早期原型排障，但它不是当前产品真相。

当前文档口径应改为：

- `world_overview` 和地图地点交互以 JSON / hotspot 配置驱动为准。
- 场景可见热点、点击命中和验收测试应围绕同一份 hotspot 数据。
- `campus_gate`、`home`、`garden` 等子场景目标已迁到 `data/maps/scene_click_targets_v001.json`，由 `SceneClickGame.get_place_rects_for_scene()` 和 `mvp_0_2_quest_data_integrity.gd` 读取同一份数据合同保护。
- 固定点击区域可以存在于数据文件中作为当前热点合同，但不应再新增 `PLACE_RECTS` / `SCENE_TARGET_RECTS` 风格的脚本硬编码常量。

### 4. `ColorRect` / `Label` 可能吃掉鼠标事件

地图建筑使用了 `ColorRect` 和 `Label` 做占位。它们属于 `Control` 节点，默认可能参与鼠标事件处理，导致底层游戏节点收不到点击。

对作为地图装饰的 UI 节点，应显式设置：

```text
mouse_filter = 2
```

也就是 `MouseFilter = Ignore`。

当前 `TownMap.tscn` 中地点建筑和文字标签已经设置为 ignore。

### 5. 手写 `.tscn` 时要特别注意静态检查

Godot 4.6 对 GDScript 类型推断比较严格。本项目里曾遇到：

```text
Cannot infer the type of variable...
Warning treated as error.
```

后续写 GDScript 时，来自 JSON、Dictionary、NodePath 的值尽量显式转换或标注类型，例如：

```gdscript
var reward_id: String = str(current_quest.get("reward_id", ""))
var target_labels: Dictionary = current_quest.get("target_labels", {})
```

这样能减少 Godot 静态检查误判或运行前失败。

### 6. 自动测试要覆盖“真实失败点”

早期 smoke test 只验证了 `quest_diary.check_target("library")` 能成功，但没有验证“鼠标点到 `library` 热点会调用 `check_target`”。

当前应继续保留输入链路测试覆盖：

- `library` hotspot 配置存在且能发出 `target_clicked("library")`。
- `classroom` hotspot 配置存在且能发出 `target_clicked("classroom")`。
- 自由探索点击 A-Z anchor 能进入首访 anchor dialogue；首访后可进入全量 A-Z `Memory Spark`。
- 点击空白区域不会完成事件。
- 热点视觉中心与点击区域保持一致，避免“看得到但点不到”。

项目内已有 `mvp_0_2_world_overview_input_flow.gd`、`mvp_0_2_world_hotspot_enablement.gd` 和 `mvp_0_2_quest_data_integrity.gd`，后续新增地图交互时应优先扩展这些测试，而不是只依赖人工点击。

### 7. 运行中的 Godot 窗口不会自动加载脚本改动

修复脚本后，需要重启正在运行的 Godot 项目。否则窗口仍使用旧逻辑。

本项目调试时使用：

```bash
pgrep -af 'godot --path .'
kill <pid>
godot --path .
```

后续修改交互脚本、场景结构、输入配置后，都应重启项目再验收。

### 8. Prototype 占位素材应保持简单可替换

当前所有可见素材都使用 Godot 内置节点占位，没有使用网络图片、真实 Logo、商标或第三方 IP 角色资产。

这个做法有两个好处：

- 降低版权和素材导入风险。
- 让第一阶段优先验证玩法闭环，而不是被美术资源阻塞。

正式素材接入前，应继续遵守 `docs/assets/AI图片素材生成规范_v0.1.md`。

### 9. Godot MCP 作为辅助工具接入

本机 Codex 已在 `~/.codex/config.toml` 接入社区 MCP：

```toml
[mcp_servers.godot]
type = "stdio"
command = "npx"
args = ["@coding-solo/godot-mcp@latest"]
env = { GODOT_PATH = "/home/xionglei/.local/bin/godot" }
```

用途定位：

- 启动/停止 Godot 项目。
- 获取 Godot debug 输出。
- 辅助读取项目结构和运行状态。
- 后续可试用场景创建/节点编辑能力。

注意事项：

- 这是社区 MCP，不是 Godot 官方工具。
- 不应替代 `godot --headless --path . --check-only --quit` 和项目内 smoke test。
- 大范围修改 `.tscn` 前仍应通过版本检查、运行检查和人工验收确认。
- 修改 `~/.codex/config.toml` 后，通常需要新开 Codex 会话或重新加载工具后才能看到新的 MCP 工具。

### 10. 验收按钮要绑定完成条件，不能只看页面是否打开

家长摘要可以通过快捷键打开。如果“完成摘要阅读”只根据 `playtest_completed` 禁用，测试者可能在未完成正式事件 gate 或未完成 Story Show 时提前点击，导致计时提前结束并生成半流程报告。

当前修复策略：

- `ParentSummary` 只有在新 home-first gate（`Welcome Box`、`Room Starter`、`Pet Hello`、`Home Pet Care`、`First Trip`）和 `mvp_0_2_review_challenge`（报告/存档兼容 ID；前台名称为 Story Show）都完成后，才允许点击“完成摘要阅读”；旧 `parent_bonus_confirmed_mvp_0_2` flag 仍可读并防重复。
- `mvp_0_2_smoke.gd` 覆盖空摘要和未完成 Story Show 时按钮不可用。
- 导出 Markdown 摘要前再次校验报告 schema、完整时间线、25 题 Story Show、6 个朗读倒计时和人工结论留空。

后续新增验收按钮时，应先定义“允许完成”的业务条件，再让 UI 状态、按钮回调和 smoke test 同时覆盖该条件。
