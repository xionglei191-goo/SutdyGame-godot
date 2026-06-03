# Godot 开发任务拆解 v0.1

> 项目：StudyGame  
> 引擎：Godot 4.6.x  
> 日期：2026-06-01  
> 文档角色：实现层开发拆解稿  
> 上位依据：
> - [教学玩法重构策划_v0.1.md](/home/xionglei/GameProject/SutdyGame-godot/docs/product/教学玩法重构策划_v0.1.md:1)
> - [StudyGame_PRD_v0.1.md](/home/xionglei/GameProject/SutdyGame-godot/docs/product/StudyGame_PRD_v0.1.md:1)
> - [小学英语故事线与关卡内容设计.md](/home/xionglei/GameProject/SutdyGame-godot/docs/product/小学英语故事线与关卡内容设计.md:1)

## 1. 文档定位

本文件不再服务“校园英语任务原型”单一路径，而是服务新的实现真相：

- 外层体验是儿童生活冒险游戏
- 世界路径是 `home -> school -> town -> transport -> world`
- 教学底层是 `记忆宫殿 + 序章 + 七篇`
- 运行时前台表达必须去学习化
- 内部技术 ID、存档键和内容配置 ID 允许继续沿用现有命名

这份文档的职责是：

1. 把产品真相压成 Godot 可执行里程碑。
2. 定义需要保留的系统、需要新增的系统、需要改名的前台出口。
3. 说明当前 MVP 代码如何从“学校任务链”升级为“生活事件垂直切片”。
4. 为后续场景、任务、数据配置和 UI 接入提供实现顺序。

## 2. 当前实现真相

### 2.1 必须保留的实现资产

- `Main.tscn` 主流程
- `SceneHost.tscn`、拆分地图子场景及 `world_overview`
- `DialogueBox`
- 任务状态流转
- 场景点击小游戏
- 拖拽放置小游戏
- `ParentSummary`
- 世界地图热点 JSON
- A-Z memory anchor 数据与对话

### 2.2 必须重构的表达层

实现层需要明确区分：

- `内部技术名`：可以保留 `QuestDiary`, `g4_u1_school_tour`, `mvp_0_2_review_challenge` 和 legacy `review_challenge_*` 报告事件
- `前台儿童文案`：必须转成生活事件表达

当前需要整理的主要前台命名：

| 内部名 | 前台命名方向 |
|---|---|
| `QuestDiary` | `Quest Diary` |
| `mvp_0_2_review_challenge` / legacy `review_challenge_*` | runtime 使用 `StoryShow`，前台显示 `Story Show` |
| `School Tour` | `Walk With Mina` |
| `Tidy Classroom` | `Room Helper` |
| `Garden Bird` | `Bird Watch` |

约束：

1. 不改任务 ID。
2. 不改存档 key。
3. 不改测试依赖的结构化事件 ID。
4. 优先改标题、按钮、提示、奖励显示和家长摘要里的可见名。

## 3. 版本目标重定义

### 3.1 Prototype 0.1

目标：完成一个“从人物对话到生活事件完成”的最小闭环。

范围：

- 主场景可运行
- 玩家能在首个场景中移动
- 能与 Mina 对话
- 能接到第一个 `Quest`
- 能完成一次点击型地点识别
- 能获得奖励

验收标准：

- 运行项目后能进入地图
- 玩家能用 WASD 或方向键移动
- 靠近 Mina 后能触发对话
- 对话结束后出现 `Quest Diary`
- 点击正确地点后任务完成
- 获得第一块探索奖励

### 3.2 MVP 0.2（历史验证切片）

目标：完成一个“从 home 出发，经过 school 事件链，再进入回顾活动和家长摘要”的儿童试玩闭环。该切片已经转为历史验证和兼容基线，不再代表新 MVP 的完整目标链。

范围：

- 默认首屏为 `HomeLayer`
- 打开 `world_overview` 后，`home` 与 `school` 同屏起步
- 1 个微序章事件 `Welcome Box`，再接 4 个连续正式 MVP 前台事件：`First Trip`、`Walk With Mina`、`Room Helper`、`Bird Watch`
- 2 类小游戏
- 1 个回顾活动
- 家长摘要
- 世界地图与 A-Z 热点可共存

验收标准：

- 玩家能完成新 home-first 链：`Welcome Box`、`Room Starter`、`Pet Hello`、`Home Pet Care`、`First Trip`，并继续兼容后续 `Walk With Mina`、`Room Helper`、`Bird Watch`
- 每个事件完成后有奖励反馈
- 至少 1 个场景在事件完成后发生可见变化
- 退出重进后能保留进度
- 家长摘要能显示词汇记录和表达记录
- 前台不再把主流程写成课时或复习题

兼容边界：

- `First Trip`、`Walk With Mina`、`Room Helper`、`Bird Watch` 仍是当前 runtime 和历史报告里可见的后续验证链。
- `parent_bonus_confirmed_home_prologue_v001` 是当前 Parent Bonus 确认 flag；`parent_bonus_confirmed_mvp_0_2` 继续作为历史确认 flag 保存和读取，用于防重复。
- 新实现不得删除 `g4_u1_school_tour`、`g4_u1_tidy_classroom`、`g4_u1_garden_bird` 或 legacy `review_challenge_*` 报告合同。

