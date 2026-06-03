# StudyGame 世界地图瓦块化改造计划

> 日期：2026-06-03  
> 基线：`HomeLayer -> world_overview -> school/town/transport/world` 生活冒险结构  
> 当前决策：`world_overview` 后续不再以单张高分辨率整图生成为主生产方式，改为“数据化瓦块/分层地图 + 局部地标/精灵资产 + 隐藏参考底图”的路线。  
> 执行状态：P0.1 已完成，已在不破坏现有热点、Quest Diary、PlaceCard、Memory Spark 坐标合同的前提下，接入可回退的分层地图骨架。

---

## 1. 核心原则

- 保留 `2560x2560` 世界逻辑画布和当前热点 ID/rect，避免一次性迁移输入、镜头、Quest 与测试合同。
- 旧整图 `map_sunshine_world_overview_v007_square.png` 只作为隐藏参考层和回退资产，不再作为新地图迭代的主要生产物。
- 地面、道路、区域边界、学校 footprint、城镇街区、交通节点优先用数据化层绘制。
- 关键地点逐步从整图烘焙改为独立地标资产或可复用瓦块资产。
- A-Z 记忆锚点仍由 `sunshine_world_hotspots_v001.json` 管理，不把学习逻辑烘死进图片。
- 地图变更优先更新数据/config 与渲染器，不在 `main.gd` 或交互控制器里新增一次性分支。

---

## 2. 阶段路线

| 阶段 | 优先级 | 目标 | 状态 |
|------|--------|------|------|
| P0.1 | P0 | 接入 `world_overview` 分层地图骨架，隐藏旧大底图，保持热点和镜头合同不变 | 已完成 |
| P0.2 | P0 | 将学校、home、town、transport 的主道路和区域块对齐现有 hotspot rect | 待开始 |
| P0.3 | P0 | 新增地图层数据校验，确保热点在对应区域内、道路连接 transport/shop cluster | 待开始 |
| P1.1 | P1 | 生成或绘制小型 tile atlas：草地、道路、广场、围墙、水面、树丛 | 待开始 |
| P1.2 | P1 | 将关键地标拆为独立 Sprite/TextureRect：Home、School、Bookshop、Pet Shop、Bus Station 等 | 待开始 |
| P1.3 | P1 | 为 world_overview 增加可切换 debug overlay：hotspot rect、A-Z anchors、route focus | 待开始 |
| P2.1 | P2 | 从过程绘制层迁移到 Godot TileMap/TileMapLayer 或稳定的 tile scene 组合 | 待开始 |
| P2.2 | P2 | 扩展 town/transport/world 新区时只新增局部 tile/landmark，不再整图重生 | 待开始 |

---

## 3. P0.1 实施清单

- [x] 新增 `data/maps/sunshine_world_layer_map_v001.json`，定义世界地图的分层绘制数据。
- [x] 新增 `scripts/maps/world_layer_map_renderer.gd`，读取层数据并绘制地面、道路、区域块和地标占位。
- [x] 修改 `scenes/maps/WorldOverviewScene.tscn`，新增 `LayerMap` 节点并把旧 `Background` 改为隐藏 `ReferenceBackground`。
- [x] 保持 `ClickGame`、`sunshine_world_hotspots_v001.json`、`SceneHost` 镜头逻辑不迁移，避免大范围回归。
- [x] 更新视觉验收测试，确认分层地图节点和隐藏参考底图同时存在。
- [x] 运行 `godot --headless --path . --check-only --quit`。
- [x] 运行 `godot --headless --path . -s res://tests/mvp_0_2_world_overview_input_flow.gd`。
- [x] 运行 `godot --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd`。

---

## 4. P0.2 对齐目标

- `home` 仍是打开 world_overview 后的起步 anchor，并与 school 起步区同屏。
- `sunshine_school` 是一个清晰的学校 footprint，`classroom/library/playground/canteen/music_room/art_room` 全部视觉上包含在学校 footprint 内。
- `town` 商店围绕主路聚类，避免分散到装饰角落。
- `bus_station/taxi/railway_station` 与道路相连，表达真实 transport 路由。
- 非学校 PlaceCard 地点继续使用当前数据路由，不新增子场景强制切换。

---

## 5. P1 资产策略

- 优先生成小图集或单个地标，不再请求模型一次性生成完整世界图。
- 推荐第一批资产：
  - `tile_grass_v001.png`
  - `tile_path_road_v001.png`
  - `tile_plaza_v001.png`
  - `landmark_home_v001.png`
  - `landmark_sunshine_school_v001.png`
  - `landmark_bookshop_v001.png`
  - `landmark_pet_shop_v001.png`
  - `landmark_bus_station_v001.png`
- 所有资产继续落在 `assets/generated/` 并保留 prompt 记录。
- 若模型生图再次卡死，只记录 prompt 和目标路径为 pending，不切换到外部生图服务。

---

## 6. 风险与回退

- 风险：过程绘制层初期美术质量低于整图。  
  处理：P0 只建立生产结构，P1 再用小资产逐步替换占位形状。
- 风险：热点坐标与新视觉块错位。  
  处理：P0.2 前不迁移 hotspot rect；P0.3 增加数据校验后再逐步微调。
- 风险：瓦块化影响现有 Quest/PlaceCard/Memory Spark。  
  处理：P0.1 不改交互数据、不改完成路由、不改 A-Z anchor ID。
- 回退：`ReferenceBackground` 保留旧整图资源，必要时可临时改回可见。
