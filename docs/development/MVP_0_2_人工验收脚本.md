# MVP 0.2 人工验收脚本

> 项目：StudyGame  
> 文档性质：`MVP 0.2` 历史人工验收脚本留档。  
> 验收目标：从新存档开始，回放当时的 MVP 0.2 home-first 微序章 + 4 个正式生活事件垂直切片人工验证  
> 写入范围：本脚本仅用于人工验收记录，不修改核心玩法  
> 建议时长：成人熟练试玩 2-5 分钟；儿童首次试玩预期更长  
> 说明：该流程用于保留历史验证证据，不代表当前产品基线或当前路线边界。

## 1. 测试前准备

推荐先运行串联脚本执行人工试玩主路径：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
./scripts/dev/run_mvp_0_2_manual_playtest.sh
```

该脚本会串联 preflight、启动游戏、游戏关闭后的 postflight 报告核验和 Markdown 摘要导出；它要求交互终端，以便在外部秒表准备好后按 Enter 启动游戏，非交互环境会拒绝运行。它不会自动填写人工结论，不会自动修改 `MVP_0_2_试玩计时记录.md` 或 `MVP_0_2_验收记录.md`。如需逐步排查，按下列分步流程执行。

### 1.1 环境记录

验收前记录：

- Godot 版本：
- 操作系统：
- 测试日期：
- 构建来源或分支：
- 屏幕分辨率：
- 输入设备：鼠标 / 触控板 / 触屏

### 1.2 新存档准备

1. 关闭正在运行的游戏。
2. 运行 preflight 脚本清理默认存档、旧计时报告和旧摘要，并验证人工试玩起跑线：

   ```bash
   cd /home/xionglei/GameProject/SutdyGame-godot
   godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_preflight.gd
   ```

3. 确认脚本输出中 `study_game_save.json`、`mvp_0_2_playtest_report.json` 和 `mvp_0_2_playtest_report_summary.md` 已删除或不存在。
4. 启动项目主场景：

   ```bash
   cd /home/xionglei/GameProject/SutdyGame-godot
   godot --path .
   ```

预期画面：

- 游戏从初始进度开始。
- 首屏不是空白、报错窗口或纯调试占位。
- 当前 runtime 首屏进入 `HomeLayer`；从家打开 `world_overview` 后，构图同时显示 `home`、`Sunshine School` 和基础 UI。

通过标准：

- 没有读取到旧事件完成状态。
- 没有自动跳到教室或花园完成态。
- 没有崩溃、脚本错误弹窗或无法操作状态。

### 1.3 试玩后报告核验

完成完整试玩后：

1. 在家长摘要中点击“完成摘要阅读”。
2. 点击“导出计时报告”。
3. 关闭游戏或保持游戏窗口打开均可。
4. 运行试玩后 postflight 脚本，核验报告并导出 Markdown 摘要：

   ```bash
   cd /home/xionglei/GameProject/SutdyGame-godot
   godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_postflight.gd
   ```

通过标准：

- 脚本能读取 `user://mvp_0_2_playtest_report.json`。
- 报告 schema、事件、Story Show、节点、计时字段完整。
- 脚本导出 `user://mvp_0_2_playtest_report_summary.md`。
- 如果用时不在成人熟练 2-5 分钟参考窗口内，脚本输出 `TIMING_OUT_OF_TARGET`，人工记录需选择有条件通过或不通过。
- 报告仍要求人工填写结论，不会自动判定 MVP 通过。

如需拆分执行，也可先核验报告，再导出可粘贴到计时记录的 Markdown 摘要：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
godot --headless --path . -s res://tests/mvp_0_2_verify_playtest_report.gd
godot --headless --path . -s res://tests/mvp_0_2_export_playtest_summary.gd
```

摘要输出到 `user://mvp_0_2_playtest_report_summary.md`，只包含事实证据和人工结论占位。postflight 和拆分命令都不会自动判定 MVP 通过。

