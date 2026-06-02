extends SceneTree

const SUMMARY_PATH := "user://mvp_0_2_playtest_report_summary.md"
const TIMING_RECORD_PATH := "res://docs/development/MVP_0_2_试玩计时记录.md"
const ACCEPTANCE_PATH := "res://docs/development/MVP_0_2_验收记录.md"

var failed := false


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	var timing_record := _read_text(TIMING_RECORD_PATH)
	var acceptance := _read_text(ACCEPTANCE_PATH)
	var docs_pending := timing_record.contains("状态：待人工计时") and acceptance.contains("[ ] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录")
	var docs_completed := timing_record.contains("状态：人工计时完成") and timing_record.contains("- [x] 通过") and acceptance.contains("[x] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录")
	var docs_archived := timing_record.contains("历史人工计时记录") and acceptance.contains("历史验证记录")
	_assert(docs_pending or docs_completed or docs_archived, "readiness should accept pending, completed, or archived manual docs")
	var save_exists := FileAccess.file_exists(game_state.DEFAULT_SAVE_PATH)
	var report_exists := FileAccess.file_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH)
	var summary_exists := FileAccess.file_exists(SUMMARY_PATH)
	var clean_user_state := not save_exists and not report_exists and not summary_exists
	var completed_user_state := docs_completed and report_exists and summary_exists
	_assert(clean_user_state or completed_user_state, "readiness should allow either a clean manual-playtest start or a preserved completed-evidence user:// state")

	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	_assert(main_scene != null, "Main scene should load for manual playtest")

	if failed:
		quit(1)
		return
	print("MVP 0.2 manual playtest readiness passed.")
	if docs_pending:
		print("No default save/report/summary found; docs are pending manual timing; Main scene loads.")
	elif docs_archived:
		print("Manual docs are archived historical evidence; Main scene loads.")
	else:
		print("Completed manual evidence is preserved in docs and user:// artifacts; Main scene loads.")
	print("This check is read-only. It does not clean user://, instantiate Main, or start a playtest.")
	quit(0)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "document should be readable: %s" % path)
	if file == null:
		return ""
	return file.get_as_text()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
