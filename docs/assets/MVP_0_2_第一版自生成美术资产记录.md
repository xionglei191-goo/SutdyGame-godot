# MVP 0.2 第一版自生成美术资产记录

> 日期：2026-05-31
> 最近维护：2026-06-02
> 工具：Codex 内置 image generation tool
> 状态：MVP 0.2 第一版自生成素材与接入状态记录。接入状态以当前 runtime 和自动化验收为准；本文只记录已生成、已接入、备用和待生成状态，不把入库素材默认视为已接入。

## 状态口径

- `generated`：图片文件已经存在于 `assets/generated/`，但不代表已经被 runtime 引用。
- `connected`：图片文件已经被 Godot 场景、脚本或 UI 运行时引用，并且当前验收流可见或可验证。
- `placeholder`：当前 runtime 使用临时代替物，例如复用已有图标、Godot 节点色块/形状、默认面板装饰或未细化背景区域。
- `pending`：只有规划或 prompt 记录，尚未生成正式图片，或正式图片尚未通过接入验收。

## 接入范围

- 地图背景：world overview 中的 home + school 起步区、正式 `HomeLayer` 室内背景、school arrival、教室、花园已生成并接入。
- `HomeLayer` 室内背景和 `world_overview` 上的 home 起点是两个不同 runtime 视觉层：`HomeLayer/HomeBackgroundSlot` 使用 `assets/generated/maps/home/map_home_interior_bg_v001.png`；`world_overview` 的 home 起点仍属于 `assets/generated/maps/world/map_sunshine_world_overview_v001.png` 的大地图区域，不能把二者互相描述为同一张背景。
- 角色精灵：玩家、Mina、Leo、Nora。
- 任务道具：book、pencil、bag 已用于当前整理房间交互；desk、shelf、school/garden 图标已入库但当前作为备用资产。
- 奖励图标：Adventure Star、First Trip Ticket、Room Helper Badge、Garden Leaf Charm 已生成；`first_trip_ticket` 运行时通过 `data/rewards/reward_icons_v001.json` 使用独立 ticket 图标。
- UI 图标素材：Quest Diary、Memory Spark 与 PlaceCard 装饰图已接入对应 UI；对话与奖励装饰图已入库，作为后续 UI 精修备用素材。

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
- `RewardPopup` 按 `data/rewards/reward_icons_v001.json` 的奖励 ID 映射显示生成奖励图标；`first_trip_ticket` 当前使用独立 `reward_first_trip_ticket_v001.png`。
- `QuestDiary.tscn` 已引用 `ui_quest_diary_ornament_v001.png`；`MemorySparkCard.tscn` 已引用 `ui_memory_spark_ornament_v001.png`；`PlaceCard.tscn` 已引用 `ui_place_card_ornament_v001.png`。
- school 与 garden 目录下的地点/目标图标已入库，但当前地图仍以背景图、标签和热点区域承载点击，不代表这些图标已经接入 `TownMap.tscn`。

## P0.5 / P0.7 / P1.7 资产状态矩阵

