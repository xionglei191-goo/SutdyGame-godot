# MVP 0.2 Smoke Test Plan

> 目标：为后续 `tests/mvp_0_2_smoke.gd` 自动化脚本提供测试设计，不在本文件中修改游戏逻辑。

## 1. 执行入口

推荐保留两层 smoke：

```bash
godot --headless --path . --check-only --quit
godot --headless --path . -s res://tests/mvp_0_2_smoke.gd
```

完整自动检查可使用一键脚本：

```bash
./scripts/dev/run_mvp_0_2_checks.sh
```

该脚本会顺序执行核心自动检查，跳过需要真实人工报告的 `mvp_0_2_manual_playtest_postflight.gd`、`mvp_0_2_verify_playtest_report.gd` 和 `mvp_0_2_export_playtest_summary.gd`，并在退出前运行 `mvp_0_2_manual_playtest_preflight.gd` 清理默认正式存档、报告和摘要。

第一条用于发现场景、脚本、资源导入级错误。第二条用于快速验证 MVP 0.2 关键业务闭环。

## 2. 自动化范围

### 2.1 场景加载

- 加载主场景。
- 加载 world_overview 中的 home + school 起步区、正式 `HomeLayer`、教室、花园 4 个关键场景层。
- 断言场景实例化成功，且根节点下存在可交互内容。

建议断言：

- 场景资源不是 `null`。
- 实例化后节点数大于 0。
- 关键 NPC 或交互点节点存在，节点名可根据最终实现调整。

### 2.1.1 World Overview 输入基线

- 新开局默认显示 `HomeLayer`，以 `Welcome Box` 作为 home-first opener。
- `world_overview` 逻辑尺寸为 `2560x2560`，运行时视口仍保持 `1280x720`。
- 打开世界地图后，world overview 起步镜头同时覆盖 `home` 和 `Sunshine School`，以 `home + school` 同屏的 world overview 起步构图进入地图。
- 世界地图起步镜头同时覆盖 `home` 和 `Sunshine School`。
- 世界地图起步镜头应让 `home + Sunshine School + town road` 的关系同时成立；school 核心簇视觉归组，但不能成为唯一主视觉。
- `classroom`、`library`、`canteen`、`music room`、`art room`、`playground` 都收进学校主体内部。
- 社区位于第二圈，需要轻微移动视角才能看全。
- 交通区和边缘地标位于外圈，需要继续移动才能到达。
- `home` 属于校外关键场景，必须存在正式热点与可读标签。
- `home` 点击后应能进入正式 `HomeLayer` 子场景，而不是只停留在 world overview。
- `HomeLayer` 内的 Mina 新存档起手对话使用 `mina_letter_box_intro`，启动 `Welcome Box`（`prologue_letter_box`，target `home_letter_box`）；随后按 `mina_room_starter_intro`、`mina_pet_hello_intro`、`mina_home_pet_care_intro`、`mina_first_trip_handoff` 接上 `Room Starter -> Pet Hello -> Home Pet Care -> First Trip`，再衔接 Walk With Mina。
- `bus station` 应贴近主路，`supermarket` 下移到更外圈商业区，避免把交通节点放进商业街深处。
- 总览图热点从 `data/maps/sunshine_world_hotspots_v001.json` 读取，而不是只依赖硬编码矩形；`home`、`campus_gate`、`garden` 等子场景目标也应通过 `data/maps/scene_click_targets_v001.json` 这类数据配置继续迁移和扩展。
- world hotspot 启用规则当前由热点数据驱动：
  - `default_visible: true` 的地点或锚点默认可点；
  - `world_enabled_mode: quest_only` 是内部字段，表现为事件期间开放的互动热点，只在对应 `quest_targets` 激活时可点；
  - `world_enabled_mode: pilot_recall` 的少数 recall 试点锚点允许作为常开例外；
  - `world_enabled_mode: disabled` 的热点当前保留在数据层，但不应在总览图中响应点击。
- 任务进行中优先命中 `place hotspot`；自由探索优先命中 `memory_anchor hotspot`。
- `memory_anchor_clicked(anchor_id)` 属于首版输入基线。
- 总览图支持玩家移动时相机跟随，并支持拖拽平移浏览大地图。
- `tests/mvp_0_2_world_overview_input_flow.gd` 负责锁定当前 runtime 基线：
  - 点击 `anchor_a_apple` 会打开对话框。
  - Walk With Mina 完成前点击学校核心区会按当前兼容路由从总览图进入 `campus_gate`。

