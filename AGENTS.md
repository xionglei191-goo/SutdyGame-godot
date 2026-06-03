# Repository Guidelines

## Project Structure & Module Organization

This repository contains an active Godot 4 project for `StudyGame`, a children’s English life-adventure RPG. The current product direction is `home -> school -> town -> transport -> world`, with A-Z memory anchors, a movable `world_overview` map, child-facing quest wording, pet/shop economy loops, and curriculum-driven progression under the hood. Do not frame the child-facing product as a school app, school tour, lesson panel, word-list drill, or review test.

Current product north star: `StudyGame` is a children’s English life-adventure game whose first mental model is “start from home, travel through a town, meet friends, care for a pet, shop, collect, and slowly discover school, city, and world places.” School is important, but it must never become the whole product frame.

- `docs/product/`: PRD, story, and game design documents.
- `docs/development/`: Godot implementation plans and task breakdowns.
- `docs/assets/`: generated image style, safety, and import rules.
- `docs/collaboration/`: sub-agent workflow and handoff templates.
- `docs/source/`: archived early source plans and reference material. Do not treat this directory as the current product baseline unless a task explicitly asks for historical comparison.
- `curriculum/`: grade-level English source notes.
- `scenes/`: Godot scenes under `main/`, `maps/`, `actors/`, `ui/`, and `minigames/`.
- `scripts/`: GDScript under `core/`, `actors/`, `systems/`, `maps/`, and `minigames/`.
- `data/`: JSON quest, hotspot, dialogue, and compatibility definitions.
- `tests/`: headless smoke, routing, docs-audit, and playtest helper scripts.
- `scripts/dev/`: project-level validation, map generation, and manual playtest helpers.
- `assets/generated/`: generated character, map, prop, reward, and UI assets.

Important runtime baselines:

