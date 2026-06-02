# MVP 0.2 人工试玩快速流程

> 文档性质：`MVP 0.2` 历史人工试玩流程留档。  
> 说明：仅用于回溯三任务垂直切片的当时验证方式，不代表当前产品基线或当前版本入口。  
> 用途：给当时的人工验收提供短路径执行清单。详细步骤仍以 `MVP_0_2_人工验收脚本.md` 和 `MVP_0_2_试玩计时记录.md` 为准。

## 执行顺序

如只想确认当前环境是否适合开始人工试玩，而不清理或写入任何 `user://` 文件，可先运行只读 readiness 检查：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_readiness.gd
```

该检查只确认默认存档/报告/摘要不存在、计时记录仍处于待人工状态、验收记录未勾选“成人熟练 2-5 分钟闭环”项、主场景资源可加载；它不会清理现场、不会实例化 Main、不会启动试玩。若 readiness 失败，可用 preflight 清理并重置起跑线。

推荐使用串联脚本减少漏步骤：

```bash
cd /home/xionglei/GameProject/SutdyGame-godot
./scripts/dev/run_mvp_0_2_manual_playtest.sh
```

该脚本会依次执行 preflight、启动游戏、游戏关闭后执行 postflight 并导出摘要；它要求交互终端，以便在外部秒表准备好后按 Enter 启动游戏，非交互环境会拒绝运行。它不会自动填写人工结论，不会自动修改计时记录或验收记录，也不会自动判定 MVP 通过。需要单步排查时，可按以下步骤手动执行。

1. 清理并验证起跑线：

   ```bash
   cd /home/xionglei/GameProject/SutdyGame-godot
   godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_preflight.gd
   ```

2. 打开外部秒表，然后启动游戏：

   ```bash
   cd /home/xionglei/GameProject/SutdyGame-godot
   godot --path .
   ```

3. 从新存档开始完整试玩，不跳过人工体验判断：

## Home Pet Care 输入基线

在 `HomeLayer` 中还可以进行可重复的宠物照料互动：

- `feed` 会消耗 `2 coins`。
- `clean` 和 `play` 不消耗 `coins`。
- 宠物状态保存在 `GameState.coins`、`GameState.parent_bonus` 和 `GameState.pet_state` 中。


   - 完成 First Trip。
   - 完成 Walk With Mina。
   - 完成 Room Helper。
   - 完成 Bird Watch。
   - 完成 25 题 Story Show。
   - 6 道 Read aloud / 口述题等待倒计时结束。
   - 阅读家长摘要。

4. 在家长摘要中点击“完成摘要阅读”，同时停止外部秒表。

5. 点击“导出计时报告”。

6. 运行试玩后核验和摘要导出：

   ```bash
   cd /home/xionglei/GameProject/SutdyGame-godot
   godot --headless --path . -s res://tests/mvp_0_2_manual_playtest_postflight.gd
   ```

   如果输出 `TIMING_OUT_OF_TARGET`，说明报告完整但用时不在成人熟练 2-5 分钟参考窗口内；此时只能填写“有条件通过”或“不通过”。

7. 打开 `user://mvp_0_2_playtest_report_summary.md`，把 `Timing Record Paste` 和 `Segment Timing Helper` 粘贴到 `MVP_0_2_试玩计时记录.md` 的记录区。

8. 在 `MVP_0_2_试玩计时记录.md` 中填写人工结论，只能选择：

   - 通过
   - 有条件通过
   - 不通过

9. 运行最终人工 gate 检查：

   ```bash
   cd /home/xionglei/GameProject/SutdyGame-godot
   godot --headless --path . -s res://tests/mvp_0_2_manual_final_gate.gd
   ```

   该脚本只检查人工证据是否已经记录且状态一致，不会自动判定 MVP 通过。

## 判定提醒

- 外部秒表是试玩时长的人工事实来源。
- 游戏内报告用于交叉核对，不自动判定 MVP 通过。
- `Segment Timing Helper` 是报告节点参考，不替代人工秒表。
- `MVP_0_2_验收记录.md` 的“成人熟练 2-5 分钟闭环”项只能在真实完整试玩且结论为通过时勾选。