### 2.1.2 Home Pet Care 输入基线

- `HomeLayer` 内应存在 Welcome Box、房间物件、宠物照料入口和 Mina 起手对话；宠物照料已纳入 `Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip` 序章链。
- 宠物照料状态通过 `GameState` 读写，不新增平行存档字段。
- `feed` 消耗 `2 coins`；`clean` 与 `play` 不消耗 `coins`。
- 宠物照料完成后，`coins` 和 `pet_state` 变更可被运行时和存档回读观察到。

### 2.1.3 Non-school PlaceCard 与首访 Coin 基线

- `world_overview` 中的非学校（non-school）`place hotspot` 点击当前应弹出 `PlaceCard`，而不是强制切入子场景。
- `home` 仍保留进入正式 `HomeLayer` 子场景的例外路由，用于承接 `Welcome Box`、`Room Starter`、`Pet Hello`、`Home Pet Care` 与 `First Trip`。
- 首次访问通过 `visited_place_<id>` 故事标记发放 `+1 coin`；重复访问只显示 `Already visited`，不重复发币。
- `bookshop` 当前已从 generic PlaceCard 样例升级成首个非学校 Quest Diary 委托入口；自由探索仍先打开 `PlaceCard`，但会显示 `Help Find a Book` 动作。
- `tests/mvp_0_2_home_pet_care_input_flow.gd` 当前顺带锁定 `bookshop` 打开 PlaceCard 但不触发委托时，Mina 的 home-first 对话链仍可继续接上 `First Trip`。
- `tests/mvp_0_2_non_school_place_card_matrix.gd` 批量锁定 `post_office`、`hospital`、`restaurant`、`cinema`、`bus_station`、`railway_station`、`airport` 的 PlaceCard 打开、首访 coin、重复访问和关闭后输入恢复。

### 2.1.3.1 Bookshop Helper 委托基线

- `bookshop` 当前是第一个从 `PlaceCard` 升级成短 `Quest Diary` 委托的非学校地点。
- 首次点击 `bookshop` 时，仍先按 non-school 规则发放首访 `+1 coin` 并打开 `PlaceCard`。
- `bookshop` 的 `PlaceCard` 应额外提供 `Help Find a Book` 动作入口。
- 点击该动作后：
  - 隐藏 `PlaceCard`；
  - 启动 `town_bookshop_find_book`；
  - `Quest Diary` 前台显示 `Bookshop Helper`；
  - prompt 为 `Help the reading bear find a book.`；
  - 仍停留在 `world_overview`，并聚焦 bookshop 区域。
- 点击错误地点应显示 `Look again`，点击 `bookshop` 完成委托。
- 完成后记录 `bookshop / book / read` 与 `Find a book. / Read at the bookshop.`，发放 `Bookshop Leafmark`，额外奖励 `+1 coin`。
- `town_bookshop_find_book` 是自由探索支线，不加入 Parent Bonus 当前 home-first Quest 门槛。
- `tests/mvp_0_2_bookshop_commission_flow.gd` 锁定当前第一个非学校 Quest Diary 委托闭环。

### 2.1.4 Supermarket Pet Bowl 基线

- `supermarket` 当前是第一个从探索走向消费的序章样例，不引入完整商店系统。
- 首次点击 `supermarket` 时，仍先按 non-school 规则发放首访 `+1 coin` 并打开 `PlaceCard`。
- `supermarket` 的 `PlaceCard` 应额外提供 `Buy Pet Bowl (3)` 动作入口。
- 购买成功后：
  - 写入 `owned_items: pet_bowl`，并保留 legacy `owned_pet_bowl` / `visited_place_<id>` 故事标记；
  - 消耗 `3 coins`；
  - 增加 `shop`、`bowl`、`food` 等序章词汇；
  - `home` 的宠物面板可见 `Pet bowl ready` 回流结果。
- 购买成功后再次喂食，反馈应升级为 `Your pet enjoyed a snack in the new bowl.`

