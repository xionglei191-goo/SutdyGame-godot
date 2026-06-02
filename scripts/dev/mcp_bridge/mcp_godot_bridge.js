#!/usr/bin/env node

/**
 * StudyGame Godot MCP Server Bridge
 * 
 * A 100% free, lightweight, and robust Node.js bridge that connects standard desktop
 * AI assistants (Cursor, Claude Code, etc.) to the Godot 4 Editor WebSocket client.
 * 
 * Architecture:
 * 1. Speaks MCP (Model Context Protocol) via Stdio (Standard I/O) with the IDE.
 * 2. Opens a local WebSocket Server on port 6505 for the Godot Editor plugin client to connect to.
 * 3. Acts as a dynamic pass-through proxy for tool calls, routing them into Godot
 *    and returning responses asynchronously.
 *
 * NOTE: All diagnostic logging uses console.error() (stderr) intentionally.
 * MCP's Stdio transport reserves stdout exclusively for JSON-RPC messages;
 * writing anything else to stdout would corrupt the protocol stream.
 */

const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const { WebSocketServer } = require("ws");
const { CallToolRequestSchema, ListToolsRequestSchema } = require("@modelcontextprotocol/sdk/types.js");

// --- WebSocket Configurations ---
const BASE_PORT = 6505;
const MAX_PORT = 6514;
const REQUEST_TIMEOUT_MS = 60000; // 60 seconds before a pending tool call is auto-rejected
let PORT = BASE_PORT;
let wss = null;
let godotWs = null;
const pendingRequests = new Map(); // id -> { resolve, reject, timer }
let requestIdCounter = 0;

function startWebSocketServer(port) {
    if (port > MAX_PORT) {
        console.error(`[Godot MCP Bridge] Critical: All ports in range ${BASE_PORT}-${MAX_PORT} are already in use!`);
        process.exit(1);
    }

    // Try creating server on the current candidate port
    const candidateServer = new WebSocketServer({ port: port });

    candidateServer.on("listening", () => {
        wss = candidateServer;
        PORT = port;
        console.error(`[Godot MCP Bridge] WebSocket server listening on ws://127.0.0.1:${PORT}`);
        setupWssEvents();
    });

    candidateServer.on("error", (err) => {
        if (err.code === "EADDRINUSE") {
            console.error(`[Godot MCP Bridge] Port ${port} in use, trying next port ${port + 1}...`);
            startWebSocketServer(port + 1);
        } else {
            console.error(`[Godot MCP Bridge] WebSocket server error:`, err.message);
            process.exit(1);
        }
    });
}

/**
 * Reject all pending requests with a given error message and clear the map.
 * Also clears associated timeout timers.
 */
function rejectAllPending(reason) {
    for (const [id, entry] of pendingRequests) {
        if (entry.timer) clearTimeout(entry.timer);
        entry.reject(new Error(reason));
    }
    pendingRequests.clear();
}

function setupWssEvents() {
    wss.on("connection", (ws) => {
        // If an existing Godot connection is still open, close it gracefully
        // and reject its pending requests before accepting the new one.
        if (godotWs && godotWs.readyState === godotWs.OPEN) {
            console.error("[Godot MCP Bridge] New Godot connection received — closing previous connection.");
            rejectAllPending("Godot WebSocket 被新连接替换，旧请求已取消");
            godotWs.close();
        }

        godotWs = ws;
        console.error(`[Godot MCP Bridge] Godot Editor plugin successfully connected to port ${PORT}!`);

        ws.on("message", (message) => {
            try {
                const payload = JSON.parse(message.toString());

                // Handle periodic ping from Godot to reset inactivity/keepalive
                if (payload.method === "ping") {
                    ws.send(JSON.stringify({ jsonrpc: "2.0", method: "pong", params: {} }));
                    return;
                }

                // Resolve pending tool executions from Cursor/Claude Code
                if (payload.id !== undefined && pendingRequests.has(payload.id)) {
                    const entry = pendingRequests.get(payload.id);
                    pendingRequests.delete(payload.id);
                    if (entry.timer) clearTimeout(entry.timer);

                    if (payload.error) {
                        entry.reject(new Error(payload.error.message || `Godot returned error code ${payload.error.code}`));
                    } else {
                        entry.resolve(payload.result);
                    }
                }
            } catch (err) {
                console.error("[Godot MCP Bridge] Error parsing WebSocket packet:", err.message);
            }
        });

        ws.on("close", () => {
            if (godotWs === ws) {
                godotWs = null;
                // Reject all pending requests — Godot will never reply to them now
                rejectAllPending("Godot WebSocket 连接已断开");
            }
            console.error(`[Godot MCP Bridge] Godot Editor connection closed on port ${PORT}.`);
        });

        ws.on("error", (err) => {
            console.error(`[Godot MCP Bridge] WebSocket client error:`, err.message);
        });
    });
}

