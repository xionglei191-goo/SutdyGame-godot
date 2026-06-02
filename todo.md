# StudyGame 新 MVP 重构开发 Todo

> 日期：2026-06-02  
> 角色：项目经理 / 主 Agent 整合稿  
> 目标：把项目从历史 `MVP 0.2` 可玩验证切片推进到新的 `home-first` 生活冒险 MVP。先形成可执行任务清单，后续按本文件分组推进策划、美术、工程、文档和 QA。

## 0. 本轮探索状态

- [x] 已阅读 `AGENTS.md`、多 Agent 协作规范、任务交接模板和 `docs/product/教学玩法重构策划_v0.1.md`。
- [x] 已本地扫描 `docs/`、`data/`、`scripts/`、`scenes/`、`tests/`、`assets/` 的当前实现与旧方向残留。
- [x] 已尝试启动 4 个探索 agent：产品策划、工程架构、美术/UI、文档/QA/课程。
- [x] 初始 fork agent 因工具侧认证问题退出：`Your access token could not be refreshed because your refresh token was revoked`。
- [x] 已关闭失效子 agent 会话，避免后续混入半截状态。
- [x] 已按 fallback 策略由主 Agent 接管，并结合后续可用 agent/worker 回报完成产品、叙事、美术、工程、QA 和文档整合。

### 0.1 本轮交付 Checkpoint

- [x] 新 home-first runtime 链已落地：`Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip`，后续继续衔接 `Walk With Mina -> Room Helper -> Bird Watch -> Story Show`。
- [x] 新增 home quest/dialogue/scene targets，宠物命名与首轮照顾闭环复用 `GameState.pet_name`、`set_pet_name()` 和 `care_for_pet(action_id)`。
- [x] `PlaceCard` action、starter economy、transport、town commission、reward icon、dialogue-to-quest、Memory Spark、Parent Bonus gate 均完成本轮数据化或 controller 化迁移。
- [x] home pet props、First Trip Ticket、PlaceCard ornament 已生成、导入并接入 runtime。
- [x] 新增/更新新 MVP 自动化：`mvp_new_home_prologue_flow.gd`、`run_new_mvp_checks.sh`、town commission、Parent Bonus gate、visual/docs/data integrity 覆盖。
- [x] 当前清理策略：未删除仍有历史验证价值的 `MVP_0_2_*` 文档；已重写当前入口文档、素材记录和 docs audit，避免旧方向继续作为产品真相。

## 1. 新 MVP 产品北极星

`StudyGame` 的新 MVP 不再继续扩大“学校任务链”，而是把第一个可玩心智稳定为：

`home -> pet -> room objects -> first trip -> school/town/world`

孩子前台应该感知到：

- 从家开始探索。
- 遇见并照顾宠物。
- 打开 Welcome Box，认识基础字母和生活物品。
- 去小镇或学校附近完成朋友委托。
- 用 Coins、Parent Bonus、道具、装扮和房间反馈让世界发生变化。

孩子前台不应该感知到：

- school app。
- lesson panel。
- word list drill。
- review test。
- L1/L2/L3。
- 单元课时、词汇表、句型表、测试。

## 2. 当前可继承基线

- `HomeLayer` 已是默认入口，`HomeBackgroundSlot` 已接入 `assets/generated/maps/home/map_home_interior_bg_v001.png`。
- `world_overview` 已是 `2560x1440` 可拖动总览图，运行时视口为 `1280x720`。
- 已有历史 `MVP 0.2` runtime 链路：`Welcome Box -> First Trip -> Walk With Mina -> Room Helper -> Bird Watch -> Story Show -> ParentSummary`。该链路是兼容和验证证据，不再作为新 MVP 目标链。
- 当前新 MVP runtime 链路已升级为：`Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip -> Walk With Mina -> Room Helper -> Bird Watch -> Story Show -> ParentSummary`。
- `data/quests/*.json` 已承载 `title`、`scene_id`、`type`、`start_focus_hotspot`、`completion`、`reward_coins`。
- `data/maps/sunshine_world_hotspots_v001.json` 已承载 `world_place_action`、`place_card_hint`、`place_card_actions`、`visible_when`、`success_status_text`、`home_feedback`、`success_focus_hotspot`。
- `GameState` 已有 `coins`、`parent_bonus`、`pet_name`、`pet_state`、`owned_items`、`care_for_pet(action_id)` 和 starter item 兼容迁移。
- 已有 starter loops：`supermarket -> pet bowl`、`pet_shop -> pet ball`、`general_store -> star rug`、`clothes_shop -> explorer cape`。
- 已有 `bookshop -> Help Find a Book -> Bookshop Helper` 非学校委托切片。
- 已有 `bus_station -> Choose Town Route -> travel_route_town_edge` 交通切片。
- 已有全量 A-Z `Memory Spark`：26 个 frozen A-Z anchors 均支持首访编码、回访提取、奖励与学习记录回流；历史 pilot anchors 继续作为回归样本。
- A-Z 主锚点和 `route_order` 已冻结，`A = Apple` 保持不动。