### 2.1.4.1 Transport Town Route 基线

- `bus_station` 当前是第一个从地点卡升级成 travel slice 的交通样例，不引入完整路线系统。
- 首次点击 `bus_station` 时，仍先按 non-school 规则发放首访 `+1 coin` 并打开 `PlaceCard`。
- `bus_station` 的 `PlaceCard` 应额外提供 `Choose Town Route` 动作入口。
- 选择路线成功后：
  - 写入 `travel_route_town_edge` 轻量故事标记；
  - 额外发放 `+1 coin` 作为路线发现奖励；
  - 增加 `bus`、`route`、`town` 等序章/出行词汇；
  - 增加 `Take the bus to town.` 出行句型；
  - `PlaceCard` 状态显示 `Town route marked: +1 coin.`；
  - 世界总览镜头聚焦到 bus station / town-edge 区域；
  - 该路线动作在之后访问 `bus_station` 时不再重复出现。
- `tests/mvp_0_2_transport_town_route_flow.gd` 锁定当前最小 travel slice。
- `tests/mvp_0_2_supermarket_pet_bowl_flow.gd` 负责锁定 `supermarket -> Buy Pet Bowl (3) -> home` 的首版消费回流路径。

### 2.1.5 Pet Shop Pet Ball 基线

- `pet_shop` 当前是第二个从探索走向消费的序章样例，继续复用 `PlaceCard`，不引入完整商店系统。
- 首次点击 `pet_shop` 时，仍先按 non-school 规则发放首访 `+1 coin` 并打开 `PlaceCard`。
- `pet_shop` 的 `PlaceCard` 应额外提供 `Buy Pet Ball (2)` 动作入口。
- 购买成功后：
  - 写入 `owned_items: pet_ball`，并保留 legacy `owned_pet_ball` / `visited_place_<id>` 故事标记；
  - 消耗 `2 coins`；
  - 增加 `pet`、`ball`、`play` 等序章词汇；
  - 增加 `Buy a pet ball.` 序章句型；
  - `PlaceCard` 状态显示 `The pet ball is ready at home.`；
  - `home` 的宠物面板可见 `Pet ball ready` 回流结果。
- 购买成功后再次陪玩，反馈应升级为 `Your pet had fun with the new ball.`
- `tests/mvp_0_2_pet_shop_pet_ball_flow.gd` 负责锁定 `pet_shop -> Buy Pet Ball (2) -> home` 的首版消费回流路径。

### 2.1.6 Clothes Shop Explorer Cape 基线

- `clothes_shop` 当前是第一个 `Parent Bonus` 外观消费出口，继续复用 `PlaceCard` 和轻量 `owned_items` 归属层；当前只做物品归属镜像，不引入数量、装备栏、完整背包或 wardrobe UI 系统。
- 首次点击 `clothes_shop` 时，仍先按 non-school 规则发放首访 `+1 coin` 并打开 `PlaceCard`。
- `clothes_shop` 的 `PlaceCard` 应额外提供 `Buy Explorer Cape (1 Parent Bonus)` 动作入口。
- 购买失败时：
  - `parent_bonus = 0` 不写入 `owned_explorer_cape`；
  - `coins` 不被扣除；
  - `PlaceCard` 状态显示 `You need 1 Parent Bonus for the explorer cape.`。
- 购买成功后：
  - 写入 `owned_items: explorer_cape`，并保留 legacy `owned_explorer_cape`，不复用 `owned_pet_bowl / owned_pet_ball`；
  - 消耗 `1 Parent Bonus`，不消耗 `coins`；
  - 增加 `clothes`、`cape`、`wear` 等序章词汇；
  - 增加 `Wear the explorer cape.` 序章句型；
  - `PlaceCard` 状态显示 `The explorer cape is ready at home.`；
  - `home` 的独立 `Outfit` 状态显示 `Explorer cape ready`，且不污染 `Pet item` 状态；
  - `Player/ExplorerCape` 从隐藏变为可见，形成玩家身上的可见装扮反馈；
  - `PlaceCard` 不再重复提供该购买动作。
- `tests/mvp_0_2_clothes_shop_parent_bonus_flow.gd` 负责锁定 `clothes_shop -> Buy Explorer Cape (1 Parent Bonus)` 的首版外观消费路径。

