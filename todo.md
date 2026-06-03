# StudyGame 开发计划：赛道 B & 赛道 C

> 日期：2026-06-02  
> 完成更新：2026-06-03  
> 角色：项目经理  
> 基线：MVP 0.2 全量 38+ 自动化测试通过，赛道 A（Git 推送 + 测试修复）已关闭  
> 产品北极星：`home → school → town → transport → world` 生活冒险游戏
> 执行状态：赛道 B / 赛道 C 已完成，最终自动化检查通过

---

## 当前决策：世界地图基准

- 当前只保留 `assets/generated/maps/world/map_sunshine_world_overview_v006.png` 作为下一版 `world_overview` 风格候选。
- v002-v005 世界地图过程 prompt 与 `docs/assets/world_map_*` 过程预览图已清理，不再作为当前决策依据。
- A-Z 记忆路线保持独立覆盖层，当前候选资产为 `assets/generated/maps/world/map_sunshine_world_memory_overlay_v001.png`，后续不应直接烘死在常驻底图里。
- 现阶段先确认世界地图本体，再进入游戏数据调整；`data/maps/sunshine_world_hotspots_v001.json`、视口聚焦、PlaceCard/scene routing 应在下一阶段围绕确认后的底图对齐。
- 当前 runtime 尚未替换已接入的 `assets/generated/maps/world/map_sunshine_world_overview_v001.png`。

## 下一阶段建议

| 优先级 | 任务 | 交付物 |
|--------|------|--------|
| P0 | 将确认后的世界地图风格候选复制/版本化到 `assets/generated/maps/world/` | 已完成：`map_sunshine_world_overview_v006.png` |
| P0 | 评估 v006 是否作为最终接入版本 | 选定最终接入版本 |
| P0 | 接入新版 world_overview 背景并保留可回退路径 | Godot 场景引用更新 + visual acceptance |
| P0 | 基于确认后的底图重新微调 hotspot rect | `data/maps/sunshine_world_hotspots_v001.json` |
| P1 | 将 A-Z 记忆路线作为独立显示层接入 | Memory Spark / debug / recall overlay 控制 |
| P1 | 重新验收 1280x720 初始视口和拖动视口 | opening viewport + town/transport viewport 手动检查 |

---

## 最终完成记录

| 维度 | 完成状态 |
|------|----------|
| B1 Pet 可视化 | 已完成：新增 happy / neutral / sleepy 与 eating / playing / sleeping 资产，HomeLayer 根据 `GameState.pet_state` 刷新并播放 action feedback |
| B2 Room 探索 | 已完成：新增 `home_room_explore_a` / `home_room_explore_b` 可重复 quest，扩展 lamp / clock / window targets 与入口 UI |
| B3 Home 装饰 | 已完成：购买 `star_rug` / `explorer_cape` 后显示 `DecorSlot_Rug` / `DecorSlot_Cape`，save/load 后恢复 |
| B4 School 美术 | 已完成：`ClassroomLayer` / `GardenLayer` 接入 1280x720 v002 生成背景，保留交互节点 |
| B5 Transport | 已完成：bus / taxi / railway 三条轻量路线保留 story flag，并补齐地图聚焦与 PlaceCard 成功展示 |
| C1 GameState 拆分 | 已完成：抽取 `PetCareManager`、`StarterActionEngine`、`PlaytestReporter`、`GameStatePersistence`，公共 API 不变，`game_state.gd` 降至 497 行 |
| C2 第一篇内容 | 已完成：新增「第一篇：小镇新朋友」设计文档、Ava NPC 规格/肖像、3 个 town quest 与 dialogue |
| C3 PlaceCard 升级 | 已完成：hospital / airport / railway_station 上线可玩 PlaceCard action，不加入 Parent Bonus gate |
| C4 Music / Art Room | 已完成：`music_room` / `art_room` 改为 `after_prologue` 解锁，各有 1 个 world_overview click quest |
| 最终验证 | 已通过：`godot --headless --path . --check-only --quit` 与 `./scripts/dev/run_mvp_0_2_checks.sh` |

## 当前已完成基线

