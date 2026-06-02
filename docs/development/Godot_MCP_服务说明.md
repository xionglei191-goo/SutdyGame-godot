# Godot MCP 服务说明

> 更新日期：2026-06-02  
> 适用项目：`StudyGame` / Godot 4.6.3

本文记录当前项目内 `study_game_godot` MCP 服务的安装位置、启动条件、验证方法和已知维护点。它是开发辅助基础设施，用于让 AI 助手读取 Godot 编辑器状态、修改场景节点、启动游戏并检查运行期节点。

## 1. 当前集成状态

- Godot 插件目录：`addons/godot_mcp/`
- Node.js MCP bridge：`scripts/dev/mcp_bridge/mcp_godot_bridge.js`
- 项目主场景：`res://scenes/main/Main.tscn`
- Godot 版本：`4.6.3-stable`
- 插件启用后会向项目 autoload 注入：
  - `MCPGameInspector`
  - `MCPInputService`
  - `MCPScreenshot`

## 2. 使用前条件

使用 `study_game_godot` 工具前确认：

1. Godot 编辑器已打开当前项目。
2. `addons/godot_mcp` 插件已在 Godot 的 `Project Settings > Plugins` 中启用。
3. `project.godot` 中存在 MCP 相关 autoload。
4. MCP bridge 已由当前 Codex/MCP 环境启动。

如果工具返回“Godot 4 编辑器目前未运行，或者没有启用 addons/godot_mcp 插件”，优先检查第 1、2 项。

## 3. Bridge 依赖安装

Node.js MCP bridge 依赖不纳入版本控制。新环境或依赖缺失时，在项目根目录执行：

```bash
cd scripts/dev/mcp_bridge
npm install
```

依赖由 `scripts/dev/mcp_bridge/package.json` 和 `scripts/dev/mcp_bridge/package-lock.json` 锁定。

## 4. 快速验证流程

建议按下面顺序验证服务是否可用：

1. 调用 `get_project_info`：确认能读到项目名、Godot 版本、主场景和 autoload。
2. 调用 `get_scene_tree`：确认能读取当前编辑器打开的场景树。
3. 调用 `get_filesystem_tree`：确认能读取 `res://addons/godot_mcp` 和项目场景文件。
4. 调用 `play_scene`，使用 `mode: "main"` 启动主场景。
5. 调用 `wait_for_node`，等待 `/root/Main` 出现。
6. 调用 `get_game_scene_tree`、`get_game_node_properties` 或 `get_game_screenshot`：确认运行期桥接可用。

一次成功验证的关键现象：

- `get_project_info` 返回 `project_name: "StudyGame"`。
- `get_scene_tree` 能读到 `TownMap` 或当前编辑器场景。
- `wait_for_node("/root/Main")` 返回 `found: true`。
- `get_game_screenshot` 返回 PNG base64 数据。

## 5. 固定 Smoke Test

MCP 集成变更后，按下面顺序执行最小验收：

1. `get_project_info`
2. `play_scene`，参数 `mode: "main"`
3. `wait_for_node`，节点 `/root/Main`
4. `get_game_scene_tree`
5. `get_game_screenshot`
6. `stop_scene`

成功标准：

- 项目信息返回 `StudyGame`、Godot `4.6.3`、主场景 `res://scenes/main/Main.tscn`。
- `/root/Main` 能在运行期出现。
- 运行期场景树能读取。
- 截图返回 PNG 数据。
- smoke test 结束后游戏被停止。

## 6. 常用工具

- `get_project_info`：读取项目、Godot 版本、主场景、autoload。
- `get_scene_tree`：读取编辑器当前场景树。
- `get_node_properties`：读取编辑器节点属性。
- `update_property`：修改编辑器节点属性，会进入 Godot Undo 历史。
- `play_scene` / `stop_scene`：启动或停止游戏。
- `get_game_scene_tree`：读取运行中游戏的活节点树。
- `get_game_node_properties`：读取运行中节点属性或脚本变量。
- `set_game_node_property`：修改运行中节点属性或脚本变量。
- `get_game_screenshot`：截取运行中游戏画面。
- `simulate_key` / `simulate_mouse_click` / `simulate_action`：模拟输入。

## 7. 已知维护点

### JSON Schema 不支持 `type: "any"`

MCP 工具输入 schema 必须符合 JSON Schema。`type: "any"` 不是合法写法，会导致工具声明校验失败。

当前 bridge 中 `update_property.value` 和 `set_game_node_property.value` 已修正为：

```js
type: ["string", "number", "integer", "boolean", "array", "object", "null"]
```

相关文件：

- `scripts/dev/mcp_bridge/mcp_godot_bridge.js`

修改 bridge 源码后，需要重启 MCP bridge 或重开 Codex/MCP 会话，新的工具 schema 才会被客户端重新加载。

### 编辑器插件和 bridge 是两层

`addons/godot_mcp/` 负责 Godot 编辑器和运行期桥接；`scripts/dev/mcp_bridge/mcp_godot_bridge.js` 负责向 MCP 客户端暴露工具。只安装插件但 bridge schema 有误时，编辑器可能能连接，但客户端仍会在工具声明阶段失败。

## 8. 排障优先级

1. 先确认 Godot 编辑器正在打开当前项目。
2. 再确认插件已启用，autoload 已写入。
3. 再确认 MCP bridge 进程是最新代码启动的。
4. 最后检查工具 schema 是否仍有非法字段，例如 `type: "any"`。

不要把运行期工具失败和编辑器工具失败混为一类：`get_scene_tree` 属于编辑器侧，`get_game_scene_tree` 属于运行期侧。运行期工具需要先 `play_scene`。