## 3. 主要差距与清债原则

- [x] `home` 序章薄弱问题已处理：`scene_click_targets_v001.json` 已扩展 room/pet/kitchen/yard/door 等 home targets，并由 `mvp_new_home_prologue_flow.gd` 保护。
- [x] 宠物剧情化事件已处理：`Pet Hello` 和 `Home Pet Care` 已成为正式 Quest/生活事件链，命名和照顾均复用 `GameState`。
- [x] `PlaceCardController.handle_action()` 分支债已收敛：starter actions 进入 `data/economy/starter_actions_v001.json`，PlaceCard action 使用数据声明和 `GameState` action dispatch。
- [x] `RewardPopup` 图标硬编码债已收敛：`data/rewards/reward_icons_v001.json` 管理 reward icon，`first_trip_ticket` 使用独立 ticket 图标。
- [x] `ParentSummary` gate 已迁到新 home-first 事件组，旧 flag 保持可读并防重复发放。
- [x] `main.gd` 的 dialogue-to-quest 触发已优先读取 dialogue JSON 的 `starts_quest` 字段，旧映射只作兼容兜底。
- [x] `tests/mvp_0_2_docs_audit.gd` 已同步新 MVP 事实，避免继续保护旧 gate、旧 ticket 占位或 pilot Memory Spark 口径。
- [x] 删除前记录规则保留；本轮未删除具有历史证据价值的文件，改为更新当前入口和状态文档。

## 4. 里程碑

- [x] M0：完成新 MVP 任务清单和当前基线审查。
- [x] M1：补齐真实 `home` 序章 foundation，覆盖房间物件、宠物命名、第一轮宠物照顾和 First Trip 前置体验。
- [x] M2：把 starter shop / transport / commission 行为从硬编码分支推进到更可扩展的数据或注册表。
- [x] M3：补齐 home-first 美术资产、PlaceCard/UI 装饰和奖励图标，清理未接入或误导性资产记录。
- [x] M4：更新产品、开发、素材、QA 文档，让 `todo.md` 成为新 MVP 的执行入口。
- [x] M5：新增并跑通新 MVP 自动化检查；自动化验收已完成，人工窗口试玩脚本和文档已更新但真实窗口人工结论仍需真人执行。

## 5. P0 任务

### P0.1 锁定新 MVP 范围文档

- Owner：PM Agent / Game Design Agent / 主 Agent。
- Scope：`todo.md`、`docs/product/StudyGame_PRD_v0.1.md`、`docs/product/小学英语故事线与关卡内容设计.md`、`docs/development/Godot开发任务拆解_v0.1.md`。
- Deliverables：新增 “新 MVP：Letters, Home, My First Pet” 的可执行范围，明确哪些事件进入本阶段，哪些保留为后续。
- Acceptance：文档明确 `home -> pet -> room objects -> first trip` 是新 MVP 起点；儿童前台不出现 lesson、word list、review test、school app；`MVP 0.2` 历史证据继续标为历史，不冒充当前目标。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_docs_audit.gd`，必要时同步更新 docs audit。
- Status：已完成。产品、故事、开发文档和 docs audit 已锁定新 P0 目标链，runtime quest/dialogue/map data 已同步落地。

### P0.2 设计 home 序章事件链

- Owner：Game Design Agent / Narrative Agent / Curriculum Agent。
- Scope：`docs/product/小学英语故事线与关卡内容设计.md`、`data/quests/`、`data/dialogues/`。
- Candidate events：`Welcome Box` 保留；新增候选 `Room Starter`、`Pet Hello`、`Home Pet Care`、`First Shop`，最终命名需保持儿童生活冒险口吻。
- Deliverables：每个事件的 `title`、`prompt`、`vocabulary`、`patterns`、`targets`、`reward_id`、`reward_name`、`reward_coins`、`completion`。
- Acceptance：事件覆盖 letters、room objects、meet/name pet、feed/clean/play/rest、first trip 的自然衔接；不复用旧 school-tour 口径；不改已有兼容 ID，新增 ID 使用 snake_case。
- Verification：新增 quest data integrity 覆盖；运行 `godot --headless --path . -s res://tests/mvp_0_2_quest_data_integrity.gd`。
- Status：已完成。新增 `prologue_room_starter`、`prologue_pet_hello`、`prologue_home_pet_care` quest data；更新 `prologue_letter_box.next_quest`；新增 Mina home-first dialogue，并通过 `starts_quest` 数据触发。