### 3.3 新 MVP P0：Letters, Home, My First Pet

目标：把第一个正式目标链改为 home-first 生活冒险序章：

`Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip`

范围：

- `Welcome Box` 继续复用 `prologue_letter_box`。
- `Room Starter` 新增 `prologue_room_starter`，通过 home room targets 建立 `bed / bag / book / door`。
- `Pet Hello` 新增 `prologue_pet_hello`，通过 `GameState.pet_name` / `set_pet_name()` 建立宠物身份。
- `Home Pet Care` 新增 `prologue_home_pet_care`，必须复用 `GameState.care_for_pet(action_id)`。
- `First Trip` 继续复用 `prologue_go_to_school`，完成后路由到内部兼容 `campus_gate` / 前台 `school_arrival`。

验收标准：

- 新 MVP 文档和 quest data 使用生活事件标题，不使用 school app、lesson panel、word list drill、review test、L1/L2/L3。
- 新增 home targets 来自 `data/maps/scene_click_targets_v001.json`，不新增 `PLACE_RECTS` / `SCENE_TARGET_RECTS` 风格脚本常量。
- `Home Pet Care` 的 feed / clean / play / rest 首轮反馈走现有 pet state，不创建平行宠物存档。
- 前三步给到足够 coins，保证 `feed` 的 `2 coins` 成本不会卡死首轮体验。
- 完成 `First Trip` 后写入 `az_full_unlocked_after_prologue`，A-Z 首访锚点进入正式可点击状态；首访后可进入全量 A-Z `Memory Spark` 回访提取。

## 4. 推荐项目结构

```text
SutdyGame-godot/
  project.godot
  scenes/
    main/
      Main.tscn
    maps/
      SceneHost.tscn
      HomeScene.tscn
      WorldOverviewScene.tscn
      CampusGateScene.tscn
      ClassroomScene.tscn
      GardenScene.tscn
      SchoolGate.tscn
      Classroom.tscn
      Garden.tscn
    actors/
      Player.tscn
      Npc.tscn
    ui/
      DialogueBox.tscn
      QuestDiary.tscn
      RewardPopup.tscn
      ParentSummary.tscn
      StoryShow.tscn
    minigames/
      SceneClickGame.tscn
      DragPlaceGame.tscn
  scripts/
    core/
      game_state.gd
      save_manager.gd
      scene_router.gd
    actors/
      player_controller.gd
      npc_interaction.gd
    systems/
      dialogue_system.gd
      quest_diary.gd
      reward_system.gd
      story_show.gd
      parent_summary.gd
    maps/
      scene_host.gd
      home_scene.gd
      world_overview_scene.gd
    minigames/
      scene_click_game.gd
      drag_place_game.gd
  data/
	    quests/
	      prologue_letter_box.json
	      prologue_go_to_school.json
      g4_u1_school_tour.json
      g4_u1_tidy_classroom.json
      g4_u1_garden_bird.json
	    dialogues/
	      mina_letter_box_intro.json
	      mina_room_starter_intro.json
	      mina_pet_hello_intro.json
	      mina_home_pet_care_intro.json
	      mina_first_trip_handoff.json
	      mina_home_intro.json
      mina_intro.json
      leo_room_intro.json
      nora_garden_intro.json
      anchor_*.json
    maps/
      sunshine_world_hotspots_v001.json
```

说明：

- `data/quests/` 是当前 Quest Diary 唯一主动加载的数据目录；`data/lessons/` 不再作为 runtime fallback，旧调用只能通过 `start_lesson` 等包装转到 quest 数据。
- `StoryShow.tscn` / `story_show.gd` 已是 runtime 命名；legacy `mvp_0_2_review_challenge` 和 `review_challenge_started/completed` 仅作为报告/存档兼容 ID 保留。
- Quest 配置前台显示生活事件名，内部 ID 继续兼容现有存档和报告。

当前实现补充：

- `PlaceCard` 的首访奖励与 starter 购买行为已抽到 `scripts/systems/place_card_controller.gd`
- `Memory Spark` 前台体验的 gating / full A-Z defs / 完成回写已抽到内部 `scripts/systems/memory_spark_controller.gd`
- `Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip -> Walk With Mina -> Room Helper -> Bird Watch -> Story Show / ParentSummary` 这条主流程编排已开始从 `main.gd` 抽到 `scripts/systems/main_flow_controller.gd`（`main_flow_controller.gd`）
- `world_overview` 的 place/anchor/home 交互编排已开始从 `main.gd` 抽到 `scripts/systems/world_interaction_controller.gd`（`world_interaction_controller.gd`）
- 当前 `main.gd` 仍保留少量兼容字段与信号接线；后续继续减债时优先扩 controller，而不是把新主流程分支继续塞回 `main.gd`

## 5. 系统拆解

### 5.1 世界地图与场景路由

任务：

- 保持 `HomeLayer` 作为新存档默认首屏，承接 `Welcome Box`
- 维持 `world_overview` 打开后的 `home + school` 同屏起步
- 维持 `classroom` / `garden` 作为现有子场景
- 继续从 `sunshine_world_hotspots_v001.json` 读热点
- 保留 place 和 memory anchor 双通道点击
- 将 world hotspot 启用逻辑继续收口到热点数据：
  - `default_visible` 负责默认开放项；
  - `world_enabled_mode: quest_only` 是内部 hotspot mode，负责 `tree / flower / bench / bird` 这类只在对应 `quest_targets` 激活时开放的事件期间互动热点；
  - `world_enabled_mode: pilot_recall` 负责少量 recall 试点锚点的常开例外；
  - `world_enabled_mode: disabled` 用于保留数据但暂不开放点击的总览图热点，如当前 `music_room / art_room`。

