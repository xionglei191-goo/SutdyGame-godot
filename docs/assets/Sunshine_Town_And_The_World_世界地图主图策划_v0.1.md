# Sunshine Town & The World 世界地图主图策划 v0.1

> 项目：StudyGame  
> 用途：指导儿童英语生活冒险世界地图主图的美术生成、交互承载和后续生活事件、委托、地点探索与世界扩展  
> 日期：2026-06-01  
> 适用阶段：主图概念设计、AI 出图、地图交互规划、后续版本扩展

## 1. 目标

`Sunshine Town & The World` 是 StudyGame 的世界地图主图方案。它不是一张单纯的装饰海报，而是同时承担以下职责：

1. 作为从 `HomeLayer/home` 打开的 `world_overview` 主地图核心视觉。
2. 作为小学英语高频生活场景和地点词汇的空间总览。
3. 作为后续章节、任务、地点探索和世界拓展内容的统一容器。
4. 作为“从家出发，经过学校与小镇，再走向城市与世界”的学习路径可视化表达。

这张图必须同时满足三类要求：

1. 儿童第一眼能看懂，知道中心在哪里、能去哪些地方。
2. 美术上明亮、友好、适龄，具备可长期使用的品牌感。
3. 工程上可拆分、可点击、可做热点区域，不是一张无法交互的大海报。

运行时边界补充：

1. 当前 runtime 使用 `map_sunshine_world_overview_v001.png` 作为 `world_overview` 底图。
2. `map_sunshine_world_az_label_v001.png` 只用于工程对位、热点校验和教学审阅，不接 runtime。
3. `map_sunshine_world_az_label_showcase_v001.png` 只用于展示审阅，不接 runtime。
4. 当前主图交互不只承载地点点击，还必须兼容：
   - non-school `PlaceCard`
   - `supermarket -> pet bowl -> home`
   - `pet_shop -> pet ball -> home play feedback`
   - full A-Z `Memory Spark`

## 2. 核心设计判断

### 2.1 核心主题

地图主题为：`从 Sunshine Town 的 home + school + town road 起步区出发，先认识家、宠物、学校和小镇日常，再走向社区，并把视野延伸到世界。`

这符合儿童生活探索与英语递进的自然路径：

1. 先学家、宠物、学校生活和身边物品。
2. 再学社区公共设施、购物和日常活动。
3. 再学交通、城市功能和远距离出行。
4. 最后接触国家、世界地标和跨文化表达。

### 2.2 起步视觉中心

主图必须有一个明确起步中心：`home + Sunshine School + town road`。

原因：

1. 对小学生来说，home 是最自然的出发点，school 是最熟悉的生活枢纽之一，二者必须同时构成第一眼的生活冒险起点。
2. school 可以天然承载大量教材高频词汇，但 `classroom`、`library`、`playground`、`canteen`、`music room`、`art room` 应收束在校园内部，不再散成独立小镇地标。
3. town road 要把 home、school、shops 和 transport 串起来，避免世界地图变成孤立建筑拼贴。
4. 从 `home + school + town road` 的起步层向外一圈圈扩展，更符合当前产品的儿童生活冒险路径。

当前基线硬规则：

1. `home` 是开局锚点和心理出发点，不应被归为普通社区建筑。
2. `Sunshine School` 是重要地标和教材高频场景承载区，但不是首屏唯一中心，也不是产品外层体验的全部脸面。
3. A-Z 记忆宫殿的第 1 个字母锚点 `Apple` 固定在校园广场，这是字母路线规则；玩家生活路线仍然从 home 出发。

### 2.3 主图定位

这张图应被定义为：`可玩的世界地图主图`，而不是 `词汇总表海报`。

因此需要遵守以下原则：

1. 主图优先保证视觉层次和可点击性。
2. 英文标签必须受控，不能把所有词一次性写满。
3. 不同层级内容要有主次，完整版点位可以通过后续缩放、弹出卡片、小地图或章节解锁承载。

## 3. 用户与使用场景

### 3.1 目标用户

- 7-12 岁小学生
- 以小学英语学习为主
- 对“地图探索”“地点点击”“收集反馈”有较强接受度

### 3.2 家长和教师视角

家长和教师需要能一眼看出：

1. 游戏内容和英语学习有关。
2. 画面是安全、积极、适龄的。
3. 地图中的地点、设施和世界元素具有明确教学价值。

### 3.3 使用场景

这张主图可用于：