#### P0.2 本轮事件规格

新 MVP P0 目标链固定为：`Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip`。

| 技术 ID | 儿童端标题 | Prompt | Words | Patterns | Reward | Completion / routing |
|---|---|---|---|---|---|---|
| `prologue_letter_box` | `Welcome Box` | `Open Mina's welcome box.` | `apple`, `book`, `bag`, `home`, `letter`, `box` | `A is for Apple.`, `Open the welcome box.`, `This is my bag.` | `welcome_box_star` / `Welcome Box Star` / `+1 coin` | `scene_id: home`；写入 `prologue_letter_box_done`；下一步改为 `prologue_room_starter` |
| `prologue_room_starter` | `Room Starter` | `Help set up your room starter spots.` | `room`, `bed`, `bag`, `book`, `door` | `This is my room.`, `Find the bag.`, `Put the book here.` | `room_starter_sticker` / `Room Starter Sticker` / `+1 coin` | `scene_id: home`；目标来自 `scene_click_targets_v001.json`；写入 `prologue_room_starter_done`；下一步 `prologue_pet_hello` |
| `prologue_pet_hello` | `Pet Hello` | `Meet your pet at the pet corner.` | `pet`, `name`, `hello`, `come`, `home` | `Hello, my pet.`, `This is my pet.`, `Come here.` | `pet_name_tag` / `Pet Name Tag` / `+1 coin` | `scene_id: home`；复用 `GameState.pet_name` / `set_pet_name()`；写入 `prologue_pet_hello_done`；下一步 `prologue_home_pet_care` |
| `prologue_home_pet_care` | `Home Pet Care` | `Help your pet feel ready at home.` | `feed`, `clean`, `play`, `sleep`, `bowl`, `ball` | `Feed the pet.`, `Play with the pet.`, `Rest at home.` | `pet_care_heart` / `Pet Care Heart` / `+2 coins` | `scene_id: home`；动作必须走 `GameState.care_for_pet(action_id)`；写入 `prologue_home_pet_care_done`；下一步 `prologue_go_to_school` |
| `prologue_go_to_school` | `First Trip` | `Start Mina's first trip.` | `home`, `school`, `go`, `trip` | `This is my home.`, `Let's start the first trip.`, `Go with Mina.` | `first_trip_ticket` / `First Trip Ticket` / `+1 coin` | `scene_id: world_overview`；完成后仍路由到内部兼容 `campus_gate` / 前台 `school_arrival`；写入 `prologue_go_to_school_done` 与 `az_full_unlocked_after_prologue`；下一步兼容 `g4_u1_school_tour` |

Target baseline：`home_letter_box` 继续服务 `Welcome Box`；`Room Starter` 需要 `home_book`、`home_bag`、`home_bed`、`home_door`；`Pet Hello` 需要 `home_pet_corner`；`Home Pet Care` 需要 `home_pet_bowl`、`home_pet_toy`、`home_pet_bed` 或等价 home pet targets。所有新增 target 必须来自 `data/maps/scene_click_targets_v001.json`，不新增脚本 rect 常量。

Coins baseline：前三个事件至少给到 `3 coins`，保证进入 `Home Pet Care` 时 `feed` 的 `2 coins` 成本不会卡死首轮体验。`clean`、`play`、`rest/sleep` 不花 `coins`，并继续更新 `pet_state`。

### P0.3 扩展 home 点击目标数据

- Owner：Godot Dev Agent。
- Scope：`data/maps/scene_click_targets_v001.json`、`scripts/minigames/scene_click_game.gd`、`tests/`。
- Deliverables：为 home 增加房间物件和宠物相关目标，例如 `home_letter_box`、`home_book`、`home_bag`、`home_bed`、`home_pet_corner`、`home_pet_bowl`。
- Acceptance：新目标从 JSON 读取，不新增 `PLACE_RECTS` 或 `SCENE_TARGET_RECTS` 风格脚本常量；老 `Welcome Box` 仍可完成。
- Verification：新增 `tests/mvp_new_home_prologue_flow.gd` 或扩展现有 home flow；运行 `godot --headless --path . -s res://tests/mvp_0_2_home_pet_care_input_flow.gd`。
- Status：已完成。`home_letter_box`、`home_book`、`home_bag`、`home_bed`、`home_door`、`home_pet_corner`、`home_pet_bowl`、`home_pet_toy`、`home_pet_bed`、`home_kitchen`、`home_yard` 等目标已由 JSON 提供。

