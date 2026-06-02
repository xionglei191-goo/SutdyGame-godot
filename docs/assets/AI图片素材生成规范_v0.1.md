# AI 图片素材生成规范 v0.1

> 项目：StudyGame  
> 用途：统一自生成图片素材的风格、版权边界、命名、审核和导入流程  
> 日期：2026-05-31

## 1. 目标

StudyGame 当前以自生成图片素材为主。本规范用于保证素材：

- 风格统一。
- 适合小学儿童。
- 不侵犯已有 IP 或商标。
- 能被 Godot 稳定使用。
- 方便后续替换、追踪和复用。

## 2. 风格定位

### 2.1 核心风格

原创儿童向生活冒险插画风，适合 7-12 岁儿童。

关键词：

- bright
- cute
- dreamy
- lively
- child-friendly
- pastel colors
- toy town
- magical school
- cozy home corner
- cozy garden
- readable town places
- clean shapes

中文描述：

- 明亮
- 梦幻
- 精致
- 可爱
- 生活化但适龄
- 玩具小镇感
- 童话小镇冒险感
- 家与小镇的生活感
- 可探索但不拥挤
- 色彩清透
- 轮廓清晰

### 2.2 色彩方向

主色可包含：

- 珊瑚粉
- 樱花粉
- 奶油白
- 浅金色

辅助色建议：

- 薄荷绿
- 天空蓝
- 薰衣草紫
- 柠檬黄

限制：

- 不要整屏只有粉色。
- 不要高饱和霓虹色。
- 不要暗黑、恐怖、压抑风格。
- 不要成人化时尚大片风格。

## 3. 版权与安全边界

### 3.1 禁止项

- 不使用“Barbie / 芭比”作为素材文件名、角色名、游戏名或宣传名。
- 不要求模型模仿任何具体商业 IP。
- 不生成已有动画、电影、玩具、游戏角色。
- 不出现真实品牌 Logo。
- 不出现可识别商标、包装、学校名称或人物肖像。
- 不生成成人化服装、姿态或妆容。

### 3.2 推荐描述

可使用：

- original child-friendly adventure game character
- original pastel toy-town style
- child-friendly everyday outfit
- cute magical school town
- dreamy life-adventure game art

避免使用：

- in Barbie style
- Barbie-like
- Disney style
- Pixar style
- Sanrio style
- Monster High style
- any named IP style

## 4. 素材分类

### 4.1 角色素材

包括：

- 玩家主角立绘
- 玩家行走精灵
- NPC 立绘
- NPC 地图精灵
- 表情差分

要求：

- 儿童或少年角色必须适龄。
- 服装明亮、可爱、健康。
- 脸部表情友好。
- 轮廓清楚，适合小尺寸显示。
- 同一角色需要保持发型、主色和标志性配饰一致。

### 4.2 场景素材

包括：

- world overview / home + school 起步区
- home 室内与宠物角
- 教室
- 花园
- 小镇非学校地点
- 商店/出行地点
- PlaceCard / Memory Spark 所需辅助图

要求：

- 画面干净，交互目标清晰。
- 预留玩家移动区域。
- 背景不要过度复杂。
- 适合 2D 俯视或 2.5D 表现。

### 4.3 道具素材

包括：

- 生活冒险道具
- 家具
- 服装
- 星片
- 贴纸
- 事件道具

要求：

- 单个道具最好透明背景。
- 缩小到 64x64 后仍可识别。
- 重要互动道具不能被装饰遮挡。

### 4.4 UI 素材

包括：

- 按钮
- 对话框
- Quest Diary 冒险日志
- 奖励弹窗
- 图标

要求：

- 8px 左右圆角即可，不做过度圆润。
- 按钮文字区域足够大。
- 图标优先清晰表达功能。
- UI 不抢过地图探索和故事互动。

## 5. MVP 素材清单