1. 从家进入后的世界总览 / 主地图界面。
2. 主线世界地图界面。
3. 章节入口地图。
4. 点位点击导航界面。
5. 宣传图或内容展示图的基础版式。

## 4. 世界观设定

### 4.1 地图名称

英文名称：`Sunshine Town & The World`  
中文名称：`阳光小镇与世界`

### 4.2 世界观描述

在这个世界里，孩子每天从 `home + Sunshine School` 的起步区出发，先进入学校到达区与校园核心，再穿过 `Sunshine Community`，去公园、书店、医院、剧院、车站和机场，也会通过地图边缘的相册、地球仪和方向牌了解更远的国家与世界名胜。

地图不追求真实城市比例，而采用儿童友好的“主题地图”结构：

1. 中心区域更大、更详细。
2. 常用生活地点围绕中心分布。
3. 远郊和交通枢纽布置在边缘。
4. 世界地标以边框插图或角落信息窗形式出现。

## 5. 设计目标

### 5.1 教学目标

支持以下英语内容长期承载：

1. 学校场景词汇。
2. 社区公共设施词汇。
3. 购物、餐饮、娱乐和公共服务词汇。
4. 交通与问路词汇。
5. 城市边缘与自然场景词汇。
6. 国家与世界地标相关表达。

### 5.2 体验目标

孩子在看到地图时应获得以下感受：

1. 这是一个丰富但不混乱的英语世界。
2. 我知道从哪里开始探索。
3. 我愿意点击建筑或区域继续玩。
4. 我能慢慢从校园走到更大的世界。

### 5.3 工程目标

这张图应支持后续：

1. 热点点击。
2. 区域锁定和解锁。
3. 任务气泡和进度标记。
4. 昼夜、节日或章节状态变化。
5. 分层导出和局部替换。

## 6. 地图总布局

地图采用四层结构。

### 6.1 第一层：home + school + town road 起步区

位置：画面正中央  
主题：`home + Sunshine School + town road`

核心定位：

1. 作为从 `HomeLayer` 打开世界总览后的第一理解区域。
2. 让 home 成为默认心理起点，school 成为相邻关键区域，town road 负责连接后续小镇探索。
3. 承载 Welcome Box、First Trip、Walk With Mina、宠物照顾、商店回流和早期 A-Z 锚点的共同起步关系。

### 6.2 第二层：社区环绕区

位置：校园四周，形成一个可步行到达的生活圈  
主题：`Sunshine Community`

核心定位：

1. 承载日常购物、公共服务、娱乐休闲和生活交往场景。
2. 形成孩子“放学后的小镇世界”。
3. 为问路、购物、职业、规则、时间安排等内容提供场景基础。

### 6.3 第三层：城市边缘区

位置：主图的边缘地带  
主题：`City Outskirts & Transport Hubs`

核心定位：

1. 表达“需要乘车或专门安排才能去的地方”。
2. 承载博物馆、自然场景、工厂、站点和机场等扩展内容。
3. 为更高年级的旅行、调查、比较、公共行动等内容留出空间。

### 6.4 第四层：世界边框区

位置：地图四周角落或边框插图区域  
主题：`Global Landmarks`

核心定位：

1. 表达“更远的世界”。
2. 避免把不在同一个城市的地标硬塞进主地图道路系统。
3. 为世界认知、国家文化和毕业旅行主题做视觉铺垫。

## 7. 分区详细策划

### 7.1 起步区：home + Sunshine School + town road

建议把起步区画成 home、校园入口、校园核心设施和主路相邻的生活冒险起点。`Sunshine School` 是重要 school cluster，但不是整张图唯一中心。

应包含的起步地点：

| 分组 | 英文 | 中文 | 重要级 |
|---|---|---|---|
| 家与出发 | home | 家 | P0 |
| 路线连接 | town road | 小镇主路 | P0 |
| 路线连接 | crossing | 路口 / 斑马线 | P1 |
| 宠物与生活 | pet corner / yard | 宠物角 / 院子 | P1 |

布局建议：

1. home 要能一眼看出是孩子的出发点，并能自然通向 school 和 town road。
2. town road 要把 home、school、shops 和 transport 串起来，避免地点像孤立贴纸。
3. school cluster 应贴近起步区，但不要压过 home 和主路关系。
4. 起步区应给 Welcome Box、First Trip、Home Pet Care 和早期 A-Z 锚点留出清晰热点空间。

### 7.2 school cluster：Sunshine School

建议把 `Sunshine School` 画成一座完整、温暖、清晰可辨认的小学校园。

应包含的核心地点：