- `docs/product/教学玩法重构策划_v0.1.md` is the current upper-level product truth for gameplay direction. Use it to interpret future PRD, story, world-map, and implementation changes unless the user explicitly supersedes it. If a lower-level document conflicts with it, update the lower-level document rather than reviving the older direction.
- New games start at `HomeLayer` for the `Welcome Box` opener. `SceneHost.tscn` / `WorldOverviewScene.tscn` remains the world-map runtime scene opened from home and used for A-Z anchors, town exploration, PlaceCard, and transport/world routing. The current generated overview map is a large `2560x1440` exploration surface shown through the `1280x720` runtime viewport.
- `HomeLayer` is the runtime default entry and `HomeBackgroundSlot` is connected to `assets/generated/maps/home/map_home_interior_bg_v001.png`. The older Godot-node color/shape home background remains only as a hidden backup layer. Do not describe the `world_overview` home starting area as the generated `HomeLayer` interior background.
- The current opener starts with the micro-prologue `Welcome Box` (`prologue_letter_box`) at `home`, then continues into `First Trip` (`prologue_go_to_school`) and hands off into `Walk With Mina` at school arrival. `Welcome Box` may appear in completed quest/reward lists, but the current Parent Bonus gate still uses the four formal MVP events plus `Story Show`.
- `home` and `school` are both part of the first playable map experience. School is a key region inside the wider life-adventure world, not the whole face of the product.
- Map composition must keep strongly related places together. `classroom`, `library`, `playground`, `canteen`, `music_room`, and `art_room` belong inside the school area; `canteen` and `playground` should be visually contained by the school footprint rather than floating as separate town landmarks.
- `home` is a required opening anchor and should stay visible in the initial world-map experience. It supports family dialogue, pet care, outfit status, room decor, and parent-reward feedback.
- Town and transport composition should preserve practical routing: shops cluster around the town road, while `bus_station`, `taxi`, `railway_station`, and later transport hubs should read as connected to main roads rather than isolated decorative corners.
- A-Z memory anchors are a frozen memory-palace layer. Keep `A = Apple` and the existing hotspot IDs/route order unless a coordinated data, docs, map, and test migration is explicitly requested.
- A-Z anchors are not optional Easter eggs. They are the memory-palace backbone for letter recognition, picture-word recall, place recall, and later quest/review callbacks. New maps may add secondary props, but must not replace the frozen primary anchor for a letter.
- Child-facing wording uses names such as `Quest Diary`, `Story Show`, `Welcome Box`, `Walk With Mina`, `First Trip`, `Room Helper`, `Bird Watch`, `Home Pet Care`, `PlaceCard`, and `Memory Spark`.
- Internal stable IDs remain in code and data, for example `QuestDiary`, `g4_u1_school_tour`, `mvp_0_2_review_challenge`, and legacy `review_challenge_*` report events. Do not expose these names in player-facing copy.
- `start_quest` is the Quest Diary primary API. `start_lesson`, `lesson_id`, and `current_lesson` only remain as documented compatibility wrappers for older save/report/test contracts; do not reintroduce `lesson_targets` or `lesson_only` into active runtime data.
- `quest_active` is the preferred runtime state name for current Quest Diary activity. Keep `set_task_active()`, `is_task_active()`, and `task_*` signals only as compatibility wrappers when existing scenes, tests, or saved report contracts still rely on them.
- Quest startup now reads `scene_id`, `type`, and `start_focus_hotspot` from `data/quests/*.json` before falling back to legacy quest-id routing. New Quest startup behavior should extend quest data, not add new `handle_quest_started()` `match quest_id` branches.
- Quest completion routing now reads the `completion` object in `data/quests/*.json`, including `scene_id`, `action`, `story_flags`, `dialogue_id`, `npc_prompts_visible`, and `click_input_enabled`, before falling back to legacy quest-id routing. New Quest completion behavior should extend quest data, not add new `handle_quest_completed()` `match quest_id` branches.
- Quest completion coin rewards now live in `data/quests/*.json` as `reward_coins`. `MainFlowController` reads that field first and only keeps a legacy fallback for older/incomplete quest data; do not add new quest coin amounts as controller `match quest_id` branches.
- Quest child-facing event titles now live in `data/quests/*.json` as `title`. `MainFlowController.quest_title()` reads that field first and only keeps legacy names as a fallback for older/incomplete quest data; do not add new event names as controller `match quest_id` branches.
- `GameState.get_completed_quests()` and the `completed_quests` debug-snapshot mirror are the current quest-facing read path. The legacy `completed_tasks` key remains derived for old save/load, playtest reports, and Debug IDs; do not reintroduce a separate in-memory `completed_tasks` source without a coordinated report migration.
- `school_arrival` is the current front-end / art / planning name for the home-to-school arrival slice. `campus_gate` is still used as an internal runtime compatibility scene ID in code, data, and tests unless a task explicitly migrates that ID.
- `GameState` already owns `coins`, `parent_bonus`, `pet_name`, `pet_state`, `care_for_pet(action_id)`, `owned_items`, `has_owned_item(item_id)`, and compatibility helpers such as `has_pet_bowl()`, `has_pet_ball()`, and `has_explorer_cape()`; new `home`, shop, parent-reward, economy, outfit, or pet interactions must extend this state instead of introducing parallel save state.
- `Coins` and `Parent Bonus` are separate currencies. `Coins` drive normal exploration/shop loops; `Parent Bonus` is a parent-confirmed reward layer and must not be merged into `coins`.
- `care_for_pet` currently supports `feed`, `clean`, `play`, and `rest/sleep`; `feed` spends `2 coins`, while the other actions only update pet stats.
- `home` already has a repeatable pet-care loop in runtime, including a visible pet corner, starter pet name, and Rest button. Keep new home-side interactions compatible with the existing `coins`, `pet_name`, and `pet_state` flow.
- Non-school `world_overview` places can open a `PlaceCard` instead of forcing a sub-scene. First visits currently award `+1 coin` through `visited_place_<id>` story flags.
- The current starter economy loops are `supermarket -> Buy Pet Bowl (3) -> home feed feedback`, `pet_shop -> Buy Pet Ball (2) -> home play feedback`, and `clothes_shop -> Buy Explorer Cape (1 Parent Bonus)`. Extend `PlaceCardController` and the lightweight `GameState.owned_items` layer before adding any shop, outfit, or item behavior; do not add a separate inventory/save model.
- `ParentSummary` is the parent-facing explanation layer for completed events, learned words/patterns, Story Show status, timing export, and the current one-time `Parent Bonus +2` confirmation. Do not move child-facing quest flow into this layer.
- Parent Bonus confirmation is gated by the four current MVP events plus `Story Show`, writes `parent_bonus_confirmed_mvp_0_2`, and must be idempotent across repeat clicks and save/load.
- `Explorer Cape` is the current first Parent Bonus spend. It writes `owned_explorer_cape`, spends `parent_bonus`, and returns to a separate `home` `Outfit` status. It must not spend `coins` or pollute pet-item status.
- `owned_items` is now the lightweight ownership mirror for starter items and decor. Legacy `owned_pet_bowl`, `owned_pet_ball`, `owned_explorer_cape`, and `owned_star_rug` story flags remain saved and are bidirectionally migrated for compatibility with older saves, reports, and tests.
- New parent-facing UI should use `GameState.get_parent_summary_state()` or explicit `GameState` getters instead of treating `debug_snapshot()` as the main product data API. Keep `debug_snapshot()` for reports, diagnostics, and legacy fixtures.
- `world_overview` hotspot enablement is no longer a flat always-on set. Follow `default_visible`, `world_enabled_mode`, and `az_unlock_mode` in `data/maps/sunshine_world_hotspots_v001.json`:
  - `quest_only` for event-gated world targets such as `tree`, `flower`, `bench`, and `bird`
  - `pilot_recall` for the current small always-on `Memory Spark` pilot anchors
  - `disabled` for map/planning-only hotspots that are not yet clickable in runtime, such as `music_room` and `art_room`
