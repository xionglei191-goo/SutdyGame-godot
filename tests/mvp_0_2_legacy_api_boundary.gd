extends SceneTree

const PRODUCTION_SCRIPT_DIRS := [
	"res://scripts"
]

const DISALLOWED_LEGACY_PATTERNS := [
	"hotspot_matches_lesson"
]

const ALLOWED_LEGACY_PATTERNS := {
	"start_lesson(": [
		"res://scripts/systems/quest_diary.gd"
	],
	"get_lesson_id(": [
		"res://scripts/systems/quest_diary.gd"
	],
	"set_lesson_id(": [
		"res://scripts/systems/quest_diary.gd"
	],
	"get_current_lesson(": [
		"res://scripts/systems/quest_diary.gd"
	],
	"set_current_lesson_id(": [
		"res://scripts/maps/scene_host.gd",
		"res://scripts/minigames/scene_click_game.gd"
	],
	"set_task_active(": [
		"res://scripts/maps/scene_host.gd",
		"res://scripts/minigames/scene_click_game.gd"
	],
	"is_task_active(": [
		"res://scripts/minigames/scene_click_game.gd"
	],
	"complete_task(": [
		"res://scripts/core/game_state.gd"
	],
	"has_completed_task(": [
		"res://scripts/core/game_state.gd"
	]
}

var failed := false


func _initialize() -> void:
	for dir_path: String in PRODUCTION_SCRIPT_DIRS:
		for path: String in _collect_gd_files(dir_path):
			_assert_legacy_usage_allowed(path)
	if failed:
		quit(1)
		return
	print("mvp_0_2_legacy_api_boundary passed.")
	quit(0)


func _collect_gd_files(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(dir_path)
	_assert(dir != null, "script directory should open: %s" % dir_path)
	if dir == null:
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		var path := "%s/%s" % [dir_path, file_name]
		if dir.current_is_dir():
			paths.append_array(_collect_gd_files(path))
		elif file_name.ends_with(".gd"):
			paths.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths


func _assert_legacy_usage_allowed(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "script file should open: %s" % path)
	if file == null:
		return
	var text := file.get_as_text()
	for pattern: String in DISALLOWED_LEGACY_PATTERNS:
		_assert(not text.contains(pattern), "retired legacy API pattern should not appear in production scripts: %s in %s" % [pattern, path])
	for pattern: String in ALLOWED_LEGACY_PATTERNS.keys():
		if not text.contains(pattern):
			continue
		var allowed_paths: Array = ALLOWED_LEGACY_PATTERNS[pattern]
		_assert(allowed_paths.has(path), "legacy API pattern should only appear in documented compatibility wrappers: %s in %s" % [pattern, path])


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