| 分组 | 英文 | 中文 | 重要级 |
|---|---|---|---|
| 主体建筑 | classroom | 教室 | P0 |
| 主体建筑 | teachers' office | 教师办公室 | P1 |
| 功能室 | library | 图书馆 | P0 |
| 功能室 | reading room | 阅览室 | P1 |
| 功能室 | music room | 音乐室 | P1 |
| 功能室 | art room | 美术室 | P1 |
| 功能室 | computer room | 电脑室 | P1 |
| 户外区域 | playground | 操场 | P0 |
| 生活区域 | canteen / dining hall | 食堂 / 餐厅 | P0 |

布局建议：

1. 学校主区应向玩家打开，入口可读，但不把校门或到校入口设计成唯一第一落点。
2. `playground` 放在视觉上较开阔的一侧，形成透气区域。
3. `library`、`music room`、`art room` 等功能室不必全部做成独立大楼，可通过带识别性的附属建筑或分区牌表示。
4. 校园内部道路要比社区道路更整洁、更安全，体现儿童活动核心区。

交互建议：

1. 打开 `world_overview` 后，school 核心区属于首批可见和可进入区域。
2. 适合放置起步事件、`Walk With Mina`、学校生活互动和收集入口。
3. 可通过点击建筑进入生活事件、伙伴互动、PlaceCard 或 Memory Spark；避免把学校建筑做成课堂入口列表。

### 7.3 第二层：Sunshine Community

社区层是主图的主体扩展圈，要营造“学校旁边的生活小镇”。

建议通过街道、路口、斑马线、红绿灯、公交站牌、树木和街区招牌把各个地点组织起来。

#### 7.2.1 公共服务区

| 英文 | 中文 | 重要级 | 建议用途 |
|---|---|---|---|
| post office | 邮局 | P0 | 寄信、路线、通知单 |
| hospital | 医院 | P0 | 健康、建议、症状 |
| bank | 银行 | P2 | 城市认知、职业延展 |
| police station | 警察局 | P1 | 安全、规则、问路 |

建议：

1. `post office` 和 `hospital` 优先进入主图第一版。
2. `bank` 可作为次级点位，不必在第一版做大。
3. `police station` 适合靠近十字路口或主干道。

#### 7.2.2 生活购物区

| 英文 | 中文 | 重要级 | 建议用途 |
|---|---|---|---|
| supermarket | 超市 | P0 | 购物、数量、食物 |
| shopping centre / mall | 购物中心 | P1 | 城市场景扩展 |
| clothes shop | 服装店 | P1 | 穿搭、颜色、大小 |
| bookstore / bookshop | 书店 | P0 | 阅读、选书、故事 |
| meat shop | 肉店 | P2 | 食材延展 |
| pet shop | 宠物店 | P1 | 宠物照顾、描述 |

建议：

1. `supermarket`、`bookshop`、`pet shop` 是儿童感知最强的一组。
2. `shopping centre` 可以画成较大的综合建筑，用于城市热闹感，不必承担太多独立标签。
3. `meat shop` 在儿童主图中不宜过于突出，可缩小处理。

#### 7.2.3 餐饮住宿区

| 英文 | 中文 | 重要级 | 建议用途 |
|---|---|---|---|
| restaurant | 餐馆 | P0 | 点餐、礼貌表达 |
| cafe | 咖啡馆 | P1 | 社交、小镇氛围 |
| tea house / teahouse | 茶馆 | P2 | 地域文化延展 |
| hotel | 宾馆 | P1 | 问路、接待 |
| B&B hotel | 民宿 | P2 | 旅行拓展 |

建议：

1. `restaurant` 和 `hotel` 更适合作为高频学习点位。
2. `cafe` 可以做氛围建筑，增加小镇精致感。
3. `teahouse` 和 `B&B hotel` 放到扩展版，不强行塞进首版主图核心标签。

#### 7.2.4 休闲娱乐区

| 英文 | 中文 | 重要级 | 建议用途 |
|---|---|---|---|
| cinema | 电影院 | P0 | 娱乐选择、时间安排 |
| drive-in cinema | 汽车影院 | P2 | 趣味扩展 |
| theatre | 剧院 | P1 | 演出、电话约定 |
| concert hall | 音乐厅 | P2 | 音乐主题 |
| City Park | 城市公园 | P0 | 户外活动、规则 |
| swimming pool / area | 游泳池 / 游泳区 | P1 | 运动、夏季活动 |

建议：