验收：

- 新开局默认显示 `HomeLayer`
- 打开世界地图后，初始镜头能看到 `home` 与 `Sunshine School`
- 学校核心区在首个事件完成前正确路由
- A-Z 锚点点击与地点点击分流正确
- 自由探索时 `tree / flower / bench / bird` 不应在总览图可点，进入 `g4_u1_garden_bird` 后再开放。
- 当前 `music_room / art_room` 仍显示在地图构图里，但在没有 world 路由或 `PlaceCard` 语义前不应响应总览图点击。

### 5.2 玩家与 NPC

任务：

- 保留当前移动控制
- 保留 NPC 靠近交互
- 提示文案保持短、稳定、低压力
- 让 `home` 中的 Mina 成为起手引导 NPC

验收：

- 玩家不会穿过边界
- 近距离提示稳定出现/消失
- 对话结束后能正确触发首个 Quest

### 5.3 对话系统

任务：

- 复用 `DialogueBox`
- 支持普通 NPC 对话和 A-Z anchor 对话
- 控制单屏文本长度
- 为序章和生活事件预留更生活化对话口径

验收：

- 文本不溢出
- 锚点对话和 NPC 对话都可正常结束
- 对话结束事件能稳定驱动主流程

### 5.4 Home Pet Care

任务：

- 复用 `GameState` 现有 `coins`、`parent_bonus`、`pet_name`、`pet_state` 和 `care_for_pet(action_id)`。
- 当前动作开放 `feed`、`clean`、`play`、`rest/sleep`。
- `feed` 消耗 `2 coins`；`clean`、`play`、`rest/sleep` 不消耗 `coins`。
- 交互发生在 `HomeLayer`。当前 runtime 中它是 `Pet Hello -> Home Pet Care -> First Trip` 之间的正式生活事件，并继续复用现有宠物状态和 home feedback。
- `HomeLayer` 保留程序搭建的可见宠物角、宠物名、Rest 按钮和 `HomeBackgroundSlot`，后续 home 背景图接入时只替换背景层，不删除交互层。

验收：

- 新存档默认有可用 `coins`，且 `parent_bonus` 仍为独立字段。
- `pet_name` 默认可见为 `Sunny`，并能保存、读取。
- `pet_state` 至少包含 `hunger`、`cleanliness`、`mood`、`bond`、`rest`。
- 成功操作后会更新 `pet_state`，并发出 `pet_state_changed`；涉及喂食时同时更新 `coins` 并发出 `coins_changed`。
- `coins` 不足时，`feed` 返回 `You need 2 coins for pet food.`，且不修改宠物状态。
- 存档与读档后，`coins`、`pet_name` 和 `pet_state` 保持一致。

### 5.5 Non-school PlaceCard 与首访 Coin

任务：

- 保持 `world_overview` 中非学校 `place hotspot` 的 `PlaceCard` 打开逻辑，当前不强制切入子场景。
- 保持 `home` 作为例外入口，继续进入正式 `HomeLayer`，以承接 `Welcome Box`、`First Trip` 与 Home Pet Care。
- `world_overview` 静态地点路由已开始数据化：`data/maps/sunshine_world_hotspots_v001.json` 的 `world_place_action` 决定自由探索点击后进入 `scene` 还是打开 `place_card`；经济、物品归属、交通奖励和 Quest Diary 委托启动副作用仍留在 `PlaceCardController` / `WorldInteractionController` / `GameState`。
- `PlaceCard` 静态文案、按钮声明、窄口径可见条件和成功后的展示回流已开始数据化：`data/maps/sunshine_world_hotspots_v001.json` 的 `place_card_hint`、`place_card_actions`、`visible_when`、`success_status_text`、`home_feedback` 与 `success_focus_hotspot` 决定 hint 文案、按钮 `id/label`、已知按钮可见条件、成功状态文案、HomeLayer 回流提示和成功后的地图聚焦；点击后的存档、经济、道具、委托副作用仍由 controller 与 `GameState` 解释。
- 首访奖励继续复用 `GameState.coins`，并通过 `visited_place_<id>` 故事标记避免重复发币。
- `PlaceCard` 前台反馈维持当前基线：首访显示 `+1 coin`，重复访问显示 `Already visited`。
- 当前实现上，`PlaceCard` 的提示词、首访奖励和 `supermarket` starter action 已从 `main.gd` 抽到独立 `PlaceCardController`，后续继续扩非学校地点时优先改 controller，而不是在 `main.gd` 继续堆分支。

验收：

- `bookshop`、`restaurant`、`cinema`、`bus station`、`railway station`、`airport`、`post office` 等非学校地点点击后可弹 `PlaceCard`；其中 `bookshop` 已升级为第一个 PlaceCard-to-Quest 委托入口。
- `school_core` 内地点仍按既有任务/路由逻辑处理，不被 `PlaceCard` 截走。
- 首访通过 `visited_place_<id>` 发放 `+1 coin`，关闭 `PlaceCard` 后可继续探索或回到主链。
- 重复访问同一非学校地点不重复加币，并显示 `Already visited`。