| 切片 | 目标文件或视觉对象 | 状态 | 当前 runtime / 占位说明 | prompt / 规划记录 |
|---|---|---|---|---|
| HomeLayer 背景基线 | `assets/generated/maps/home/map_home_interior_bg_v001.png` | `generated`, `connected` | 正式 `HomeLayer/HomeBackgroundSlot` 背景；不是 `world_overview` home 起点区域。 | `assets/source_prompts/maps/map_backgrounds_v001.md` |
| world_overview home 起点 | `assets/generated/maps/world/map_sunshine_world_overview_v001.png` 内的 home 区域 | `generated`, `connected` | 大地图起步区，供拖动总览、A-Z 锚点和地点路由使用；不是 HomeLayer 室内背景。 | `assets/source_prompts/maps/map_sunshine_world_v001.md` |
| Home pet corner refinements | `map_home_interior_bg_v002.png` 或等价后续 home pet corner 修订 | `pending` | 当前 home 已有背景和可见宠物角；细化宠物垫、碗位、玩具收纳、清洁反馈仍待美术和接入。 | `assets/source_prompts/maps/home_pet_corner_refinement_v001.md` |
| Pet care prop | `assets/generated/props/home/prop_pet_bowl_v001.png` | `generated`, `connected` | `HomeLayer/PetCorner/PetBowl` 已接入正式碗贴图。 | `assets/source_prompts/props/home_pet_care_props_v001.md` |
| Pet care prop | `assets/generated/props/home/prop_pet_food_v001.png` | `generated`, `connected` | `HomeLayer/PetCorner/PetFood` 已接入正式食物贴图。 | `assets/source_prompts/props/home_pet_care_props_v001.md` |
| Pet care prop | `assets/generated/props/home/prop_pet_toy_v001.png` | `generated`, `connected` | `HomeLayer/PetCorner/PetToy` 已接入正式玩具贴图。 | `assets/source_prompts/props/home_pet_care_props_v001.md` |
| Pet care prop | `assets/generated/props/home/prop_soap_v001.png` | `generated`, `connected` | `HomeLayer/PetCorner/PetSoap` 已接入正式清洁贴图。 | `assets/source_prompts/props/home_pet_care_props_v001.md` |
| First Trip reward | `assets/generated/rewards/reward_first_trip_ticket_v001.png` | `generated`, `connected` | `first_trip_ticket` 通过 `data/rewards/reward_icons_v001.json` 使用独立 ticket 图标。 | `assets/source_prompts/props/reward_place_card_ui_prompts_v001.md` |
| Reward placeholder | `assets/generated/rewards/reward_adventure_star_piece_v001.png` | `generated`, `connected` | Adventure Star 自身可用；不再作为 First Trip Ticket 当前图标。 | `assets/source_prompts/props/icon_atlas_v001.md` |
| PlaceCard ornament | `assets/generated/ui/ui_place_card_ornament_v001.png` | `generated`, `connected` | `PlaceCard.tscn` 已接入独立装饰图标。 | `assets/source_prompts/props/reward_place_card_ui_prompts_v001.md` |
| Quest Diary ornament | `assets/generated/ui/ui_quest_diary_ornament_v001.png` | `generated`, `connected` | 已接入 `QuestDiary.tscn`，可继续作为冒险日志语义基线。 | `assets/source_prompts/props/icon_atlas_v001.md` |
| Memory Spark ornament | `assets/generated/ui/ui_memory_spark_ornament_v001.png` | `generated`, `connected` | 已接入 `MemorySparkCard.tscn`，不代表 PlaceCard ornament 已完成。 | `assets/source_prompts/props/icon_atlas_v001.md` |
| P1.7 UI semantics | PlaceCard / Quest Diary / Memory Spark / ParentSummary 文案语义 | `pending` | 本轮只准备文档；运行时标题、按钮和布局接入仍由 UI/Godot worker 处理。 | `docs/assets/MVP_new_asset_ui_semantics_v0.1.md` |

## P0.5 / P0.7 / P1.7 安全锁

- 所有新增 prompt 必须继续写明：no logo, no readable text, no existing IP, no brand elements, no trademark, no watermark。
- 宠物食物不能出现真实或仿真实品牌包装、条形码、商标、学校名、品牌色带；只能是原创无文字的通用 pet food 袋/罐。
- First Trip Ticket 图标可以表现路、星、票根、家到小镇的出发感，但图片本身不要生成可读文字；`First Trip Ticket` 文案由 UI/runtime 添加。
- PlaceCard ornament 只能做边角装饰、地图 pin、路标、贴纸或柔和图案，不能加入品牌、店铺 Logo、商标或可读地点名。
- Home pet corner 修订不得把 pet bowl、food、toy、soap 等关键互动道具完全烘死在背景里；正式互动仍应使用独立 prop 或可替换节点。

## 待生成 / 备用状态

- 已生成并接入：`assets/generated/maps/home/map_home_interior_bg_v001.png`。
- 已生成并接入：`assets/generated/props/home/prop_pet_bowl_v001.png`、`prop_pet_food_v001.png`、`prop_pet_toy_v001.png`、`prop_soap_v001.png`；focused prompt 见 `assets/source_prompts/props/home_pet_care_props_v001.md`。
- 待生成：`assets/generated/props/town/prop_place_card_visit_v001.png`、`prop_shop_bag_v001.png`、`prop_ticket_v001.png`。
- 已生成并接入：`assets/generated/rewards/reward_first_trip_ticket_v001.png`；focused prompt 见 `assets/source_prompts/props/reward_place_card_ui_prompts_v001.md`。
- 已生成并接入：`assets/generated/ui/ui_place_card_ornament_v001.png`；focused prompt 见 `assets/source_prompts/props/reward_place_card_ui_prompts_v001.md`。
- 备用未接入：`assets/generated/props/school/*.png`、`assets/generated/props/garden/*.png`、`assets/generated/props/room/prop_desk_v001.png`、`assets/generated/props/room/prop_shelf_v001.png`、`assets/generated/ui/ui_dialogue_ornament_v001.png`、`assets/generated/ui/ui_reward_sparkle_v001.png`。