### P0.4 做成宠物命名和第一轮照顾闭环

- Owner：Godot Dev Agent / UIUX Agent。
- Scope：`scenes/maps/TownMap.tscn`、`scripts/maps/town_map.gd`、`scripts/main/main.gd`、`scripts/systems/world_interaction_controller.gd`、`scripts/core/game_state.gd`。
- Deliverables：在 `HomeLayer` 内让 `pet_name` 变成可见、可选择或可命名的序章步骤；复用 `GameState.set_pet_name()`，不新增平行宠物存档。
- Acceptance：命名后 UI 显示新名字；feed/clean/play/rest 仍走 `GameState.care_for_pet()`；save/load 后 `pet_name` 和 `pet_state` 保持一致；`feed` 仍花 `2 coins`，其它动作不花 coins。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_game_state_pet_care.gd`，新增命名测试。
- Status：已完成。`GameState.pet_name_changed`、quest completion `pet_name`、home pet action completion 和 `mvp_new_home_prologue_flow.gd` 已覆盖命名与照顾闭环。

### P0.5 强化 HomeLayer 视觉与交互反馈

- Owner：Asset Agent / Technical Artist / Godot Dev Agent。
- Scope：`assets/generated/props/home/`、`assets/generated/rewards/`、`assets/generated/ui/`、`assets/source_prompts/`、`docs/assets/MVP_0_2_第一版自生成美术资产记录.md`、`scenes/maps/TownMap.tscn`、`scenes/ui/PlaceCard.tscn`。
- Deliverables：生成并接入 `prop_pet_bowl_v001.png`、`prop_pet_food_v001.png`、`prop_pet_toy_v001.png`、`prop_soap_v001.png`、`reward_first_trip_ticket_v001.png`、`ui_place_card_ornament_v001.png`。
- Acceptance：素材原创、无 IP/Logo/商标；prompt 记录完整；PetCorner 不再主要依赖 ColorRect/Polygon 形状表达；`first_trip_ticket` 不再复用 Adventure Star 图标。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd`，必要时新增资产存在性检查。
- Status：已完成。home pet props、First Trip Ticket、PlaceCard ornament 已生成、导入、接入 `TownMap.tscn` / `PlaceCard.tscn` / reward icon data，并由 visual acceptance 锁定。

### P0.6 PlaceCard action 扩展去分支化

- Owner：Godot Dev Agent。
- Scope：`scripts/systems/place_card_controller.gd`、`scripts/core/game_state.gd`、`data/maps/sunshine_world_hotspots_v001.json`、`tests/mvp_0_2_place_card_*`。
- Deliverables：把当前 `supermarket/pet_shop/clothes_shop/general_store/bus_station/bookshop` action 处理整理为 action handler 注册表或 action-id 映射，避免继续按 place 堆分支。
- Acceptance：现有 6 个 PlaceCard actions 行为不变；隐藏 action 仍不能通过直接调用执行；新增 action 不需要修改 `main.gd`。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_place_card_action_authorization.gd`，`godot --headless --path . -s res://tests/mvp_0_2_place_card_visibility_data.gd`。
- Status：已完成。新增 `data/economy/starter_actions_v001.json`，`PlaceCardController` 使用 action 数据、visibility keys 和 `GameState` action dispatch。

### P0.7 Reward 图标与奖励数据清理

