# Sunshine World Overview v006 Modern Game Map Candidate

> Date: 2026-06-03
> Status: generated and copied into the project asset tree
> Intended output: `assets/generated/maps/world/map_sunshine_world_overview_v006.png`
> Generated source file: `/home/xionglei/.codex/generated_images/019e8be4-8ef6-7ee0-8da2-0006decf8d95/ig_08241fdbc7fabef3016a1fca9a44488195be37c6ae1cfdb29e.png`

## Goal

Generate a modern child-friendly game background version of the accepted v009 road network and post-office layout. Preserve the confirmed spatial relationships and routing logic, but avoid the classical watercolor / storybook look from v005. The target is a clean contemporary 2D / 2.5D mobile game map background suitable for `world_overview`.

## Built-In Image Generation Prompt

```text
Use case: stylized-concept
Asset type: 2560x1440 world overview background for a modern 2D children's life-adventure RPG map.
Primary request: Create a modern polished 2D / 2.5D mobile game map based on the provided v009 layout reference. Preserve the road network, district placement, and post-office layout from the reference, while making the final image feel like a contemporary colorful game background, not a classical watercolor illustration and not a flat planning diagram.
Input image: Reference image is a layout and road-network guide only. Keep its composition and routing relationships; do not copy rough vector styling, hard outlines, arrows, or readable labels.

Scene/backdrop:
A bright modern children's game town map from a gentle top-down / 2.5D perspective. The world starts at a cozy home on the left, moves into a contained school campus in the upper middle, continues into a town shopping street in the lower middle, then expands to transport and wider-world travel areas on the right. Use clean modern shapes, crisp but soft edges, bright balanced colors, subtle ambient occlusion, simple stylized grass, neat roads, compact buildings, modern playground pieces, and readable landmark silhouettes.

Locked layout and routing:
- Keep home on the left side as the opening anchor.
- Keep the main road from home bending down toward the school gate / school side, not cutting directly across the campus and not pointing straight to the playground.
- Keep Sunshine School as one visually contained school footprint in the upper-middle area.
- Keep classroom, library, canteen, art room, music room, playground, garden, and gate inside or directly attached to the school footprint.
- Keep canteen and playground visually inside the school campus, not floating as separate town landmarks.
- Keep the school internal paths smaller and softer than the town roads.
- Keep a clear horizontal town road below the school.
- Keep the post office on the lower-left town road frontage, near the bus station / taxi side and before the bookshop.
- Keep bookshop, restaurant, supermarket, pet shop, clothes shop, and general store clustered along the town roads with clear street frontage.
- Keep the town road connected to the right-side transport/world area through a main junction.
- Keep bus station and taxi connected to the town road on the left/lower-left side.
- Keep railway station, road/rail corridor, travel route, and wider-world area on the right side.
- Keep a right-side world/travel zone with open blue-green landscape, trees, travel road, railway, and simple far-travel landmark shapes.
- Do not add new gameplay places beyond the reference layout.
- Do not bake A-Z memory anchors, route arrows, hotspot rectangles, UI labels, or dialogue elements into this background.

Modern game art direction:
Original child-friendly life-adventure game map art, contemporary mobile game background style, clean 2D / 2.5D rendering, smooth color blocking, soft gradients only for lighting, crisp readable silhouettes, playful but practical architecture, fresh town colors, modern road and sidewalk design, light material texture, subtle shadows, no heavy paper grain, no antique watercolor wash, no medieval or old European village feeling, no sepia, no classical storybook mood. It should feel like a modern cozy adventure game world for children age 7 to 12.

Visual hierarchy:
Main roads should be clear and continuous, with warm light road surfaces and clean curb edges. School internal paths should be narrower and quieter. Buildings should be colorful, modern, and simple enough for gameplay readability. Important districts must remain visually distinct: home, school, town shops, transport/world edge. Leave enough clean open space around landmarks for Godot hotspots and runtime UI overlays.

Text and symbols:
No readable text in the image. Do not write place names, school names, shop names, labels, arrows, legends, or UI callouts. Use visual silhouettes and generic symbols only. Runtime labels will be added separately by Godot.

Safety / exclusions:
No logo, no readable text, no existing IP, no brand elements, no trademark, no watermark, no real school name, no real map provider styling, no photorealism, no horror, no dark mood, no cluttered background, no hard vector-planning-diagram look, no classical watercolor, no antique paper texture, no vintage map look, no medieval village style.
```

## Acceptance Notes

- Compare the output against v009 for road logic, post-office placement, and macro district placement.
- Compare the output against v005 specifically to ensure the style moved away from classical watercolor and toward modern game background art.
- Runtime replacement is out of scope until hotspot alignment and viewport screenshots are regenerated.