| 维度 | 状态 |
|------|------|
| Home 序章 Quest 链 | `Welcome Box → Room Starter → Pet Hello → Home Pet Care → First Trip` 5 个 quest 已落地 |
| School Quest 链 | `Walk With Mina → Room Helper → Bird Watch → Story Show → ParentSummary` 兼容保留 |
| Town 委托 | bookshop / cinema / post_office / restaurant 4 条非学校委托 |
| Starter economy | supermarket(pet_bowl) / pet_shop(pet_ball) / clothes_shop(cape) / general_store(rug) 4 条闭环 |
| Transport | bus_station / taxi / railway_station 3 条轻量 travel action |
| A-Z Memory Spark | 全量 26 锚点参数化 |
| 数据驱动 | Quest / PlaceCard / MemorySpark / Reward / StarterAction 均从 JSON 读取 |
| Controller 架构 | MainFlowController / WorldInteractionController / PlaceCardController 已抽取 |
| 美术资产 | 50 个生成 PNG (地图/角色/道具/UI)，新增 pet 状态/动作、room props、home decor、school v002 背景、Ava 肖像 |
| 代码规模 | game_state.gd 497行 / main.gd 224行 / 全 systems/ 3413行 |

---

## 赛道 B：短期产品扩展（1-2 周）

目标：让孩子首次进入游戏时的「在家探索」体验从"可用"提升到"好玩"。

---

### B1. Home 序章深化 — Pet 可视化与状态反馈

**优先级：P0** | **预估工期：3 天** | **Owner：Godot Dev + Asset Agent**

#### 背景

当前 Pet 是静态图片，`pet_state`（hunger/cleanliness/mood/bond/rest）仅存在于数据层，HomeLayer 无任何视觉反馈。孩子执行 feed/clean/play/rest 后看不到宠物变化。

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **美术** | 生成 3 套宠物表情状态图：happy / neutral / sleepy | `assets/generated/characters/pet/pet_mood_happy_v001.png` 等 3 张 |
| **美术** | 生成宠物动作反馈图：eating / playing / sleeping | `assets/generated/characters/pet/pet_action_eating_v001.png` 等 3 张 |
| **工程** | 在 `HomeLayer/PetCorner` 增加 `PetStateDisplay` 节点，根据 `pet_state` 切换 Sprite | `scenes/maps/TownMap.tscn` 修改 |
| **工程** | 新增 `scripts/systems/pet_visual_controller.gd`，监听 `pet_state_changed` 信号刷新表情 | 新文件 ~60 行 |
| **工程** | feed/clean/play/rest 执行后播放 0.5s 简单缩放动画 | Tween 动画，不新增 AnimationPlayer |
| **QA** | 新增 `tests/mvp_pet_visual_state_flow.gd` | headless 验证状态切换后 Sprite texture 变化 |

#### 验收标准

- [x] `pet_state.mood >= 70` 时显示 happy 表情，`< 40` 时显示 sleepy，其余显示 neutral
- [x] 执行 `care_for_pet("feed")` 后 PetCorner 播放 eating 反馈动画
- [x] 所有状态图从 `assets/generated/` 加载，不使用 ColorRect 占位
- [x] `GameState.pet_state_changed` 信号触发后 200ms 内刷新完毕
- [x] 不新增平行宠物存档；复用现有 `GameState.pet_state`
- [x] 现有 `mvp_0_2_game_state_pet_care.gd` 和 `mvp_0_2_home_pet_care_input_flow.gd` 继续通过

#### 验证命令

```bash
godot --headless --path . -s res://tests/mvp_pet_visual_state_flow.gd
godot --headless --path . -s res://tests/mvp_0_2_game_state_pet_care.gd
godot --headless --path . -s res://tests/mvp_0_2_home_pet_care_input_flow.gd
```

---

### B2. Home 序章深化 — Room 物品指认交互事件

**优先级：P0** | **预估工期：2 天** | **Owner：Game Design + Godot Dev**

#### 背景

