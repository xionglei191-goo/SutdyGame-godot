# Home Room Explore Props v001

> Date: 2026-06-02  
> Tool: Codex built-in image generation tool  
> Runtime target: `HomeLayer/HomeSpaces`

## Outputs

| Asset | Runtime role |
|---|---|
| `assets/generated/props/room/prop_lamp_v001.png` | `home_lamp` click target visual |
| `assets/generated/props/room/prop_clock_v001.png` | `home_clock` click target visual |
| `assets/generated/props/room/prop_window_v001.png` | `home_window` click target visual |

## Prompt Pattern

Original cozy home room props for a children's life-adventure RPG room exploration target, in bright pastel toy-town style. Each prop is centered, readable at small size, and avoids readable text, logos, existing IP, brand elements, trademarks, and watermarks.

Transparent-output workflow: generated on a flat `#00ff00` chroma-key background, then processed locally with the Codex imagegen chroma-key removal helper and resized to `256x256` PNG.

## Safety Review

- Style pass: matches the warm `HomeLayer` interior.
- Age pass: child-safe room objects.
- Copyright pass: no brands, logos, text, or existing IP.
- Usability pass: separate runtime Sprite2D nodes align with `scene_click_targets_v001.json`.
