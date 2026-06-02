# Sunshine Town & The World 主图执行清单 v0.1

> 用途：将世界地图主图策划转成可执行的出图和接入任务  
> 日期：2026-06-01

## 1. 首版主图范围确认

- [x] 确认首版运行时使用 home + school + town road 起步区、社区核心、交通枢纽和世界地标边框。
- [ ] 确认是否保留 `teachers' office`、`theatre`、`zoo`、`space museum` 作为弱标签预留位。
- [x] 确认标题使用 `Sunshine Town & The World`。
- [x] 确认 A-Z 字母系统每个字母只保留一个正式主编码。
- [x] 确认 A-Z 锚点采用固定顺时针回忆路线，不在后续版本中漂移位置。

## 2. 出图准备

- [x] 输出主图专用中英文提示词。
- [x] 输出局部裁切图提示词。
- [x] 输出包含 A-Z 记忆宫殿锚点的主图提示词版本。
- [x] 确认统一风格关键词与禁用词。
- [x] 确认首版横图比例、运行时分辨率和 `2560x1440` 源图基线。

## 3. 资产生成

- [x] 已生成世界地图总览主图，并接入当前 runtime `world_overview`。
- [x] 已生成 A-Z 锚点工程/参考标注版主图。
- [x] 已生成 A-Z 锚点展示版主图。
- [ ] 生成学校核心区裁切图。
- [ ] 生成社区环绕区裁切图。
- [ ] 生成城市边缘区裁切图。
- [ ] 生成世界地标边框插图组。

## 4. 游戏接入

- [x] 在 Godot 中接入总览主图并核对运行时缩放。
- [x] 添加学校、社区、交通、世界边框热点并核对落点。
- [x] 添加 A-Z 锚点热点及对应字母词卡并核对落点。
- [x] 补全 26 个 A-Z 锚点 dialogue JSON。
- [x] 设计从图像回忆字母、从字母找地点的基础提取交互：当前以全量 A-Z `Memory Spark` 承载回访提取。
- [x] 点击后接入 PlaceCard、场景入口、角色请求入口：当前以 non-school `PlaceCard`、学校场景入口和 home 子场景承载。
- [ ] 验证移动端和桌面端的标签可读性。

## 5. 审核

- [ ] 审核视觉中心是否清晰。
- [ ] 审核文字数量是否受控。
- [ ] 审核运行时底图与工程/参考标注图是否明确分离。
- [ ] 审核是否符合 `AI图片素材生成规范_v0.1.md`。
- [ ] 审核 A-Z 锚点是否自然融入环境，而不是生硬贴图。
- [ ] 审核每个字母是否仍然保持唯一、稳定、可提取。
- [ ] 审核是否适合 7-12 岁儿童使用。

## 6. 当前已产出规格

- [x] A-Z 锚点版首图构图表：`docs/assets/Sunshine_Town_And_The_World_A-Z锚点版首图构图表_v0.1.md`
- [x] 主图生成用中英文提示词：`assets/source_prompts/maps/map_sunshine_world_v001.md`
- [x] Godot 热点数据草案：`data/maps/sunshine_world_hotspots_v001.json`
- [x] 世界总览图资源：`assets/generated/maps/world/map_sunshine_world_overview_v001.png`（当前 runtime 底图基线）
- [x] A-Z 工程标注图资源：`assets/generated/maps/world/map_sunshine_world_az_label_v001.png`（工程/参考图，不接 runtime）
- [x] A-Z 展示标注图资源：`assets/generated/maps/world/map_sunshine_world_az_label_showcase_v001.png`（展示审阅图，不接 runtime）
- [x] 总览图输入流测试：`tests/mvp_0_2_world_overview_input_flow.gd`
- [x] 全量 26 个 A-Z 锚点对话：`data/dialogues/anchor_*.json`
- [x] world hotspot 启用规则测试：`tests/mvp_0_2_world_hotspot_enablement.gd`
- [x] Pet Shop 消费回流测试：`tests/mvp_0_2_pet_shop_pet_ball_flow.gd`
- [x] Clothes Shop / Parent Bonus 外观消费测试：`tests/mvp_0_2_clothes_shop_parent_bonus_flow.gd`
- [x] General Store / Room Decor 消费回流测试：`tests/mvp_0_2_general_store_room_decor_flow.gd`
