# StudyGame Godot MCP Server Bridge

这是一个 **100% 免费、完全开源且私有** 的 Model Context Protocol (MCP) 桥接服务器，专门为 `StudyGame-godot` 项目定制开发。

它能够将你的桌面开发工具（如 **Cursor** 或 **Claude Desktop**）与正在运行的 **Godot 4 编辑器** 深度打通。通过它，AI 助手可以直接读取并安全地操作你打开的场景树、挂载脚本、更新节点属性（支持 Ctrl+Z 撤销），以及在游戏运行期自动模拟点击、触发动作和截取画面进行测试。

---

## 🛠️ 第一步：初始化 Node.js 依赖包

运行本服务前，你需要在本地安装 Node.js（推荐 v18 或以上版本）。

在终端中执行以下命令进入本目录，并下载依赖包：

```bash
cd scripts/dev/mcp_bridge
npm install
```

这会自动下载官方 `@modelcontextprotocol/sdk` 和高效率 WebSocket 库 `ws`。

`node_modules/` 是本地生成目录，不纳入版本控制；换机或清理依赖后用上面的 `npm install` 恢复。

---

## 🚀 第二步.一：在 Cursor 中进行配置

要想让 Cursor 的 AI 助手识别并加载这套桥接服务：

1. 打开 **Cursor** 客户端，点击右上角进入 **Settings** -> **Features** -> **MCP**。
2. 点击 **+ Add New MCP Server**。
3. 按照如下参数填写：
   * **Name**: `StudyGameGodot`
   * **Type**: `command`
   * **Command**: `node /home/xionglei/GameProject/SutdyGame-godot/scripts/dev/mcp_bridge/mcp_godot_bridge.js`
4. 点击 **Save** 保存。

此时，Cursor 会自动拉起这个 Node.js 进程，并进入等待连接状态。

---

## 🚀 第二步.二：在 VS Code 中进行配置

VS Code 本身不原生集成 MCP，但你可以通过两款主流的强大的 AI 插件轻松启用：

### 1. 使用 Cline / Roo Code 插件配置（强烈推荐）
**Cline** (及分支 **Roo Code**) 是 VS Code 中最强大的 AI Agent 插件，原生支持 MCP 服务器。
1. 在 VS Code 中打开 **Cline** 侧边栏，点击顶部的 ⚙️ (齿轮) 打开设置。
2. 点击 **Configure MCP Servers** 按钮，这会自动在编辑器中打开 `cline_mcp_settings.json`（或 `roo_mcp_settings.json`）文件。
3. 在 JSON 字典的 `"mcpServers"` 下添加以下块：
   ```json
   "study-game-godot": {
     "command": "node",
     "args": ["/home/xionglei/GameProject/SutdyGame-godot/scripts/dev/mcp_bridge/mcp_godot_bridge.js"],
     "disabled": false,
     "autoApprove": []
   }
   ```
4. 保存文件，插件会自动拉起并监听此桥接服务。

### 2. 使用 Continue 插件配置
**Continue** 是最流行的开源 VS Code 自动补全与对话助手。
1. 点击 Continue 对话框底部的 ⚙️ (齿轮) 打开 `config.json` 配置文件。
2. 在 JSON 的最外层对象中，添加或修改 `"mcpServers"` 属性：
   ```json
   "mcpServers": [
     {
       "name": "study-game-godot",
       "command": "node",
       "args": ["/home/xionglei/GameProject/SutdyGame-godot/scripts/dev/mcp_bridge/mcp_godot_bridge.js"]
     }
   ]
   ```
3. 保存后重新加载 Continue，对话框中就会支持使用 `@StudyGameGodot` 调用这些指令！

---

## 🚀 第二步.三：在 Antigravity 中进行配置

作为与你进行对话的 AI 编程助手，**Antigravity** 也完全支持加载并使用你搭建的这套本地桥接服务器！

我已经在你的后台系统配置中为你自动配置完成了这一步。具体的手动注册规则如下，供参考：
1. 打开 Antigravity 宿主客户端的配置文件 `~/.gemini/antigravity/mcp_config.json`。
2. 在 `"mcpServers"` 配置对象下，添加我们服务的 `study-game-godot` 启动命令：
   ```json
   "study-game-godot": {
     "command": "node",
     "args": ["/home/xionglei/GameProject/SutdyGame-godot/scripts/dev/mcp_bridge/mcp_godot_bridge.js"]
   }
   ```
3. 保存配置文件。在下次会话启动或终端唤醒时，我将自动作为调用端连接此服务，这意味着**我能够直接在对话中帮你操作你的 Godot 场景与运行测试**！

---

## 🚀 第二步.四：在 Codex 命令行工具中配置

如果你使用本地安装的 **Codex CLI** 终端工具来进行 AI 辅助开发，它也可以随时调用此服务！

我已经通过命令行**成功为你完成了这一步的注册**。你可以直接在终端中运行以下命令来查看或管理它：

* **查看已注册的服务器列表**：
  ```bash
  codex mcp list
  ```
  你将能看到 `study-game-godot` 处于 `enabled` 状态。
  
* **手动注册命令（供参考）**：
  ```bash
  codex mcp add study-game-godot -- node /home/xionglei/GameProject/SutdyGame-godot/scripts/dev/mcp_bridge/mcp_godot_bridge.js
  ```

每次你在终端中唤醒 `codex` 开始新的会话，Codex 就会自动加载该服务，让你直接在命令行终端里呼唤 AI 去操作游戏、抓取截图或做模拟测试！

---




## 🎮 第三步：启动 Godot 并享受 AI 协同

1. 用 Godot 打开你的 `SutdyGame-godot` 项目。
2. 确保在 **Project Settings** -> **Plugins** 中启用了 `addons/godot_mcp` 开源插件。
3. 编辑器启动后，它会自动建立与本地 Node.js 服务的 WebSocket 连接。你可以看到桥接终端中输出：
   `[Godot MCP Bridge] Godot Editor plugin successfully connected!`
4. 现在，你可以在 Cursor 的 Chat (Ctrl+L) 或 Composer (Ctrl+I) 中对 AI 助手说：
   > *"帮我看看当前编辑器里打开的场景树，然后帮我截图看看运行中的游戏画面。"*

AI 将会直接通过你搭建的免费桥接通道与 Godot 编辑器进行流畅的交互！

---

## 🧰 工具箱功能列表

该自建桥接服务预先集成了 **24 个强大的核心开发与自动化 QA 测试工具**：

1. **项目与文件系统**：`get_project_info`、`get_filesystem_tree`
2. **场景节点操作（撤销历史安全）**：`get_scene_tree`、`get_node_properties`、`update_property`、`add_node`、`connect_signal`
3. **GDScript 脚本控制**：`read_script`、`create_script`、`edit_script`、`validate_script`
4. **游戏测试与输入模拟**：`play_scene`、`stop_scene`、`get_game_screenshot`、`simulate_key`、`simulate_mouse_click`、`simulate_action`
5. **游戏运行期高阶洞察（QA 自动化）**：`get_game_scene_tree`、`get_game_node_properties`、`set_game_node_property`、`click_button_by_text`、`wait_for_node`、`capture_frames`、`monitor_properties`

---
*祝你用 AI 辅助开发愉快！如果有任何问题，可以随时让你的 AI 助手协助调试。*
