# MVP 0.2 验收记录

> 项目：StudyGame  
> 版本目标：MVP 0.2 home-first 微序章 + 4 个正式生活事件垂直切片  
> 依据：`docs/development/Godot开发任务拆解_v0.1.md` 中 MVP 0.2 范围与验收标准  
> 文档性质：`MVP 0.2` 历史验证记录。  
> 状态：历史验证记录；当时自动检查通过，人工体验验收通过，不作为当前产品基线。

## 1. 验收范围

- 4 个关键场景层：world overview 中的 home + school 起步区、HomeLayer、教室、花园。
- 3 个 NPC：Mina、Leo、Nora。
- 1 个 home-first 微序章事件：Welcome Box。
- 4 个连续正式 MVP 前台事件：First Trip、Walk With Mina、Room Helper、Bird Watch。
- 2 类小游戏：场景点击、拖拽放置。
- 结尾 Story Show：25 个故事线索、选择和口述展示项。
- 简单本地存档：事件状态、奖励、家长摘要用词汇/表达记录。
- 家长摘要页面：今日完成事件、接触过的词汇/表达、建议回访内容。
- 试玩计时：家长摘要显示本次试玩用时和试玩节点，点击“完成摘要阅读”后在存档快照中保留 `playtest_elapsed_*` 与 `playtest_events` 字段，并可导出 QA 计时报告。
- 第一版自生成图片素材或占位素材接入，并满足素材安全要求。

## 2. 版本准入检查

- [x] `godot --path .` 能识别并打开项目。
- [x] `godot --headless --path . --check-only --quit` 无严重错误。
- [x] 主场景能进入可操作流程，不停留在空白或调试占位画面。
- [x] 测试前能清理或隔离本地存档，避免旧存档污染任务状态。
- [x] 测试环境记录 Godot 版本、操作系统、测试日期和构建来源。
- [x] 完成回顾活动并点击“完成摘要阅读”后，家长摘要、存档快照和 QA 计时报告能记录试玩用时及节点，支持人工计时交叉核对。

## 3. 主流程验收

### 3.1 连续试玩闭环

- [x] 新存档进入游戏后，当前 runtime 首屏进入 `HomeLayer`；从家打开 `world_overview` 后，以 `home + Sunshine School` 的起步构图顺利进入第一任务。
- [x] 玩家能按顺序完成 Walk With Mina、Room Helper、Bird Watch。
- [x] 3 个任务之间的解锁、跳转或引导不会卡死。
- [x] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录。
  - 2026-05-31 人工试玩结果：外部秒表与导出报告一致为 02:13，`within_window=true`，按成人熟练试玩参考窗口判定通过；儿童首次试玩更长时长保留在计时记录中说明。
- [x] 任一任务失败、误点或放错物品后，玩家能继续尝试，不需要重启游戏。

### 3.2 场景验收

| 场景 | 必验内容 | 验收结果 | 备注 |
|---|---|---|---|
| world overview 中的 home + school 起步区 | 打开世界地图后，构图能看到 `home`、`Sunshine School`、Mina、可交互地点、通往后续内容的入口或流程引导 | 自动通过，人工观感待验 | `mvp_0_2_world_overview_input_flow.gd` 断言首屏覆盖 home 与 school，`mvp_0_2_visual_acceptance.gd` 断言 world overview 资源和热点基线存在。 |
| HomeLayer | 新开局默认进入 `HomeLayer`，可点击 Welcome Box、进行宠物照顾并返回 world overview；正式室内背景已接入 `HomeBackgroundSlot`，旧 Godot 色块层仅作隐藏备份 | 自动通过，人工观感待验 | `mvp_0_2_smoke.gd`、`mvp_0_2_home_pet_care_input_flow.gd` 和 `mvp_0_2_visual_acceptance.gd` 覆盖 home-first、宠物交互与 HomeBackgroundSlot 基线。 |
| 教室 | 能看到 Leo、Room Helper 所需物品和目标区域 | 自动通过，人工观感待验 | `mvp_0_2_smoke.gd` 断言 Leo、桌子、书架存在；拖拽目标由 `drag_place_game_smoke.gd` 和视觉验收覆盖。 |
| 花园 | 能看到 Nora、鸟/树/花/长椅等可识别目标 | 自动通过，人工观感待验 | `mvp_0_2_smoke.gd` 断言 Nora、树、鸟存在；`mvp_0_2_visual_acceptance.gd` 断言鸟/树/花/长椅点击区域覆盖视觉中心。 |