1. `park` 要作为社区呼吸空间，避免地图满屏建筑。
2. `cinema` 和 `theatre` 是很好的章节入口点位。
3. `drive-in cinema` 更适合做趣味彩蛋，不建议占主版面。

### 7.4 第三层：City Outskirts & Transport Hubs

城市边缘区要明显和中心区拉开节奏。这里不需要太密，重点是表达“远一点”“更大一点”“需要出发”。

#### 7.3.1 自然与户外

| 英文 | 中文 | 重要级 | 建议用途 |
|---|---|---|---|
| beach | 海滩 | P1 | 假期、天气、旅行 |
| wetland park | 湿地公园 | P2 | 环保、观察 |
| safari park | 野生动物园 | P2 | 动物词汇扩展 |
| zoo | 动物园 | P1 | 动物、比较级 |

建议：

1. 海滩可放在地图一侧边缘，形成视觉变化。
2. `zoo` 比 `safari park` 更适合小学英语常规教学优先级。
3. `wetland park` 适合后期加入“环保行动”路线。

#### 7.3.2 大型展馆

| 英文 | 中文 | 重要级 | 建议用途 |
|---|---|---|---|
| history museum | 历史博物馆 | P1 | 调查、参观 |
| space museum | 太空博物馆 | P1 | 地球、太空、科学 |
| City Museum | 城市博物馆 | P1 | 城市文化、路线 |
| Hunan Museum | 湖南博物院 | P2 | 地域拓展 |

建议：

1. 第一版保留 1-2 个代表性博物馆即可。
2. `space museum` 非常适合和高年级地球、世界、太空主题联动。
3. `Hunan Museum` 更像地方特定内容，适合做地区化版本，不建议默认强绑定在通用版主图里。

#### 7.3.3 工业与交通枢纽

| 英文 | 中文 | 重要级 | 建议用途 |
|---|---|---|---|
| food factory | 食品工厂 | P2 | 生产流程、食物来源 |
| carpark | 停车场 | P2 | 城市配套 |
| bus station | 汽车站 | P0 | 出行、交通 |
| railway station | 火车站 | P0 | 旅行、路线、城市连接 |
| airport | 机场 | P0 | 世界连接、旅行 |
| port | 港口 | P1 | 国际连接、货运概念 |

建议：

1. `bus station`、`railway station`、`airport` 是第三层的主干点位。
2. `airport` 要成为“通往世界”的视觉出口。
3. `port` 可以放在水边，与海滩或海岸一侧呼应。
4. `food factory` 和 `carpark` 作为补充认知点位，放在边角，不做主视觉抢夺。

### 7.5 第四层：Global Landmarks

世界地标不应被处理成“同一城市里并列出现的建筑”，而应以边框插图、旅行相册、地球仪标签或方向指示牌呈现。

推荐结构：

1. 左上角：中国
2. 右上角：英国 / 法国
3. 左下角：美国
4. 右下角：澳大利亚

推荐点位：

| 国家 / 地区 | 英文 | 中文 | 重要级 |
|---|---|---|---|
| China | The Great Wall | 长城 | P0 |
| China | Tian'anmen Square | 天安门广场 | P1 |
| China | The Palace Museum | 故宫博物院 | P1 |
| China | Beihai Park | 北海公园 | P2 |
| The UK | Big Ben | 大本钟 | P0 |
| The UK | Buckingham Palace | 白金汉宫 | P1 |
| The USA | The Golden Gate Bridge | 金门大桥 | P0 |
| The USA | Broadway | 百老汇 | P1 |
| France | The Eiffel Tower | 埃菲尔铁塔 | P0 |
| Australia | Sydney Opera House | 悉尼歌剧院 | P0 |

使用建议：

1. 每个国家优先保留一个最强识别物。
2. 地标更适合作为“远方象征”和毕业旅行内容预告。
3. 不建议在主版面同时写出过多国家说明文字，避免抢占阅读注意力。

## 8. 首版主图建议收敛范围

虽然完整版策划允许大量地点存在，但首版主图必须做减法。

### 8.1 第一版必须出现的点位

| 层级 | 点位 |
|---|---|
| 校园核心 | Sunshine School、classroom、library、playground、canteen |
| 社区核心 | post office、hospital、supermarket、bookshop、restaurant、park、cinema |
| 城市边缘 | bus station、railway station、airport |
| 世界边框 | The Great Wall、Big Ben、The Eiffel Tower、The Golden Gate Bridge、Sydney Opera House |

### 8.2 第一版可弱化但预留位置的点位