| 编号 | 类型 | 名称 | 数量 | 优先级 |
|---|---|---|---:|---|
| A001 | 角色 | 玩家主角立绘 | 1 | P0 |
| A002 | 角色 | 玩家主角行走图 | 1 套 | P0 |
| A003 | 角色 | Mina 立绘 | 1 | P0 |
| A004 | 角色 | Leo 立绘 | 1 | P0 |
| A005 | 角色 | Nora 立绘 | 1 | P0 |
| A006 | 场景 | world overview / home + school 起步区 | 1 | P0 |
| A007 | 场景 | home 室内 / pet corner | 1 | P0，待生成 |
| A008 | 场景 | 教室 | 1 | P0 |
| A009 | 场景 | 花园 | 1 | P0 |
| A010 | 道具 | classroom / library / playground 图标 | 3 | P1，已入库备用 |
| A011 | 道具 | pet bowl / pet food / pet ball toy / soap | 4 | P0，待生成 |
| A012 | 道具 | book / pencil / schoolbag / desk / shelf | 5 | P0；book/pencil/schoolbag 已接入，desk/shelf 备用 |
| A013 | 道具 | bird / flower / tree / bench | 4 | P0，已入库备用 |
| A014 | 道具 | place card / shop / travel / pet care 辅助图标 | 8 | P0，部分待生成 |
| A015 | 奖励 | First Trip Ticket / Adventure Star / Tidy Badge / Garden Leaf | 4 | P0；First Trip Ticket 待生成 |
| A016 | UI | 对话框 | 1 套 | P1 |
| A017 | UI | Quest Diary / PlaceCard / Memory Spark | 1 套 | P1 |
| A018 | UI | 奖励弹窗 / 轻反馈装饰 | 1 套 | P1 |

## 6. 文件命名规范

使用英文小写、下划线和版本号：

```text
角色：
char_player_portrait_v001.png
char_player_walk_down_v001.png
char_mina_portrait_happy_v001.png

场景：
map_sunshine_world_overview_v001.png
map_home_interior_bg_v001.png
map_school_arrival_bg_v001.png
map_classroom_bg_v001.png
map_garden_bg_v001.png

道具：
prop_library_icon_v001.png
prop_pet_bowl_v001.png
prop_pet_food_v001.png
prop_schoolbag_blue_v001.png

奖励：
reward_first_trip_ticket_v001.png
reward_adventure_star_piece_v001.png

UI：
ui_dialogue_box_v001.png
ui_place_card_v001.png
ui_memory_spark_v001.png
ui_quest_diary_ornament_v001.png
```

## 7. 目录规范

```text
assets/
  generated/
    characters/
      player/
      npcs/
    maps/
      world/
      home/
      school_arrival/
      classroom/
      garden/
    props/
      school/
      home/
      town/
      room/
      garden/
    rewards/
    ui/
  source_prompts/
    characters/
    maps/
    props/
    ui/
```

每张正式素材必须有对应提示词记录。当前 home 室内背景统一使用 `map_home_interior_bg_v001.png` 作为计划文件名，旧写法 `map_home_interior_v001.png` 不再作为本项目当前命名基线。

## 8. 提示词模板

### 8.1 角色立绘模板

```text
Original child-friendly adventure game character for a children's life-adventure RPG where English is embedded through home, town, pet care, shopping, travel, and story moments, age 9 to 10, bright pastel everyday outfit, friendly and confident expression, healthy age-appropriate clothing, clean shape language, dreamy toy-town aesthetic, soft lighting, full body character portrait, transparent background, no logo, no text, no existing IP, no brand elements.
```

变量：

- 角色名
- 发型
- 主色
- 配饰
- 性格

### 8.2 NPC 模板

```text
Original child-friendly NPC character for a pastel toy-town life-adventure RPG where English is embedded through story, home, town, pet care, shopping, and travel moments, friendly expression, age-appropriate outfit, clear silhouette, bright colors, storybook charm, suitable for children age 7 to 12, transparent background, no logo, no text, no existing IP, no brand elements.
```

### 8.3 场景模板

```text
Original pastel toy-town life-adventure background for a 2D children's life-adventure English RPG, bright and dreamy style, clean readable layout, clear interactive areas, child-friendly, soft daylight, no logo, no text, no existing IP, no brand elements.
```

### 8.4 道具模板

```text
Cute readable game prop icon for a children's life-adventure English RPG, pastel colors, clean outline, centered object, transparent background, high readability at small size, no logo, no text, no brand elements.
```

### 8.5 UI 模板

```text
Cute clean UI element for a children's life-adventure RPG, pastel color palette, readable shape, soft shadow, simple border, suitable for dialogue box, PlaceCard, Memory Spark, and adventure journal panels, no text, no logo, no brand elements.
```

## 9. 负面提示词