填写试玩计时记录并选择唯一人工结论后，可运行最终 gate 检查：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
godot --headless --path . -s res://tests/mvp_0_2_manual_final_gate.gd
```

该脚本只检查人工证据是否已记录且和验收记录状态一致，不会自动替代人工结论；分段计时必须使用 `MM:SS`，每行开始/结束/用时要自洽，总用时要和导出报告在 60 秒容差内一致。

## 2. World Overview 起步区：移动、提示与对话

### 2.1 基础移动

操作步骤：

1. 使用方向键或项目支持的移动输入，让玩家向左、右、上、下移动。
2. 观察镜头是否跟随玩家，或尝试拖拽浏览大地图。
3. 停在 `home` 或 `Sunshine School` 附近的起步区域。

预期画面：

- 玩家角色跟随输入移动，移动方向和速度稳定。
- 镜头能跟随玩家，或允许拖拽查看 world overview。
- 玩家不会穿过主要边界或离开可玩区域。
- 靠近起步区域中的 Mina 后出现可交互提示。

通过标准：

- 连续移动 10 秒内无卡死、抖动、瞬移或穿墙。
- 角色停下后位置稳定。
- NPC 提示只在合理距离内出现，离开后消失。

### 2.2 Mina 对话

操作步骤：

1. 从 `home` 起步区域靠近 Mina。
2. 按项目提示的交互键或点击 Mina。
3. 逐屏推进对话，直到Quest 提示出现。

预期画面：

- Mina 对话框正常出现。
- 文本简短、完整显示，不溢出对话框。
- Quest 提示包含 `Find Mina's story stop.`

通过标准：

- 对话能从开始推进到结束。
- 每屏主要文本适合儿童阅读，建议不超过 2 行。
- 结束后进入 Walk With Mina，没有重复打开空白对话。

## 3. Walk With Mina：点击小游戏

### 3.1 错误点击反馈

操作步骤：

1. 在 Quest 激活后，点击非 `library` 的目标，例如 classroom 或 playground。
2. 观察 Quest Diary 和反馈。

预期画面：

- 出现温和错误反馈或 Quest 提示仍保持。
- 事件没有完成。
- 玩家仍可继续点击其他目标。

通过标准：

- 错误点击不会发放奖励。
- 错误点击不会锁死输入。
- Quest 提示仍能让玩家理解下一步要找 library。

### 3.2 正确点击完成事件

操作步骤：

1. 点击 `library` 对应的画面目标。
2. 观察事件完成反馈和奖励。
3. 再次点击 `library`。

预期画面：

- Walk With Mina 完成。
- 展示 “Adventure Star” 奖励；`school_star_piece` 仅作为存档/报告兼容 ID 核验。
- 家长摘要/报告层记录应包含 `classroom`、`library`、`playground`。

通过标准：

- 正确点击能稳定命中视觉目标。
- 完成后不会重复发奖。
- 重复点击不会重复触发完成逻辑。
- 流程引导能自然进入教室或解锁下一个事件。

## 4. 教室：NPC 提示、对话与拖拽

### 4.1 Leo 提示与对话

操作步骤：

1. 进入教室后移动到 Leo 附近。
2. 观察交互提示。
3. 与 Leo 对话并推进到Quest 开始。

预期画面：

- 教室内能看到 Leo、书桌、架子、书包、书、铅笔等整理目标。
- 靠近 Leo 出现交互提示，离开后提示消失。
- Quest 提示包含 `Help Leo set up the story room.`

通过标准：

- 教室不是空白场景。
- Leo 对话完整显示且不溢出 UI。
- 对话结束后 Room Helper 可操作。

### 4.2 拖拽错误放置

操作步骤：

1. 拖动 `book` 到错误区域，例如 desk。
2. 释放鼠标或触控输入。
3. 观察物品和 Quest 状态。

预期画面：

- 物品回到原位，或出现清晰的错误提示。
- Room Helper 未完成。
- 仍可继续拖动物品。

通过标准：

- 拖拽过程中物品不丢失。
- 错误放置不会卡死游戏。
- 目标区域和反馈足够清楚，儿童能继续尝试。

### 4.3 拖拽正确放置

操作步骤：

1. 将 `book` 拖到 `shelf`。
2. 将 `pencil` 拖到 `desk`。
3. 将 `bag` 拖到 `under_desk`。
4. 观察事件完成反馈和奖励。

预期画面：

- 每个物品放对后锁定在正确位置，或进入明确完成态。
- Room Helper 完成。
- 展示 “Room Helper Badge” 奖励；`tidy_badge_piece` 仅作为存档/报告兼容 ID 核验。
- 家长摘要/报告层记录应包含 `book`、`bag`、`pencil`、`desk`、`shelf`。

