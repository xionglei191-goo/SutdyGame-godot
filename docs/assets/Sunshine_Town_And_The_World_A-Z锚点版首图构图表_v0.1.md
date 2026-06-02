# Sunshine Town & The World A-Z 锚点版首图构图表 v0.1

> 项目：StudyGame  
> 用途：将世界主图落成可出图、可接入、可分层点击的落位级构图规格  
> 日期：2026-06-01  
> 适用阶段：AI 出图、UI 标注、Godot 热点接入

## 1. 使用说明

本构图表是 [Sunshine_Town_And_The_World_世界地图主图策划_v0.1.md](/home/xionglei/GameProject/SutdyGame-godot/docs/assets/Sunshine_Town_And_The_World_世界地图主图策划_v0.1.md:1) 和 [Sunshine_Town_And_The_World_A-Z字母记忆宫殿策划_v0.1.md](/home/xionglei/GameProject/SutdyGame-godot/docs/assets/Sunshine_Town_And_The_World_A-Z字母记忆宫殿策划_v0.1.md:1) 的执行版补充。

本表只做一件事：把世界主图的地点层和 A-Z 锚点层落成“可直接绘制和可直接做热点”的位置规格。

固定前提：

1. 世界主图作为从 `HomeLayer/home` 打开的 `TownMap/world_overview` 总览底图，子场景继续承接 school_arrival/classroom/garden。
2. 地图形态为 `总览图 + 子场景`。
3. 英文地点标签常显。
4. A-Z 锚点采用固定顺时针路线。
5. 任务进行中优先响应 `place hotspot`，自由探索时优先响应 `anchor hotspot`。
6. runtime 底图、工程对位图、展示审阅图必须明确分离，不混用。
7. 当前主图基线为 `home-first`：玩家从 `HomeLayer/home` 出发进入 `world_overview`，`home` 是开局锚点；A-Z 记忆宫殿的第 1 个字母锚点仍从校园 Apple 开始，不等于产品从学校开始。

命名约束：

1. `school arrival` 是前台/美术/策划层的统一概念名。
2. 运行时 scene id 继续保留 `campus_gate` 作为内部兼容名，直到后续统一改造时再迁移。
3. `music_room` 与 `art_room` 当前属于构图保留位，但在没有 world route / `PlaceCard` 语义前，不应作为总览图可点击热点。
4. `tree / flower / bench / bird` 当前属于 `quest_only` 热点，只在 `g4_u1_garden_bird` 激活时开放点击。

## 2. 首图总布局

### 2.1 画面结构

主图采用 16:9 横版，运行时逻辑画布按 `1280x720` 规划，统一源图真值为 `2560x1440`。

画面分成四层：

1. `home_core`：开局 home 锚点 / home-first origin
2. `school_core`：起步学校区 / school cluster
3. `community_ring`：社区生活环
4. `outskirts_transport`：边缘交通与远郊
5. `global_frame`：四角世界地标边框

### 2.2 视觉主次

主图第一视线应落在 `home + Sunshine School + town road` 起步区；`Sunshine School` 是重要地标，但不是唯一中心。

视觉层级固定为：

1. 第一层：`home`、`Sunshine School` 主体、连接二者的 town road，以及校园钟楼、操场、大门
2. 第二层：图书馆、书店、公园、餐馆、车站、机场
3. 第三层：A-Z 中型装置与场景道具
4. 第四层：世界地标边框插图

### 2.3 强锚点名单

首版强视觉锚点固定为：

- `A`
- `C`
- `E`
- `G`
- `K`
- `L`
- `S`
- `T`
- `W`
- `U`

这些锚点必须在主图第一眼就能被找到。

## 3. 地点主布局

### 3.1 主导航地点表