- [x] 3 个场景均非空白，关键目标清晰可辨。
- [x] 玩家移动不会穿过主要边界或离开可玩区域。
- [x] 场景切换后玩家位置、UI 和任务状态正常。
- [x] 至少 1 个场景在任务完成后发生可见变化，例如目标变为完成态、道具被摆放好、装饰或奖励出现。

### 3.3 NPC 验收

| NPC | 任务 | 必验内容 | 验收结果 | 备注 |
|---|---|---|---|---|
| Mina | Walk With Mina | 靠近提示、对话、发放 `Find Mina's story stop.` 任务 | 自动通过，人工阅读观感待验 | `mvp_0_2_input_flow.gd` 覆盖交互提示显示/隐藏；`mvp_0_2_smoke.gd` 覆盖 Mina 事件发放和完成。 |
| Leo | Room Helper | 靠近提示、对话、发放 `Help Leo set up the story room.` 任务 | 自动通过，人工阅读观感待验 | `mvp_0_2_smoke.gd` 覆盖 Leo 事件发放、拖拽小游戏显示和完成。 |
| Nora | Bird Watch | 靠近提示、对话、发放 `Find the bird in the garden.` 任务 | 自动通过，人工阅读观感待验 | `mvp_0_2_smoke.gd` 覆盖 Nora 事件发放、错误点击保持活跃和正确点击完成。 |

- [x] 玩家进入交互范围后出现提示，离开后提示消失。
- [x] 对话文本完整显示，不溢出 UI。
- [x] 每屏主要文本不超过 2 行，适合儿童阅读。
- [x] 已完成事件的 NPC 不会重复发奖或重复触发完成逻辑。

## 4. 任务验收

### 4.1 Walk With Mina

- [x] 内部兼容 ID 为 `g4_u1_school_tour`，奖励兼容 ID 为 `school_star_piece`；前台显示 Walk With Mina / Adventure Star。
- [x] 英文提示包含 `Find Mina's story stop.`
- [x] 目标包含 `classroom`、`library`、`playground`。
- [x] 点击错误目标时有温和反馈，流程不中断。
- [x] 点击正确目标后任务完成并展示 “Adventure Star” 奖励。
- [x] 家长摘要/报告层词汇记录写入 `classroom`、`library`、`playground`。
- [x] 家长摘要/报告层表达记录写入 `This is our classroom.`、`That is the playground.`。

### 4.2 Room Helper

- [x] 任务 ID 为 `g4_u1_tidy_classroom`，奖励为 `tidy_badge_piece`。
- [x] 英文提示包含 `Help Leo set up the story room.`
- [x] 可拖拽物品包含 `book`、`bag`、`pencil`。
- [x] 目标区域覆盖 `shelf`、`under_desk`、`desk`。
- [x] 放错位置后物品回到原位或出现清晰提示。
- [x] 放对位置后物品锁定或进入完成态，并推进任务。
- [x] 家长摘要/报告层词汇记录写入 `book`、`bag`、`pencil`、`desk`、`shelf`。
- [x] 家长摘要/报告层表达记录写入 `Put the book on the shelf.`、`Put the bag under the desk.`。

### 4.3 Bird Watch

- [x] 任务 ID 为 `g4_u1_garden_bird`，奖励为 `garden_leaf_piece`。
- [x] 英文提示包含 `Find the bird in the garden.`
- [x] 目标包含 `tree`、`flower`、`bench`、`bird`。
- [x] 玩家能通过场景点击或等价交互识别正确目标。
- [x] 错误点击不会卡死任务。
- [x] 完成后展示“花园叶片”奖励。
- [x] 家长摘要/报告层词汇记录写入 `garden`、`tree`、`flower`、`bird`。
- [x] 家长摘要/报告层表达记录写入 `The bird is in the tree.`、`Where is the bird?`。

## 5. 小游戏验收

### 5.1 场景点击小游戏

- [x] 正确目标能被稳定识别。
- [x] 错误点击不会推进任务，也不会锁死输入。
- [x] 成功、错误反馈中能复现或强化核心英文提示。
- [x] 目标区域与视觉目标匹配，儿童可合理点击命中。
- [x] 连续多次点击不会重复发奖或重复写入完成状态。

### 5.2 拖拽放置小游戏

- [x] 鼠标拖拽或触控等价操作稳定，不丢失物品。
- [x] 目标区域足够大，允许合理吸附。
- [x] 放错后有恢复或提示机制。
- [x] 放对后物品位置稳定，不被后续输入破坏。
- [x] 拖拽完成能正确推进 Quest 系统状态。

## 6. 存档验收

