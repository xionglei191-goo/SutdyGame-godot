# MVP 0.2 第一版自生成美术资产记录

> 日期：2026-05-31  
> 工具：Codex 内置 image generation tool  
> 状态：MVP 0.2 第一版自生成素材与接入状态记录。接入状态以当前 runtime 和自动化验收为准；本文只记录已生成、已接入、备用和待生成状态，不把入库素材默认视为已接入。

## 接入范围

- 地图背景：world overview 中的 home + school 起步区、正式 `HomeLayer` 室内背景、school arrival、教室、花园已生成并接入。
- 角色精灵：玩家、Mina、Leo、Nora。
- 任务道具：book、pencil、bag 已用于当前整理房间交互；desk、shelf、school/garden 图标已入库但当前作为备用资产。
- 奖励图标：Adventure Star、Room Helper Badge、Garden Leaf Charm 已生成；First Trip Ticket 独立图标尚未生成，当前 `first_trip_ticket` 运行时复用 Adventure Star 图标。
- UI 图标素材：Quest Diary 与 Memory Spark 装饰图已接入对应 UI；对话与奖励装饰图已入库，作为后续 UI 精修备用素材；PlaceCard 独立装饰图标尚未生成。

## 文件位置

- 图片素材：`assets/generated/`
- 提示词记录：`assets/source_prompts/`

## 审核记录

| 项目 | 结果 | 备注 |
|---|---|---|
| 风格统一 | 通过 | pastel toy-town / magical school 风格一致 |
| 适龄性 | 通过 | 角色为适龄儿童，服装健康 |
| 版权边界 | 通过 | 未使用现有 IP、品牌、Logo、商标名 |
| 可用性 | 通过 | 已接入素材可支撑当前 runtime；`map_sunshine_world_overview_v001.png` 为 `2560x1440` 源图基线。部分已入库图标仍是备用资产，若干宠物/小镇图标仍待生成。 |

## Godot 接入

- `TownMap.tscn` 已接入 world overview、正式 `HomeLayer` 室内、school arrival、classroom、garden 背景；世界总览图接入状态由 `mvp_0_2_visual_acceptance.gd` 和 `mvp_0_2_world_overview_input_flow.gd` 锁定。
- `HomeLayer/HomeBackgroundSlot` 已引用 `assets/generated/maps/home/map_home_interior_bg_v001.png`；旧 Godot 色块背景节点保留为隐藏备份层，不再作为当前视觉基线。
- `Player.tscn` 使用玩家精灵。
- `Npc.tscn` 和 `npc_interaction.gd` 按 `npc_id` 切换 NPC 精灵。
- `DragPlaceGame` 的 book、pencil、schoolbag 拖拽物显示生成图标；desk、shelf 图标已入库但当前未作为运行时目标视觉引用。
- `RewardPopup` 按奖励 ID 显示生成奖励图标；`first_trip_ticket` 当前复用 Adventure Star 图标，独立 First Trip Ticket 图标待生成。
- `QuestDiary.tscn` 已引用 `ui_quest_diary_ornament_v001.png`；`MemorySparkCard.tscn` 已引用 `ui_memory_spark_ornament_v001.png`。
- school 与 garden 目录下的地点/目标图标已入库，但当前地图仍以背景图、标签和热点区域承载点击，不代表这些图标已经接入 `TownMap.tscn`。

## 待生成 / 备用状态

- 已生成并接入：`assets/generated/maps/home/map_home_interior_bg_v001.png`。
- 待生成：`assets/generated/props/home/prop_pet_bowl_v001.png`、`prop_pet_food_v001.png`、`prop_pet_toy_v001.png`、`prop_soap_v001.png`。
- 待生成：`assets/generated/props/town/prop_place_card_visit_v001.png`、`prop_shop_bag_v001.png`、`prop_ticket_v001.png`。
- 待生成：`assets/generated/rewards/reward_first_trip_ticket_v001.png`。
- 待生成：`assets/generated/ui/ui_place_card_ornament_v001.png`。
- 备用未接入：`assets/generated/props/school/*.png`、`assets/generated/props/garden/*.png`、`assets/generated/props/room/prop_desk_v001.png`、`assets/generated/props/room/prop_shelf_v001.png`、`assets/generated/ui/ui_dialogue_ornament_v001.png`、`assets/generated/ui/ui_reward_sparkle_v001.png`。
