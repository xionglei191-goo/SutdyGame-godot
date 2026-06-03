# Home Decor Props v001

> Date: 2026-06-02  
> Tool: Codex built-in image generation tool  
> Runtime target: `HomeLayer/DecorSlot_Rug` and `HomeLayer/DecorSlot_Cape`

## Outputs

| Asset | Runtime role |
|---|---|
| `assets/generated/props/home/prop_star_rug_placed_v001.png` | visible after owning `star_rug` |
| `assets/generated/props/home/prop_explorer_cape_display_v001.png` | visible after owning `explorer_cape` |

## Prompt Pattern

Original home decor props for a children's life-adventure RPG: a pastel star rug placed on the floor and a friendly explorer cape display on a simple hook or stand. Both images use cozy child-safe home decor styling and avoid readable text, logos, existing IP, brand elements, trademarks, and watermarks.

Transparent-output workflow: generated on a flat `#00ff00` chroma-key background, then processed locally with the Codex imagegen chroma-key removal helper. The rug is resized to `512x256`; cape display is resized to `512x512`.

## Safety Review

- Style pass: bright pastel home adventure props.
- Age pass: child-safe decor and outfit display.
- Copyright pass: no brands, logos, text, or existing IP.
- Usability pass: connected through `HomeDecorRenderer` and existing `owned_items` state.