### 5.5.1 Bookshop Helper 委托

任务：

- 把 `bookshop` 升级成第一个从 `PlaceCard` 进入短 `Quest Diary` 委托的非学校地点。
- `bookshop` 首访仍通过 `visited_place_bookshop` 发放 `+1 coin`。
- `bookshop` 只额外开放 1 个 starter 动作：`Help Find a Book`。
- 点击动作后启动 `town_bookshop_find_book`，前台标题为 `Bookshop Helper`，不使用课时、测试或词表口径。
- 委托仍发生在 `world_overview`，目标是再次点击 `bookshop`，形成“看见地点 -> 接委托 -> 回到地点完成”的最小 town loop。
- 完成后记录词汇 `bookshop`、`book`、`read`，记录句型 `Find a book.`、`Read at the bookshop.`，发放 `Bookshop Leafmark` 并额外给 `+1 coin`。
- `town_bookshop_find_book` 是自由探索支线，不加入 Parent Bonus 当前 home-first Quest 门槛。

验收：

- `bookshop` 自由探索点击仍先打开 `PlaceCard`，首访奖励保持 `+1 coin`。
- `PlaceCard` 提供 `Help Find a Book` 动作。
- 动作启动后 `Quest Diary` 显示 `Bookshop Helper` 与 `Keepsake: Bookshop Leafmark`。
- 错误地点不完成委托，正确点击 `bookshop` 后完成。
- 完成后再次打开 `bookshop` 不再显示该动作。
- `tests/mvp_0_2_bookshop_commission_flow.gd` 覆盖该闭环。

### 5.6 Supermarket Pet Bowl

任务：

- 把 `supermarket` 升级成第一个“从探索走向消费”的序章样例，不先引入完整商店系统。
- `supermarket` 继续沿用 `PlaceCard`，只额外开放 1 个 starter 动作：`Buy Pet Bowl (3)`。
- 购买成功后写入轻量 `owned_items: pet_bowl`，并保留 legacy `owned_pet_bowl` story flag，不新建数量、消耗品或背包 UI 大系统。
- 购买结果回流到 `HomeLayer/PetPanel`，显示 `Pet bowl ready`，并让喂食反馈升级为 `Your pet enjoyed a snack in the new bowl.`

验收：

- 首次点击 `supermarket` 时，仍先按探索基线发放首访 `+1 coin`。
- 成功购买后总计消耗 `3 coins`，并新增 `shop`、`bowl`、`food` 等序章词汇。
- 已拥有 `owned_pet_bowl` 时，`PlaceCard` 不再重复提供该购买动作。
- `home` 在 school 起步事件 / Walk With Mina 进行前后都可作为长期 hub 继续进入，查看宠物与购买回流结果。

### 5.6.1 Transport Town Route

任务：

- 把 `bus_station` 升级成第一个最小可玩的 `transport` 样例，继续复用 `PlaceCard`，不引入完整路线系统。
- `bus_station` 首访仍通过 `visited_place_bus_station` 发放 `+1 coin`。
- `bus_station` 只额外开放 1 个 starter 动作：`Choose Town Route`。
- 选择路线成功后只写入轻量标记：`travel_route_town_edge`，不新建路线背包、时刻表或交通系统。
- 选择路线成功后额外发放 `+1 coin`，新增序章/出行词汇 `bus`、`route`、`town`，新增句型 `Take the bus to town.`。
- 选择路线成功后仍停留在 `world_overview`，但镜头聚焦到 bus station / town-edge 区域，形成最小“到达”反馈。
- 已拥有 `travel_route_town_edge` 时，`PlaceCard` 不再重复提供该路线动作。

验收：

- 首次点击 `bus_station` 时，仍先按探索基线发放首访 `+1 coin`。
- `PlaceCard` 提供 `Choose Town Route` 动作。
- 成功选择路线后显示 `Town route marked: +1 coin.`，并隐藏动作按钮。
- 重复访问 `bus_station` 不重复发放路线奖励，不重复显示路线动作。
- `tests/mvp_0_2_transport_town_route_flow.gd` 覆盖该闭环。

### 5.7 Pet Shop Pet Ball

任务：

- 把 `pet_shop` 作为第二个从探索走向消费的序章样例，继续复用 `PlaceCard`，不引入完整商店系统。
- `pet_shop` 只额外开放 1 个 starter 动作：`Buy Pet Ball (2)`。
- 购买成功后写入轻量 `owned_items: pet_ball`，并保留 legacy `owned_pet_ball` story flag，继续不新建数量、消耗品或背包 UI 大系统。
- 购买结果回流到 `HomeLayer/PetPanel`，显示 `Pet ball ready`，并让陪玩反馈升级为 `Your pet had fun with the new ball.`。

验收：

- 首次点击 `pet_shop` 时，仍先按探索基线发放首访 `+1 coin`。
- 成功购买后总计消耗 `2 coins`，并新增 `pet`、`ball`、`play` 等序章词汇。
- 已拥有 `owned_pet_ball` 时，`PlaceCard` 不再重复提供该购买动作。
- `home` 中点击 `play` 不消耗 coins，但会显示带 pet ball 的升级反馈。

