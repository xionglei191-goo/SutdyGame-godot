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

EXPECTED_STATUS_BY_SOURCE = {
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
            "Verify that world landmark asset files, manifest metadata, and world layer map "
            "generation metadata all agree."
        )
    )
    parser.add_argument(
        "--expected-source",
        choices=sorted(EXPECTED_STATUS_BY_SOURCE.keys()),
        help="Fail if the current landmark asset source does not match this value.",
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
    return parser.parse_args()


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Missing file: {path}") from exc


def resolve_resource_path(resource_path: str) -> Path:
    if not resource_path.startswith("res://"):
        raise SystemExit(f"Expected res:// path, got: {resource_path}")
    return ROOT / resource_path.removeprefix("res://")


def collect_landmark_objects(layer_map: dict[str, Any]) -> dict[str, dict[str, Any]]:
    results: dict[str, dict[str, Any]] = {}
    for layer in layer_map.get("object_layers", []):
        if not isinstance(layer, dict):
            continue
        for obj in layer.get("objects", []):
            if not isinstance(obj, dict):
                continue
            if str(obj.get("type", "")) != "landmark_asset":
                continue
            hotspot_id = str(obj.get("hotspot_id", ""))
            if hotspot_id:
                results[hotspot_id] = obj
    return results


def collect_manifest_assets(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    results: dict[str, dict[str, Any]] = {}
    for asset in manifest.get("assets", []):
        if not isinstance(asset, dict):
            continue
        hotspot_id = str(asset.get("hotspot_id", ""))
        if hotspot_id:
            results[hotspot_id] = asset
    return results


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def verify_asset_file(asset_path: str) -> Path:
    absolute_path = resolve_resource_path(asset_path)
    assert_true(absolute_path.exists(), f"Missing landmark asset file: {asset_path}")
    return absolute_path


def main() -> int:
    args = parse_args()
    layer_map = load_json(args.layer_map.resolve())
    manifest = load_json(args.manifest.resolve())

    asset_generation = layer_map.get("asset_generation", {})
    current_source = str(asset_generation.get("current_source", ""))
    preferred_tool = str(asset_generation.get("preferred_tool", ""))
    generation_status = str(asset_generation.get("status", ""))

    assert_true(preferred_tool == "built_in_imagegen", "World layer map should keep built_in_imagegen as preferred_tool")
    assert_true(current_source in EXPECTED_STATUS_BY_SOURCE, f"Unexpected current_source: {current_source}")
    if args.expected_source is not None:
        assert_true(
            current_source == args.expected_source,
            f"Expected current_source={args.expected_source}, got {current_source}",
        )

    expected_status = EXPECTED_STATUS_BY_SOURCE[current_source]["generation_status"]
    assert_true(
        generation_status == expected_status,
        f"Expected generation status {expected_status}, got {generation_status}",
    )

    manifest_preferred_tool = str(manifest.get("preferred_tool", ""))
    manifest_current_source = str(manifest.get("current_source", ""))
    assert_true(
        manifest_preferred_tool == "built_in_imagegen",
        "Landmark manifest should keep built_in_imagegen as preferred_tool",
    )
    assert_true(
        manifest_current_source == current_source,
        "Landmark manifest current_source should match world layer map current_source",
    )

    layer_landmarks = collect_landmark_objects(layer_map)
    manifest_assets = collect_manifest_assets(manifest)
    assert_true(layer_landmarks, "World layer map should define landmark assets")
    assert_true(manifest_assets, "Landmark manifest should define assets")
    assert_true(
        set(layer_landmarks.keys()) == set(manifest_assets.keys()),
        "Landmark manifest hotspot ids should match world layer map hotspot ids",
    )

    expected_asset_status = EXPECTED_STATUS_BY_SOURCE[current_source]["asset_status"]
    for hotspot_id, landmark in sorted(layer_landmarks.items()):
        manifest_entry = manifest_assets[hotspot_id]
        layer_asset_path = str(landmark.get("asset_path", ""))
        manifest_asset_path = str(manifest_entry.get("asset_path", ""))
        assert_true(layer_asset_path == manifest_asset_path, f"{hotspot_id}: asset_path mismatch")
        assert_true(
            str(landmark.get("preferred_generation", "")) == "built_in_imagegen",
            f"{hotspot_id}: preferred_generation should stay built_in_imagegen",
        )
        assert_true(
            str(manifest_entry.get("preferred_generation", "")) == "built_in_imagegen",
            f"{hotspot_id}: manifest preferred_generation should stay built_in_imagegen",
        )
        assert_true(
            str(landmark.get("generation_source", "")) == current_source,
            f"{hotspot_id}: generation_source should match current_source",
        )
        assert_true(
            str(manifest_entry.get("current_source", "")) == current_source,
            f"{hotspot_id}: manifest current_source should match current_source",
        )
        assert_true(
            str(landmark.get("asset_status", "")) == expected_asset_status,
            f"{hotspot_id}: asset_status should be {expected_asset_status}",
        )
        assert_true(
            len(str(manifest_entry.get("prompt", ""))) >= 32,
            f"{hotspot_id}: manifest prompt should be populated",
        )
        verify_asset_file(layer_asset_path)

    print(
        "World landmark generation metadata verified:\n"
        f"  current_source: {current_source}\n"
        f"  generation_status: {generation_status}\n"
        f"  landmark_count: {len(layer_landmarks)}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
