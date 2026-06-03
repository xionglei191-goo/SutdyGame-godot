# Sunshine World Overview v007 Square Runtime Map

> Date: 2026-06-03
> Status: generated from local v006 reference and connected to runtime
> Intended output: `assets/generated/maps/world/map_sunshine_world_overview_v007_square.png`
> Source reference: `assets/generated/maps/world/map_sunshine_world_overview_v006.png`

## Goal

Adjust the `world_overview` runtime map into a square canvas while preserving the modern polished child-friendly game-map style from v006. Keep the existing home, school, town, shop, transport, and wider-world spatial relationships readable for Godot hotspots.

## Local Processing

The current session did not expose the built-in image generation tool. To keep the project moving without switching to an external image-generation service, this asset was produced by deterministic local post-processing:

1. Use `map_sunshine_world_overview_v006.png` as the style and composition source.
2. Resize the v006 map content to `2560` px width, preserving its original aspect ratio.
3. Place the resized map content in the vertical center of a `2560x2560` canvas.
4. Fill the extra top and bottom space with a softened cover crop derived from v006, so the square asset keeps the same color, lighting, and texture family.
5. Feather the top and bottom edges of the sharp map insert to avoid a hard banner edge.

## Runtime Notes

- Runtime canvas size is now `2560x2560`.
- Existing hotspot `x`, `w`, and `h` values are preserved.
- Existing hotspot `y` values are offset downward by `560` px to align with the centered map content.
- Top and bottom blurred extension zones are visual padding only and should not host active hotspots.

## Future Native Generation Prompt

If a native image-generation pass is available later, regenerate a purpose-built square map with this prompt:

```text
Use case: stylized-concept
Asset type: 2560x2560 square world overview background for a modern 2D children's life-adventure RPG map.
Primary request: Create a square version of the modern polished 2D / 2.5D Sunshine World map in the style of map_sunshine_world_overview_v006. Preserve the same road network, district placement, post-office placement, home-left starting anchor, contained school campus, lower town shopping street, right-side transport corridor, railway station, and wider-world travel edge. The map must be a complete square composition, not a cropped horizontal banner.

Scene/backdrop:
A bright modern children's game town map from a gentle top-down / 2.5D perspective. The world starts at a cozy home on the left, moves into a contained school campus in the upper-middle area, continues into a town shopping street in the lower-middle area, then expands to transport and wider-world travel areas on the right. Use clean modern shapes, crisp but soft edges, bright balanced colors, subtle ambient occlusion, stylized grass, neat roads, compact buildings, modern playground pieces, and readable landmark silhouettes.

Composition constraints:
- Keep home visible as the opening anchor on the left.
- Keep Sunshine School visually contained in the upper-middle area.
- Keep classroom, library, canteen, art room, music room, playground, garden, and gate inside or directly attached to the school footprint.
- Keep the town shopping road below the school, with post office before bookshop and shops clustered along the road.
- Keep bus station and taxi connected to the lower-left town road.
- Keep railway station and travel corridor on the lower-right side.
- Keep right-side world/travel landscape connected to the main road.
- Use the extra square vertical space as meaningful surrounding landscape, roads, greenery, and travel edges, not empty blur or decorative filler.
- Do not add new gameplay places beyond the established layout.
- Do not bake A-Z memory anchors, route arrows, hotspot rectangles, UI labels, or dialogue elements into the background.

Text and symbols:
No readable text, no place names, no school name, no shop labels, no arrows, no legends, no UI callouts. Use generic visual silhouettes only.

Safety / exclusions:
No logo, no readable text, no existing IP, no brand elements, no trademark, no watermark, no real school name, no real map provider styling, no photorealism, no horror, no dark mood, no cluttered background, no classical watercolor, no antique paper texture, no vintage map look, no medieval village style.
```