| place_id | zone | display_label | world_position_desc | visual_weight | default_visible_label | scene_role | child_scene_link | hotspot_type |
|---|---|---|---|---|---|---|---|---|
| home | home_core | home | 地图左侧开局家园，与 Sunshine School 通过主路相连，是玩家从 HomeLayer 进入 world_overview 后的心理出发点 | landmark | true | navigation | home | place hotspot |
| sunshine_school | school_core | Sunshine School | 正中央最大校园主体，主区向玩家打开，内部容纳功能室和操场，并与 home + school 起步路径衔接 | landmark | true | navigation | campus_gate | place hotspot |
| classroom | school_core | classroom | 校园主体左上侧教学楼区域 | major_prop | true | quest_target | classroom | place hotspot |
| library | school_core | library | 校园主体右上侧图书馆楼 | landmark | true | navigation | classroom | place hotspot |
| canteen | school_core | canteen | 校园主体左中部，靠近教学楼与功能室之间 | major_prop | true | navigation | "" | place hotspot |
| art_room | school_core | art room | 校园左下侧活动教室，靠近 canteen 下方 | major_prop | true | navigation | "" | place hotspot |
| music_room | school_core | music room | 校园中下侧活动教室，靠近苹果广场右下方 | major_prop | true | navigation | "" | place hotspot |
| playground | school_core | playground | 校园右下侧，完全收束在学校围墙内部 | landmark | true | quest_target | campus_gate | place hotspot |
| post_office | community_ring | post office | 社区左侧主路旁，连接学校和商业街 | major_prop | true | navigation | "" | place hotspot |
| hospital | community_ring | hospital | 社区右侧主路旁，靠近十字路口 | major_prop | true | navigation | "" | place hotspot |
| supermarket | community_ring | supermarket | 左下更外圈商业区，位于 bus station 下方 | major_prop | true | navigation | "" | place hotspot |
| pet_shop | community_ring | pet shop | supermarket 右侧的宠物用品店，与 home pet care 消费回流绑定 | major_prop | true | navigation | "" | place hotspot |
| bookshop | community_ring | bookshop | 社区左上阅读街区，与 library 视觉呼应 | landmark | true | navigation | "" | place hotspot |
| restaurant | community_ring | restaurant | 社区下方偏右餐饮街 | major_prop | true | navigation | "" | place hotspot |
| park | community_ring | park | 社区中下方开阔绿地 | landmark | true | navigation | garden | place hotspot |
| cinema | community_ring | cinema | 社区右下娱乐街区 | major_prop | true | navigation | "" | place hotspot |
| bus_station | outskirts_transport | bus station | 左侧主路边交通节点，紧贴 home + school 起步区外出的主路 | major_prop | true | navigation | "" | place hotspot |
| railway_station | outskirts_transport | railway station | 画面下方偏中到右的主交通枢纽 | landmark | true | navigation | "" | place hotspot |
| airport | outskirts_transport | airport | 画面右上到右侧外圈出口 | landmark | true | navigation | "" | place hotspot |

### 3.2 旧课程兼容地点

以下旧目标即使未来主要存在于子场景，也必须在总览规格中保留映射去向：

| target_id | zone | world_position_desc | child_scene_link | hotspot_type | 说明 |
|---|---|---|---|---|---|
| classroom | school_core | 校园左上教学楼 | classroom | place hotspot | 运行时兼容 ID：`g4_u1_school_tour` |
| library | school_core | 校园右上图书馆 | classroom | place hotspot | 运行时兼容 ID：`g4_u1_school_tour` |
| playground | school_core | 学校主区内部操场 | campus_gate | place hotspot | 运行时兼容 ID：`g4_u1_school_tour` |
| tree | community_ring | 公园或花园树区 | garden | place hotspot | 运行时兼容 ID：`g4_u1_garden_bird` |
| flower | community_ring | 公园或花园花坛 | garden | place hotspot | 运行时兼容 ID：`g4_u1_garden_bird` |
| bench | community_ring | 公园长椅区 | garden | place hotspot | 运行时兼容 ID：`g4_u1_garden_bird` |
| bird | community_ring | 花园大树上方或近树枝区域 | garden | place hotspot | 运行时兼容 ID：`g4_u1_garden_bird` |

## 4. A-Z 锚点布局

### 4.1 字段说明

每个锚点条目必须包含：

- `zone`
- `route_order`
- `anchor_id`
- `letter`
- `keyword`
- `display_label`
- `world_position_desc`
- `visual_weight`
- `default_visible_label`
- `paired_place_id`
- `scene_role`
- `child_scene_link`
- `hotspot_type`

