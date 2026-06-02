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


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