- [x] 完成 1 个生活事件后退出重进，事件仍保持已完成。
- [x] 完成 4 个正式 MVP 前台事件后退出重进，4 个事件均保持已完成。
- [x] 已获得奖励能随存档保留。
- [x] 家长层词汇和表达记录能随存档保留，并能被家长摘要读取。
- [x] 已完成事件不会在重进后重复奖励。
- [x] 存档缺失时能从初始状态开始。
- [x] 存档损坏或字段缺失时能回退到初始状态，且不崩溃。

## 7. 家长摘要验收

- [x] 家长摘要入口可达，且不会暴露复杂调试数据。
- [x] 能显示今日正式 gate 事件：First Trip、Walk With Mina、Room Helper、Bird Watch；Welcome Box 可作为微序章出现在历史记录或奖励列表中。
- [x] 能显示家长摘要/报告层词汇记录，至少覆盖 4 个正式 gate 事件数据中的核心词汇。
- [x] 能显示家长摘要/报告层表达记录，至少覆盖 4 个正式 gate 事件数据中的核心表达。
- [x] 能显示建议回访内容。
- [x] 家长能在 30 秒内理解孩子完成了什么、学了什么、接下来可以继续什么。
  - Readability agent 复查通过；自动检查已确认摘要显示中文任务名、中文奖励名、核心词汇、核心句型和具体回访建议。
- [x] 摘要在无家长层词汇/表达记录时有空状态文案，不崩溃。

## 8. 素材与内容安全验收

- [x] 自生成图片素材不使用真实品牌 Logo、商标、学校名称或可识别人像。
- [x] 素材文件名、角色名、游戏名和宣传名不包含 `Barbie`、`Disney`、`Pixar`、`Sanrio` 等商业 IP 名称。
- [x] 角色为原创儿童友好形象，服装、姿态和妆容适龄。
- [x] 场景素材清晰呈现 world overview 中的 home + school 起步区、正式 `HomeLayer` 室内背景、教室、花园，不依赖网络热图或第三方 IP。
- [x] 占位素材如仍存在，应仅使用 Godot 内置节点、自绘色块或项目自有图形。
- [x] 关键互动目标在 64x64 或实际游戏尺寸下仍可识别。
- [x] 素材导入后没有拉伸、黑边、透明通道错误或遮挡核心交互目标。
- [x] 素材路径和命名遵守 `docs/assets/AI图片素材生成规范_v0.1.md`。

说明：MVP 0.2 已接入第一版自生成图片素材，覆盖 world overview 中的 home + school 起步区、正式 `HomeLayer` 室内背景、教室、花园、玩家、Mina、Leo、Nora、拖拽物和奖励图标。`HomeLayer/HomeBackgroundSlot` 已引用 `map_home_interior_bg_v001.png`，旧 Godot 色块背景层仅作为隐藏备份保留。素材文件位于 `assets/generated/`，提示词和审核记录见 `assets/source_prompts/` 与 `docs/assets/MVP_0_2_第一版自生成美术资产记录.md`；交互碰撞、任务目标和英文学习文本仍保留在 Godot 节点中，避免将玩法逻辑烘死进背景图。

## 9. 可自动化 Smoke Test 建议

已新增 `tests/mvp_0_2_smoke.gd`，覆盖不依赖人工视觉判断的稳定逻辑：

- 直接驱动 Quest 系统完成 4 个正式 MVP 前台事件，断言事件完成、奖励、家长层词汇和表达记录均写入状态。
- 驱动场景点击事件：错误目标不完成且 Quest 保持活跃，正确目标完成。
- 驱动拖拽放置小游戏的判定函数：错误位置不完成，随后正确放置仍可完成。
- 写入一次存档，重新加载后断言 4 个正式 MVP 前台事件和奖励仍存在。
- 加载家长摘要页面，断言无家长层词汇/表达记录空状态，以及完成 4 个正式 MVP 前台事件后的事件数、奖励、词汇和表达记录完成态。
- 使用默认存档路径模拟退出重进，断言会恢复到花园场景。
- 写入损坏 JSON 存档，断言加载失败时进度被重置且不崩溃。
- 断言三场景关键节点与三 NPC 存在，事件完成后会切换到教室/花园可见层。
- 断言同一点击事件完成后继续点击不会重复写入完成事件。
- 断言 NPC 交互提示进入范围显示、离开隐藏，且玩家会记录/清理附近 NPC。
- 断言关键视觉目标中心落在对应点击区域内，降低“看得到但点不到”的回归风险。
- 断言 Story Show、Dialogue、Quest Diary、ParentSummary 的关键动态文本启用换行，Story Show/摘要按钮达到最小触控高度。
- 断言 MVP 验收文档不再包含旧任务 ID、旧 story-room 提示、旧花园风筝目标或“待测”残留，同时保持“成人熟练 2-5 分钟闭环”人工试玩项未勾选。