// Start scanning for a free port from the base port
startWebSocketServer(BASE_PORT);


// --- MCP Server Definitions ---
const server = new Server(
    { name: "study-game-godot-bridge", version: "1.0.0" },
    { capabilities: { tools: {} } }
);

// Map of registered tools and their specifications
const toolsRegistry = [
    // --- 1. Project & File System Tools ---
    {
        name: "get_project_info",
        description: "获取 Godot 项目的基础配置信息（如项目名、Godot 版本、主视口尺寸、渲染器等）",
        inputSchema: { type: "object", properties: {} }
    },
    {
        name: "get_filesystem_tree",
        description: "获取项目的文件系统树。支持使用扩展名进行过滤，如 '*.tscn' 或 '*.gd'",
        inputSchema: {
            type: "object",
            properties: {
                filter: { type: "string", description: "Glob 过滤规则，例如 *.gd" }
            }
        }
    },
    
    // --- 2. Editor Scene & Node Tools ---
    {
        name: "get_scene_tree",
        description: "获取当前 Godot 编辑器中打开的场景的节点层级树结构",
        inputSchema: {
            type: "object",
            properties: {
                max_depth: { type: "integer", default: -1, description: "遍历深度层级限制，-1 表示无限制" }
            }
        }
    },
    {
        name: "get_node_properties",
        description: "获取编辑器中指定节点的属性列表与其当前值",
        inputSchema: {
            type: "object",
            properties: {
                node_path: { type: "string", description: "节点绝对或相对路径" },
                properties: { type: "array", items: { type: "string" }, description: "可选，只获取指定的属性" }
            },
            required: ["node_path"]
        }
    },
    {
        name: "update_property",
        description: "修改编辑器中指定节点的某个属性值（如 position, modulate, size）。该操作会注册到 Undo 系统，可被 Ctrl+Z 撤销",
        inputSchema: {
            type: "object",
            properties: {
                node_path: { type: "string", description: "目标节点的绝对路径" },
                property: { type: "string", description: "属性名，如 modulate" },
                value: { type: ["string", "number", "integer", "boolean", "array", "object", "null"], description: "属性值，支持 Vector2('100, 200') 或 Color('#ff0000') 格式的字符串" }
            },
            required: ["node_path", "property", "value"]
        }
    },
    {
        name: "add_node",
        description: "在当前编辑中的场景树里新建一个子节点，注册到 Undo 系统",
        inputSchema: {
            type: "object",
            properties: {
                parent_path: { type: "string", description: "父节点的绝对路径" },
                node_type: { type: "string", description: "节点类型，如 Button 或 Sprite2D" },
                node_name: { type: "string", description: "新节点的名称" },
                properties: { type: "object", description: "初始化属性字典，如 {'text': 'Hello'}" }
            },
            required: ["parent_path", "node_type", "node_name"]
        }
    },
    {
        name: "connect_signal",
        description: "在编辑器中将某个节点的信号绑定到另一个节点的回调函数上",
        inputSchema: {
            type: "object",
            properties: {
                source_node_path: { type: "string", description: "发射信号的节点路径" },
                signal_name: { type: "string", description: "信号名称，如 pressed" },
                target_node_path: { type: "string", description: "接收信号并挂载脚本的节点路径" },
                method_name: { type: "string", description: "回调函数的方法名，如 _on_button_pressed" }
            },
            required: ["source_node_path", "signal_name", "target_node_path", "method_name"]
        }
    },

    // --- 3. Script Manipulation Tools ---
    {
        name: "read_script",
        description: "读取指定 GDScript 脚本文件的全部源代码内容",
        inputSchema: {
            type: "object",
            properties: {
                script_path: { type: "string", description: "脚本文件绝对路径，以 res:// 开头，如 res://scripts/core/game_state.gd" }
            },
            required: ["script_path"]
        }
    },
    {
        name: "create_script",
        description: "在指定路径新建一个 GDScript 脚本文件并写入源码内容",
        inputSchema: {
            type: "object",
            properties: {
                script_path: { type: "string", description: "脚本路径，如 res://tests/my_test.gd" },
                content: { type: "string", description: "完整的 GDScript 源码" }
            },
            required: ["script_path", "content"]
        }
    },
    {
        name: "edit_script",
        description: "对已有的 GDScript 脚本文件进行局部精准修改",
        inputSchema: {
            type: "object",
            properties: {
                script_path: { type: "string", description: "脚本路径" },
                replacements: {
                    type: "array",
                    items: {
                        type: "object",
                        properties: {
                            search: { type: "string", description: "要搜索的旧代码块" },
                            replace: { type: "string", description: "要替换的全新代码块" }
                        },
                        required: ["search", "replace"]
                    },
                    description: "替换的块列表"
                }
            },
            required: ["script_path", "replacements"]
        }
    },
    {
        name: "validate_script",
        description: "在 Godot 后台对指定的 GDScript 脚本运行一次快速编译期语法校验",
        inputSchema: {
            type: "object",
            properties: {
                script_path: { type: "string", description: "要验证的脚本路径" }
            },
            required: ["script_path"]
        }
    },

    // --- 4. Playtest Controls & Input Simulation ---
    {
        name: "play_scene",
        description: "启动游戏播放（可选择启动当前场景、主场景或指定场景文件）",
        inputSchema: {
            type: "object",
            properties: {
                mode: { type: "string", enum: ["current", "main", "custom"], default: "current", description: "启动模式" },
                custom_scene_path: { type: "string", description: "仅在 custom 模式下有效，指定 .tscn 路径" }
            }
        }
    },
    {
        name: "stop_scene",
        description: "立即关闭并停止当前正在运行的游戏进程",
        inputSchema: { type: "object", properties: {} }
    },
    {
        name: "get_game_screenshot",
        description: "异步触发并截取当前运行中游戏的视口画面，返回 Base64 编码的 PNG 图片数据",
        inputSchema: { type: "object", properties: {} }
    },
    {
        name: "simulate_key",
        description: "向运行中的游戏进程发送按键按下并释放的事件。支持配置按下持续时间（秒）",
        inputSchema: {
            type: "object",
            properties: {
                keycode: { type: "string", description: "按键常数字符串，例如 KEY_A, KEY_SPACE, KEY_ENTER" },
                pressed: { type: "boolean", default: true, description: "是否为按下事件" },
                duration: { type: "number", default: 0.1, description: "按键按下持续的时间（秒）" }
            },
            required: ["keycode"]
        }
    },
    {
        name: "simulate_mouse_click",
        description: "向运行中的游戏进程发送指定视口坐标处的鼠标点击事件",
        inputSchema: {
            type: "object",
            properties: {
                position: {
                    type: "object",
                    properties: {
                        x: { type: "number" },
                        y: { type: "number" }
                    },
                    required: ["x", "y"]
                },
                button: { type: "integer", default: 1, description: "鼠标按键索引。1: 左键, 2: 右键" },
                double_click: { type: "boolean", default: false, description: "是否是双击" }
            },
            required: ["position"]
        }
    },
    {
        name: "simulate_action",
        description: "触发 Godot 运行环境 InputMap 里定义好的某个映射输入动作（如ui_accept, ui_right）",
        inputSchema: {
            type: "object",
            properties: {
                action: { type: "string", description: "动作名称" },
                pressed: { type: "boolean", default: true },
                strength: { type: "number", default: 1.0 }
            },
            required: ["action"]
        }
    },

    // --- 5. Game Runtime Inspection ---
    {
        name: "get_game_scene_tree",
        description: "获取正在运行中游戏的实时活动场景树（Active Scene Tree）层级结构",
        inputSchema: {
            type: "object",
            properties: {
                max_depth: { type: "integer", default: -1 }
            }
        }
    },
    {
        name: "get_game_node_properties",
        description: "读取运行中游戏指定活节点当前真实的物理属性与变量值",
        inputSchema: {
            type: "object",
            properties: {
                node_path: { type: "string", description: "运行时的节点绝对路径，如 /root/Main/Player" },
                properties: { type: "array", items: { type: "string" }, description: "指定要查询的变量属性，若为空则获取全部常用属性" }
            },
            required: ["node_path"]
        }
    },
    {
        name: "set_game_node_property",
        description: "在运行期动态修改指定活节点的某个变量属性值（例如修改角色生命值、改变怪物位置）",
        inputSchema: {
            type: "object",
            properties: {
                node_path: { type: "string", description: "节点运行时绝对路径" },
                property: { type: "string", description: "变量/属性名称" },
                value: { type: ["string", "number", "integer", "boolean", "array", "object", "null"], description: "要设置的值" }
            },
            required: ["node_path", "property", "value"]
        }
    },
    {
        name: "click_button_by_text",
        description: "在游戏运行时的 HUD / UI 节点树中，自动检索文本文字内容包含 target_text 的所有 Button 按钮并自动模拟点击它",
        inputSchema: {
            type: "object",
            properties: {
                text: { type: "string", description: "按钮上显示的文本，例如 '完成摘要阅读'" }
            },
            required: ["text"]
        }
    },
    {
        name: "wait_for_node",
        description: "轮询等待，直到指定的节点路径在游戏运行时场景树中成功实例化并出现",
        inputSchema: {
            type: "object",
            properties: {
                node_path: { type: "string", description: "节点绝对路径" },
                timeout_seconds: { type: "number", default: 5.0 }
            },
            required: ["node_path"]
        }
    },
    {
        name: "capture_frames",
        description: "高频捕获游戏运行期连续多帧的画面快照，用以审计流畅度、动效衔接或玩家 waddle Sway 摇晃动画",
        inputSchema: {
            type: "object",
            properties: {
                count: { type: "integer", default: 5, description: "帧捕获总数" },
                frame_interval: { type: "integer", default: 10, description: "每隔多少帧抓取一次" },
                half_resolution: { type: "boolean", default: true, description: "是否使用半分辨率来提高处理速度" }
            }
        }
    },
    {
        name: "monitor_properties",
        description: "在游戏运行期连续监测某节点的多项属性在多帧间的渐变数据采样，绘制运动曲线",
        inputSchema: {
            type: "object",
            properties: {
                node_path: { type: "string", description: "监测节点路径" },
                properties: { type: "array", items: { type: "string" }, description: "渐变变量属性列表，如 ['position', 'velocity']" },
                frame_count: { type: "integer", default: 60, description: "监测的帧总数" },
                frame_interval: { type: "integer", default: 1, description: "采样间隔帧数" }
            },
            required: ["node_path", "properties"]
        }
    }
];