### 2.1.7 General Store Star Rug 基线

- `general_store` 当前是第一个 `Coins` 家园装饰消费出口，继续复用 `PlaceCard` 和轻量 `owned_items` 归属层；当前只做装饰归属镜像，不引入完整 home decoration inventory、数量或摆放编辑系统。
- 首次点击 `general_store` 时，仍先按 non-school 规则发放首访 `+1 coin` 并打开 `PlaceCard`。
- `general_store` 的 `PlaceCard` 应额外提供 `Buy Star Rug (4)` 动作入口。
- 购买成功后：
  - 写入 `owned_items: star_rug`，并保留 legacy `owned_star_rug`，不复用 `owned_pet_bowl / owned_pet_ball / owned_explorer_cape`；
  - 消耗 `4 coins`，不消耗 `Parent Bonus`；
  - 增加 `room`、`rug`、`star` 等序章词汇；
  - 增加 `Put the star rug in your room.` 序章句型；
  - `PlaceCard` 状态显示 `The star rug is ready at home.`；
  - `home` 的独立 `Room decor` 状态显示 `Star rug ready`，且不污染 `Pet item` 或 `Outfit` 状态；
  - `PlaceCard` 不再重复提供该购买动作。
- `tests/mvp_0_2_general_store_room_decor_flow.gd` 负责锁定 `general_store -> Buy Star Rug (4) -> home Room decor` 的首版家园装饰消费路径。

### 2.1.8 Memory Spark 基线

- `memory_anchor` 不再只是一轮三句对话；当前全量 A-Z anchors 支持“首访编码、回访提取”的轻 progression。
- 首次点击 anchor 时，仍先显示现有 `anchor_*.json` 对话，并写入 `anchor_seen_<id>` 轻量标记。
- 再次点击同一 anchor 时，若尚未完成 recall，应打开 `Memory Spark` 小卡，而不是再次只播对话。
- 首版 recall 只做低压图像线索选择，不接入 `Quest Diary`，不污染主线 Quest 完成状态；Debug/报告层的 legacy `completed_tasks` 兼容字段不得被 Memory Spark 写入。
- `Memory Spark` 小卡前台使用 `picture clue / memory word / What comes back?` 口吻，不回退成填空题、词表测验或 `anchor` / `recall` 机制词。
- 首版完成 recall 后：
  - 写入 legacy `anchor_recall_done_<id>` 存档 flag；
  - 增加少量 `coins`；
  - 回流到 `learned_words / learned_patterns`；
  - 关闭 recall 卡后返回 `world_overview` 自由探索。
- 历史试点锚点 `anchor_b_bear`、`anchor_g_gate`、`anchor_h_hat`、`anchor_o_orange`、`anchor_t_taxi`、`anchor_w_watch` 继续作为回归样本；当前 `memory_spark_defs` 覆盖完整 26 个 frozen A-Z anchors。
- A-Z 可点击开放由 `az_unlock_mode` 控制，不再由 `default_visible` 或 `world_enabled_mode: pilot_recall` 隐式决定。
- 序章完成前只开放 starter anchors：`anchor_a_apple`、`anchor_c_clock`、`anchor_e_elephant`、`anchor_g_gate`、`anchor_s_sun`、`anchor_u_umbrella`。
- 序章完成后写入 `az_full_unlocked_after_prologue`，全部 26 个 A-Z anchors 可点击，并可在首访对话后进入 `Memory Spark` 回访。
- `tests/mvp_0_2_memory_spark_flow.gd` 负责锁定“首访对话 -> Memory Spark 回访 -> 奖励与家长层词汇/表达记录回流”的全量覆盖样本路径。
- `tests/mvp_0_2_az_unlock_flow.gd` 负责锁定 starter 限定、序章后全量开放和 route_order 1-26 完整性。
- `tests/mvp_0_2_world_hotspot_enablement.gd` 负责锁定：
  - `tree / flower / bench / bird` 在自由探索中保持隐藏；
  - `g4_u1_garden_bird` 激活时它们变为可点；
  - `music_room / art_room` 在没有 world 路由前不应作为总览图可点热点。

### 2.2 NPC 与事件绑定