### 4.2 顺时针锚点表

说明：

1. 原始口述路线中遗漏了 `R`。
2. 本执行版已补齐 `R = Robot`，并将其固定在校园科技区。
3. 从本表开始，以补齐后的 26 字母路线为唯一执行真相。
4. 运行时使用无标注底图；本表对应的标注信息仅用于工程对位、教学参考和展示审阅。

| zone | route_order | anchor_id | letter | keyword | display_label | world_position_desc | visual_weight | default_visible_label | paired_place_id | scene_role | child_scene_link | hotspot_type |
|---|---:|---|---|---|---|---|---|---|---|---|---|---|
| school_core | 1 | anchor_a_apple | A | Apple | Apple | 校园中心广场，主楼前的巨型红苹果雕塑，位于 home + school 起步路径进入校园后的首个强记忆点 | landmark | false | sunshine_school | memory | campus_gate | anchor hotspot |
| school_core | 2 | anchor_c_clock | C | Clock | Clock | 主教学楼中央钟楼，作为校园最高识别点 | landmark | true | sunshine_school | navigation | campus_gate | anchor hotspot |
| school_core | 3 | anchor_d_dog | D | Dog | Dog | 学校主区入口附近迎宾小狗吉祥物 | major_prop | false | sunshine_school | memory | campus_gate | anchor hotspot |
| school_core | 4 | anchor_e_elephant | E | Elephant | Elephant | playground 左侧的大象滑梯 | landmark | true | playground | quest_target | campus_gate | anchor hotspot |
| school_core | 5 | anchor_k_kite | K | Kite | Kite | 校园和社区交界上空的发光风筝 | landmark | false | playground | memory | campus_gate | anchor hotspot |
| school_core | 6 | anchor_r_robot | R | Robot | Robot | computer room 外侧的机器人信息牌 | major_prop | false | sunshine_school | memory | classroom | anchor hotspot |
| community_ring | 7 | anchor_b_bear | B | Bear | Bear | bookshop 门口的读书熊长椅 | major_prop | false | bookshop | memory | "" | anchor hotspot |
| community_ring | 8 | anchor_l_lion | L | Lion | Lion | 书店广场中央的狮子喷泉 | landmark | true | bookshop | navigation | "" | anchor hotspot |
| community_ring | 9 | anchor_f_fox | F | Fox | Fox | 公园与花园过渡带的狐狸灌木雕塑 | major_prop | false | park | decoration_with_interaction | garden | anchor hotspot |
| community_ring | 10 | anchor_g_gate | G | Gate | Gate | 社区主入口拱门，连接校园外环道路 | landmark | true | post_office | navigation | "" | anchor hotspot |
| community_ring | 11 | anchor_h_hat | H | Hat | Hat | 十字路口商铺区上方的巨型帽子招牌 | major_prop | false | supermarket | decoration_with_interaction | "" | anchor hotspot |
| community_ring | 12 | anchor_i_ice_cream | I | Ice cream | Ice cream | 公园边街角的冰淇淋推车 | major_prop | false | park | memory | garden | anchor hotspot |
| community_ring | 13 | anchor_j_jacket | J | Jacket | Jacket | clothes shop 橱窗中的跳跃夹克 | minor_prop | false | supermarket | decoration_with_interaction | "" | anchor hotspot |
| community_ring | 14 | anchor_m_monkey | M | Monkey | Monkey | 公园主树树冠中的猴子装置 | major_prop | false | park | memory | garden | anchor hotspot |
| community_ring | 15 | anchor_o_orange | O | Orange | Orange | restaurant 外侧的橙汁摊位 | major_prop | false | restaurant | memory | "" | anchor hotspot |
| community_ring | 16 | anchor_p_panda | P | Panda | Panda | 茶点区和书店之间的熊猫雕像 | major_prop | false | bookshop | decoration_with_interaction | "" | anchor hotspot |
| community_ring | 17 | anchor_q_queen | Q | Queen | Queen | theatre 前方女王立牌或海报雕塑 | major_prop | false | cinema | memory | "" | anchor hotspot |
| community_ring | 18 | anchor_v_violin | V | Violin | Violin | theatre 侧边发光小提琴雕塑 | major_prop | false | cinema | decoration_with_interaction | "" | anchor hotspot |
| outskirts_transport | 19 | anchor_n_net | N | Net | Net | 泳池或运动区边缘的大网装置 | minor_prop | false | park | decoration_with_interaction | garden | anchor hotspot |
| outskirts_transport | 20 | anchor_s_sun | S | Sun | Sun | City Park 上空的太阳天气转盘 | landmark | true | park | navigation | garden | anchor hotspot |
| outskirts_transport | 21 | anchor_t_taxi | T | Taxi | Taxi | bus station 与主路交界的黄色出租车 | landmark | true | bus_station | navigation | "" | anchor hotspot |
| outskirts_transport | 22 | anchor_w_watch | W | Watch | Watch | railway station 主立面上的巨型手表钟 | landmark | true | railway_station | navigation | "" | anchor hotspot |
| outskirts_transport | 23 | anchor_x_x_mark_box | X | X-mark Box | X-mark Box | airport 货运区的巨大 X 宝箱 | major_prop | false | airport | memory | "" | anchor hotspot |
| outskirts_transport | 24 | anchor_u_umbrella | U | Umbrella | Umbrella | 海边或广场边缘的巨型彩虹伞 | landmark | true | airport | memory | "" | anchor hotspot |
| outskirts_transport | 25 | anchor_z_zebra | Z | Zebra | Zebra | zoo 边缘或斑马线旁的斑马雕塑 | major_prop | false | park | decoration_with_interaction | garden | anchor hotspot |
| school_core | 26 | anchor_y_yo_yo | Y | Yo-yo | Yo-yo | 校园活动角悬挂的溜溜球装置 | minor_prop | false | sunshine_school | memory | campus_gate | anchor hotspot |