- Subscene click targets for `home`, `campus_gate`, and `garden` live in `data/maps/scene_click_targets_v001.json`. New or migrated subscene targets should extend data/config, not add `PLACE_RECTS` or `SCENE_TARGET_RECTS` style script constants.
- Static `world_overview` place routing now lives in `data/maps/sunshine_world_hotspots_v001.json` as `world_place_action` (`scene` / `place_card`). Extend hotspot data for new place routes; keep economy, item ownership, transport rewards, and Quest Diary commission side effects in `PlaceCardController`, `WorldInteractionController`, and `GameState`.
- PlaceCard static copy, button declarations, narrow visibility keys, and success presentation metadata now live on place hotspots as `place_card_hint`, `place_card_actions`, `visible_when`, `success_status_text`, `home_feedback`, and `success_focus_hotspot`. Use hotspot data for new PlaceCard hint text, action labels, known visibility conditions, success status text, home feedback, and post-action map focus; keep all save/economy/quest side effects in controller code.
- A-Z anchor clickability is controlled by `az_unlock_mode`: starter anchors are available before the prologue is complete, and `az_full_unlocked_after_prologue` unlocks all 26 anchors. Do not use `default_visible` or `pilot_recall` as the A-Z learning unlock rule.
- `scripts/systems/world_overview_rules.gd` is the current source of truth for hotspot enablement, pilot recall anchor collection, school-core gating, and world-place action routing. Extend that helper before adding new one-off world-overview branches in `main.gd` or `scene_click_game.gd`.
- `PlaceCard` visit/reward/action logic is now partially extracted into `scripts/systems/place_card_controller.gd`; prefer extending that controller before adding more `PlaceCard` branches back into `main.gd`.
- The current memory-anchor baseline is no longer “dialogue only” for every revisit. Pilot anchors can use a lightweight child-facing `Memory Spark` follow-up after the first dialogue pass, while still keeping the main quest chain and `Story Show` contract untouched.
- `Memory Spark` is now also the runtime scene/script/test name. Keep legacy `anchor_*` IDs and `anchor_recall_done_*` save flags for compatibility; do not rename those without a coordinated save/data migration. Preserve `main.memory_spark_defs` unless you also update the tests that inspect that field.
- The current main story/progression orchestration is no longer entirely embedded in `main.gd`. Task start/completion, restore-from-progress, and `Story Show`/`ParentSummary` branching are now partially extracted into `scripts/systems/main_flow_controller.gd`. Prefer extending that controller before adding more lifecycle branches back into `main.gd`.
- `world_overview` place/anchor/home interaction routing is also no longer entirely embedded in `main.gd`. Place clicks, home pet actions, place-card close/action handling, and Memory Spark close/completion are now partially extracted into `scripts/systems/world_interaction_controller.gd`. Prefer extending that controller before reintroducing more world interaction branches into `main.gd`.
- `StoryShow.tscn` / `story_show.gd` are now the runtime names for the child-facing show flow. Keep legacy `mvp_0_2_review_challenge` and `review_challenge_started/completed` report IDs unless a coordinated report migration is requested.
- New child-facing copy should use adventure, home, town, pet, shop, trip, show, and discovery language. Avoid reviving old phrases such as `校园导览`, `School Tour`, `Task Panel`, or `Review Challenge` except when documenting internal compatibility names.
- Do not introduce child-facing UI that lists `lesson`, `word list`, `sentence pattern`, `review test`, `L1/L2/L3`, or similar school-administration terms. Keep those concepts in parent summaries, data/config IDs, audits, and curriculum documentation.