- Mina 绑定 `g4_u1_school_tour`。
- Leo 绑定 `g4_u1_tidy_classroom`。
- Nora 绑定 `g4_u1_garden_bird`。

建议断言：

- NPC 的内部事件 ID 不为空。
- 内部事件 ID 能在 Quest 数据中查到。
- 已完成事件不会重复发奖。

### 2.3 起手与 Quest 状态闭环

脚本直接调用 Quest 系统或 UI 暴露的测试接口，模拟完成新 home-first 链与后续兼容链：

- Welcome Box。
- Room Starter。
- Pet Hello。
- Home Pet Care。
- First Trip。
- Walk With Mina。
- Room Helper。
- Bird Watch。

建议断言：

- 前台断言新 home-first 链 `Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip` 与后续 `Walk With Mina -> Room Helper -> Bird Watch` 均可完成；`GameState.get_completed_quests()` / `completed_quests` 镜像保留 8 个 Quest ID；Debug IDs 中 `completed_tasks` 继续保留同一组兼容任务 ID，但报告验证必须以 `completed_quests` 为主字段，`completed_tasks` 只能镜像派生。Parent Bonus 当前以 `Welcome Box / Room Starter / Pet Hello / Home Pet Care / First Trip + Story Show` 为门槛。
- `rewards` 包含兼容 ID `first_trip_ticket`、`school_star_piece`、`tidy_badge_piece`、`garden_leaf_piece`，其中 `school_star_piece` 前台奖励名为 `Adventure Star`。
- `learned_words` 包含 home-first 链与后续兼容链的核心单词。
- `learned_patterns` 或等价字段包含 home-first 链与后续兼容链的核心句型。

### 2.4 小游戏判定

场景点击：

- 输入错误目标，断言事件未完成。
- 输入正确目标，断言事件完成或目标进度推进。

拖拽放置：

- 输入错误物品位置组合，断言事件未完成。
- 输入正确物品位置组合，断言事件完成或目标进度推进。

### 2.5 存档回读

- 清理测试存档或使用独立测试存档路径。
- 写入 8 个已完成 Quest、奖励、家长层词汇和表达记录。
- 重新加载存档。
- 断言状态与写入前一致。
- 写入损坏 JSON 或缺字段存档，断言能回退到初始状态且不崩溃。

### 2.6 家长摘要数据

- 完成 home-first Quest 事件组和 Story Show 后加载家长摘要页面或摘要系统。
- 断言摘要数据包含完成事件、接触过的词汇/表达、建议回访内容。
- 无家长层记录时加载摘要，断言有空状态且不崩溃。
- 断言点击“完成摘要阅读”后写入试玩总用时和试玩节点。
- 断言 `ParentSummary` 展示 `Parent Bonus` 当前值，空摘要时为 `0`。
- 断言未完成 home-first Quest 事件组和 25 题 Story Show 前，`Parent Bonus` 按钮禁用。
- 断言 Story Show 完成后可在家长摘要中一次性发放 `Parent Bonus +2`。
- 断言发放后写入 `parent_bonus_confirmed_home_prologue_v001`；旧 `parent_bonus_confirmed_mvp_0_2` 仍可读并防重复，重复点击不重复加值。
- 断言 `Parent Bonus` 与 `Coins` 分离，存档回读后 `parent_bonus` 和确认 flag 都恢复。

### 2.7 Story Show 时长合同

- 断言 Story Show 共有 25 题。
- 断言朗读/口述题共有 6 道。
- 断言每道朗读/口述题都有 `read_seconds`，且单题不低于 5 秒。
- 断言朗读/口述题固定倒计时总和不低于 30 秒。
- 断言朗读/口述题在倒计时结束前不能直接跳过。
- 断言 Story Show 台词/反馈启用换行，动态选项按钮满足最小点击高度。
- 断言 Story Show 前台提示使用 show / scene / story clue 口吻，不回退到 `Find the word`、`Choose the`、`Round 2`、`Read aloud:`、`library card`、`school place` 这类练习题或学校标签式表达。
- 断言 Dialogue、Quest Diary、ParentSummary 的动态文本标签启用换行，摘要按钮和 `Parent Bonus` 按钮满足最小触控高度。
- 断言 Quest Diary 接入装饰素材、事件名、状态标签和 `Keepsake` 奖励提示。
- 断言 Quest Diary 词汇提示使用 `Quest clues:`，不回退到 `Look for:` 词表式前台表达。
- 断言前期 Quest prompt 使用 `Start Mina's first trip. / Find Mina's story stop. / Help Leo set up the story room.` 等生活事件提示。
- 断言儿童层可见 UI（SceneHost、DialogueBox、Quest Diary、Story Show、PlaceCard、Memory Spark、RewardPopup、DragPlaceGame）不暴露 `QuestDiary`、`StoryShow`、`ReviewChallenge`、`lesson panel`、`word list`、`review test`、`L1/L2/L3` 等内部或学校化词；`ParentSummary` 属于成人层，不纳入该儿童层 denylist。

