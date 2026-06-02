#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

GODOT_BIN="${GODOT_BIN:-godot}"
PREFLIGHT="res://tests/mvp_0_2_manual_playtest_preflight.gd"
POSTFLIGHT="res://tests/mvp_0_2_manual_playtest_postflight.gd"
FINAL_GATE="res://tests/mvp_0_2_manual_final_gate.gd"
LOG_DIR="$(mktemp -d)"

if [[ ! -t 0 ]]; then
	echo "This manual playtest runner requires an interactive terminal for external stopwatch confirmation." >&2
	echo "Run the documented preflight, Godot launch, postflight, and final gate commands manually in non-interactive environments." >&2
	exit 2
fi

cleanup() {
	local status=$?
	if (( status == 0 )); then
		rm -rf "$LOG_DIR"
	else
		echo "Manual playtest logs kept for diagnosis: $LOG_DIR" >&2
	fi
	exit "$status"
}
trap cleanup EXIT

run_checked() {
	local log_file
	log_file="$LOG_DIR/manual_$(printf '%s' "$*" | tr -c '[:alnum:]' '_').log"
	set +e
	"$@" 2>&1 | tee "$log_file"
	local cmd_status=${PIPESTATUS[0]}
	set -e
	if (( cmd_status != 0 )); then
		echo "Command failed with exit code $cmd_status: $*" >&2
		return "$cmd_status"
	fi
	if grep -E "SCRIPT ERROR|ERROR:|FATAL:" "$log_file" >/dev/null; then
		echo "Godot emitted an error-level log: $*" >&2
		grep -n -E "SCRIPT ERROR|ERROR:|FATAL:" "$log_file" >&2
		return 1
	fi
}

echo "==> 1/3 Preflight: clean default save/report/summary and verify the start line"
run_checked "$GODOT_BIN" --headless --path . -s "$PREFLIGHT"

echo
echo "==> 2/3 Manual playtest"
echo "Start your external stopwatch now."
echo "In game: complete Welcome Box, First Trip, Walk With Mina, Room Helper, Bird Watch, finish all 25 Story Show prompts, read the parent summary, click 完成摘要阅读, stop the stopwatch, click 导出计时报告, then close the game window."
read -r -p "Press Enter when the external stopwatch is ready..."
run_checked "$GODOT_BIN" --path .

echo
echo "==> 3/3 Postflight: validate report and export Markdown summary"
run_checked "$GODOT_BIN" --headless --path . -s "$POSTFLIGHT"

echo
echo "Manual playtest report and summary are ready."
echo "Next manual steps:"
echo "1. Open user://mvp_0_2_playtest_report_summary.md and paste Timing Record Paste plus Segment Timing Helper into docs/development/MVP_0_2_试玩计时记录.md."
echo "2. Fill external stopwatch segment times and choose exactly one result: pass / conditional_pass / fail."
echo "3. Update docs/development/MVP_0_2_验收记录.md only if the human result supports it."
echo "4. Run final gate after documents are filled:"
echo "   $GODOT_BIN --headless --path . -s $FINAL_GATE"