推荐命令：

```bash
./scripts/dev/run_mvp_0_2_checks.sh
```

该脚本跳过需要真实人工报告的 `mvp_0_2_manual_playtest_postflight.gd`、`mvp_0_2_verify_playtest_report.gd` 和 `mvp_0_2_export_playtest_summary.gd`，并在退出前运行 `mvp_0_2_manual_playtest_preflight.gd` 清理默认正式存档、报告和摘要。

## 10. 验收结论

- 结论：针对 `MVP 0.2` 三任务垂直切片的历史自动化验收通过，人工完整试玩已验收
- 阻塞问题：
  - 暂无自动化阻塞问题。
- 非阻塞问题：
  - Godot MCP `run_project` 本轮返回启动成功后未保持活动进程，CLI 图形启动正常；后续继续观察 MCP 进程管理能力。
  - 成人熟练 2-5 分钟参考窗口已由 2026-05-31 的人工试玩记录验证；儿童真实试玩时长与阅读压力仍需单独用户测试。
- 回归范围：
  - Prototype 0.1 Walk With Mina 流程。
  - MVP 0.2 三任务连续流程。
  - 存档、家长摘要、素材安全检查。

人工验收建议先按 `docs/development/MVP_0_2_人工试玩快速流程.md` 执行短清单，再按 `docs/development/MVP_0_2_人工验收脚本.md` 补全详细记录。

试玩时长按 `docs/development/MVP_0_2_试玩计时记录.md` 计时并记录结果。

人工试玩完成、计时记录已填写且验收记录状态已更新后，运行：

```bash
godot --headless --path . -s res://tests/mvp_0_2_manual_final_gate.gd
```

该脚本只检查人工证据是否已记录且状态一致；当前“待人工计时”状态下应失败。

## 11. 自动检查记录

- `godot --headless --path . --check-only --quit`：通过。
- `godot --headless --path . -s res://tests/prototype_0_1_smoke.gd`：通过。
- `godot --headless --path . -s res://tests/drag_place_game_smoke.gd`：通过。
- `godot --headless --path . -s res://tests/story_show_smoke.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_docs_audit.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_prepare_manual_playtest.gd`：legacy 入口，当前应退出并提示改用 readiness / preflight / manual runner。
- `godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_preflight.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_postflight.gd`：需在真实试玩并导出正式报告后运行；缺报告时按预期失败。
- `godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_postflight_fixture.gd`：通过，验证 postflight 正向摘要导出路径，并在测试结束后清理默认报告。
- `godot --headless --path . -s res://tests/mvp_0_2_report_export_guard.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_timing_window_guard.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_full_report_flow.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_manual_final_gate_fixture.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_export_playtest_summary_fixture.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_input_flow.gd`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_smoke.gd`：通过。
  - 说明：该测试包含损坏存档回退用例，因此会输出预期的 JSON parse error 日志；退出码仍为 0。
- `godot --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd`：通过。
- `./scripts/dev/run_mvp_0_2_checks.sh`：通过。
- `godot --headless --path . -s res://tests/mvp_0_2_manual_final_gate.gd`：用于检查人工证据一致性；结合本历史记录回放时应通过，空记录场景应失败。
- `godot --path . --quit`：通过，图形环境可启动并退出。

## 12. Review 问题处理记录

