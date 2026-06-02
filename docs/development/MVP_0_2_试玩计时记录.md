# MVP 0.2 试玩计时记录

> 文档性质：`MVP 0.2` 历史人工计时记录。  
> 用途：记录当时成人熟练试玩是否形成 2-5 分钟闭环，并为儿童首次试玩更长时长保留人工说明。  
> 状态：历史人工计时记录，已完成；不作为当前产品基线。

## 计时方法

从新存档开始计时，到家长摘要阅读完成并点击“完成摘要阅读”为止停止计时。

计时前建议先运行：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_preflight.gd
```

该脚本会清理默认正式存档 `user://study_game_save.json`、默认正式报告 `user://mvp_0_2_playtest_report.json` 和旧 Markdown 摘要 `user://mvp_0_2_playtest_report_summary.md`，并验证 Main 场景可实例化、空摘要状态正确、未完成流程不能提前结束计时或导出报告；preflight 运行时间不计入试玩时长。

必须包含：

- Walk With Mina。
- Room Helper。
- Bird Watch。
- 25 题 Story Show，其中 6 道朗读/口述题必须等待倒计时结束。
- 家长摘要阅读。

游戏内家长摘要会显示“试玩用时”和“试玩节点”。点击“完成摘要阅读”后，`GameState` 会保存 `playtest_elapsed_msec`、`playtest_elapsed_seconds`、`playtest_elapsed_text`、`playtest_completed` 和 `playtest_events`。随后点击“导出计时报告”会写入 `user://mvp_0_2_playtest_report.json`，报告包含环境占位、进度、用时、节点证据、目标时长差额、Story Show 固定朗读倒计时和相邻节点耗时；报告字段 `fixed_review_read_aloud` 保留兼容命名。人工记录仍以真实操作计时为准，游戏内用时和导出报告用于交叉核对，不自动判定通过。

不计入：

- 清理存档。
- 运行 `mvp_0_2_manual_playtest_preflight.gd`。
- 启动 Godot 编辑器。
- 测试人员填写表格。
- 调试控制台操作。

## 建议记录

| 项目 | 记录 |
|---|---|
| 测试日期 | 2026-05-31 |
| 测试者 | xionglei |
| Godot 版本 | 4.6.3.stable.official.7d41c59c4 |
| 设备/分辨率 | Linux 桌面 / 窗口模式未单独记录 |
| 输入方式 | 鼠标 |
| 玩家类型 | 成人模拟 |
| 是否首次游玩 | 否 |

## 分段计时

| 阶段 | 开始时间 | 结束时间 | 用时 | 备注 |
|---|---:|---:|---:|---|
| 新存档进入到 Mina 对话结束 | 00:00 | 00:06 | 00:06 | 外部秒表与报告时间线一致 |
| Walk With Mina 完成 | 00:06 | 00:13 | 00:07 | 正常完成 |
| Leo 对话结束 | 00:13 | 00:21 | 00:08 | 正常完成 |
| Room Helper 完成 | 00:21 | 00:51 | 00:30 | 正常完成 |
| Nora 对话结束 | 00:51 | 01:06 | 00:15 | 正常完成 |
| Bird Watch 完成 | 01:06 | 01:10 | 00:04 | 正常完成 |
| Story Show 25 题完成 | 01:10 | 02:11 | 01:01 | 含 6 道 5 秒朗读倒计时 |
| 家长摘要阅读并点击完成 | 02:11 | 02:13 | 00:02 | 已点击完成摘要阅读 |
| 总用时 | 00:00 | 02:13 | 02:13 | 外部秒表与导出报告一致 |

## 导出报告核对

| 项目 | 记录 |
|---|---|
| 是否点击“完成摘要阅读” | 是 |
| 是否点击“导出计时报告” | 是 |
| 报告路径 | `user://mvp_0_2_playtest_report.json` |
| 报告 `playtest_elapsed_text` | 02:13 |
| 报告 `elapsed_vs_target_seconds` | below_min: 0.0 / above_max: 0.0 / within_window: true |
| 报告 `fixed_review_read_aloud.total_seconds` | 30.0 |
| 报告 `playtest_events_monotonic` | true |
| 报告 `timeline_coverage_complete` | true |
| 报告 `manual_result` | pass |

