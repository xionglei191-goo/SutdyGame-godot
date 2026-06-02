# 多 Agent 协作规范 v0.1

> 项目：StudyGame  
> 目的：明确后续通过子 agent 分组开发时的角色边界、交付物和交接流程。

## 1. 协作原则

- 主 Agent 负责拆解目标、分配任务、整合结果和最终验收。
- 子 Agent 只处理被分配的明确范围，不擅自改动无关文件。
- 所有产出必须落到仓库文件中，避免只停留在口头结论。
- 任何设计、内容、素材或代码变更都要说明来源、影响范围和验证方式。
- 涉及儿童内容、英语知识点和图片素材时，必须遵守适龄与版权边界。

## 2. 推荐子 Agent 分组

| Agent | 职责 | 主要输入 | 主要输出 |
|---|---|---|---|
| PM Agent | 需求拆解、版本规划、验收标准 | PRD、用户目标、当前进度 | 任务列表、里程碑、验收清单 |
| Game Design Agent | 玩法循环、生活事件和奖励设计 | PRD、课程内容 | 生活事件/委托方案、Quest Diary 配置草案 |
| Curriculum Agent | 英语知识点拆解与审核 | `curriculum/` 资料 | 词句目标、难度说明、家长层解释 |
| Narrative Agent | 世界观、角色、对话文本 | 产品设定、事件目标 | NPC 台词、剧情事件文本 |
| Godot Dev Agent | 工程实现、脚本、场景 | 开发任务、数据配置 | Godot 场景、脚本、运行说明 |
| UI/UX Agent | 儿童界面、交互流程 | PRD、玩法需求 | UI 流程、界面规格、可用性建议 |
| Asset Agent | 图片生成规范、素材清单 | 美术规范、任务场景 | 提示词、素材清单、审核记录 |
| QA Agent | 测试用例、验收、风险回归 | 版本范围、实现结果 | 测试清单、问题列表、验收结论 |

## 3. 任务分配格式

给子 Agent 分配任务时，使用以下结构：

```markdown
## Task
一句话说明目标。

## Scope
允许修改或产出的文件范围。

## Inputs
必须阅读的文档或数据。

## Deliverables
需要提交的文件、表格、代码或结论。

## Acceptance Criteria
可验证的完成标准。

## Constraints
不能触碰的范围、风格、安全和版权限制。
```

## 4. 子 Agent 交付格式

子 Agent 完成后必须说明：

- 修改了哪些文件。
- 新增了哪些内容。
- 哪些需求已经满足。
- 如何验证。
- 还有哪些风险或待确认问题。

## 5. 文件所有权

| 路径 | 主要负责 Agent |
|---|---|
| `docs/product/` | PM Agent、Game Design Agent |
| `docs/development/` | Godot Dev Agent、PM Agent |
| `docs/assets/` | Asset Agent、UI/UX Agent |
| `docs/collaboration/` | PM Agent、主 Agent |
| `curriculum/` | Curriculum Agent |
| `data/` | Curriculum Agent、Game Design Agent、Godot Dev Agent |
| `scenes/` | Godot Dev Agent |
| `scripts/` | Godot Dev Agent |
| `assets/generated/` | Asset Agent、Technical Artist |
| `tests/` | QA Agent、Godot Dev Agent |

## 6. 冲突处理

- 产品目标冲突：由 PM Agent 提出取舍，主 Agent 决策。
- 英语内容冲突：以 `curriculum/` 中资料和 Curriculum Agent 审核为准。
- 美术风格冲突：以 `docs/assets/AI图片素材生成规范_v0.1.md` 为准。
- 技术实现冲突：以能稳定完成 MVP 的最小方案优先。

## 7. 验收顺序

1. 子 Agent 自检。
2. 主 Agent 检查文件和范围。
3. QA Agent 执行测试或文档审核。
4. PM Agent 对照 PRD 验收。
5. 主 Agent 汇总状态并决定是否进入下一轮。