`scene_click_targets_v001.json` 已有 `home_book`、`home_bag`、`home_bed`、`home_door` 等目标，但当前只在 `Room Starter` quest 中使用一次 click 即完成。需要增加可重复的「找一找」小互动，让 room objects 认知更深入。

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **策划** | 设计 2 个可重复的 home room 探索小事件规格 | quest JSON 规格文档 |
| **工程** | 新增 `data/quests/home_room_explore_a.json`：找 3 个物品 | quest data + dialogue |
| **工程** | 新增 `data/quests/home_room_explore_b.json`：按描述找物品 | quest data + dialogue |
| **工程** | 扩展 `scene_click_targets_v001.json` 增加 `home_lamp`、`home_clock`、`home_window` | JSON 数据 |
| **美术** | 为新增 home targets 生成对应 prop 图标 | 3 张 prop PNG |
| **QA** | 新增 `tests/mvp_home_room_explore_flow.gd` | headless flow 测试 |

#### 验收标准

- [x] 2 个新 quest 均从 JSON 读取，不新增 `main.gd` match 分支
- [x] 新增 targets 从 `scene_click_targets_v001.json` 读取，不新增脚本常量
- [x] 每个事件奖励 `+1 coin`，不加入 Parent Bonus gate
- [x] 儿童端用 `Find the...` / `Where is the...` 生活化用语，不出现 lesson/test
- [x] 现有 `mvp_new_home_prologue_flow.gd` 继续通过

#### 验证命令

```bash
godot --headless --path . -s res://tests/mvp_home_room_explore_flow.gd
godot --headless --path . -s res://tests/mvp_new_home_prologue_flow.gd
godot --headless --path . -s res://tests/mvp_0_2_quest_data_integrity.gd
```

---

### B3. Home 装饰可视化

**优先级：P1** | **预估工期：2 天** | **Owner：Godot Dev + Asset Agent**

#### 背景

`owned_items` 已有 `star_rug` 等数据，`general_store → Buy Star Rug (4)` 购买闭环已通过测试，但 HomeLayer 中购买后无视觉变化。

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **美术** | 生成 star_rug 铺设效果图 | `assets/generated/props/home/prop_star_rug_placed_v001.png` |
| **美术** | 生成 explorer_cape 展示效果图 | `assets/generated/props/home/prop_explorer_cape_display_v001.png` |
| **工程** | 新增 `scripts/systems/home_decor_renderer.gd`，监听 `owned_items_changed` | 新文件 ~80 行 |
| **工程** | 在 HomeLayer 增加 `DecorSlot_Rug` / `DecorSlot_Cape` 占位节点 | TownMap.tscn 修改 |
| **QA** | 扩展 `tests/mvp_0_2_general_store_room_decor_flow.gd` 验证 HomeLayer 渲染 | 测试修改 |

#### 验收标准

- [x] 购买 star_rug 后 HomeLayer 显示地毯 Sprite
- [x] 购买 explorer_cape 后 HomeLayer 显示披风展示
- [x] 未购买时 DecorSlot 隐藏，不显示占位图
- [x] save/load 后装饰状态正确恢复
- [x] 不引入完整背包 UI / 数量 / 消耗品系统

#### 验证命令

```bash
godot --headless --path . -s res://tests/mvp_0_2_general_store_room_decor_flow.gd
godot --headless --path . -s res://tests/mvp_0_2_game_state_owned_items.gd
```

---

### B4. School 子场景美术替换

**优先级：P1** | **预估工期：3 天** | **Owner：Asset Agent + Godot Dev**

#### 背景

classroom 和 garden 当前仍使用 ColorRect/Polygon 程序搭建。`assets/generated/maps/classroom/` 和 `assets/generated/maps/garden/` 已有生成背景 PNG，但未接入场景节点。

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **美术** | 优化/重新生成 classroom 内景背景 (1280x720) | `assets/generated/maps/classroom/map_classroom_interior_v002.png` |
| **美术** | 优化/重新生成 garden 背景 (1280x720) | `assets/generated/maps/garden/map_garden_bg_v002.png` |
| **工程** | 替换 ClassroomLayer 的 ColorRect 为 TextureRect + 背景图 | TownMap.tscn 修改 |
| **工程** | 替换 GardenLayer 的 ColorRect 为 TextureRect + 背景图 | TownMap.tscn 修改 |
| **工程** | 保持 DeskA/Shelf/Tree/Bird 等交互节点的碰撞区域不变 | 节点位置微调 |
| **QA** | 更新 `mvp_0_2_visual_acceptance.gd` 验证背景 texture 加载 | 测试修改 |

#### 验收标准

