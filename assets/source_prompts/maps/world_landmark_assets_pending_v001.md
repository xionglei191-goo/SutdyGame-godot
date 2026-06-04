# Sunshine World Landmark Assets v001

> Date: 2026-06-03  
> Status: generated through local fallback on 2026-06-04 because the current Codex session did not expose the built-in image generation tool  
> Runtime data: `data/maps/sunshine_world_layer_map_v001.json`  
> Machine-readable manifest: `assets/source_prompts/maps/world_landmark_assets_manifest_v001.json`  
> Preferred path: use the built-in image generation interface for future landmark batches when available.  
> Local fallback result: the first landmark batch was generated with `tools/image_generator.js`, then converted to transparent PNGs with the local chroma-key helper.

## Built-In Regen Contract

When the built-in image generation interface is available again, regenerate the same file set in place under `assets/generated/maps/world/landmarks/` and then update `data/maps/sunshine_world_layer_map_v001.json`:

- Set each landmark `generation_source` from `local_fallback` to `built_in_imagegen`.
- Keep `preferred_generation` as `built_in_imagegen`.
- Set `asset_generation.current_source` to `built_in_imagegen`.
- Replace `asset_generation.status` with `generated_builtin_imagegen_complete` during that migration.
- Run `python3 scripts/dev/sync_world_landmark_generation_state.py --source built_in_imagegen` after the regenerated PNG files are in place.
- Run `python3 scripts/dev/verify_world_landmark_generation_state.py --expected-source built_in_imagegen` before the Godot smoke checks.

The current Codex session did not expose the built-in image generation tool. Per project asset rules, the prompts below were used with the local `tools/image_generator.js` fallback. Source chroma-key images were written under ignored `tmp/imagegen/`; final transparent PNGs were saved under `assets/generated/maps/world/landmarks/`.

## Shared Style

Use case: stylized-concept  
Asset type: transparent-feeling top-down / 2.5D landmark sprite for a children’s English life-adventure RPG world map  
Style/medium: polished modern 2D / 2.5D game-map landmark, clean shapes, soft crisp edges, child-friendly, bright but balanced colors, subtle ambient occlusion, no text  
Composition/framing: isolated building or transport landmark, centered, generous padding, readable at small map scale, no surrounding map labels  
Lighting/mood: bright daytime, warm and inviting  
Constraints: no readable text, no logos, no trademarked design, no UI, no arrows, no place labels, no watermark, no existing IP  
Background: flat removable chroma-key background if transparency is needed through the built-in imagegen workflow

## Generated Assets

### `assets/generated/maps/world/landmarks/landmark_home_v001.png`

Primary request: A cozy child-friendly home landmark for the left-side opening anchor of Sunshine World, small house with warm roof, garden feeling, simple family-life details, no readable text.

### `assets/generated/maps/world/landmarks/landmark_sunshine_school_v001.png`

Primary request: A contained modern school campus landmark for Sunshine World, friendly main building silhouette, courtyard footprint, classroom/library/playground feeling inside one readable campus shape, no readable school name or labels.

### `assets/generated/maps/world/landmarks/landmark_bookshop_v001.png`

Primary request: A small town bookshop landmark, cozy storefront silhouette with books implied through shapes only, child-friendly colors, no readable sign text.

### `assets/generated/maps/world/landmarks/landmark_post_office_v001.png`

Primary request: A small town post office landmark, friendly storefront or kiosk shape with parcel and envelope forms implied by simple geometry only, no readable sign text, no logo.

### `assets/generated/maps/world/landmarks/landmark_restaurant_v001.png`

Primary request: A cozy family restaurant landmark for a child-friendly town road, warm storefront silhouette with table, awning, or snack shapes implied visually, no readable menu or sign text.

### `assets/generated/maps/world/landmarks/landmark_park_v001.png`

Primary request: A compact park landmark for a town map, bright green open-space shape with path, tree, kite, or sunny play details, no labels, no UI symbols.

### `assets/generated/maps/world/landmarks/landmark_hospital_v001.png`

Primary request: A gentle care-place hospital landmark for a child-friendly town map, clean modern building silhouette with soft health-care color cues, no readable text, no real medical logo.

### `assets/generated/maps/world/landmarks/landmark_cinema_v001.png`

Primary request: A small cinema landmark for a town map, playful theater facade silhouette with poster-frame or screen shapes but no readable poster text, no logos.

### `assets/generated/maps/world/landmarks/landmark_clothes_shop_v001.png`

Primary request: A clothes shop landmark for a child-friendly town road, bright storefront silhouette with outfit or cape display shapes implied, no readable text, no fashion brand.

### `assets/generated/maps/world/landmarks/landmark_general_store_v001.png`

Primary request: A general store landmark for cozy room-decor shopping, compact storefront with home-goods shapes implied, no readable sign text, no brand elements.

### `assets/generated/maps/world/landmarks/landmark_pet_shop_v001.png`

Primary request: A friendly pet shop landmark for a child’s town map, soft storefront shape with pet-care hints such as bowl or paw-like abstract decoration, no readable text and no specific animal mascot requirement.

### `assets/generated/maps/world/landmarks/landmark_supermarket_v001.png`

Primary request: A compact supermarket landmark for a bright town shopping road, modern storefront silhouette with basket or awning shapes, no readable text or brand.

### `assets/generated/maps/world/landmarks/landmark_bus_station_v001.png`

Primary request: A bus station landmark connected to a town road, shelter roof and bus stop silhouette, friendly transport colors, no readable route number or text.

### `assets/generated/maps/world/landmarks/landmark_taxi_stand_v001.png`

Primary request: A taxi stand landmark for the transport edge of a child-friendly world map, small yellow taxi and stand silhouette, no readable text, no city branding.

### `assets/generated/maps/world/landmarks/landmark_railway_station_v001.png`

Primary request: A railway station landmark for the wider travel edge, compact station building with track/platform hint and clock-like shape without readable numbers or text.

### `assets/generated/maps/world/landmarks/landmark_airport_v001.png`

Primary request: A small airport landmark for the wider travel edge of Sunshine World, compact terminal and runway/plane-wing hints, friendly travel colors, no readable route text, no airline logo, no real airport branding.
