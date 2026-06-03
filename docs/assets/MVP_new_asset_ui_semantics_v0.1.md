# New MVP Asset And UI Semantics Plan v0.1

> 日期：2026-06-02
> 范围：P0.5 HomeLayer pet props、P0.7 First Trip Ticket、P1.7 PlaceCard/UI 语义文档
> 本文件只做资产和 UI 语义规划；不生成 binary images，不修改 scenes、runtime scripts 或 tests。

## 目标

本轮把新 MVP 的美术/UI 接口准备清楚，让后续 Asset、UIUX、Godot worker 可以继续生成和接入，而不会把 child-facing 产品重新拉回 school-only、lesson panel、word-list drill 或 review-test 口径。

优先体验仍是：从 `HomeLayer` 开始，打开 `Welcome Box`，照顾 pet，获得 `First Trip Ticket`，再去 town、school、transport 和 world 继续探索。

## HomeLayer 与 world_overview 的边界

- `HomeLayer` 是真实室内起点，当前背景是 `assets/generated/maps/home/map_home_interior_bg_v001.png`，已接入 `HomeLayer/HomeBackgroundSlot`。
- `world_overview` 上的 home 起点属于 `assets/generated/maps/world/map_sunshine_world_overview_v007_square.png` 的大地图区域，用于拖动探索、A-Z anchors、PlaceCard 和地点路由。
- Home pet corner refinement 只修订 `HomeLayer` 室内，不替换 `world_overview` 的 home 起点。
- 文档、prompt 和验收描述里不要把 `HomeLayer` interior background 与 `world_overview` home starting area 混写成同一个资产。

## 资产交付状态

| Priority | Asset | Target file | Status | Required prompt record |
|---|---|---|---|---|
| P0.5 | Pet bowl | `assets/generated/props/home/prop_pet_bowl_v001.png` | `generated`, `connected` | `assets/source_prompts/props/home_pet_care_props_v001.md` |
| P0.5 | Pet food | `assets/generated/props/home/prop_pet_food_v001.png` | `generated`, `connected` | `assets/source_prompts/props/home_pet_care_props_v001.md` |
| P0.5 | Pet toy / ball | `assets/generated/props/home/prop_pet_toy_v001.png` | `generated`, `connected` | `assets/source_prompts/props/home_pet_care_props_v001.md` |
| P0.5 | Soap | `assets/generated/props/home/prop_soap_v001.png` | `generated`, `connected` | `assets/source_prompts/props/home_pet_care_props_v001.md` |
| P0.5 | Home pet corner refinement | `map_home_interior_bg_v002.png` or approved equivalent | `pending` | `assets/source_prompts/maps/home_pet_corner_refinement_v001.md` |
| P0.7 | First Trip Ticket reward | `assets/generated/rewards/reward_first_trip_ticket_v001.png` | `generated`, `connected` | `assets/source_prompts/props/reward_place_card_ui_prompts_v001.md` |
| P1.7 | PlaceCard ornament | `assets/generated/ui/ui_place_card_ornament_v001.png` | `generated`, `connected` | `assets/source_prompts/props/reward_place_card_ui_prompts_v001.md` |

Current runtime notes:

- `first_trip_ticket` now uses dedicated `reward_first_trip_ticket_v001.png` through `data/rewards/reward_icons_v001.json`.
- `PlaceCard.tscn` now displays `ui_place_card_ornament_v001.png` as a subtle ornament.
- Home pet-care actions use separable runtime prop assets for bowl, food, toy, and soap; future home background refinements should not bake these states into the background.

## UI Semantic Rules

Child-facing UI should feel like a life-adventure game. Prefer: `Quest Diary`, `Welcome Box`, `First Trip`, `Home Pet Care`, `PlaceCard`, `Memory Spark`, `Story Show`, `Shop Stop`, `Travel Stop`, `Town Visit`, `Help Find a Book`, `Buy Pet Bowl`, `Buy Pet Ball`, `Choose Town Route`.

Avoid child-facing wording such as: lesson, word list, sentence pattern, review test, L1, L2, L3, school app, lesson panel, task panel, school tour.

Parent-facing surfaces may explain learned words/patterns and curriculum intent, but child-facing UI should keep those concepts wrapped in home, town, pet, shop, trip, show, and discovery language.

## PlaceCard Title Semantics

PlaceCard titles should come from data or a narrow UI mapping rather than a fixed hardcoded `Town Visit` label.

Recommended title semantics:

- `PlaceCard`: generic default when no narrower context exists.
- `Town Visit`: simple non-school exploration card.
- `Shop Stop`: shop/economy cards such as supermarket, pet shop, general store, and clothes shop.
- `Travel Stop`: transport cards such as bus station, taxi, railway station, and airport.
- `Pet Stop` or `Home Pet Care`: home/pet-care cards if a future home card flow needs one.

Button copy should use action verbs a child understands, such as `Buy Pet Bowl`, `Buy Pet Ball`, `Choose Town Route`, `Help Find a Book`, `Go Home`, and `Close`. Do not expose internal IDs like `town_bookshop_find_book`, `review_challenge_started`, `mvp_0_2_review_challenge`, or compatibility scene IDs.

## Visual Semantics

- Pet props: transparent PNGs, clear silhouettes, readable at 64x64, warm and cozy.
- First Trip Ticket: distinct from Adventure Star; should communicate a first outing from home without using real transit brands or readable ticket text.
- PlaceCard ornament: subtle corner/header decoration; it should support town, shop, travel, and pet contexts without looking like a worksheet.
- Home pet corner: cozy, readable, and gameplay-friendly; keep bowl/food/toy/soap as separable runtime props.

## Safety Acceptance

- No external IP, logos, brands, trademarks, readable packaging, watermark, celebrity likeness, or named style imitation.
- No real pet-food packaging, ticketing brand, transit logo, store logo, school logo, or commercial toy-like mascot.
- No child-facing UI that frames play as a lesson, review test, worksheet, word list, or school app.
- Any generated image must be reviewed against `docs/assets/AI图片素材生成规范_v0.1.md` before import.

## Handoff Notes

- Asset worker can generate images after this doc using the focused prompt records, then update `docs/assets/MVP_0_2_第一版自生成美术资产记录.md` from `pending` to `generated`.
- Godot/UI worker can mark an asset `connected` only after scene/script wiring and the relevant visual or flow check passes.
- If a placeholder remains after generated art exists, record it explicitly so QA can see whether runtime still reuses old art.
