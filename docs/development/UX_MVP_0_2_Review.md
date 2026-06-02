# UX MVP 0.2 Review

> 文档性质：2026-05-31 旧 MVP 内容轻量评审记录。  
> 当前产品基线已迁移到 `world_overview + home + town + pet/shop economy + Memory Spark`，本文件只保留当时对 quest/dialogue 文案的历史证据，不作为当前玩法范围或地图结构基线。
>
> Scope: `data/quests/`, `data/dialogues/`
> Audience: Grade 4 primary school learners
> Date: 2026-05-31

## Review Focus

- Keep each dialogue screen short and easy to read.
- Keep task prompts clear, concrete, and action-first.
- Use one consistent reward naming pattern.
- Avoid commercial IP, brand names, and trademark-like wording.
- Make the three-task chain feel natural: Walk With Mina -> Room Helper -> Bird Watch.

## Findings

- Overall level is suitable for Grade 4: vocabulary is concrete, sentences are short, and feedback is gentle.
- The original Leo instruction packed three placements into one dialogue screen. This could overload younger readers before the drag task begins.
- Reward display names were unified to the current front-end baseline and now use distinct keepsake-style names.
- No commercial IP or trademark names were found in the reviewed quest/dialogue text.

## Changes Made

- Split Mina's combined classroom/playground line into two shorter dialogue screens.
- Replaced Leo's long placement instruction with two shorter setup lines. The exact placement rules remain in quest patterns.
- Shortened Nora's garden description by removing the extra bench mention from dialogue.
- Adjusted success feedback to emphasize completion in plain child-friendly language.
- Standardized reward names:
  - `school_star_piece`: Adventure Star
  - `tidy_badge_piece`: Room Helper Badge
  - `garden_leaf_piece`: Garden Leaf Charm

## Task Chain Check

1. Mina starts Walk With Mina and asks the player to find Mina's story stop.
2. Mina naturally hands off to Leo in the classroom.
3. Leo asks the player to tidy the classroom, then sends the player to Nora.
4. Nora introduces the garden and asks the player to find the bird.

## Remaining Manual Checks

- Confirm dialogue boxes show one short line per screen on the target resolution.
- Confirm reward UI uses `reward_name` from quest data and does not hard-code older reward names.
- Confirm children can complete the drag task without needing the removed long dialogue instruction.