```text
existing IP, logo, trademark, brand name, celebrity, realistic adult fashion, mature body, revealing outfit, horror, dark, scary, violent, weapon, photorealistic child, text, watermark, blurry, cluttered background, low readability
```

## 10. 尺寸建议

| 类型 | 建议尺寸 | 说明 |
|---|---|---|
| 角色立绘 | 1024x1024 或 1024x1536 | 对话和角色页 |
| 地图精灵 | 256x256 单方向 | 后续可切动画 |
| 场景背景 | 2560x1440 | 世界总览主图基线；局部场景可按需求导出 |
| 道具图标 | 512x512 | 导入后缩放 |
| UI 面板 | 1024x512 | 可九宫格切分 |
| 奖励图标 | 512x512 | 弹窗和收藏 |

## 11. 审核流程

每张素材进入项目之前需要经过 4 步：

1. 风格审核：是否符合儿童向生活冒险小镇风。
2. 适龄审核：角色服装、姿态和表情是否适合儿童。
3. 版权审核：是否出现 IP、Logo、商标或明显模仿。
4. 可用性审核：缩小后是否清楚，是否适合 Godot 场景使用。

审核结果记录：

```json
{
  "asset_id": "A001",
  "file": "char_player_portrait_v001.png",
  "prompt_file": "char_player_portrait_v001.md",
  "style_pass": true,
  "age_pass": true,
  "copyright_pass": true,
  "usability_pass": true,
  "notes": "可用于 MVP"
}
```

## 12. Godot 导入规范

建议：

- UI 和像素清晰素材关闭过度压缩。
- 场景背景可压缩，但要检查色块和文字区域。
- 角色和道具统一锚点。
- 透明 PNG 用于角色、道具和 UI。
- 背景图用 PNG 或 WebP，视体积决定。
- 所有交互物品在 Godot 中单独建节点，不直接烘死在背景里。

## 13. 第一批生成顺序

优先级从能支撑当前 `HomeLayer + world_overview + town/shop/pet economy + Memory Spark` 运行时基线开始，而不是继续围绕旧的 school-only 或 home+school 小切片补图：

1. pet care 道具：pet bowl、pet food、pet ball toy、soap。
2. town/shop 互动道具：place-card visit、shop bag、ticket、travel helper。
3. `PlaceCard` 独立装饰与 `Memory Spark` 支撑图。
4. `First Trip Ticket` 独立奖励图标，替换当前 Adventure Star 复用。
5. world overview 后续局部修订参考：home、school、town road、shops、transport 的关系必须保持清楚。
6. 角色和已有 home/school/classroom/garden 素材只做必要修补，不再作为近期美术重构的主要缺口。

## 14. 最近下一步

当前运行时与下一批美术重构优先关注以下最小素材包：

- `assets/generated/props/home/prop_pet_bowl_v001.png`
- `assets/generated/props/home/prop_pet_food_v001.png`
- `assets/generated/props/home/prop_pet_toy_v001.png`
- `assets/generated/props/home/prop_soap_v001.png`
- `assets/generated/props/town/prop_place_card_visit_v001.png`
- `assets/generated/props/town/prop_shop_bag_v001.png`
- `assets/generated/props/town/prop_ticket_v001.png`
- `assets/generated/rewards/reward_first_trip_ticket_v001.png`
- `assets/generated/ui/ui_place_card_ornament_v001.png`

这些素材优先补齐当前已经可玩的 `home pet care`、town shops、PlaceCard、First Trip、Memory Spark 和 pet/shop economy 体验缺口。已有 player、Mina、world overview、school arrival、classroom、garden 和 Adventure Star 资源继续作为已入库/已接入基线维护，不再代表下一批美术生产的主要方向。

当前状态补充：

- `map_home_interior_bg_v001.png` 已生成并接入 `TownMap.tscn` 的 `HomeLayer/HomeBackgroundSlot`；旧 Godot 节点色块仅作为隐藏备份层保留。
- `reward_first_trip_ticket_v001.png` 尚未生成，运行时的 `first_trip_ticket` 暂时复用 Adventure Star 图标。
- `props/home/`、`props/town/` 与 `ui_place_card_ornament_v001.png` 中列出的若干图标仍是待生成项。
- 已生成的 school/garden 图标、desk/shelf、UI ornament 多数是备用资产，不能在文档中等同于已接入 runtime。