### 2.8 素材安全轻量扫描

总览图相关生成资产也纳入存在性检查：

- `map_sunshine_world_overview_v007_square.png`
- `map_sunshine_world_az_label_v001.png`
- `map_sunshine_world_az_label_showcase_v001.png`

视觉验收同时覆盖 26 个 `anchor_*.json` 是否齐全、结构是否正确，以及每行文案长度是否受控。


扫描范围建议仅限：

- `res://assets/generated/`
- `res://assets/` 中 MVP 0.2 新接入的图片素材目录

建议断言：

- 文件大小大于 0。
- 扩展名为项目允许格式，例如 `.png`、`.webp`。
- 文件名不包含 `barbie`、`disney`、`pixar`、`sanrio`、`logo`、`trademark` 等风险词。

### 2.9 MVP 文档状态审计

- 断言验收记录仍保留“成人熟练 2-5 分钟闭环”人工试玩项未勾选。
- 断言验收记录不包含旧任务 ID、旧 story-room 提示、旧花园风筝目标或 `待测` 残留。
- 断言人工脚本、计时记录和 smoke test plan 与当前任务 ID、提示文案、QA 报告字段保持一致。

### 2.10 计时摘要导出 fixture

- 构造一份 3 分钟完整报告。
- 断言 Markdown 摘要包含目标窗口结果、3 个任务 ID、Review ID、30 秒固定朗读时间、可粘贴到计时记录的报告核对字段、报告节点分段参考、Timeline、Segment Deltas。
- 断言 `Manual result` 和 `Manual notes` 保持空位，不自动给出人工结论。

### 2.11 人工试玩 preflight

- 断言默认正式存档、计时报告和 Markdown 摘要已清理。
- 断言 `Main.tscn` 可实例化，新开局默认首屏停在 `HomeLayer`，世界地图打开后仍落在当前起步区构图内。
- 断言空家长摘要显示空状态，不能提前完成摘要阅读或导出报告。
- 断言核心报告导出接口拒绝未完成流程。

### 2.12 人工试玩 readiness

- `mvp_0_2_manual_playtest_readiness.gd` 只读检查工作区是否处于“可开始人工试玩”的干净状态，或已经保留一套完整人工证据。
- 允许真实文档仍处于 `状态：待人工计时`，或已经完成并保留人工证据。
- 若人工证据已经完成，则接受计时记录“通过”和验收记录“成人熟练 2-5 分钟闭环”项已勾选。
- 断言 `Main.tscn` 资源可加载；readiness 不实例化 Main、不清理 `user://`、不启动试玩、不写报告。

### 2.13 人工试玩 postflight

- 断言试玩后正式报告通过共享 validator 完整核验。
- 断言 postflight 会导出 `mvp_0_2_playtest_report_summary.md`。
- 断言 postflight 只输出事实证据和路径，不自动填写 `manual_result`。
- 通过 fixture 构造完整默认报告，覆盖 postflight 正向摘要导出路径，并在测试结束后清理默认报告。

### 2.14 试玩时长窗口 guard

- 构造 01:59、02:00、05:00、05:01 四个完整报告快照。
- 断言 `elapsed_vs_target_seconds` 的 below/above/within 字段和 `manual_timing_hint` 正确。
- 断言 postflight runner 对 01:59 和 05:01 返回 `TIMING_OUT_OF_TARGET`，但仍只要求人工结论，不自动填写 `manual_result`。

### 2.15 主场景完整报告链路

