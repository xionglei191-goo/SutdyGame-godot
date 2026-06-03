# School Subscene Backgrounds v002

> Date: 2026-06-02  
> Tool: Codex built-in image generation tool  
> Runtime target: `ClassroomLayer/Background` and `GardenLayer/Background`

## Outputs

| Asset | Runtime role |
|---|---|
| `assets/generated/maps/classroom/map_classroom_interior_v002.png` | classroom background |
| `assets/generated/maps/garden/map_garden_bg_v002.png` | garden background |

## Prompt Pattern

Original bright pastel 16:9 Godot backgrounds for a children's English life-adventure RPG. The classroom prompt preserved clear desk and shelf regions for existing click targets; the garden prompt preserved flower bed, bench, tree, and bird regions. Both prompts forbid readable text, logos, existing IP, brand elements, trademarks, and watermarks.

Post-processing workflow: generated as wide background images, then resized and center-cropped locally to exact `1280x720` PNGs.

## Safety Review

- Style pass: bright pastel toy-town environment art.
- Age pass: safe, warm, child-friendly places.
- Copyright pass: no brands, logos, readable text, or existing IP.
- Usability pass: connected in the split school subscenes under `SceneHost.tscn`; existing interaction hit areas remain separate.