Near-term product and engineering priorities:

- P0: Implement a real `home` prologue foundation before expanding more school content. The sequence should cover letters, room objects, meeting/naming the first pet, first pet care, and the first trip from home toward school.
- P0: Continue polishing the real `HomeLayer` art and home interaction props while preserving the existing Welcome Box, pet corner, buttons, NPC, collision, and quest interaction nodes. The baseline home interior PNG is already connected at `HomeLayer/HomeBackgroundSlot`.
- P0: Continue expanding `transport` from decorative hotspots into playable travel slices. The current starter slice is `bus_station -> Choose Town Route -> focus the bus station / town-edge area`, which writes `travel_route_town_edge`, adds a route coin, and records starter travel words/patterns.
- P1: Continue upgrading non-school town places from `PlaceCard` into short Quest Diary commissions. The first slice is `bookshop -> Help Find a Book -> Bookshop Helper`, which completes `town_bookshop_find_book` on the world overview and stays outside the Parent Bonus gate.
- P1: Deepen the pet loop with visible pet identity and state, starting with `pet_name`, `sleep/rest`, and a visible home pet corner. Extend existing `pet_state` and `story_flags` instead of creating a parallel pet save model.
- P1: Continue extending the light `owned_items` layer only as needed. Quantity, consumables, category metadata, equipment slots beyond current status text, and inventory UI remain out of scope until there is a concrete gameplay need.
- P2: Expand `Memory Spark` coverage from the current pilot anchors toward the full frozen A-Z memory palace after the prologue foundation is in place. Add parameterized coverage before broadening behavior.
- P2: Continue expanding the existing non-school `PlaceCard` matrix coverage as new town/transport cards gain actions.

## Build, Test, and Development Commands

Godot is available through the `godot` command.

```bash
godot --path .
```

Open the project in the Godot editor. Requires `project.godot`.

```bash
godot --headless --path . --check-only --quit
```

Run a headless project parse/check before or after code changes.

```bash
godot --headless --path . -s res://tests/mvp_0_2_smoke.gd
```

Run the core MVP smoke flow.

```bash
godot --headless --path . -s res://tests/mvp_0_2_world_overview_input_flow.gd
```

Verify the world overview routing and anchor dialogue handoff.

```bash
godot --headless --path . -s res://tests/mvp_0_2_home_pet_care_input_flow.gd
```

Verify the `home` pet-care loop, return routing, and first-visit place-card flow.

```bash
godot --headless --path . -s res://tests/mvp_0_2_pet_shop_pet_ball_flow.gd
```