- Owner：Godot Dev Agent / Asset Agent。
- Scope：`scripts/systems/reward_system.gd`、`data/quests/*.json`、`assets/generated/rewards/`、`docs/assets/MVP_0_2_第一版自生成美术资产记录.md`。
- Deliverables：补齐 `First Trip Ticket` 独立图标；梳理 `reward_id -> icon_path` 来源，优先迁到数据或集中配置。
- Acceptance：`welcome_box_star`、`first_trip_ticket`、`school_star_piece`、`bookshop_leafmark` 不再全部共用同一图标，除非文档明确为临时占位。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_smoke.gd`，新增 reward icon 映射测试。
- Status：已完成。`data/rewards/reward_icons_v001.json` 已接入 `RewardPopup`，`first_trip_ticket` 不再复用 Adventure Star。

### P0.8 新增新 MVP home 序章自动化

- Owner：QA Agent / Godot Dev Agent。
- Scope：`tests/`、`scripts/dev/run_mvp_0_2_checks.sh` 或新脚本 `scripts/dev/run_new_mvp_checks.sh`。
- Deliverables：新增覆盖 `Welcome Box -> room objects -> pet naming -> first pet care -> First Trip` 的 headless flow。
- Acceptance：测试使用独立或可清理的 save path；不并行污染 `user://study_game_save.json`；失败时指出具体缺失目标或状态。
- Verification：`godot --headless --path . --check-only --quit`，新测试脚本，现有 `./scripts/dev/run_mvp_0_2_checks.sh` 仍通过或有明确新脚本替代。
- Status：已完成。新增 `tests/mvp_new_home_prologue_flow.gd` 和 `scripts/dev/run_new_mvp_checks.sh`，并已纳入 `run_mvp_0_2_checks.sh`。

## 6. P1 任务

### P1.1 ParentSummary 显示映射数据化