通过标准：

- 正确目标区域足够大，合理拖放能命中。
- 放对后物品不会被后续输入破坏。
- 完成后不会重复发奖。
- 流程引导能自然进入花园或解锁下一个事件。

## 5. 花园：NPC 提示、对话与点击

### 5.1 Nora 提示与对话

操作步骤：

1. 进入花园后移动到 Nora 附近。
2. 观察交互提示。
3. 与 Nora 对话并推进到Quest 开始。

预期画面：

- 花园内能看到 Nora、tree、flower、bench、bird 等关键目标。
- 靠近 Nora 出现交互提示，离开后提示消失。
- Quest 提示包含 `Find the bird in the garden.`

通过标准：

- 花园不是空白场景。
- Nora 对话完整显示且不溢出 UI。
- 对话结束后 Bird Watch 可操作。

### 5.2 错误点击与正确点击

操作步骤：

1. 先点击非 `bird` 的目标，例如 bench、tree 或 flower。
2. 观察反馈。
3. 点击 `bird`。
4. 再次点击 `bird`。

预期画面：

- 错误点击后事件未完成，并保留温和提示。
- 点击 bird 后 Bird Watch 完成。
- 展示 “Garden Leaf Charm” 奖励；`garden_leaf_piece` 仅作为存档/报告兼容 ID 核验。
- 家长摘要/报告层记录应包含 `garden`、`tree`、`flower`、`bird`。

通过标准：

- bird 的视觉目标清晰可辨，点击区域与画面目标匹配。
- 错误点击不会锁死输入。
- 正确点击只完成一次，不重复发奖。
- 完成后出现可见完成态或明确完成反馈。

## 6. 家长摘要

### 6.0 儿童 Story Show

操作步骤：

1. 完成 Bird Watch 后，观察是否出现 Story Show。
2. 逐个完成 Story Show 的找物、选择和口述展示。
3. 故意选错 1 次，观察反馈。
4. 完成全部 25 题。

预期画面：

- Story Show 显示当前进度，例如 `Show 1 / 25`。
- 六道 `Read aloud` / 口述题会先显示朗读倒计时或朗读中提示，倒计时结束后才出现确认按钮。
- 错误选择不会推进题目，并给出温和提示。
- 正确完成 25 题后进入家长摘要。

通过标准：

- Story Show 覆盖 library、book、bag、bird、tree 等已遇到的故事线索。
- 朗读题倒计时期间不能直接跳过。
- Story Show 不跳题、不重复完成、不阻塞摘要打开。
- 题目和选项文字不溢出。

### 6.1 打开摘要

操作步骤：

1. 完成 `Welcome Box` 微序章、4 个正式 MVP 前台事件（`First Trip`、`Walk With Mina`、`Room Helper`、`Bird Watch`）和儿童 Story Show 后，打开或查看自动出现的家长摘要。
2. 阅读摘要页面 30 秒。
3. 点击“完成摘要阅读”，记录停止计时时间。
4. 点击“导出计时报告”。

预期画面：

- 摘要页面可达，且不暴露复杂调试数据。
- 今日完成事件显示当前正式 gate 的 4 项：`First Trip`、`Walk With Mina`、`Room Helper`、`Bird Watch`；`Welcome Box` 可作为微序章出现在历史记录或奖励列表中，但不计入 Parent Bonus 正式 gate。
- 家长层词汇记录至少包含 `library`、`book`、`bird`。
- 家长层表达记录至少包含 `This is the library.`、`Put the book on the shelf.`、`Where is the bird?`
- 页面显示建议回访内容。

通过标准：

- 家长能在 30 秒内理解孩子完成了什么、学了什么、接下来可以继续什么。
- 文字没有重叠、截断或超出面板。
- 空间布局适合阅读，不需要猜测字段含义。
- 未完成 4 个正式 MVP 前台事件和 25 题 Story Show 前，不能提前完成摘要阅读并导出正式报告。

### 6.2 摘要空状态补测

操作步骤：

1. 清理存档并重新启动。
2. 不完成事件，直接打开家长摘要。

预期画面：