Verify the `pet_shop -> Buy Pet Ball (2) -> home play feedback` starter economy loop.

```bash
godot --headless --path . -s res://tests/mvp_0_2_supermarket_pet_bowl_flow.gd
```

Verify the `supermarket -> Buy Pet Bowl (3) -> home feed feedback` starter economy loop.

```bash
godot --headless --path . -s res://tests/mvp_0_2_clothes_shop_parent_bonus_flow.gd
```

Verify the `clothes_shop -> Buy Explorer Cape (1 Parent Bonus)` outfit loop and currency separation.

```bash
godot --headless --path . -s res://tests/mvp_0_2_general_store_room_decor_flow.gd
```

Verify the `general_store -> Buy Star Rug (4) -> home Room decor` starter home-decor loop.

```bash
godot --headless --path . -s res://tests/mvp_0_2_game_state_owned_items.gd
```

Verify `GameState.owned_items` save/load behavior and legacy `owned_*` story-flag migration.

```bash
godot --headless --path . -s res://tests/mvp_0_2_bookshop_commission_flow.gd
```

Verify the `bookshop -> Help Find a Book -> Bookshop Helper` non-school Quest Diary commission.

```bash
godot --headless --path . -s res://tests/mvp_0_2_transport_town_route_flow.gd
```

Verify the `bus_station -> Choose Town Route` starter transport slice.

```bash
godot --headless --path . -s res://tests/mvp_0_2_place_card_visit_flow.gd
```

Verify extracted `PlaceCardController` reward/action behavior through the first-visit place-card flow.

```bash
godot --headless --path . -s res://tests/mvp_0_2_place_card_visibility_data.gd
```

Verify that PlaceCard `visible_when` keys from hotspot data hide starter buttons after the matching owned item, route flag, or Quest completion is present.

```bash
godot --headless --path . -s res://tests/mvp_0_2_place_card_action_authorization.gd
```

Verify that hidden or mismatched PlaceCard actions cannot be executed by directly emitting or calling the action route.

```bash
godot --headless --path . -s res://tests/mvp_0_2_game_state_pet_care.gd
```

Verify `GameState` coin spend, pet-state updates, and save/load persistence.

```bash
godot --headless --path . -s res://tests/mvp_0_2_memory_spark_flow.gd
```

Verify the pilot `memory_anchor` progression loop: first dialogue, revisit recall, and reward/state writeback.

```bash
godot --headless --path . -s res://tests/mvp_0_2_world_hotspot_enablement.gd
```

Verify `world_overview` hotspot visibility/enablement rules, including quest-gated garden targets and disabled planning-only hotspots.

```bash
godot --headless --path . -s res://tests/mvp_0_2_docs_audit.gd
```

Verify documentation and fixture baselines.

```bash
./scripts/dev/run_mvp_0_2_checks.sh
```

Run the current end-to-end validation chain used by the repo.

```bash
rg --files .
```

Inspect repository files during planning or review.

## Multi-Agent Workflow

Use `docs/collaboration/多Agent协作规范_v0.1.md` before delegating work. Assign each sub-agent a clear scope, input documents, deliverables, and acceptance criteria. Use `docs/collaboration/任务交接模板.md` for handoffs. Sub-agents must not modify files outside their assigned scope.

## Coding Style & Naming Conventions

Use Godot 4.x conventions:

- Indent GDScript with tabs, following Godot defaults.
- Use `snake_case.gd` for scripts, methods, variables, JSON keys, and assets.
- Use `PascalCase.tscn` for reusable scenes, such as `Player.tscn`.
- Use stable content IDs, for example `g4_u1_school_tour`.
- Keep generated assets versioned, for example `char_mina_portrait_v001.png`.
- Preserve internal IDs even when child-facing labels change.
- Keep player-visible wording aligned with the current product baseline: `Quest Diary`, `Story Show`, `Welcome Box`, `Walk With Mina`, `First Trip`, `Room Helper`, `Bird Watch`, `Home Pet Care`, `PlaceCard`, `Memory Spark`, and `world_overview`.
- When front-end wording and internal IDs differ, update child-facing text first and migrate internal IDs only in coordinated refactors that also update data, tests, and docs.
- When editing documentation baselines, keep `tests/mvp_0_2_docs_audit.gd` aligned so automated docs checks do not continue locking stale product language.

