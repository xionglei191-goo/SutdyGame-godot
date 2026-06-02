extends SceneTree

const REQUIRED_HOME_PROLOGUE_QUESTS := [
	"prologue_letter_box",
	"prologue_room_starter",
	"prologue_pet_hello",
	"prologue_home_pet_care",
	"prologue_go_to_school"
]
const REQUIRED_REVIEW_ID := "mvp_0_2_review_challenge"


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	game_state.reset_progress()
	var required_home_quests := _required_home_quests()

	_complete_home_gate(game_state)
	game_state.complete_review(REQUIRED_REVIEW_ID)
	var result: Dictionary = game_state.confirm_parent_bonus(required_home_quests, REQUIRED_REVIEW_ID)
	_assert(bool(result.get("success", false)), "new home prologue Parent Bonus gate should confirm after home-first quests and Story Show")
	_assert(game_state.parent_bonus == game_state.PARENT_BONUS_REWARD, "new gate should add one Parent Bonus reward")
	_assert(game_state.has_story_flag(game_state.PARENT_BONUS_CONFIRM_FLAG), "new gate should write the versioned home prologue flag")
	_assert(not game_state.has_story_flag(game_state.LEGACY_PARENT_BONUS_CONFIRM_FLAG), "new gate should not rewrite the legacy flag")
	result = game_state.confirm_parent_bonus(required_home_quests, REQUIRED_REVIEW_ID)
	_assert(not bool(result.get("success", false)), "new gate should be idempotent on repeat confirmation")
	_assert(game_state.parent_bonus == game_state.PARENT_BONUS_REWARD, "repeat confirmation should not add Parent Bonus again")

	game_state.reset_progress()
	_complete_home_gate(game_state)
	game_state.complete_review(REQUIRED_REVIEW_ID)
	game_state.mark_story_flag(game_state.LEGACY_PARENT_BONUS_CONFIRM_FLAG)
	result = game_state.confirm_parent_bonus(required_home_quests, REQUIRED_REVIEW_ID)
	_assert(not bool(result.get("success", false)), "legacy confirmation flag should prevent duplicate reward after migration")
	_assert(game_state.parent_bonus == game_state.DEFAULT_PARENT_BONUS, "legacy-confirmed migrated save should not receive another Parent Bonus")
	_assert(game_state.has_confirmed_parent_bonus(), "legacy flag should still count as parent bonus confirmed")

	game_state.reset_progress()
	for quest_id: String in ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"]:
		game_state.complete_quest(quest_id)
	game_state.complete_review(REQUIRED_REVIEW_ID)
	result = game_state.confirm_parent_bonus(required_home_quests, REQUIRED_REVIEW_ID)
	_assert(not bool(result.get("success", false)), "old formal MVP quests alone should not satisfy the new Parent Bonus gate")
	_assert(game_state.parent_bonus == game_state.DEFAULT_PARENT_BONUS, "old gate alone should not add Parent Bonus after migration")

	_assert_missing_first_trip_completion_migrates(game_state)
	_assert_legacy_report_gate_can_finish_without_home_first(game_state)

	print("mvp_0_2_parent_bonus_gate_migration passed.")
	game_state.reset_progress()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))
	quit(0)


func _complete_home_gate(game_state: Node) -> void:
	for quest_id: String in REQUIRED_HOME_PROLOGUE_QUESTS:
		game_state.complete_quest(quest_id)


func _required_home_quests() -> Array[String]:
	var result: Array[String] = []
	for quest_id: String in REQUIRED_HOME_PROLOGUE_QUESTS:
		result.append(quest_id)
	return result