function normalizeToolParams(name, params = {}) {
    const normalized = { ...params };

    if (
        ["read_script", "create_script", "edit_script", "validate_script"].includes(name) &&
        normalized.script_path &&
        !normalized.path
    ) {
        normalized.path = normalized.script_path;
    }

    if (name === "add_node") {
        if (normalized.node_type && !normalized.type) {
            normalized.type = normalized.node_type;
        }
        if (normalized.node_name && !normalized.name) {
            normalized.name = normalized.node_name;
        }
    }

    if (name === "connect_signal") {
        if (normalized.source_node_path && !normalized.source_path) {
            normalized.source_path = normalized.source_node_path;
        }
        if (normalized.target_node_path && !normalized.target_path) {
            normalized.target_path = normalized.target_node_path;
        }
    }

    if (name === "simulate_mouse_click" && normalized.position) {
        if (normalized.position.x !== undefined && normalized.x === undefined) {
            normalized.x = normalized.position.x;
        }
        if (normalized.position.y !== undefined && normalized.y === undefined) {
            normalized.y = normalized.position.y;
        }
    }

    if (name === "play_scene" && normalized.mode === "custom" && normalized.custom_scene_path) {
        normalized.mode = normalized.custom_scene_path;
    }

    return normalized;
}

// --- MCP Request Routing ---
// 1. tools/list: Tell the IDE client what tools we support
server.setRequestHandler(ListToolsRequestSchema, async (request) => {
    return { tools: toolsRegistry };
});