Use Markdown for documents. Chinese is acceptable for product and curriculum content.

## Testing Guidelines

Automated headless checks already exist under `tests/` and `scripts/dev/`. For code or data changes, run the smallest relevant script first, then broaden only if the change touches shared behavior.

Common checks:

- `godot --headless --path . --check-only --quit`
- `godot --headless --path . -s res://tests/mvp_0_2_smoke.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_home_pet_care_input_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_supermarket_pet_bowl_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_pet_shop_pet_ball_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_clothes_shop_parent_bonus_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_general_store_room_decor_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_place_card_visit_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_place_card_visibility_data.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_place_card_action_authorization.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_game_state_pet_care.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_game_state_owned_items.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_bookshop_commission_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_transport_town_route_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_memory_spark_flow.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_world_hotspot_enablement.gd`
- `godot --headless --path . -s res://tests/mvp_0_2_docs_audit.gd`
- `./scripts/dev/run_mvp_0_2_checks.sh`

When running headless Godot tests manually, prefer serial execution for tests that mutate the default `user://study_game_save.json`. Do not parallelize fresh-save flow tests unless they use isolated save paths.

Manual verification is still required when changes affect presentation, exploration flow, or playtest-only gates. Focus manual checks on:

- Player movement and collision.
- `world_overview` camera framing, dragging, and hotspot routing.
- `world_overview` hotspot enablement, especially quest-gated garden targets and disabled planning-only hotspots.
- `home -> Welcome Box -> First Trip -> Walk With Mina` opener flow.
- `home` pet-care interaction, coin spend feedback, and pet-state persistence.
- `PlaceCard` open/close behavior and first-visit coin reward for non-school places.
- `supermarket` and `pet_shop` starter purchase loops returning visible feedback at `home`.
- `clothes_shop` Parent Bonus outfit purchase, including `owned_explorer_cape` persistence and coin separation.
- Pilot `Memory Spark` behavior for revisit anchors, including the seen/completed flag split and learned-word writeback.
- NPC interaction and dialogue flow.
- Task state transitions.
- Quest state transitions, especially where internal task IDs still back child-facing `Quest Diary` events.
- Reward display and save/load behavior.
- Parent summary display, Story Show completion gate, timing export, and `Parent Bonus` separation from `Coins`.
- Child-facing label consistency versus internal IDs.
- Quest/content data correctness against `curriculum/`; active runtime content belongs in `data/quests`, and `data/lessons` must not be reintroduced as a fallback source.
- Agent deliverables against assigned acceptance criteria.

New checks should live under `tests/`, named by feature or flow, following existing repo conventions such as `mvp_0_2_smoke.gd` or `mvp_0_2_world_overview_input_flow.gd`.

## Commit & Pull Request Guidelines

No local Git history convention exists yet.

Recommended commit style:

- `docs: add MVP development task breakdown`
- `feat: add player movement prototype`
- `data: add Walk With Mina quest content`
- `assets: add generated Mina placeholder`

Pull requests should include:

- A short summary of the change.
- Affected scenes, scripts, data files, or documents.
- Automated checks run and manual test notes.
- Screenshots or recordings for UI, map, character, or asset changes.
- Any curriculum source used for new English content.

## Asset & Content Safety

All game images should be self-generated and follow `docs/assets/AI图片素材生成规范_v0.1.md`. Do not add existing IP, logos, trademarked characters, or untracked web images. Keep prompt records for generated assets.

When generating new image assets during Codex work, call the model's built-in image generation interface directly by default. Do not rely on external image-generation CLIs, third-party APIs, browser tools, or ad hoc network services unless the user explicitly asks for that path. If the built-in interface is unavailable, record the prompt and asset target as pending instead of silently switching generation backends.