func _assert_missing_first_trip_completion_migrates(game_state: Node) -> void:
	var save_path := "user://mvp_0_2_missing_first_trip_completion_save.json"
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	_assert(file != null, "missing First Trip migration fixture should open")
	file.store_string(JSON.stringify({
		"completed_quests": [
			"prologue_letter_box",
			"prologue_room_starter",
			"prologue_pet_hello",
			"prologue_home_pet_care",
			"g4_u1_school_tour",
			"g4_u1_tidy_classroom",
			"g4_u1_garden_bird"
		],
		"completed_reviews": [REQUIRED_REVIEW_ID],
		"story_flags": [
			"prologue_letter_box_done",
			"prologue_room_starter_done",
			"prologue_pet_hello_done",
			"prologue_home_pet_care_done"
		],
		"playtest_elapsed_msec": 221928,
		"playtest_events": [
			{"id": "playtest_started", "label": "试玩开始", "elapsed_msec": 0},
			{"id": "prologue_go_to_school_started", "label": "First Trip 开始", "elapsed_msec": 49509},
			{"id": "g4_u1_school_tour_started", "label": "Walk With Mina 开始", "elapsed_msec": 112876},
			{"id": "g4_u1_school_tour_completed", "label": "Walk With Mina 完成", "elapsed_msec": 138644},
			{"id": "review_challenge_completed", "label": "Story Show 完成", "elapsed_msec": 221928}
		],
		"coins": game_state.DEFAULT_COINS,
		"parent_bonus": game_state.DEFAULT_PARENT_BONUS,
		"pet_name": game_state.DEFAULT_PET_NAME,
		"pet_state": game_state.DEFAULT_PET_STATE
	}, "\t"))
	file = null
	game_state.reset_progress()
	_assert(game_state.load_game(save_path), "missing First Trip completion fixture should load")
	_assert(game_state.has_completed_quest("prologue_go_to_school"), "load migration should backfill First Trip completed quest")
	_assert(game_state.has_story_flag("prologue_go_to_school_done"), "load migration should backfill First Trip story flag")
	_assert(game_state.has_story_flag("az_full_unlocked_after_prologue"), "load migration should backfill A-Z unlock flag")
	_assert(_has_event(game_state.playtest_events, "prologue_go_to_school_completed"), "load migration should backfill First Trip completed event")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))


func _has_event(events: Array, event_id: String) -> bool:
	for event: Dictionary in events:
		if str(event.get("id", "")) == event_id:
			return true
	return false


func _assert_legacy_report_gate_can_finish_without_home_first(game_state: Node) -> void:
	var save_path := "user://mvp_0_2_legacy_report_gate_save.json"
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	_assert(file != null, "legacy report gate fixture should open")
	file.store_string(JSON.stringify({
		"completed_quests": [
			"g4_u1_school_tour",
			"g4_u1_tidy_classroom",
			"g4_u1_garden_bird"
		],
		"completed_reviews": [REQUIRED_REVIEW_ID],
		"playtest_elapsed_msec": 180000,
		"playtest_completed": true,
		"playtest_events": [
			{"id": "playtest_started", "label": "试玩开始", "elapsed_msec": 0},
			{"id": "prologue_go_to_school_started", "label": "First Trip 开始", "elapsed_msec": 1},
			{"id": "g4_u1_school_tour_started", "label": "Walk With Mina 开始", "elapsed_msec": 1000},
			{"id": "g4_u1_school_tour_completed", "label": "Walk With Mina 完成", "elapsed_msec": 30000},
			{"id": "g4_u1_tidy_classroom_started", "label": "Room Helper 开始", "elapsed_msec": 40000},
			{"id": "g4_u1_tidy_classroom_completed", "label": "Room Helper 完成", "elapsed_msec": 60000},
			{"id": "g4_u1_garden_bird_started", "label": "Bird Watch 开始", "elapsed_msec": 70000},
			{"id": "g4_u1_garden_bird_completed", "label": "Bird Watch 完成", "elapsed_msec": 90000},
			{"id": "review_challenge_started", "label": "Story Show 开始", "elapsed_msec": 100000},
			{"id": "review_challenge_completed", "label": "Story Show 完成", "elapsed_msec": 150000},
			{"id": "parent_summary_shown", "label": "家长摘要显示", "elapsed_msec": 150000},
			{"id": "parent_summary_read", "label": "家长摘要阅读完成", "elapsed_msec": 170000},
			{"id": "playtest_completed", "label": "试玩完成", "elapsed_msec": 180000}
		],
		"coins": game_state.DEFAULT_COINS,
		"parent_bonus": game_state.DEFAULT_PARENT_BONUS,
		"pet_name": game_state.DEFAULT_PET_NAME,
		"pet_state": game_state.DEFAULT_PET_STATE
	}, "\t"))
	file = null
	game_state.reset_progress()
	_assert(game_state.load_game(save_path), "legacy report gate fixture should load")
	_assert(game_state.save_playtest_report("user://mvp_0_2_legacy_report_gate_report.json"), "legacy report gate should allow report export after migration")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://mvp_0_2_legacy_report_gate_report.json"))


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
