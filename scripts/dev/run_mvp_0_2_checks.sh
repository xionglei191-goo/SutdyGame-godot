#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

GODOT_BIN="${GODOT_BIN:-godot}"
PREFLIGHT="res://tests/mvp_0_2_manual_playtest_preflight.gd"
MANUAL_PLAYTEST_SCRIPT="./scripts/dev/run_mvp_0_2_manual_playtest.sh"
LEGACY_PREPARE="res://tests/mvp_0_2_prepare_manual_playtest.gd"
LOG_DIR="$(mktemp -d)"

cleanup() {
	local status=$?
	local cleanup_status=0
	trap - EXIT
	echo
	echo "==> Final cleanup: manual playtest preflight"
	if ! run_checked "$GODOT_BIN" --headless --path . -s "$PREFLIGHT"; then
		echo "Cleanup preflight failed. Check default user:// save/report/summary before manual playtest." >&2
		cleanup_status=1
	fi
	if (( status == 0 && cleanup_status == 0 )); then
		rm -rf "$LOG_DIR"
	else
		echo "Logs kept for failure diagnosis: $LOG_DIR" >&2
	fi
	if (( cleanup_status != 0 )); then
		exit 1
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

run_manual_runner_checks() {
	local godot_stub
	local log_file
	echo
	echo "==> manual playtest runner shell checks"
	bash -n "$MANUAL_PLAYTEST_SCRIPT"
	godot_stub="$LOG_DIR/godot_should_not_run"
	printf '#!/usr/bin/env bash\nprintf "GODOT STUB WAS RUN\\n" >&2\nexit 99\n' >"$godot_stub"
	chmod +x "$godot_stub"
	log_file="$LOG_DIR/manual_runner_noninteractive.log"
	set +e
	GODOT_BIN="$godot_stub" "$MANUAL_PLAYTEST_SCRIPT" </dev/null >"$log_file" 2>&1
	local cmd_status=$?
	set -e
	cat "$log_file"
	if (( cmd_status != 2 )); then
		echo "Manual playtest runner should exit 2 without an interactive terminal, got $cmd_status" >&2
		return 1
	fi
	if ! grep -F "requires an interactive terminal" "$log_file" >/dev/null; then
		echo "Manual playtest runner should explain the interactive terminal requirement" >&2
		return 1
	fi
	if grep -E "GODOT STUB WAS RUN|Godot Engine|==> 1/3|--path" "$log_file" >/dev/null; then
		echo "Manual playtest runner should not launch Godot or preflight without an interactive terminal" >&2
		return 1
	fi
}

run_legacy_prepare_checks() {
	local log_file
	echo
	echo "==> legacy prepare script guard"
	log_file="$LOG_DIR/legacy_prepare.log"
	set +e
	"$GODOT_BIN" --headless --path . -s "$LEGACY_PREPARE" >"$log_file" 2>&1
	local cmd_status=$?
	set -e
	cat "$log_file"
	if (( cmd_status != 2 )); then
		echo "Legacy prepare script should exit 2, got $cmd_status" >&2
		return 1
	fi
	for expected in \
		"is legacy and no longer cleans manual playtest state" \
		"mvp_0_2_manual_playtest_readiness.gd" \
		"mvp_0_2_manual_playtest_preflight.gd" \
		"run_mvp_0_2_manual_playtest.sh"; do
		if ! grep -F "$expected" "$log_file" >/dev/null; then
			echo "Legacy prepare script should mention: $expected" >&2
			return 1
		fi
	done
}

run_manual_runner_checks
run_legacy_prepare_checks
run "$GODOT_BIN" --headless --path . --check-only --quit
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_manual_playtest_readiness.gd
run "$GODOT_BIN" --headless --path . -s res://tests/prototype_0_1_smoke.gd
run "$GODOT_BIN" --headless --path . -s res://tests/drag_place_game_smoke.gd
run "$GODOT_BIN" --headless --path . -s res://tests/story_show_smoke.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_docs_audit.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_quest_data_integrity.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_legacy_api_boundary.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_export_playtest_summary_fixture.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_completed_quests_report_boundary.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_report_export_guard.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_manual_playtest_postflight_fixture.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_timing_window_guard.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_full_report_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_manual_final_gate_fixture.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_real_docs_pending_final_gate.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_input_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_game_state_pet_care.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_game_state_owned_items.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_pet_visual_state_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_home_pet_care_input_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_home_room_explore_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_place_card_visit_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_non_school_place_card_matrix.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_place_card_visibility_data.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_place_card_action_authorization.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_bookshop_commission_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_town_commission_expansion_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_town_chapter1_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_transport_town_route_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_supermarket_pet_bowl_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_pet_shop_pet_ball_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_clothes_shop_parent_bonus_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_general_store_room_decor_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_memory_spark_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_az_unlock_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_world_hotspot_enablement.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_music_art_room_unlock_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_new_home_prologue_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_parent_bonus_gate_migration.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_world_overview_input_flow.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_smoke.gd
run "$GODOT_BIN" --headless --path . -s res://tests/mvp_0_2_visual_acceptance.gd

echo
echo "MVP 0.2 automated checks passed."