- [x] ClassroomLayer / GardenLayer 不再使用 ColorRect 作为主背景
- [x] 背景图为 1280x720 PNG，无拉伸变形
- [x] DeskA/Shelf/Tree/Bird 等可交互节点位置与碰撞区域保持功能正常
- [x] `Walk With Mina → Room Helper → Bird Watch` quest 链路不受影响
- [x] 现有 `mvp_0_2_smoke.gd` 继续通过

#### 验证命令

```bash
godot --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd
godot --headless --path . -s res://tests/mvp_0_2_smoke.gd
godot --headless --path . -s res://tests/mvp_0_2_world_overview_input_flow.gd
```

---

### B5. Transport 扩展 — 第二/三条路线

**优先级：P1** | **预估工期：1 天** | **Owner：Godot Dev**

#### 背景

当前 `taxi → find_town_road` 和 `railway_station → choose_train_stop` 的 action 已在 `starter_actions_v001.json` 中注册，flow 测试已通过。需要增加对应的地图聚焦反馈和 PlaceCard success 展示。

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **策划** | 为 taxi/railway 设计 PlaceCard success_status_text 和 home_feedback | hotspot JSON 更新 |
| **工程** | 更新 `sunshine_world_hotspots_v001.json` 中 taxi/railway 的 `success_focus_hotspot` | JSON 数据 |
| **工程** | 确保 transport 完成后地图聚焦到对应区域 | WorldInteractionController 扩展 |
| **QA** | 扩展 `mvp_0_2_transport_town_route_flow.gd` 覆盖 taxi/railway 聚焦行为 | 测试修改 |

#### 验收标准

- [x] 完成 taxi route 后地图聚焦 taxi stand 区域
- [x] 完成 railway route 后地图聚焦 railway station 区域
- [x] 三条 transport 使用轻量 story flag，不引入路线背包
- [x] 现有 transport flow 测试继续通过

#### 验证命令

```bash
godot --headless --path . -s res://tests/mvp_0_2_transport_town_route_flow.gd
```

---

### 赛道 B 里程碑检查点

| 检查点 | 标志 | 自动化验证 |
|--------|------|-----------|
| B-CP1 | B1 + B2 完成，Pet 有视觉反馈 + Room 有可重复探索 | `run_mvp_0_2_checks.sh` 全通过 |
| B-CP2 | B3 + B4 完成，Home 有装饰 + School 有美术 | visual acceptance 通过 |
| B-CP3 | B5 完成，三条 transport 均有地图反馈 | transport flow 通过 |
| **B-Final** | 人工窗口试玩：home 探索 → pet 照顾 → 购物 → 装饰 → school 体验流畅 | 手动 |

---

## 赛道 C：中期架构与内容扩展（2-4 周）

目标：为项目进入「第一篇：小镇新朋友」做架构准备和内容铺垫。

---

### C1. game_state.gd 子模块拆分

**优先级：P2** | **预估工期：3 天** | **Owner：Godot Dev + QA**

#### 背景

`game_state.gd` 当前 859 行，承载了 pet care、starter action engine、playtest reporter、save/load、item management 等多种职责。需要在不改变外部 API 的前提下，拆分为可维护的子模块。

#### 拆分计划

| 子模块 | 新文件 | 估计行数 | 抽取内容 |
|--------|--------|---------|---------|
| PetCareManager | `scripts/systems/pet_care_manager.gd` | ~120 行 | `care_for_pet()`, `_adjust_pet_stat()`, `get_pet_state()`, `set_pet_name()`, pet 常量 |
| StarterActionEngine | `scripts/systems/starter_action_engine.gd` | ~150 行 | `_run_starter_action()`, `_starter_action_config()`, action catalog 加载/缓存 |
| PlaytestReporter | `scripts/systems/playtest_reporter.gd` | ~100 行 | `start_playtest_timer()`, `finish_playtest_timer()`, `record_playtest_event()`, `build_playtest_report()`, `save_playtest_report()` |

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **工程** | 抽取 PetCareManager，GameState 保留 delegate 方法 | 新文件 + game_state.gd 瘦身 |
| **工程** | 抽取 StarterActionEngine，GameState 保留 `buy_*()` wrapper | 新文件 + game_state.gd 瘦身 |
| **工程** | 抽取 PlaytestReporter，GameState 保留 timer API wrapper | 新文件 + game_state.gd 瘦身 |
| **工程** | 确保 `has_pet_bowl()` 等兼容 helper 不变 | API 兼容 |
| **QA** | 全量 38+ 测试必须零修改通过 | 零 regression |