- teachers' office
- reading room
- music room
- art room
- computer room
- police station
- clothes shop
- pet shop
- theatre
- swimming pool
- zoo
- space museum
- port

### 8.3 第一版建议暂不强调的点位

- bank
- meat shop
- tea house
- B&B hotel
- drive-in cinema
- concert hall
- wetland park
- safari park
- food factory
- carpark
- Hunan Museum

这些点位不是不能做，而是不应抢占世界总览主图的首次理解成本。

## 9. 视觉与美术方向

### 9.1 总体风格

建议采用：

- 儿童绘本感
- 明亮、梦幻但干净
- 原创 toy-town / magical school 风
- 2D 俯视角或 2.5D 等距地图
- 建筑轮廓清晰
- 色彩丰富但不过载

### 9.2 视觉关键词

英文关键词：

- bright
- child-friendly
- storybook town
- home-school-town starting map
- pastel but balanced
- clean shapes
- playful streets
- warm educational adventure

中文关键词：

- 明亮
- 温暖
- 童趣
- 适龄
- 清晰
- 轻梦幻
- 玩具小镇感
- 可探索地图

### 9.3 颜色控制

建议：

1. 校园区使用更温暖、更明亮的综合色。
2. 社区区用多色建筑区分功能，但保持统一饱和度。
3. 边缘区可加入海蓝、草绿、沙色，制造空间变化。
4. 世界边框地标要更像插画邮票或旅行贴纸，而不是写实建筑摄影。

限制：

1. 不要整屏只有粉色。
2. 不要荧光高饱和配色。
3. 不要过暗、过密、过成人化。
4. 不要加入真实品牌 Logo。

### 9.4 构图要求

1. 起步区必须一眼看出 home、Sunshine School 和 town road 的关系。
2. 道路必须能把家、校园、社区和交通入口自然连接起来。
3. 建筑之间要有呼吸空间，不能铺满。
4. 远郊区要明显更稀疏，体现层次变化。
5. 世界地标边框必须和主地图主体分层，避免误解成同城建筑。

## 10. 标签与文本策略

### 10.1 主图标签原则

主图不是词汇表，因此标签要分层：

1. 一级标签：只给关键建筑和区域。
2. 二级标签：通过点击后浮层显示。
3. 三级信息：进入事件或互动后自然出现英语表达；词汇和句型归入内部内容层与家长摘要。

### 10.2 文本控制建议

首图画面上同时可见的英文标签建议控制在 `10-16` 个以内。

推荐直接显示：

- Sunshine School
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

世界地标名称可缩写处理或进入边框卡片后展示。

### 10.3 标题建议

主标题：

`Sunshine Town & The World`

副标题可选：

- Learn, Explore, Travel
- From Home to Town and the World
- Explore English in Sunshine Town

如果主图用于游戏内主地图页面，副标题可以省略。

## 11. 交互承载设计

### 11.1 点击层建议

地图应拆为以下可交互层：

1. 背景底图层。
2. 道路与装饰层。
3. 建筑热点层。
4. 任务标记层。
5. UI 覆盖层。

### 11.2 热点设计建议

每个地点应至少支持一种后续用途：

| 点位类型 | 可承载行为 |
|---|---|
| 校园建筑 | 进入故事事件、伙伴互动、Quest Diary 入口；A-Z 锚点可触发 Memory Spark |
| 社区建筑 | PlaceCard、剧情对话、问路、购物委托、A-Z Memory Spark 回访 |
| 交通枢纽 | 地图切换、旅行事件、城镇委托 |
| 世界边框地标 | 收藏卡、文化卡、毕业旅行内容 |

### 11.3 状态变化建议

后续版本中，同一地图应支持：

1. 未解锁状态：灰化、云雾或锁标。
2. 可进入状态：柔和发光或小旗帜。
3. 任务中状态：气泡、箭头、角色头像。
4. 已完成状态：星片、贴纸、奖章或花环装饰。

## 12. 与英语内容的对应关系

### 12.1 低年级优先内容

适合优先绑定到校园和社区：

- classroom
- library
- playground
- canteen
- supermarket
- hospital
- restaurant
- park
- bookshop

### 12.2 中年级扩展内容

适合绑定到社区与城市边缘：

- post office
- cinema
- theatre
- zoo
- hotel
- railway station
- bus station

### 12.3 高年级世界内容

适合绑定到边缘区和地标边框：

- airport
- museum
- space museum
- The Great Wall
- Big Ben
- The Eiffel Tower
- Sydney Opera House

