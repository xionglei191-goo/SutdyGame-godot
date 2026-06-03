# NPC Portraits v001

> Date: 2026-06-02  
> Tool: Codex built-in image generation tool  
> Runtime target: future DialogueBox/NPC profile portrait support

## Outputs

| Asset | Runtime role |
|---|---|
| `assets/generated/characters/npcs/char_ava_portrait_neutral_v001.png` | Ava town-neighbor portrait baseline |

## Prompt Pattern

Original town NPC portrait named Ava for a children's English life-adventure RPG. Ava is a friendly adult town neighbor who supports greeting, weather, and time adventure quests. Shoulder-up portrait, warm and trustworthy expression, visually distinct from Mina/Leo/Nora, no readable text, no logo, no existing IP, no brand elements, no trademark, no watermark, and no realistic identifiable person.

Transparent-output workflow: generated on a flat `#00ff00` chroma-key background, then processed locally with the Codex imagegen chroma-key removal helper and resized to `512x512` PNG.

## Safety Review

- Style pass: bright pastel toy-town portrait.
- Age pass: friendly adult helper, child-safe presentation.
- Copyright pass: original character, no brands, logos, text, or existing IP.
- Usability pass: stored for the first town chapter portrait pipeline.