### 5.8 Clothes Shop Explorer Cape

任务：

- 把 `clothes_shop` 作为第一个 `Parent Bonus` 外观消费出口，继续复用 `PlaceCard`。
- `clothes_shop` 只额外开放 1 个 starter 动作：`Buy Explorer Cape (1 Parent Bonus)`。
- 购买成功后写入轻量 `owned_items: explorer_cape`，并保留 legacy `owned_explorer_cape` story flag；当前只做物品归属镜像，不新建数量、装备栏、完整背包或 wardrobe UI 系统。
- `Explorer Cape` 消耗 `parent_bonus`，不消耗 `coins`，也不混入宠物物品状态。
- 购买结果回流到 `HomeLayer` 的独立 `Outfit` 状态，显示 `Explorer cape ready`。
- 购买后同步显示玩家身上的 `Player/ExplorerCape` 轻量装扮层。

验收：

- 首次点击 `clothes_shop` 时，仍先按探索基线发放首访 `+1 coin`。
- `parent_bonus = 0` 时购买失败，提示 `You need 1 Parent Bonus for the explorer cape.`，且不扣 coins。
- 成功购买后消耗 `1 Parent Bonus`，新增 `clothes`、`cape`、`wear` 等序章词汇。
- 成功购买后新增 `Wear the explorer cape.` 序章句型。
- `home` 中 `Outfit` 显示 `Explorer cape ready`，`Pet item` 不显示披风。
- `Player/ExplorerCape` 默认隐藏，购买后可见，并保持在玩家精灵后方。
- 已拥有 `owned_explorer_cape` 时，`PlaceCard` 不再重复提供该购买动作。

### 5.9 General Store Star Rug

任务：

- 把 `general_store` 作为第一个 `Home Decor / General Store` 家园装饰消费出口。
- 继续复用 non-school `PlaceCard` 和轻量 `owned_items` 归属层；当前只做装饰归属镜像，不引入完整 home decoration inventory、数量或摆放编辑系统。
- `general_store` 首访仍通过 `visited_place_general_store` 发放 `+1 coin`。
- `PlaceCard` 提供 `Buy Star Rug (4)` 动作。
- 购买成功后写入轻量 `owned_items: star_rug`，并保留 legacy `owned_star_rug` story flag，消耗 `4 coins`，不消耗 `Parent Bonus`。
- 新增序章词汇 `room`、`rug`、`star`，新增句型 `Put the star rug in your room.`。
- 回到 `home` 后，独立 `Room decor` 状态显示 `Star rug ready`。
- `Pet item` 不显示地毯，`Outfit` 不显示地毯。

验收：

- `general_store` 在 `world_overview` 自由探索中可点击。
- 首访发放 `+1 coin`，重复访问不重复加币。
- `Buy Star Rug (4)` 成功后隐藏购买按钮。
- `owned_star_rug` 可保存和读取。
- `owned_items` 与 legacy `owned_*` story flags 可双向迁移，旧存档和新存档都能恢复购买状态。
- `Parent Bonus` 与家园装饰消费保持分离。
- `tests/mvp_0_2_general_store_room_decor_flow.gd` 覆盖该闭环。

### 5.10 Memory Spark

任务：

- 把首版 `memory_anchor` 从“只播三句对话”升级成“首访编码、回访提取”的轻 progression。
- 首访仍复用 `anchor_*.json` 对话，只额外写入 `anchor_seen_<id>` 标记。
- 回访时对全量 26 个 frozen A-Z anchors 打开 `Memory Spark` 小卡，不接入 `Quest Diary`，不污染主线 Quest 完成状态；Debug/报告层的 legacy `completed_tasks` 兼容字段也不得被 Memory Spark 写入。
- `Memory Spark` 前台使用 `picture clue / memory word / What comes back?` 的记忆宫殿口吻，不做填空题或词表测验包装，也不暴露 `anchor` / `recall` 机制词。
- 历史试点样本 `anchor_b_bear`、`anchor_g_gate`、`anchor_h_hat`、`anchor_o_orange`、`anchor_t_taxi`、`anchor_w_watch` 继续作为回归样本；当前 `memory_spark_defs` 覆盖完整 26 个 frozen A-Z anchors。
- A-Z 可点击开放由 `az_unlock_mode` 控制，不再由 `default_visible` 或 `world_enabled_mode: pilot_recall` 隐式决定。
- 序章完成前只开放 starter anchors；序章完成后写入 `az_full_unlocked_after_prologue`，全部 26 个 A-Z anchors 可点击，并可在首访后进入 `Memory Spark` 回访。
- Memory Spark 成功后写入 legacy `anchor_recall_done_<id>` 存档 flag，并把少量 `coins`、`learned_words`、`learned_patterns` 回流到现有 `GameState` / `ParentSummary`。
- 当前实现上，Memory Spark 的 gating、defs 构建、完成奖励与状态回写已从 `main.gd` 抽到内部 `MemorySparkController`；`main.gd` 继续保留 `memory_spark_defs` 镜像字段，仅用于兼容当前测试与可视化校验。

验收：