// 2. tools/call: Route the selected tool call to the connected Godot WebSocket
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: rawParams } = request.params;
    const params = normalizeToolParams(name, rawParams);

    if (!godotWs) {
        return {
            content: [{
                type: "text",
                text: "【自建桥接错误】Godot 4 编辑器目前未运行，或者您没有在编辑器中启用 'addons/godot_mcp' 插件插件！请确保 Godot 编辑器处于打开状态。"
            }],
            isError: true
        };
    }

    // Return a Promise that resolves when Godot replies to this exact ID
    return new Promise((resolve) => {
        const id = ++requestIdCounter;

        const doResolve = (result) => {
            resolve({
                content: [{
                    type: "text",
                    text: typeof result === "object" ? JSON.stringify(result, null, 2) : String(result)
                }]
            });
        };

        const doReject = (err) => {
            resolve({
                content: [{
                    type: "text",
                    text: `【Godot 运行时执行错误】: ${err.message}`
                }],
                isError: true
            });
        };

        // Auto-reject after timeout to prevent permanently hung promises
        const timer = setTimeout(() => {
            if (pendingRequests.has(id)) {
                pendingRequests.delete(id);
                console.error(`[Godot MCP Bridge] Request #${id} (${name}) timed out after ${REQUEST_TIMEOUT_MS / 1000}s`);
                doReject(new Error(`Godot 响应超时 (${REQUEST_TIMEOUT_MS / 1000}s)，工具: ${name}`));
            }
        }, REQUEST_TIMEOUT_MS);

        pendingRequests.set(id, {
            resolve: doResolve,
            reject: doReject,
            timer: timer
        });

        // Pack standard JSON-RPC 2.0 packet and dispatch over WebSocket to Godot
        const packet = JSON.stringify({
            jsonrpc: "2.0",
            id: id,
            method: name,
            params: params || {}
        });
        godotWs.send(packet);
    });
});

// --- Graceful Shutdown ---
function gracefulShutdown(signal) {
    console.error(`[Godot MCP Bridge] Received ${signal}, shutting down...`);
    rejectAllPending("MCP Bridge 正在关闭");
    if (godotWs && godotWs.readyState === godotWs.OPEN) {
        godotWs.close();
    }
    if (wss) {
        wss.close(() => {
            console.error("[Godot MCP Bridge] WebSocket server closed.");
            process.exit(0);
        });
        // Force exit after 2 seconds if close callback hangs
        setTimeout(() => process.exit(0), 2000);
    } else {
        process.exit(0);
    }
}
process.on("SIGINT", () => gracefulShutdown("SIGINT"));
process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));

// --- Server Transport Connection ---
const transport = new StdioServerTransport();
server.connect(transport)
    .then(() => {
        console.error("[Godot MCP Bridge] Custom Bridge Server successfully connected via Stdio transport.");
    })
    .catch((err) => {
        console.error("[Godot MCP Bridge] Critical failed to initialize transport:", err.message);
    });