- 从 `Main.tscn` 驱动 Walk With Mina、Room Helper、Bird Watch、Story Show 和家长摘要阅读。
- 写入默认正式报告 `user://mvp_0_2_playtest_report.json`。
- 调用 postflight runner 校验报告并导出 `user://mvp_0_2_playtest_report_summary.md`。
- 断言摘要包含 `Timing Record Paste`、`Segment Timing Helper` 和空的 `Manual result`。
- 测试结束后清理默认存档、默认报告和默认摘要，避免污染人工试玩起跑线。

### 2.16 一键自动检查入口

- `scripts/dev/run_mvp_0_2_checks.sh` 顺序运行核心 headless 检查。
- 脚本不直接运行需要真实人工报告的 postflight/verify/export 命令。
- 脚本通过 `trap` 在退出前运行人工试玩 preflight，确保默认正式存档、报告和摘要被清理。
- 脚本捕获每条 Godot 命令输出；即使退出码为 0，只要出现 `SCRIPT ERROR`、`ERROR:` 或 `FATAL:` 也会失败。
- 最终 cleanup preflight 复用同一套错误日志扫描，并在 cleanup 内先取消 `trap`，避免失败时递归 cleanup。
- 脚本成功时删除临时日志目录；主体检查或 cleanup preflight 失败时保留日志目录并打印路径。

### 2.17 人工试玩串联入口

- `scripts/dev/run_mvp_0_2_manual_playtest.sh` 串联人工试玩命令顺序：preflight、提示启动外部秒表、启动游戏、游戏关闭后运行 postflight。
- 脚本要求交互终端，非交互环境会拒绝运行，避免跳过外部秒表确认。
- 脚本只导出报告摘要并打印后续文档填写和 final gate 命令，不自动填写计时记录、不自动选择人工结论、不自动勾选验收记录。
- 脚本不在试玩后运行 preflight 清理现场，避免删除本次人工证据。

### 2.18 人工最终 gate

- `mvp_0_2_manual_final_gate.gd` 只在真实人工试玩、postflight 摘要粘贴、计时记录选择唯一人工结果、验收记录状态更新后运行。
- final gate 要求建议记录基础字段已填写，分段计时每个阶段的开始、结束、用时已填写，并明确记录“完成摘要阅读”和“导出计时报告”为“是”。
- final gate 要求 `mvp_0_2_playtest_report_summary.md` 与当前 `mvp_0_2_playtest_report.json` 重新生成的摘要完全一致，避免旧摘要混入。
- 当前 `状态：待人工计时` 时应失败，避免误把自动化通过当成 MVP 完成。
- 通过结果只能证明人工证据已记录且状态一致，不自动替代人工结论。
- `mvp_0_2_manual_final_gate_fixture.gd` 使用内存文本和报告字典覆盖通过、有条件通过、不通过、旧摘要混入失败、待人工计时失败、验收记录不一致失败路径，不写真实文档或默认 `user://` 报告/摘要。
- `mvp_0_2_real_docs_pending_final_gate.gd` 读取当前真实计时记录和验收记录，配合内存报告断言当前真实人工证据和 final gate 规则保持一致，且不写默认 `user://` 报告/摘要。
- `mvp_0_2_restore_recorded_manual_report.gd` 可在自动检查 cleanup 清理默认 `user://` 报告后，按已记录的 2026-05-31 人工证据重建默认报告和摘要，再运行真实 final gate。

## 3. 不适合 Smoke 自动化的内容

以下项目保留人工验收：

- 成人熟练试玩 2-5 分钟体感。
- 真实完整流程是否稳定落在成人熟练 2-5 分钟参考窗口内。
- 儿童阅读压力是否合适。
- 家长是否能在 30 秒内理解摘要。
- 图片素材是否足够美观、统一、适龄。
- 事件完成后的场景变化是否足够明显。

## 4. 失败处理建议

- 场景加载失败：优先修复资源路径、脚本语法、缺失依赖。
- 任务断言失败：检查任务 ID、任务状态流转、奖励重复发放保护。
- 存档断言失败：检查测试存档路径是否被旧数据污染。
- 素材扫描失败：重命名或替换风险素材，不在测试中放宽商业 IP 关键词。