- 试点 anchor 首访仍先走普通对话。
- 已 `seen` 但未完成 recall 时，再次点击同一 anchor 会打开 `Memory Spark` 小卡。
- recall 失败只提示回看 `picture clue`，不锁死探索。
- recall 成功后记录完成标记、奖励 `coins`，并新增相应词汇与句型。
- `tests/mvp_0_2_az_unlock_flow.gd` 覆盖 starter 限定、序章后全量开放和 route_order 1-26 完整性。

### 5.11 Quest 系统

任务：

- 当前运行时场景与脚本名为 `QuestDiary.tscn` / `quest_diary.gd`。
- 继续使用 `quest_diary.gd`
- `start_quest` 是 Quest Diary 主接口，`start_lesson` 仅作为兼容包装保留。
- `quest_id` / `current_quest` 是运行时主状态；`lesson_id`、`current_lesson` 不再作为主状态字段继续扩展，如需兼容旧调用只能通过 getter/setter 包装。
- `completed_quests` 是当前 Quest 完成状态主存储，`GameState.get_completed_quests()` 是主读取路径；legacy `completed_tasks` 只作为存档读取、计时报告和 Debug IDs 的派生兼容 key，不再维护独立内存镜像。
- Quest 启动行为已开始数据化：`data/quests/*.json` 的 `scene_id` 决定起始场景，`type` 决定 `click_target` / `drag_place` 的输入模式，`start_focus_hotspot` 决定 world overview 委托的开场聚焦点；`MainFlowController.handle_quest_started()` 仅保留旧 quest-id 路由兜底。
- Quest 完成路由已开始数据化：`data/quests/*.json` 的 `completion` 对象决定完成后的 `scene_id`、`action`、`story_flags`、`dialogue_id`、`npc_prompts_visible`、`click_input_enabled`；`MainFlowController.handle_quest_completed()` 仅保留旧 quest-id 路由兜底。
- Quest 完成金币奖励已开始数据化：`data/quests/*.json` 必须提供 `reward_coins`，`MainFlowController` 优先读取该字段，旧 `match quest_id` 金币分支只作为不完整旧数据兜底。
- Quest 前台事件名已开始数据化：`data/quests/*.json` 必须提供 `title`，`MainFlowController.quest_title()` 优先读取该字段，旧 `match quest_id` 标题分支只作为不完整旧数据兜底。
- 支持 `click_target` 和 `drag_place`
- 前台显示名改为 `Quest Diary`
- 事件标题改为生活事件名
- 当前 runtime 已接入 Quest Diary 装饰素材、生活事件名、状态标签和 `Keepsake` 奖励提示。
- 当前 runtime 已把任务词展示改为 `Quest clues:`，不再用 `Look for:` 词表式前台表达。

验收：

- 接取、推进、完成流程稳定
- 已完成事件不会重复发奖
- 不需要让孩子看见 `L1/L2/L3`
- `Quest Diary` 显示 `Welcome Box / First Trip / Walk With Mina / Room Helper / Bird Watch` 等生活事件名。
- `Quest Diary` 显示 `Open Mina's welcome box. / Start Mina's first trip. / Find Mina's story stop. / Help Leo set up the story room.` 等生活事件提示。
- 状态能在 `Quest open / Look again / Done` 之间切换。
- 奖励提示使用 `Keepsake: <reward_name>`，不硬编码旧课堂奖励名。

### 5.12 Scene Click Game

任务：

- 继续支撑地点识别类任务
- 提示句保持简洁
- 错误反馈保持温和
- 和 `world_overview` 热点路由兼容

验收：

- 正确目标可识别
- 错误点击不锁死
- 核心句型能自然复现

### 5.13 Drag Place Game

任务：

- 继续支撑整理类任务
- 保持拖拽稳定、吸附明确
- 目标区域足够大

验收：

- 拖拽不抖动
- 放错可回位
- 放对可锁定并推进

### 5.14 Reward 系统

任务：

- 保留 `RewardPopup`
- 前台奖励命名从“课堂奖励”转成“探索奖励 / helper reward / keepsake”
- 奖励继续写入存档

验收：

- 完成事件后有明确奖励反馈
- 奖励可在家长摘要和后续收藏中读取

### 5.15 回顾活动系统

任务：

- 保留 `StoryShow` 节点和 `story_show.gd` 脚本
- 前台改包装为回顾活动，不显示考试感标题
- 继续保留 25 条提示和 6 条朗读计时

验收：

- 历史 runtime gate 中，结束第 4 个正式 `MVP 0.2` 事件 `Bird Watch` 后能自动进入回顾活动
- 朗读计时仍有效
- 家长摘要前置门槛不变

### 5.16 家长摘要

任务：

- 保留 `ParentSummary`
- 家长层可以继续使用“词汇记录/表达记录/建议回顾”这类解释口径
- 但摘要里显示的任务名改成新的生活事件名
- 当前 runtime 已接入 `Parent Bonus +2` 家长确认按钮。
- 当前 runtime 的 Parent Bonus gate 已迁移为完成 `Welcome Box / Room Starter / Pet Hello / Home Pet Care / First Trip` 和 25 题 `Story Show`。
- 确认后写入 `parent_bonus_confirmed_home_prologue_v001`；旧 `parent_bonus_confirmed_mvp_0_2` 仍可读并防止重复发放，同时保持与 `Coins` 分离。
- `ParentSummary` 通过 `GameState.get_parent_summary_state()` 读取家长层数据；`debug_snapshot()` 只保留给报告、诊断和 legacy fixture，不作为家长 UI 主数据 API。
- 重复点击或读档后再次进入摘要，不应重复发放 `Parent Bonus`。

