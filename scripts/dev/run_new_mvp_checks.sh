#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

GODOT_BIN="${GODOT_BIN:-godot}"
LOG_DIR="$(mktemp -d)"

cleanup() {
	local status=$?
	if (( status == 0 )); then
		rm -rf "$LOG_DIR"
	else
		echo "Logs kept for failure diagnosis: $LOG_DIR" >&2
	fi
	exit "$status"
}
trap cleanup EXIT

run_checked() {
	local log_file
	log_file="$LOG_DIR/check_$(printf '%s' "$*" | tr -c '[:alnum:]' '_').log"
	set +e
	"$@" 2>&1 | tee "$log_file"
	local cmd_status=${PIPESTATUS[0]}
	set -e
	if (( cmd_status != 0 )); then
		echo "Command failed with exit code $cmd_status: $*" >&2
		return "$cmd_status"
	fi
	if grep -E "SCRIPT ERROR|SCRIPT ERROR:|ERROR:|FATAL:" "$log_file" >/dev/null; then
		echo "Godot emitted an error-level log while exit code was 0: $*" >&2
		grep -n -E "SCRIPT ERROR|SCRIPT ERROR:|ERROR:|FATAL:" "$log_file" >&2
		return 1
	fi
}

run() {
	echo
	echo "==> $*"
	run_checked "$@"
}

run "$GODOT_BIN" --headless --path . --check-only --quit
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_quest_data_integrity.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_game_state_pet_care.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_game_state_owned_items.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_home_pet_care_input_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_home_room_explore_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_pet_visual_state_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_new_home_prologue_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_parent_bonus_gate_migration.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_supermarket_pet_bowl_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_pet_shop_pet_ball_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_clothes_shop_parent_bonus_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_general_store_room_decor_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_non_school_place_card_matrix.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_place_card_visibility_data.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_place_card_action_authorization.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_town_commission_expansion_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_town_chapter1_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_transport_town_route_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_memory_spark_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_az_unlock_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_world_layer_map_data.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd

echo
echo "New MVP automated checks passed."