### 4.3 终点回环

第 27 步不是新锚点，而是“回到 `home + Sunshine School` 起步层”。

作用：

1. 让整条路线闭环。
2. 保持 A-Z 字母路线与玩家生活路线相接：从 home 出发，进入校园 Apple，再经小镇和交通区回到 home + school 起步层。
3. 让总览图探索始终回到孩子最熟悉的生活起点，而不是把学校误读成整个产品的唯一中心。

## 5. 标签显示规则

### 5.1 地点标签

默认常显：

- Sunshine School
- classroom
- library
- playground
- canteen
- post office
- hospital
- supermarket
- bookshop
- restaurant
- park
- cinema
- bus station
- railway station
- airport

### 5.2 A-Z 标签

默认不常显全部 A-Z 标签。

只允许以下锚点在主图上常显或半常显英文名：

- Clock
- Elephant
- Gate
- Lion
- Sun
- Taxi
- Watch

其余锚点通过以下方式显示：

1. 点击后显示
2. 悬停后显示
3. 标注版主图中显示

## 6. 热点兼容规则

### 6.1 双热点规则

同一区域允许同时存在：

1. `place hotspot`
2. `anchor hotspot`

例如：

- `library`
- `anchor_b_bear`

### 6.2 响应优先级

固定规则：

1. 任务进行中：`place hotspot` 优先
2. 自由探索时：`anchor hotspot` 优先
3. 若两个热点区域高度重叠，可通过点击后弹出二级选择卡处理

### 6.3 子场景链接

首版固定支持的 `child_scene_link`：

- `campus_gate`（学校到达区 / school arrival hub）
- `classroom`
- `garden`

后续可扩展，但本版不新增更多子场景标识。

## 7. 构图验收标准

1. 第一眼必须看清 `home + Sunshine School + town road` 的起步关系，且 `Sunshine School` 作为重要地标清楚可辨。
2. A-Z 全部有落位，但视觉强度分层明确。
3. 主要英文地点标签清楚可读，不像词汇海报。
4. 世界地标只在边框层，不与主城道路混排。
5. 现有课程目标 `classroom/library/playground/tree/flower/bench/bird` 都有总览图映射去向。