验收：

- 家长能在 30 秒内理解本次学习发生了什么
- 摘要能同时说明玩法事件和语言收获
- 家长摘要可显示 `Parent Bonus` 当前值，并一次性确认发放 `+2`

## 6. 新 MVP 垂直切片规格

新 MVP P0 主线不再对外称作“L1/L2/L3 课堂链”，也不继续把历史 `MVP 0.2` 的 school-side gate 当作当前产品目标。当前实现工作应围绕：

`Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip`

### 6.1 P0 home prologue quest data 合同

| 技术 ID | 前台事件名 | Scene / type | Targets / actions | Reward | Completion routing |
|---|---|---|---|---|---|
| `prologue_letter_box` | `Welcome Box` | `home` / `click_target` | `home_letter_box` | `welcome_box_star` / `Welcome Box Star` / `reward_coins: 1` | 写入 `prologue_letter_box_done`；下一步 `prologue_room_starter` |
| `prologue_room_starter` | `Room Starter` | `home` / `click_target` 或轻量 `drag_place` | `home_book`、`home_bag`、`home_bed`、`home_door` | `room_starter_sticker` / `Room Starter Sticker` / `reward_coins: 1` | 写入 `prologue_room_starter_done`；下一步 `prologue_pet_hello` |
| `prologue_pet_hello` | `Pet Hello` | `home` / `click_target` + naming UI | `home_pet_corner` | `pet_name_tag` / `Pet Name Tag` / `reward_coins: 1` | 复用 `GameState.pet_name` / `set_pet_name()`；写入 `prologue_pet_hello_done`；下一步 `prologue_home_pet_care` |
| `prologue_home_pet_care` | `Home Pet Care` | `home` / pet actions | `feed`、`clean`、`play`、`rest/sleep` | `pet_care_heart` / `Pet Care Heart` / `reward_coins: 2` | 复用 `GameState.care_for_pet(action_id)`；写入 `prologue_home_pet_care_done`；下一步 `prologue_go_to_school` |
| `prologue_go_to_school` | `First Trip` | `world_overview` / `click_target` | `home`、`sunshine_school` | `first_trip_ticket` / `First Trip Ticket` / `reward_coins: 1` | 完成后进入内部兼容 `campus_gate` / 前台 `school_arrival`；写入 `prologue_go_to_school_done` 与 `az_full_unlocked_after_prologue`；触发 `mina_school_arrival_intro`；下一步兼容 `g4_u1_school_tour` |

实现要求：

- `prologue_letter_box` 和 `prologue_go_to_school` 是已有兼容 ID，继续保留。
- 新增 `prologue_room_starter`、`prologue_pet_hello`、`prologue_home_pet_care` 时，quest data 必须提供 `title`、`prompt`、`vocabulary`、`patterns`、`targets`、`reward_id`、`reward_name`、`reward_coins`、`completion`。
- Quest startup 继续从 `scene_id`、`type`、`start_focus_hotspot` 读取；Quest completion 继续从 `completion` 对象读取，不在 `MainFlowController.handle_quest_started()` 或 `handle_quest_completed()` 里新增 quest-id match 分支。
- 新增 home targets 必须写入 `data/maps/scene_click_targets_v001.json`，不新增脚本 rect 常量。
- `Home Pet Care` 的重复动作继续遵守现有成本：`feed` 消耗 `2 coins`；`clean`、`play`、`rest/sleep` 不消耗 `coins`。

### 6.2 历史 MVP 0.2 兼容链

历史 `MVP 0.2` runtime 仍可能保留以下链路，用于旧存档、旧报告、现有测试和过渡验收：

| 技术 ID | 前台事件名 | 兼容用途 |
|---|---|---|
| `prologue_go_to_school` | `First Trip` | 新 MVP 仍复用的 First Trip |
| `g4_u1_school_tour` | `Walk With Mina` | 旧 formal gate / school arrival 后续事件 |
| `g4_u1_tidy_classroom` | `Room Helper` | 旧 formal gate / classroom 整理事件 |
| `g4_u1_garden_bird` | `Bird Watch` | 旧 formal gate / garden 观察事件 |
| `mvp_0_2_review_challenge` | `Story Show` | legacy report ID；儿童前台继续显示 `Story Show` |

该链路只能作为历史验证和兼容说明，不作为新 MVP P0 范围边界。

### 6.3 P1 town / transport 实施规格

P1 继续扩展非学校生活地点，不把 school 变成产品唯一脸面。