- 今日完成事件为 0 或等价空状态。
- 奖励、单词、句型为空状态。
- 建议回访内容指向第一个待完成事件，例如 `Find Mina's story stop.`

通过标准：

- 摘要不崩溃。
- 空状态文案清楚，不显示 `null`、空数组或调试字段。

## 7. 存档退出重进

### 7.1 完成 1 个生活事件后重进

操作步骤：

1. 从新存档开始，只完成 Walk With Mina。
2. 正常退出游戏。
3. 重新启动游戏。

预期画面：

- Walk With Mina 保持已完成。
- Adventure Star 保留；`school_star_piece` 仅作为存档兼容 ID 保留。
- 家长摘要/报告层词汇和表达记录保留。
- 不会再次自动发放 Walk With Mina 奖励。

通过标准：

- 重进后进度和 UI 一致。
- Mina 或 Quest 系统不会重复触发 Walk With Mina 完成奖励。
- 玩家可以继续 Room Helper。

### 7.2 完成 4 个正式 MVP 前台事件后重进

操作步骤：

1. 完成 First Trip、Walk With Mina、Room Helper、Bird Watch。
2. 打开家长摘要确认 4 个正式 MVP 前台事件完成。
3. 正常退出游戏。
4. 重新启动游戏。
5. 再次打开家长摘要。

预期画面：

- 4 个正式 MVP 前台事件均保持已完成。
- 4 个正式 gate 奖励均保留；Welcome Box 微序章奖励可作为历史记录保留。
- 家长摘要/报告层词汇和表达记录保留。
- 摘要仍显示 4 个正式完成事件和回访建议。

通过标准：

- 重进后不会回退到新存档。
- 已完成事件不会重复发奖。
- 摘要数据和退出前一致。
- 游戏仍可移动、打开 UI、与场景互动，不进入不可操作状态。

## 8. 素材与视觉安全快速检查

操作步骤：

1. 在 world overview / school 起步区、教室、花园分别停留观察。
2. 检查关键交互目标在实际尺寸下是否可辨。
3. 检查场景、角色、道具是否出现商业 IP、真实品牌 Logo、学校名或可识别人像。

预期画面：

- 场景能清楚表达 world overview / school 起步区、教室、花园。
- 角色为原创儿童友好形象。
- 图片没有明显拉伸、黑边、透明通道错误或遮挡核心目标。

通过标准：

- 未发现 `Barbie`、`Disney`、`Pixar`、`Sanrio` 等商业 IP 元素或文字。
- 关键互动目标在当前游戏尺寸下可识别。
- 素材不会妨碍点击、拖拽或阅读。

## 9. 验收记录模板

| 编号 | 验收项 | 结果 | 问题描述 | 截图/录屏 | 严重度 |
|---|---|---|---|---|---|
| 1 | 新存档启动 | 未测 |  |  |  |
| 2 | 移动与边界 | 未测 |  |  |  |
| 3 | Mina 提示与对话 | 未测 |  |  |  |
| 4 | Walk With Mina | 未测 |  |  |  |
| 5 | Leo 提示与对话 | 未测 |  |  |  |
| 6 | Room Helper | 未测 |  |  |  |
| 7 | Nora 提示与对话 | 未测 |  |  |  |
| 8 | Bird Watch | 未测 |  |  |  |
| 9 | Story Show 25 题 | 未测 |  |  |  |
| 10 | 完成摘要阅读/计时停止 | 未测 |  |  |  |
| 11 | 导出计时报告 | 未测 |  |  |  |
| 12 | 导出 Markdown 摘要 | 未测 |  |  |  |
| 13 | 家长摘要完成态 | 未测 |  |  |  |
| 14 | 家长摘要空状态 | 未测 |  |  |  |
| 15 | 完成 1 事件后重进 | 未测 |  |  |  |
| 16 | 完成 3 事件后重进 | 未测 |  |  |  |
| 17 | 素材与视觉安全 | 未测 |  |  |  |

结果填写建议：通过 / 不通过 / 阻塞 / 不适用。

严重度填写建议：

- S1：崩溃、无法启动、主流程完全阻塞。
- S2：事件无法完成、存档丢失、重复发奖、关键 UI 不可读。
- S3：反馈不清楚、点击区域偏差、视觉遮挡但可绕过。
- S4：文案、排版、观感类轻微问题。