导出报告后推荐运行 postflight，一次完成报告核验和 Markdown 摘要导出：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_postflight.gd
```

该脚本会核验报告完整性并导出 `user://mvp_0_2_playtest_report_summary.md`；如果报告不存在会失败并提示先完成试玩、点击“完成摘要阅读”并导出报告。若报告用时不在成人熟练 2-5 分钟参考窗口内，脚本会输出 `TIMING_OUT_OF_TARGET` 强提醒。脚本不会自动填写 `manual_result`，也不会自动判定 MVP 通过。

如需拆分执行，可先核验，再导出一份便于粘贴到本文件 `记录` 区的 Markdown 摘要：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
godot --headless --path . -s res://tests/mvp_0_2_verify_playtest_report.gd
godot --headless --path . -s res://tests/mvp_0_2_export_playtest_summary.gd
```

摘要路径为 `user://mvp_0_2_playtest_report_summary.md`。该摘要只包含报告事实、可粘贴到本文件“导出报告核对”的字段表、报告节点分段参考、时间线和人工结论占位，不自动填写通过结论；分段参考不替代人工秒表。

## 判定

- 通过：成人熟练完整试玩稳定落在 2-5 分钟，且主流程无阻塞；如判断儿童首次试玩会更长，在记录中说明即可。
- 有条件通过：时长不在 2-5 分钟参考窗口内，但主流程通顺，且能用“儿童首次/慢读更长”或“成人过于熟练导致偏短”等原因解释；需记录原因。
- 不通过：主流程阻塞、无法完整导出报告，或当前时长与目标用户预期明显不符且无法合理解释。

## 结果

- [x] 通过
- [ ] 有条件通过
- [ ] 不通过

记录：

```text
人工完整试玩 02:13，主流程无阻塞，完成摘要阅读与计时报告导出均成功。
本次记录按“成人熟练试玩 2-5 分钟参考窗口”判定为通过；报告字段显示 within_window=true。
儿童首次试玩预期更长，但不影响本次成人熟练试玩通过结论。

Timing Record Paste
- 是否点击“完成摘要阅读”：是
- 是否点击“导出计时报告”：是
- 报告路径：user://mvp_0_2_playtest_report.json
- 报告 playtest_elapsed_text：02:13
- 报告 elapsed_vs_target_seconds：below_min 0.0 / above_max 0.0 / within_window true
- 报告 fixed_review_read_aloud.total_seconds：30.0
- 报告 playtest_events_monotonic：true
- 报告 timeline_coverage_complete：true

Segment Timing Helper
- playtest_started -> mina_intro_dialogue_finished: 00:06
- g4_u1_school_tour_started -> g4_u1_school_tour_completed: 00:07
- g4_u1_tidy_classroom_started -> g4_u1_tidy_classroom_completed: 00:30
- g4_u1_garden_bird_started -> g4_u1_garden_bird_completed: 00:03
- review_challenge_started -> review_challenge_completed: 01:02（历史报告兼容事件 ID；前台名称为 Story Show）
- parent_summary_shown -> parent_summary_read: 00:01
```

人工试玩完成、粘贴 postflight 摘要并选择唯一结果后，可运行最终 gate 检查：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
godot --headless --path . -s res://tests/mvp_0_2_manual_final_gate.gd
```

该脚本只检查人工证据是否已记录且状态一致，不会自动替代人工结论；检查范围包括建议记录基础字段、分段计时开始/结束/用时、完成摘要阅读确认、导出报告确认、报告字段、唯一人工结果和验收记录状态。最终 gate 还会要求 `user://mvp_0_2_playtest_report_summary.md` 与当前 `user://mvp_0_2_playtest_report.json` 重新生成的摘要完全一致，避免旧摘要混入。分段计时必须使用 `MM:SS`，每行用时需匹配开始/结束时间，总用时需和导出报告 `playtest_elapsed_seconds` 在 60 秒容差内一致；“通过”要求人工总用时落在 2-5 分钟且 `within_window: true`，“有条件通过/不通过”保留人工解释空间。以本历史记录回放时应通过，空记录场景才应失败。