#### 验收标准

- [x] `game_state.gd` 行数降至 ~500 行以下
- [x] 外部调用方（main.gd、controllers、tests）零修改
- [x] `GameState.care_for_pet()` / `GameState.buy_pet_bowl()` 等公共 API 签名不变
- [x] 三个新文件均有 `class_name` 并由 `GameState` autoload 内部引用
- [x] `./scripts/dev/run_mvp_0_2_checks.sh` 全量通过

#### 验证命令

```bash
godot --headless --path . --check-only --quit
./scripts/dev/run_mvp_0_2_checks.sh
```

---

### C2. 序章 → 第一篇「小镇新朋友」内容设计

**优先级：P2** | **预估工期：5 天** | **Owner：PM + Game Design + Narrative + Curriculum**

#### 背景

序章完成后（5 个 home quest + school 4 quest），孩子缺少一个自然的叙事过渡把 home/school 连接到更广的 town 探索。需要设计第一篇章内容。

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **策划** | 设计第一篇主线：3-5 个 town 探索 quest，覆盖问候/天气/时间主题 | `docs/product/第一篇_小镇新朋友_设计.md` |
| **策划** | 设计 1 个新 NPC（town 居民），与 Mina/Leo/Nora 区分 | NPC 规格 + 对话设计 |
| **课程** | 为第一篇 quest 配置适龄词汇和句型（G4 Unit 2-3 范围） | curriculum mapping |
| **叙事** | 编写 town NPC 对话 JSON（生活冒险口吻，非教学口吻） | `data/dialogues/town_*.json` |
| **工程** | 新增 quest JSON + dialogue JSON + hotspot 数据 | `data/quests/town_chapter1_*.json` |

#### 验收标准

- [x] 第一篇包含 3-5 个可执行 quest，每个有明确 words/patterns/reward
- [x] 至少 1 个新 NPC，有名字、对话、可生成的肖像规格
- [x] 所有 quest 从 JSON 启动，不新增 `main.gd` / `main_flow_controller.gd` match 分支
- [x] 儿童端用 help/visit/discover/meet 语气，不用 lesson/test/review
- [x] 不改 A-Z 锚点 route_order
- [x] `mvp_0_2_quest_data_integrity.gd` 通过

#### 验证命令

```bash
godot --headless --path . -s res://tests/mvp_0_2_quest_data_integrity.gd
godot --headless --path . -s res://tests/mvp_0_2_docs_audit.gd
```

---

### C3. PlaceCard → 可玩事件升级矩阵

**优先级：P2** | **预估工期：3 天** | **Owner：Game Design + Godot Dev**

#### 背景

当前 51 个世界热点中，仍有多个只有 PlaceCard 浏览而无可玩 action 的地点：`park`、`hospital`、`airport`、`playground`、`canteen` 等。

#### 升级候选

| Place | 当前状态 | 候选 Quest | 候选 Action |
|-------|---------|-----------|------------|
| `park` | PlaceCard 浏览 | `town_park_kite_fly` (Kite Day) | Help Fly a Kite |
| `hospital` | PlaceCard 浏览 | `town_hospital_band_aid` (Band-Aid Helper) | Help Find a Band-Aid |
| `playground` | 学校内，无独立 action | `school_playground_ball_game` (Ball Game) | Play a Ball Game |
| `canteen` | 学校内，无独立 action | `school_canteen_lunch_pick` (Lunch Pick) | Help Pick Lunch |
| `airport` | PlaceCard 浏览 | 暂缓（world 阶段） | — |

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **策划** | 确定首批 2-3 个升级地点的 quest 规格 | quest 规格文档 |
| **工程** | 新增对应 quest JSON + hotspot action 声明 | `data/quests/` + `data/maps/` 更新 |
| **工程** | 新增对应 dialogue JSON | `data/dialogues/` |
| **QA** | 每个新 quest 新增一个 flow 测试 | `tests/mvp_*_flow.gd` |

#### 验收标准

