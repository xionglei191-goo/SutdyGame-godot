# Life-Adventure Prop, Reward, and UI Icon Prompt v001

Prompt set maintained on 2026-06-02. This file is both the broad icon-generation prompt and an asset status list; not every prompt target has been generated or connected to runtime.

For the new MVP P0.5/P0.7/P1.7 slice, prefer the focused prompt records before regenerating broad atlas art:

- `assets/source_prompts/props/home_pet_care_props_v001.md`
- `assets/source_prompts/props/reward_place_card_ui_prompts_v001.md`
- `assets/source_prompts/maps/home_pet_corner_refinement_v001.md`

## Files

### Generated Runtime / Current Life-Adventure Support

- `assets/generated/props/room/prop_book_v001.png`
- `assets/generated/props/room/prop_pencil_v001.png`
- `assets/generated/props/room/prop_schoolbag_blue_v001.png`
- `assets/generated/props/room/prop_desk_v001.png`
- `assets/generated/props/room/prop_shelf_v001.png`
- `assets/generated/props/garden/prop_tree_v001.png`
- `assets/generated/props/garden/prop_flowers_v001.png`
- `assets/generated/props/garden/prop_bird_v001.png`
- `assets/generated/props/garden/prop_bench_v001.png`
- `assets/generated/rewards/reward_adventure_star_piece_v001.png`
- `assets/generated/rewards/reward_tidy_badge_piece_v001.png`
- `assets/generated/rewards/reward_garden_leaf_piece_v001.png`
- `assets/generated/ui/ui_dialogue_ornament_v001.png`
- `assets/generated/ui/ui_quest_diary_ornament_v001.png`
- `assets/generated/ui/ui_memory_spark_ornament_v001.png`
- `assets/generated/ui/ui_reward_sparkle_v001.png`
- `assets/generated/props/home/prop_pet_bowl_v001.png`
- `assets/generated/props/home/prop_pet_food_v001.png`
- `assets/generated/props/home/prop_pet_toy_v001.png`
- `assets/generated/props/home/prop_soap_v001.png`
- `assets/generated/rewards/reward_first_trip_ticket_v001.png`
- `assets/generated/ui/ui_place_card_ornament_v001.png`

### Generated Backup / School-Cluster Support

- `assets/generated/props/school/prop_classroom_icon_v001.png`
- `assets/generated/props/school/prop_library_icon_v001.png`
- `assets/generated/props/school/prop_playground_icon_v001.png`

### Pending Generation

- `assets/generated/props/town/prop_place_card_visit_v001.png`
- `assets/generated/props/town/prop_shop_bag_v001.png`
- `assets/generated/props/town/prop_ticket_v001.png`

### Runtime Status Notes

- Runtime currently uses the room icons `prop_book_v001.png`, `prop_pencil_v001.png`, and `prop_schoolbag_blue_v001.png` in `DragPlaceGame`.
- `first_trip_ticket` now uses standalone `reward_first_trip_ticket_v001.png` through `data/rewards/reward_icons_v001.json`.
- School, garden, desk/shelf, and UI ornament PNGs are generated asset-library items, but are not proof of direct `TownMap.tscn` or UI scene wiring.
- The generated pet-care, First Trip Ticket, and PlaceCard ornament assets must remain original: no external IP, logos, brands, trademarks, readable packaging, real transit marks, or store/school logos.

## Prompt

Create a clean atlas of original pastel game icons for a children's English life-adventure RPG with a child-friendly town-exploration tone. Include separate centered icons for:

- classroom building
- library building
- playground slide
- pet bowl
- pet food
- pet ball toy
- soap
- book
- pencil
- school bag
- desk
- shelf
- tree
- flower bunch
- small bird
- bench
- place-card visit icon
- shop bag
- ticket
- First Trip ticket reward
- Adventure Star reward
- tidy badge reward
- garden leaf reward
- dialogue ornament
- quest diary ornament
- place card ornament
- memory spark ornament
- reward sparkle ornament

One image with separate icons arranged in a tidy grid, each icon centered in its own invisible cell with generous padding and no overlap. Use a perfectly flat solid `#00ff00` chroma-key background for background removal. No cast shadows, no contact shadows, no reflections. Do not use `#00ff00` anywhere in the icons. No readable text.

Style: cute readable mobile game icons, pastel toy-town style, clean outline, high readability at 64x64, polished, original. No logo, no text, no existing IP, no brand elements, no watermark, no scary or mature content.