### 12.4 与现有关卡内容的兼容方向

这张地图与 [小学英语故事线与关卡内容设计.md](/home/xionglei/GameProject/SutdyGame-godot/docs/product/小学英语故事线与关卡内容设计.md:1) 兼容性较高，尤其适合承接：

1. Walk With Mina：陪 Mina 到达 story stop，认识 school-side welcome 区与伙伴路线。
2. 购物、问路、点餐、健康建议、公共设施类任务。
3. 博物馆、天气、旅行、世界名胜分享类任务。

## 13. 资产拆分建议

### 13.1 推荐资产结构

建议不要只生成一张不可拆的大图，而是至少规划两种资产：

1. `世界地图总览主图（运行时底图）`
2. `局部区域裁切图`
3. `工程/参考标注图`

推荐拆分：

- 学校核心区裁切图
- 社区环绕区裁切图
- 城市边缘区裁切图
- 世界地标边框插图组

### 13.2 文件命名建议

```text
map_sunshine_world_overview_v001.png
map_sunshine_school_core_v001.png
map_sunshine_community_ring_v001.png
map_sunshine_outskirts_transport_v001.png
map_global_landmarks_frame_v001.png
```

如果后续有点击热点数据：

```text
map_sunshine_world_hotspots_v001.json
```

### 13.3 分辨率建议

用于主图生成的底稿建议至少准备：

- 运行时基准：`1280x720`
- 主图源图真值：`2560x1440`
- 如需额外宣传或后续裁切，可在 `2560x1440` 基础上继续上采样留档

运行时底图、展示图和工程/参考标注图都应从同一张 `2560x1440` 源图导出。如果后续要做镜头缩放和局部裁切，建议始终从该源图出发。

## 14. AI 出图执行建议

### 14.1 出图目标

第一轮不要求一步到位把所有细节画全，而是优先验证：

1. home + Sunshine School + town road 起步关系是否足够清楚。
2. 社区圈层是否清楚。
3. 城市边缘和世界边框是否层次明确。
4. 整体是否适合儿童英语游戏。

### 14.2 提示词方向

主图提示词应强调：

1. home-school-town starting world map
2. child-friendly English learning town
3. illustrated storybook style
4. clear labeled zones
5. layered map composition

同时避免：

1. 真实航拍城市风格
2. 信息图表式死板布局
3. 过度写实建筑贴图
4. 成人旅游海报质感

### 14.3 出图轮次建议

第一轮：

- 只验证整体布局和风格。

第二轮：

- 强化校园核心和社区点位识别。

第三轮：

- 增加文字标签、安全留白、交互热点预留。

## 15. Godot 接入建议

### 15.1 实现方式

Godot 内推荐两种路径：

1. 先作为静态背景图接入，再叠加可点击热点。
2. 主图拆成多区域贴图，再通过节点组合与镜头控制承载交互。

### 15.2 推荐最小实现

首版可采用：

1. 一张总览主图背景。
2. 若干 `Area2D` 热点覆盖在学校、社区、交通和世界边框位置。
3. 点击后弹出 PlaceCard、伙伴事件、Memory Spark 或旅行入口。

### 15.3 后续扩展

后续可升级为：

1. 缩放地图。
2. 拖拽漫游。
3. 地点解锁动画。
4. 基于任务状态切换图层装饰。

## 16. 风险与控制

### 16.1 最大风险

最大风险不是画不出来，而是“试图把全部地点一次性画进世界总览主图”。

这样会直接导致：

1. 信息过载。
2. 视觉中心丢失。
3. 标签拥挤。
4. 后续交互热点难做。

### 16.2 控制原则

1. 首版只保证核心区和高频点位完整。
2. 次级点位通过局部扩展和二级信息承载。
3. 世界地标必须和主地图主体分层。
4. 地图优先服务探索和任务，不优先服务地点罗列。

## 17. 结论

`Sunshine Town & The World` 适合作为 StudyGame 的世界地图主图方案。

它的优势在于：

1. 以 `home + school + town road` 起步区作为入口，并向社区、交通和世界扩展。
2. 以社区和城市边缘扩展，承接大量教材高频地点词汇。
3. 以世界地标作边框延伸，能自然引出更高阶的世界主题。
4. 在视觉、教学和工程三方面都具备长期扩展价值。

后续工作建议按以下顺序推进：

1. 先确认首版主图收敛范围。
2. 再产出 AI 出图专用提示词。
3. 然后生成主图和局部版本。
4. 最后进入 Godot 热点接入和主地图交互实现。
