# StudyGame

StudyGame 是一款面向小学生的 Godot 儿童英语生活冒险 RPG。产品方向是 `home-first` 半开放小镇探索，以 `Quest Diary`、`Story Show`、`Memory Spark`、`PlaceCard`、宠物/装扮/商店循环和记忆宫殿地图，把英语内容自然嵌入生活冒险。

## 当前状态

当前仓库已经进入 Godot MVP 重构开发阶段，当前基线包括：

- 产品 PRD、生活冒险玩法重构总纲与内容设计。
- Godot Prototype/MVP 开发任务拆解与基础运行链路。
- 默认从 `HomeLayer` 开始，随后可进入 `world_overview` 世界地图与 A-Z 锚点；总览图当前可玩起步区位于 `home + school`，长期路线定义为 `home -> school -> town -> transport -> world`。
- `Home Pet Care`、`PlaceCard`、`supermarket -> pet bowl -> home`、`pet_shop -> pet ball -> home play feedback`、`general_store -> star rug -> home Room decor` 的轻经济回流切片。
- `owned_items` 轻量物品归属层，兼容 `owned_pet_bowl / owned_pet_ball / owned_explorer_cape / owned_star_rug` 旧 story flags。
- `bookshop -> Help Find a Book -> Bookshop Helper` 的第一个非学校 Quest Diary 委托切片。
- `bus_station -> Choose Town Route -> travel_route_town_edge` 的最小交通路线切片。
- `ParentSummary -> Parent Bonus +2 -> clothes_shop -> Explorer Cape -> home Outfit` 的家长奖励与外观消费闭环，和 `Coins` 保持双层货币分离。
- `Memory Spark` 首访对话 / 回访提取已覆盖全量 A-Z anchors，运行时已使用 `MemorySpark*` 命名；`anchor_*` ID 与 `anchor_recall_done_*` 存档 flag 保持兼容。
- `Quest Diary`、`Story Show`、`Walk With Mina` 等新前台表达。
- 多 Agent 协作规范。
- 英语内容来源资料与序章基础层设计。
- `tests/` 与 `scripts/dev/` 下的自动化检查和人工试玩辅助脚本。

## 目录

```text
docs/
  product/        产品需求、故事线、生活事件设计
  development/    Godot 开发任务拆解
  assets/         AI 图片素材生成与审核规范
  collaboration/  多 Agent 协作规范和任务模板
  source/         已归档的早期参考资料
curriculum/
  小学英语重点分析/  英语内容拆解来源
AGENTS.md         仓库贡献与协作指南
```

## 多 Agent 协作

后续开发采用分组子 Agent 模式。开始任务前先阅读：

- `AGENTS.md`
- `docs/collaboration/多Agent协作规范_v0.1.md`
- `docs/collaboration/任务交接模板.md`

推荐分组：

- PM Agent
- Game Design Agent
- Curriculum Agent
- Narrative Agent
- Godot Dev Agent
- UI/UX Agent
- Asset Agent
- QA Agent

## 当前文档口径

1. 产品空间主线固定为 `home -> school -> town -> transport -> world`。
2. 当前新存档默认从 `HomeLayer` 起步；打开 `world_overview` 后以 `home + school` 作为路线起点，但这不是长期产品边界。
3. 地图交互的当前方向以 `world_overview`/热点配置驱动为准；`home`、`campus_gate`、`garden` 等子场景目标已迁到 `data/maps/scene_click_targets_v001.json`，由 `SceneClickGame.get_place_rects_for_scene()` 和 quest data integrity 测试共同保护，后续新增/迁移子场景目标应继续走数据配置，不再扩展脚本硬编码 rect。
4. 运行时当前已经包含：
   - `world_overview`
   - `Welcome Box -> Room Starter -> Pet Hello -> Home Pet Care -> First Trip`
   - `Walk With Mina -> Room Helper -> Bird Watch`
   - `home pet care`
   - non-school `PlaceCard`
   - `bookshop -> Help Find a Book -> Bookshop Helper`
   - `bus_station -> Choose Town Route -> travel_route_town_edge`
   - `supermarket -> pet bowl -> home`
   - `pet_shop -> pet ball -> home play feedback`
   - `general_store -> Buy Star Rug (4) -> home Room decor`
   - `ParentSummary -> Parent Bonus +2`
   - `clothes_shop -> Buy Explorer Cape (1 Parent Bonus)`
   - `Story Show`
   - full A-Z `Memory Spark`
5. `docs/development/` 下 `Prototype_0_1` 与 `MVP_0_2` 的试玩/验收文档用于保留历史验证证据，不作为当前产品基线。