- 已修复：花园错误点击路径不完整。`SceneClickGame` 已增加 `tree`、`flower`、`bench` 点击区域，并按当前场景过滤可点击目标。
- 已修复：家长摘要可读性不足。摘要现在显示中文任务名、中文奖励名、词汇、句型和回访建议。
- 已修复：场景切换后旧 school 子场景地点残留。进入教室/花园时隐藏 `Paths` 和 `PlaceLayer`，并按场景切换 NPC 可见性。
- 已记录：拖拽测试通过脚本事件覆盖核心逻辑，但真实鼠标/触控手感仍保留人工验收。
- 已增补：MVP 结尾增加 25 项 `Story Show`，在打开家长摘要前让儿童重新遇到 library/book/bird 等故事线索、物品和口述表达；回顾完成状态会写入存档，未完成回顾时重进会恢复 Story Show。
- 已增补：Story Show 的 6 道朗读/口述题加入 5/5/5/5/5/5 秒倒计时，倒计时结束后才可确认完成。
- 已增补：`story_show_smoke.gd` 断言 25 题、6 道朗读/口述题、固定倒计时顺序 `[5, 5, 5, 5, 5, 5]`、总固定时长不少于 30 秒，并断言倒计时结束前不能跳过朗读题。
- 已记录：Playtime final review 已改为“成人熟练 2-5 分钟参考窗口 + 儿童首次试玩更长”的标准；当前仍需真实人工计时并记录结论，不能自动勾选试玩时长项。
- 已增补：`GameState` 记录试玩开始、关键节点、完成和总用时；家长摘要展示“试玩用时”和“试玩节点”，点击“完成摘要阅读”后存档快照包含 `playtest_elapsed_msec`、`playtest_elapsed_seconds`、`playtest_elapsed_text`、`playtest_completed` 和 `playtest_events`，用于人工计时交叉核对。
- 已增补：`QATimingReport` 导出 `user://mvp_0_2_playtest_report.json`，包含 schema、Godot 版本、目标时长、完成状态、总用时、目标时长差额、节点序列、节点覆盖、相邻节点耗时、Story Show 固定朗读倒计时、事件/奖励/家长层词汇与表达记录进度，以及人工验收占位字段；报告不自动判定 MVP 是否通过。
- 已废弃：`mvp_0_2_prepare_manual_playtest.gd` 是早期 cleanup-only 入口，已停止清理现场；当前仅提示改用 `mvp_0_2_manual_playtest_readiness.gd`、`mvp_0_2_manual_playtest_preflight.gd` 或 `scripts/dev/run_mvp_0_2_manual_playtest.sh`。
- 已增补：`mvp_0_2_manual_playtest_preflight.gd` 在人工计时前验证默认存档/报告/摘要不存在、Main 场景可实例化、空摘要状态正确，并确认未完成流程不能提前结束计时或导出报告。
- 已增补：`mvp_0_2_report_export_guard.gd` 断言核心 `GameState.save_playtest_report()` 会拒绝未完成流程，避免绕过 UI 生成半流程报告。
- 已增补：`mvp_0_2_verify_playtest_report.gd` 用于人工试玩后核验默认正式计时报告完整性；报告不存在时会提示先完成试玩、点击“完成摘要阅读”并导出报告；脚本不自动判定 MVP 是否通过。
- 已增补：`mvp_0_2_export_playtest_summary.gd` 将默认正式计时报告转换为 `user://mvp_0_2_playtest_report_summary.md`，便于人工粘贴到计时记录；摘要只包含事实证据和人工结论占位。
- 已增补：`mvp_0_2_manual_playtest_postflight.gd` 作为试玩后推荐收口命令，复用完整报告校验并导出 Markdown 摘要，同时继续保持人工结论留空。
- 已增补：`mvp_0_2_manual_playtest_postflight_fixture.gd` 构造完整默认报告，验证 postflight 正向摘要导出路径，并在测试结束后清理默认报告和 fixture 摘要。
- 已增补：`mvp_0_2_export_playtest_summary_fixture.gd` 构造一份完整合格报告，正向验证 Markdown 摘要内容包含目标时长、任务、Review、Timeline、Segment Deltas 和人工结论空位。
- 已增补：`PlaytestPostflightRunner` 统一 postflight 报告校验、摘要导出和 `TIMING_OUT_OF_TARGET` warning；`mvp_0_2_timing_window_guard.gd` 构造 01:59、02:00、05:00、05:01 四个完整报告快照，验证时长窗口字段、postflight warning 和人工提示不会自动给出通过结论。
- 已增补：`mvp_0_2_full_report_flow.gd` 从 `Main.tscn` 驱动完整 MVP 流程，写入默认正式报告，调用 postflight runner 导出正式摘要，并在结束后清理默认存档、报告和摘要。
- 已增补：`scripts/dev/run_mvp_0_2_checks.sh` 作为一键自动检查入口，顺序运行核心 headless 检查，跳过需要真实人工报告的命令，捕获并扫描 Godot error-level 输出，在退出前用同样的日志扫描执行 preflight 清理人工试玩起跑线，并在失败时保留临时日志目录。
- 已增补：`mvp_0_2_manual_final_gate.gd` 作为人工试玩后的最终 gate 检查，只验证计时记录和验收记录的人工证据是否已填写且状态一致，不自动替代人工结论。
- 已增补：`PlaytestManualFinalGate` helper 和 `mvp_0_2_manual_final_gate_fixture.gd`，用内存 fixture 覆盖人工 final gate 的通过、有条件通过、不通过、待人工计时失败和验收记录不一致失败路径，且不写真实文档或默认 `user://` 报告/摘要。