| 类型 | Place | ID / flag | 前台动作 | Words / patterns | Side effects |
|---|---|---|---|---|---|
| town commission | `post_office` | `town_post_office_small_parcel` | `Help Carry a Parcel` | `post`, `parcel`, `stamp`; `Take the parcel.` | PlaceCard 启动 Quest Diary；完成写 `town_post_office_small_parcel_done`；奖励 `Parcel Stamp` / `+1 coin` |
| town commission | `restaurant` | `town_restaurant_snack_order` | `Help Choose a Snack` | `snack`, `juice`, `rice`; `Choose a snack.` | PlaceCard 启动 Quest Diary；完成写 `town_restaurant_snack_order_done`；奖励 `Snack Star` / `+1 coin` |
| town commission | `cinema` | `town_cinema_show_poster` | `Help Make a Poster` | `show`, `poster`, `ticket`; `Put up the poster.` | PlaceCard 启动 Quest Diary；完成写 `town_cinema_show_poster_done`；奖励 `Poster Spark` / `+1 coin` |
| transport action | `bus_station` | `travel_route_town_edge` | `Choose Town Route` | `bus`, `route`, `town`; `Take the bus to town.` | 已落地 starter slice；成功后 `+1 coin`，聚焦 town-edge |
| transport action | `taxi` | `travel_route_town_road` | `Find Town Road` | `taxi`, `road`, `stop`; `Take a taxi to the road.` | 写轻量 story flag；`+1 coin`；不建路线背包 |
| transport action | `railway_station` | `travel_route_train_stop` | `Choose Train Stop` | `train`, `station`, `stop`; `Take the train to the stop.` | 写轻量 story flag；`+1 coin`；不建时刻表系统 |

实现要求：

- PlaceCard 静态 copy 和按钮声明继续放在 hotspot data；经济、item ownership、travel flag、Quest Diary 启动副作用继续留在 `PlaceCardController`、`WorldInteractionController` 和 `GameState`。
- P1 town/transport 不加入当前 Parent Bonus gate。
- 每个新切片新增独立 flow 测试，先跑单测，再跑 smoke。

### 6.4 P2 Parent Bonus gate 迁移规格

当前 runtime 已接入 `Parent Bonus +2` 家长确认按钮；gate 已从历史 4 个 `MVP 0.2` formal events 迁移到 home-first 事件组与 `Story Show`。

新 home-first MVP runtime 稳定后，gate 迁移为：

`prologue_letter_box / prologue_room_starter / prologue_pet_hello / prologue_home_pet_care / prologue_go_to_school + Story Show`

实现要求：

- 新确认 flag 为 `parent_bonus_confirmed_home_prologue_v001`。
- 旧 `parent_bonus_confirmed_mvp_0_2` 继续可读，可用于旧报告和防重复。
- 如果旧 flag 已确认，不因新 gate 自动重复发放同一阶段 `Parent Bonus +2`；如需新奖励，必须另定版本化奖励 ID。
- `Coins` 和 `Parent Bonus` 继续分离；`Explorer Cape` 继续只花 `Parent Bonus`，不花 `coins`。
- ParentSummary 使用 `GameState.get_parent_summary_state()` 或明确 getter，不把 `debug_snapshot()` 当产品 UI 主数据 API。

## 7. 数据与命名策略

### 7.1 保留不动的内部名

- `QuestDiary`
- `mvp_0_2_review_challenge`
- `g4_u1_school_tour`
- `g4_u1_tidy_classroom`
- `g4_u1_garden_bird`
- 现有 `GameState` 事件 key
- 现有测试里依赖的完成状态 ID

### 7.2 必须改掉的前台出口

- 标题
- 提示副文案
- 回顾活动名
- 家长摘要里展示给家长的任务名
- 奖励可见名

### 7.3 命名映射建议

| 内部名 | 前台显示 |
|---|---|
| `QuestDiary` | `Quest Diary` |
| `g4_u1_school_tour` | `Walk With Mina` |
| `g4_u1_tidy_classroom` | `Room Helper` |
| `g4_u1_garden_bird` | `Bird Watch` |
| `mvp_0_2_review_challenge` | `Story Show` |
| `school_star_piece` | `Adventure Star` |
| `tidy_badge_piece` | `Room Helper Badge` |
| `garden_leaf_piece` | `Garden Leaf Charm` |

## 8. 开发顺序建议

1. 锁定前台命名映射
2. 改 `QuestDiary`、`StoryShow`、`ParentSummary` 的可见文案与报告兼容说明
3. 改 quest 配置中的前台事件标题和 reward display name
4. 改 `main.gd` 中任务标题显示出口
5. 跑现有 smoke / visual / input-flow 回归
6. 在已落地的 `pet_shop`、Parent Bonus、Quest Diary、starter shops 和 room decor 基础上，继续扩展 consumables、更多委托和更细的展示状态

## 9. 技术风险

| 风险 | 表现 | 处理 |
|---|---|---|
| 只改 UI 不改摘要映射 | 儿童端和家长端出现两套任务名 | 统一通过显示名映射收口 |
| 改动任务 ID | 破坏存档、测试和热点绑定 | 本轮禁止改任务 ID |
| 回顾活动改得过度 | 打坏 25 题计时与 gate | 只改标题和前台口径，不改完成合同 |
| 文档和运行时不同步 | 继续存在两套真相 | 先改开发拆解，再改运行时出口 |

## 10. 最近下一步

当前文档基线完成后，下一步实现顺序建议为：

1. 完成当前运行时前台命名整理
2. 继续深化 `Quest Diary` 的图标、分段状态和任务链提示
3. 把 `Story Show` 和 `ParentSummary` 做成同一条展示收尾链
4. 在已落地的序章、宠物、商店、Coins 回流、Parent Bonus 确认闭环和 Explorer Cape 外观消费基础上继续扩展 consumables、更多外观收集和 Parent Bonus 消费出口