- Owner：Godot Dev Agent / QA Agent。
- Scope：`scripts/systems/parent_summary.gd`、`data/quests/*.json`、`tests/mvp_0_2_smoke.gd`。
- Deliverables：ParentSummary 优先从 quest data 读取 `title` 和 `reward_name`，只把旧映射保留为兼容兜底。
- Acceptance：新增新 MVP quest 后不需要手动更新 `QUEST_NAMES` / `REWARD_NAMES` 常量；Parent Bonus 当前 gate 已迁到 home-first 事件组 + Story Show，旧 flag 只作兼容防重复。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_smoke.gd`。
- Status：已完成。ParentSummary 优先读取 quest data / GameState parent summary state，新 gate 由 `parent_bonus_confirmed_home_prologue_v001` 保护。

### P1.2 dialogue-to-quest 触发迁移

- Owner：Godot Dev Agent / Narrative Agent。
- Scope：`scripts/main/main.gd`、`data/dialogues/*.json`、`data/quests/*.json`、`tests/mvp_0_2_world_overview_input_flow.gd`。
- Deliverables：把 `main.gd` 的 `dialogue_to_quest` 硬编码表迁到 dialogue 或 quest 数据，例如 `starts_quest` 字段。
- Acceptance：Mina/Leo/Nora 现有对话触发不变；新增 home/pet 序章对话不需要修改 `main.gd`。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_world_overview_input_flow.gd`。
- Status：已完成。`DialogueBox.starts_quest()` 读取 dialogue JSON 的 `starts_quest` 字段，`main.gd` 仅保留旧映射兜底。

### P1.3 扩展 town 非学校委托

- Owner：Game Design Agent / Godot Dev Agent / Curriculum Agent。
- Scope：`data/quests/`、`data/maps/sunshine_world_hotspots_v001.json`、`data/dialogues/`、`tests/`。
- Implementation-ready starter specs：
| Place | Quest ID | 儿童端标题 | PlaceCard action | Words / patterns | Reward / routing |
|---|---|---|---|---|---|
| `post_office` | `town_post_office_small_parcel` | `Parcel Helper` | `Help Carry a Parcel` | `post`, `parcel`, `stamp`; `Take the parcel.` | `Parcel Stamp` / `+1 coin`；完成后聚焦 `post_office`，写入 `town_post_office_small_parcel_done` |
| `restaurant` | `town_restaurant_snack_order` | `Snack Stop` | `Help Choose a Snack` | `snack`, `juice`, `rice`; `Choose a snack.` | `Snack Star` / `+1 coin`；完成后回到 `restaurant` PlaceCard，写入 `town_restaurant_snack_order_done` |
| `cinema` | `town_cinema_show_poster` | `Show Poster` | `Help Make a Poster` | `show`, `poster`, `ticket`; `Put up the poster.` | `Poster Spark` / `+1 coin`；完成后可提示 `Story Show`，写入 `town_cinema_show_poster_done` |
- Acceptance：每个新委托从 PlaceCard 进入短 Quest Diary，不加入当前 Parent Bonus gate；学习内容包装为 help/shop/trip/show，不包装为练习。
- Verification：每个切片新增一个 flow 测试，先跑单测再跑 smoke。
- Status：已完成。`post_office`、`restaurant`、`cinema` 已新增 Quest / PlaceCard action / flow 覆盖，并保持在 Parent Bonus gate 外。

### P1.4 扩展 transport playable slice

- Owner：Game Design Agent / Godot Dev Agent。
- Scope：`data/maps/sunshine_world_hotspots_v001.json`、`scripts/systems/place_card_controller.gd`、`scripts/core/game_state.gd`、`tests/`。
- Implementation-ready starter specs：
| Place | Action ID / flag | 儿童端动作 | Words / patterns | Reward / routing |
|---|---|---|---|---|
| `bus_station` | `choose_town_route` / `travel_route_town_edge` | `Choose Town Route` | `bus`, `route`, `town`; `Take the bus to town.` | 已落地 starter slice；成功后 `+1 coin` 并聚焦 town-edge |
| `taxi` | `find_town_road` / `travel_route_town_road` | `Find Town Road` | `taxi`, `road`, `stop`; `Take a taxi to the road.` | `+1 coin`；写轻量 story flag，不建路线背包 |
| `railway_station` | `choose_train_stop` / `travel_route_train_stop` | `Choose Train Stop` | `train`, `station`, `stop`; `Take the train to the stop.` | `+1 coin`；成功后聚焦 railway / town-edge area |
- Acceptance：继续使用轻量 story flag 和 learned words/patterns，不引入完整路线背包或时刻表系统。
- Verification：扩展 `tests/mvp_0_2_transport_town_route_flow.gd` 或新增 transport flow。
- Status：已完成。`bus_station`、`taxi`、`railway_station` 三个轻量 travel actions 已接入 action catalog、story flags、coin reward 和 transport flow。

### P1.5 Memory Spark 参数化扩展

- Owner：Godot Dev Agent / Curriculum Agent。
- Scope：`scripts/systems/memory_spark_controller.gd`、`data/maps/sunshine_world_hotspots_v001.json`、`tests/mvp_0_2_memory_spark_flow.gd`、`tests/mvp_0_2_az_unlock_flow.gd`。
- Deliverables：让 Memory Spark 的 prompt、choices、reward_coins、learned_words、learned_patterns 可由 hotspot 或独立数据覆盖。
- Acceptance：历史 pilot 6 个锚点行为不变并作为回归样本；新增 starter anchors 不需要改脚本；当前 `memory_spark_defs` 覆盖完整 26 个 frozen A-Z anchors。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_memory_spark_flow.gd`。
- Status：已完成。Memory Spark prompt、choices、reward、learned words/patterns 支持 hotspot override，并生成全量 A-Z defs。

### P1.6 轻量 item/action catalog

- Owner：Godot Dev Agent。
- Scope：`data/items/` 或 `data/economy/`、`scripts/core/game_state.gd`、`scripts/systems/place_card_controller.gd`、`tests/mvp_0_2_game_state_owned_items.gd`。
- Deliverables：把 pet bowl、pet ball、explorer cape、star rug 的 cost、currency、owned item id、legacy flag、learned words/patterns 集中配置。
- Acceptance：不引入完整背包 UI、数量、消耗品系统；旧 `has_pet_bowl()` 等兼容 helper 继续可用。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_game_state_owned_items.gd`。
- Status：已完成。`data/economy/starter_actions_v001.json` 集中 starter cost/currency/owned item/flags/learned records，旧 helper 保留。

### P1.7 UI/UX 语义精修

- Owner：UIUX Agent / Godot Dev Agent。
- Scope：`scenes/ui/QuestDiary.tscn`、`scenes/ui/PlaceCard.tscn`、`scenes/ui/MemorySparkCard.tscn`、`scenes/ui/ParentSummary.tscn`、`scripts/systems/place_card.gd`。
- Deliverables：PlaceCard 标题从固定 `Town Visit` 改为数据化，如 `PlaceCard`、`Town Visit`、`Travel Stop`、`Shop Stop`；Quest Diary 增强任务链提示但不暴露 lesson。
- Acceptance：儿童层 UI 不出现内部 ID；ParentSummary 可以保留家长解释词；移动端和桌面都不遮挡核心按钮。
- Verification：`godot --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd`，人工窗口检查。
- Status：已完成。PlaceCard title 语义和 ornament 已接入，儿童层 denylist 由 visual acceptance 和新 home prologue flow 覆盖。

## 7. P2 任务

### P2.1 完整 home 空间扩展

- Owner：Game Design Agent / Asset Agent / Godot Dev Agent。
- Scope：`scenes/maps/TownMap.tscn`、`data/maps/scene_click_targets_v001.json`、`assets/generated/maps/home/`。
- Deliverables：把 home 从单一 interior 扩展为 bedroom / kitchen / yard / pet corner 的可维护结构。
- Acceptance：仍从 HomeLayer 起步；不把 home 描述成 world overview 的 home 起点背景；不破坏现有 pet panel 和 Mina opener。
- Status：已完成。`TownMap.tscn` 已加入 bedroom/kitchen/yard/pet corner 可读空间标签与 pet props，home scene targets 扩展到对应区域。

### P2.2 全量 A-Z Memory Spark 覆盖

- Owner：Curriculum Agent / Godot Dev Agent / QA Agent。
- Scope：`data/maps/sunshine_world_hotspots_v001.json`、`data/dialogues/anchor_*.json`、`tests/`。
- Deliverables：把 26 个 A-Z 锚点补齐可回访 Spark，但保持 route_order 和主编码不变。
- Acceptance：A = Apple 不改；旧 `anchor_*` ID 和 `anchor_recall_done_*` flag 不迁移，除非另开协调迁移。
- Status：已完成。全量 A-Z `memory_spark_defs` 已生成；`anchor_*` ID、`anchor_recall_done_*` flag、route_order 和 `A = Apple` 保持兼容。

### P2.3 新 Parent Bonus gate 迁移

- Owner：PM Agent / Godot Dev Agent / QA Agent。
- Scope：`scripts/core/game_state.gd`、`scripts/systems/parent_summary.gd`、`tests/helpers/playtest_report_validator.gd`、manual docs。
- Deliverables：在新 home-first MVP 正式事件组稳定后，把 gate 从历史 4 个正式 MVP events 迁到 `Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip` + `Story Show` 的新事件组。
- Implementation-ready gate spec：新增确认 flag `parent_bonus_confirmed_home_prologue_v001`；required events 为 `prologue_letter_box`、`prologue_room_starter`、`prologue_pet_hello`、`prologue_home_pet_care`、`prologue_go_to_school`；required show state 继续读 `StoryShow` / legacy `mvp_0_2_review_challenge` 完成合同；奖励仍为一次性 `Parent Bonus +2`。
- Migration rule：旧 `parent_bonus_confirmed_mvp_0_2` 仍保存、可读、可出现在历史报告中。若旧 flag 已确认，不因新 gate 自动重复发放同一阶段 `Parent Bonus`，除非产品另开一个明确命名的新奖励档位。
- Acceptance：旧报告和旧存档仍可读；`Coins` 和 `Parent Bonus` 不合并；Explorer Cape 或后续稀有奖励继续只花 Parent Bonus；ParentSummary 使用 `GameState.get_parent_summary_state()` 或明确 getter，不把 `debug_snapshot()` 当产品 API。
- Status：已完成。新 flag `parent_bonus_confirmed_home_prologue_v001` 已写入；旧 flag `parent_bonus_confirmed_mvp_0_2` 可读并防重复；新增迁移测试通过。

### P2.4 旧文档与素材深度清理

- Owner：Docs Agent / Asset Agent / 主 Agent。
- Scope：`docs/source/`、历史 `docs/development/MVP_0_2_*`、未接入 `assets/generated/`。
- Deliverables：把历史材料归档说明再压缩；删除或移动确认为误导当前方向且无历史证据价值的文件。
- Acceptance：删除前在本 todo 记录路径、理由和替代来源；`docs/README.md` 明确当前入口；docs audit 同步。
- Status：已完成。未删除具有历史验证价值的 `MVP_0_2_*` 文档；已更新当前入口、素材状态、source prompts、docs audit 和 smoke plan，清理旧 ticket/pilot/gate 当前口径。

## 8. 后续 Agent 分组派发模板

### PM / Game Design Agent

- Inputs：`AGENTS.md`、`todo.md`、`docs/product/教学玩法重构策划_v0.1.md`、`docs/product/小学英语故事线与关卡内容设计.md`。
- Deliverables：新 MVP 事件链规格、任务标题、奖励和验收标准。
- Acceptance：每个事件都是生活事件，不是 lesson/test；能直接转换为 quest JSON。

### Curriculum / Narrative Agent

- Inputs：`curriculum/小学英语重点分析/`、新 MVP 事件规格、`data/dialogues/`。
- Deliverables：适龄词汇、句型、NPC 对话、家长解释。
- Acceptance：儿童对话短、具体、可操作；英语内容与 home/pet/shop/trip 行为绑定。

### Godot Dev Agent

- Inputs：`todo.md`、`scripts/`、`scenes/`、`data/quests/`、`data/maps/`。
- Deliverables：数据驱动 quest/home/pet/PlaceCard 实现、测试。
- Acceptance：优先扩 controller 和 JSON，不把新生命周期分支塞回 `main.gd`。

### UIUX / Asset Agent

- Inputs：`docs/assets/AI图片素材生成规范_v0.1.md`、`docs/assets/MVP_0_2_第一版自生成美术资产记录.md`、`assets/source_prompts/`。
- Deliverables：home/pet/PlaceCard/reward 资产、prompt 记录、接入说明。
- Acceptance：原创、适龄、无 IP/Logo/商标；已接入和备用状态明确。

### QA / Docs Agent

- Inputs：`tests/`、`scripts/dev/run_mvp_0_2_checks.sh`、`docs/`。
- Deliverables：新 MVP flow 测试、docs audit 更新、人工验收脚本。
- Acceptance：自动化覆盖数据合同、输入链路、存档回读、货币分离和儿童前台 denylist。

## 9. 推荐执行顺序

1. 完成 P0.1，锁定新 MVP 的正式事件列表。
2. 完成 P0.2 和 P0.3，先让 home 序章可数据化。
3. 完成 P0.4，把宠物命名和第一轮照顾接入 runtime。
4. 完成 P0.8，为 home 序章建立自动化保护。
5. 完成 P0.5 和 P0.7，补齐关键 home-first 美术反馈。
6. 完成 P0.6，避免继续堆 PlaceCard 分支债。
7. 跑最小回归：`godot --headless --path . --check-only --quit` 和新增 home flow。
8. 跑现有相关回归：home pet、owned items、PlaceCard、transport、Memory Spark、world overview。
9. 跑完整自动链：`./scripts/dev/run_mvp_0_2_checks.sh` 或新建 `run_new_mvp_checks.sh`。
10. 完成人工窗口试玩，重点检查 home/pet/Quest Diary/PlaceCard/世界地图拖动和儿童前台文案。

## 10. 通用验收命令

```bash
godot --headless --path . --check-only --quit
godot --headless --path . -s res://tests/mvp_0_2_docs_audit.gd
godot --headless --path . -s res://tests/mvp_0_2_quest_data_integrity.gd
godot --headless --path . -s res://tests/mvp_0_2_game_state_pet_care.gd
godot --headless --path . -s res://tests/mvp_0_2_game_state_owned_items.gd
godot --headless --path . -s res://tests/mvp_0_2_home_pet_care_input_flow.gd
godot --headless --path . -s res://tests/mvp_0_2_place_card_action_authorization.gd
godot --headless --path . -s res://tests/mvp_0_2_memory_spark_flow.gd
godot --headless --path . -s res://tests/mvp_0_2_world_overview_input_flow.gd
godot --headless --path . -s res://tests/mvp_0_2_smoke.gd
godot --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd
./scripts/dev/run_mvp_0_2_checks.sh
```

## 11. 删除与重构记录

后续如果执行删除或大范围重构，先在这里新增记录，再改文件。

| 日期 | 路径 | 操作 | 原因 | 替代来源 | 验证 |
|---|---|---|---|---|---|
| 2026-06-02 | `todo.md` | 新增并收口 | 建立并完成新 MVP 推进清单 | 本轮 agent/worker 回报与主 Agent 整合 | `mvp_0_2_docs_audit.gd`、`run_new_mvp_checks.sh` |
| 2026-06-02 | `docs/development/MVP_0_2_*` | 保留为历史证据，不删除 | 仍有人工试玩、计时、报告验证价值；已在 `docs/README.md` 标注不作为当前基线 | 当前入口改为 `docs/README.md`、`tests/MVP_0_2_smoke_test_plan.md`、本 `todo.md` | `mvp_0_2_docs_audit.gd` |
| 2026-06-02 | `assets/source_prompts/props/*`、`docs/assets/*` | 重构状态文案 | 清理 ticket 复用、pending placeholder、pilot Memory Spark 等旧当前口径 | `data/rewards/reward_icons_v001.json`、已接入生成素材、visual acceptance | `mvp_0_2_visual_acceptance.gd`、`mvp_0_2_docs_audit.gd` |
| 2026-06-02 | `README.md`、`docs/README.md`、`lessons.md`、`docs/product/*`、`docs/development/Godot开发任务拆解_v0.1.md` | 重构当前入口口径 | 避免旧 `Welcome Box -> First Trip`、旧 4 gate、pilot Memory Spark 被误读为当前产品方向 | 新 home-first chain、new Parent Bonus gate、full A-Z Memory Spark runtime | `mvp_0_2_docs_audit.gd` |
