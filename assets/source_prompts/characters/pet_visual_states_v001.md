# Pet Visual States v001

> Date: 2026-06-02  
> Tool: Codex built-in image generation tool  
> Runtime target: `HomeLayer/PetCorner/PetStateDisplay`

## Outputs

| Asset | Runtime role |
|---|---|
| `assets/generated/characters/pet/pet_mood_happy_v001.png` | mood >= 70 |
| `assets/generated/characters/pet/pet_mood_neutral_v001.png` | 40 <= mood < 70 |
| `assets/generated/characters/pet/pet_mood_sleepy_v001.png` | mood < 40 |
| `assets/generated/characters/pet/pet_action_eating_v001.png` | short feed feedback |
| `assets/generated/characters/pet/pet_action_playing_v001.png` | short play feedback |
| `assets/generated/characters/pet/pet_action_sleeping_v001.png` | short rest feedback |

## Prompt Pattern

Original cute small orange-and-cream puppy sprite for a children's English life-adventure RPG, matching `StudyGame` pastel toy-town style. Each image uses a clear centered full-body pose, soft rounded shapes, child-safe expression, no text, no logo, no existing IP, no brand elements, no trademark, and no watermark.

Transparent-output workflow: generated on a flat `#00ff00` chroma-key background, then processed locally with the Codex imagegen chroma-key removal helper and resized to `512x512` PNG.

## Safety Review

- Style pass: bright pastel toy-town game art.
- Age pass: friendly child-safe pet expressions.
- Copyright pass: original pet, no existing IP, logo, trademark, or readable text.
- Usability pass: transparent sprite files are connected through `PetVisualController`.
