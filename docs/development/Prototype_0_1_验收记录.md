# Prototype 0.1 验收记录

> 文档性质：`Prototype 0.1` 历史验收记录。  
> 说明：用于保留第一段 `Walk With Mina` 早期闭环的历史验证证据；其中地点目标曾以 `Find the library.` 呈现，但这不是当前儿童前台文案、当前地图结构或当前 QA 入口。

## 范围

- Godot 4.6 工程骨架。
- 第一段 `Walk With Mina` 可玩闭环，底层目标为找到 `library`。
- 三个地点：`classroom`、`library`、`playground`。
- Mina 对话、Quest Diary 生活事件提示、地点点击校验、奖励弹窗。

## 手动验收清单

- [x] `godot --path .` 能识别并打开项目。
- [x] `godot --headless --path . --check-only --quit` 无严重错误。
- [ ] 运行后进入 `Main.tscn`，能看到测试地图。
- [ ] 玩家可用 WASD 和方向键移动。
- [ ] 玩家不能穿过地图边界。
- [ ] 靠近 Mina 出现交互提示，离开提示消失。
- [ ] 按 `E` 或空格打开 Mina 对话。
- [ ] 对话结束后 Quest Diary 出现生活事件提示；历史版本曾显示 `Find the library.`，当前版本不以该词表式文案作为验收基线。
- [ ] 点击 `classroom` 或 `playground` 给出温和提示，不中断流程。
- [ ] 点击 `library` 后 `Walk With Mina` 闭环完成。
- [ ] 弹出 “Adventure Star” 奖励。
- [x] `GameState` 记录完成事件 `g4_u1_school_tour`（历史兼容 ID，前台显示 `Walk With Mina`）。
- [x] `GameState` 记录兼容奖励 ID `school_star_piece`。
- [x] `GameState` 为家长摘要/报告层记录词汇 `classroom`、`library`、`playground`。

## 自动检查记录

- `godot --headless --path . --check-only --quit`：通过。
- `godot --headless --path . --quit`：通过。
- `godot --headless --path . -s res://tests/prototype_0_1_smoke.gd`：通过。

## 内容安全

- 未新增真实 Logo、商标或网络图片。
- 未新增第三方 IP 角色或正式图片资产。
- Prototype 可见素材仅使用 Godot 内置节点占位。
