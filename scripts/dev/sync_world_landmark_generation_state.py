#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LAYER_MAP_PATH = ROOT / "data/maps/sunshine_world_layer_map_v001.json"
DEFAULT_MANIFEST_PATH = ROOT / "assets/source_prompts/maps/world_landmark_assets_manifest_v001.json"

SOURCE_CONFIG = {
    "built_in_imagegen": {
        "asset_status": "generated_builtin_imagegen",
        "generation_status": "generated_builtin_imagegen_complete",
    },
    "local_fallback": {
        "asset_status": "generated_local_image_generator_fallback",
        "generation_status": "generated_local_image_generator_fallback_complete",
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Synchronize world landmark generation metadata after landmark PNGs "
            "have been regenerated."
        )
    )
    parser.add_argument(
        "--source",
        choices=sorted(SOURCE_CONFIG.keys()),
        required=True,
        help="Target generation source to write into the world layer map and manifest.",
    )
    parser.add_argument(
        "--layer-map",
        type=Path,
        default=DEFAULT_LAYER_MAP_PATH,
        help="Path to sunshine_world_layer_map_v001.json.",
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        default=DEFAULT_MANIFEST_PATH,
        help="Path to world_landmark_assets_manifest_v001.json.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the planned update summary without writing files.",
    )
    return parser.parse_args()


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Missing file: {path}") from exc


def write_json(path: Path, data: Any) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def to_resource_path(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def resolve_resource_path(resource_path: str) -> Path:
    if not resource_path.startswith("res://"):
        raise SystemExit(f"Expected res:// path, got: {resource_path}")
    return ROOT / resource_path.removeprefix("res://")


def collect_landmark_objects(layer_map: dict[str, Any]) -> list[dict[str, Any]]:
    landmarks: list[dict[str, Any]] = []
    for layer in layer_map.get("object_layers", []):
        if not isinstance(layer, dict):
            continue
        for obj in layer.get("objects", []):
            if not isinstance(obj, dict):
                continue
            if str(obj.get("type", "")) == "landmark_asset":
                landmarks.append(obj)
    return landmarks


def collect_manifest_assets(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    assets = manifest.get("assets", [])
    return [asset for asset in assets if isinstance(asset, dict)]


def ensure_assets_exist(entries: list[dict[str, Any]], label: str) -> None:
    missing: list[str] = []
    for entry in entries:
        asset_path = str(entry.get("asset_path", ""))
        if not asset_path:
            missing.append(f"{label}:<missing asset_path>")
            continue
        absolute_path = resolve_resource_path(asset_path)
        if not absolute_path.exists():
            missing.append(asset_path)
    if missing:
        joined = "\n".join(f"  - {item}" for item in missing)
        raise SystemExit(
            f"Cannot mark landmark assets as generated while files are missing:\n{joined}"
        )


def sync_generation_state(
    layer_map: dict[str, Any],
    manifest: dict[str, Any],
    source: str,
) -> dict[str, int]:
    config = SOURCE_CONFIG[source]
    landmark_objects = collect_landmark_objects(layer_map)
    manifest_assets = collect_manifest_assets(manifest)

    ensure_assets_exist(landmark_objects, "layer_map")
    ensure_assets_exist(manifest_assets, "manifest")

    for obj in landmark_objects:
        obj["preferred_generation"] = "built_in_imagegen"
        obj["generation_source"] = source
        obj["asset_status"] = config["asset_status"]

    for asset in manifest_assets:
        asset["preferred_generation"] = "built_in_imagegen"
        asset["current_source"] = source

    manifest["preferred_tool"] = "built_in_imagegen"
    manifest["current_source"] = source

    asset_generation = layer_map.setdefault("asset_generation", {})
    asset_generation["mode"] = "built_in_imagegen_with_local_script_fallback"
    asset_generation["preferred_tool"] = "built_in_imagegen"
    asset_generation["current_source"] = source
    asset_generation["status"] = config["generation_status"]
    if source == "local_fallback":
        asset_generation["fallback_tool"] = "tools/image_generator.js"

    return {
        "landmark_object_count": len(landmark_objects),
        "manifest_asset_count": len(manifest_assets),
    }


def main() -> int:
    args = parse_args()
    layer_map_path = args.layer_map.resolve()
    manifest_path = args.manifest.resolve()
    layer_map = load_json(layer_map_path)
    manifest = load_json(manifest_path)

    expected_manifest_resource = str(
        layer_map.get("asset_generation", {}).get("prompt_manifest", "")
    )
    if expected_manifest_resource:
        actual_manifest_resource = to_resource_path(manifest_path)
        if expected_manifest_resource != actual_manifest_resource:
            raise SystemExit(
                "Layer-map prompt_manifest does not match the selected manifest path:\n"
                f"  layer_map: {expected_manifest_resource}\n"
                f"  script:    {actual_manifest_resource}"
            )

    counts = sync_generation_state(layer_map, manifest, args.source)

    print(
        "Prepared world landmark metadata update:\n"
        f"  source: {args.source}\n"
        f"  layer_map: {layer_map_path}\n"
        f"  manifest: {manifest_path}\n"
        f"  landmark_objects: {counts['landmark_object_count']}\n"
        f"  manifest_assets: {counts['manifest_asset_count']}\n"
        f"  generation_status: {SOURCE_CONFIG[args.source]['generation_status']}"
    )

    if args.dry_run:
        print("Dry run only. No files were written.")
        return 0

    write_json(layer_map_path, layer_map)
    write_json(manifest_path, manifest)
    print("Updated world landmark generation metadata.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