- [x] 首批至少 2 个新可玩 PlaceCard action 上线
- [x] 新 quest 不加入 Parent Bonus gate
- [x] 每个新 quest 包含 2-3 个 words + 1 个 pattern
- [x] 现有 `mvp_0_2_non_school_place_card_matrix.gd` 继续通过

#### 验证命令

```bash
godot --headless --path . -s res://tests/mvp_0_2_non_school_place_card_matrix.gd
godot --headless --path . -s res://tests/mvp_0_2_place_card_action_authorization.gd
godot --headless --path . -s res://tests/mvp_0_2_quest_data_integrity.gd
```

---

### C4. Music Room / Art Room 解锁

**优先级：P3** | **预估工期：2 天** | **Owner：Game Design + Godot Dev**

#### 背景

`music_room` 和 `art_room` 当前 `world_enabled_mode: disabled`，是 planning-only 热点。需要设计解锁条件和首个可玩事件。

#### 工作内容

| 组 | 任务 | 交付物 |
|----|------|--------|
| **策划** | 设计 music_room / art_room 解锁条件（如完成序章后可见） | 热点数据更新规格 |
| **策划** | 各设计 1 个首个可玩 quest | quest 规格 |
| **工程** | 更新 `sunshine_world_hotspots_v001.json` 中 `world_enabled_mode` | JSON 更新 |
| **工程** | 新增 quest + dialogue JSON | 数据文件 |
| **QA** | 更新 `mvp_0_2_world_hotspot_enablement.gd` | 测试更新 |

#### 验收标准

- [x] music_room / art_room 在序章完成后从 disabled 变为可见
- [x] 各有 1 个可玩首访事件
- [x] 现有 hotspot enablement 测试更新后通过

#### 验证命令

```bash
godot --headless --path . -s res://tests/mvp_0_2_world_hotspot_enablement.gd
```

---

### 赛道 C 里程碑检查点

| 检查点 | 标志 | 自动化验证 |
|--------|------|-----------|
| C-CP1 | C1 完成，game_state.gd < 500 行 | 全量 38+ 测试零修改通过 |
| C-CP2 | C2 完成，第一篇设计文档 + 3 个 quest JSON 到位 | quest data integrity 通过 |
| C-CP3 | C3 完成，park/hospital 等至少 2 个新可玩 action | PlaceCard matrix 通过 |
| C-CP4 | C4 完成，music_room/art_room 可访问 | hotspot enablement 通过 |
| **C-Final** | 人工窗口试玩：序章 → 第一篇过渡自然，新 NPC 对话流畅 | 手动 |

---

## 执行顺序总览

```
Week 1:  B1(Pet可视化) ──→ B2(Room探索) ──→ B-CP1
Week 2:  B3(Home装饰) + B4(School美术) + B5(Transport) ──→ B-Final
Week 3:  C1(game_state拆分) + C2-设计阶段(第一篇策划) ──→ C-CP1
Week 4:  C2-工程落地 + C3(PlaceCard升级) + C4(解锁房间) ──→ C-Final
```

## 通用验收命令

```bash
# 编译检查
godot --headless --path . --check-only --quit

# 全量自动化
./scripts/dev/run_mvp_0_2_checks.sh

# 核心单项
godot --headless --path . -s res://tests/mvp_0_2_smoke.gd
godot --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd
godot --headless --path . -s res://tests/mvp_0_2_quest_data_integrity.gd
godot --headless --path . -s res://tests/mvp_0_2_docs_audit.gd
```

## 风险与约束

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| 美术生成质量不稳定 | B1/B3/B4 可能返工 | 每张图先生成 2-3 个变体选优 |
| game_state 拆分引入回归 | C1 可能破坏全量测试 | 严格保持 API 签名不变；拆分后立刻全量跑测试 |
| 第一篇设计范围膨胀 | C2 超期 | 先锁定 3 个 quest，后续迭代扩展 |
| A-Z 锚点冻结约束 | C3/C4 不能动 route_order | 新事件使用独立 quest_id，不复用 anchor ID |

## 删除与重构记录

后续如果执行删除或大范围重构，先在这里新增记录，再改文件。

| 日期 | 路径 | 操作 | 原因 | 替代来源 | 验证 |
|------|------|------|------|---------|------|
| — | — | — | — | — | — |
