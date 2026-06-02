extends CanvasLayer

const QUEST_NAMES := {
	"prologue_letter_box": "Welcome Box",
	"prologue_go_to_school": "First Trip",
	"g4_u1_school_tour": "Walk With Mina",
	"town_bookshop_find_book": "Bookshop Helper",
	"g4_u1_tidy_classroom": "Room Helper",
	"g4_u1_garden_bird": "Bird Watch"
}

const REWARD_NAMES := {
	"welcome_box_star": "Welcome Box Star",
	"first_trip_ticket": "First Trip Ticket",
	"school_star_piece": "Adventure Star",
	"bookshop_leafmark": "Bookshop Leafmark",
	"tidy_badge_piece": "Room Helper Badge",
	"garden_leaf_piece": "Garden Leaf Charm"
}
const REQUIRED_QUEST_IDS: Array[String] = [
	"prologue_letter_box",
	"prologue_room_starter",
	"prologue_pet_hello",
	"prologue_home_pet_care",
	"prologue_go_to_school"
]
const LEGACY_REPORT_QUEST_IDS: Array[String] = [
	"prologue_go_to_school",
	"g4_u1_school_tour",
	"g4_u1_tidy_classroom",
	"g4_u1_garden_bird"
]
const REQUIRED_REVIEW_ID := "mvp_0_2_review_challenge"
const QUEST_DATA_DIR := "res://data/quests"

var _quest_data_cache: Dictionary = {}
var _reward_name_cache: Dictionary = {}

@onready var completed_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/CompletedValue
@onready var quests_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/QuestsValue
@onready var rewards_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/RewardsValue
@onready var playtime_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/PlaytimeValue
@onready var parent_bonus_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/ParentBonusValue
@onready var words_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/WordsValue
@onready var patterns_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/PatternsValue
@onready var review_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/ReviewValue
@onready var timeline_value: Label = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/TimelineValue
@onready var finish_reading_button: Button = $Panel/MarginContainer/VBoxContainer/FinishReadingButton
@onready var parent_bonus_button: Button = $Panel/MarginContainer/VBoxContainer/ParentBonusButton
@onready var export_report_button: Button = $Panel/MarginContainer/VBoxContainer/ExportReportButton
@onready var report_status_value: Label = $Panel/MarginContainer/VBoxContainer/ReportStatusValue


func _ready() -> void:
	finish_reading_button.pressed.connect(_on_finish_reading_pressed)
	parent_bonus_button.pressed.connect(_on_parent_bonus_pressed)
	export_report_button.pressed.connect(_on_export_report_pressed)
	refresh()


func refresh() -> void:
	var state := _parent_summary_state()
	var completed_quests := _completed_quests_from(state)
	completed_value.text = str(completed_quests.size())
	quests_value.text = _join_quest_titles_or_empty(completed_quests)
	rewards_value.text = _join_reward_names_or_empty(state.get("rewards", []))
	playtime_value.text = str(state.get("playtest_elapsed_text", "00:00"))
	parent_bonus_value.text = str(int(state.get("parent_bonus", 0)))
	words_value.text = _join_or_empty(state.get("learned_words", []))
	patterns_value.text = _join_or_empty(state.get("learned_patterns", []))
	review_value.text = _review_text(state)
	timeline_value.text = _timeline_text(state.get("playtest_events", []))
	var ready_to_finish := _ready_to_finish_playtest(state)
	var playtest_completed := bool(state.get("playtest_completed", false))
	finish_reading_button.disabled = playtest_completed or not ready_to_finish
	if playtest_completed:
		finish_reading_button.text = "摘要阅读已完成"
	elif ready_to_finish:
		finish_reading_button.text = "完成摘要阅读"
	else:
		finish_reading_button.text = "完成 home-first Quest 和 Story Show 后可用"
	var parent_bonus_confirmed := _parent_bonus_confirmed(state)
	var ready_for_parent_bonus := _ready_for_parent_bonus(state)
	parent_bonus_button.disabled = parent_bonus_confirmed or not ready_for_parent_bonus
	if parent_bonus_confirmed:
		parent_bonus_button.text = "Parent Bonus 已发放"
	elif ready_for_parent_bonus:
		parent_bonus_button.text = "发放 Parent Bonus +%d" % GameState.PARENT_BONUS_REWARD
	else:
		parent_bonus_button.text = "完成 home-first Quest 后可发放 Parent Bonus"
	export_report_button.disabled = not bool(state.get("playtest_completed", false))


func _join_or_empty(value: Variant) -> String:
	if typeof(value) != TYPE_ARRAY:
		return "-"
	var items: Array = value
	if items.is_empty():
		return "-"
	var text_items: Array[String] = []
	for item: Variant in items:
		text_items.append(str(item))
	return ", ".join(text_items)


func _join_mapped_or_empty(value: Variant, labels: Dictionary) -> String:
	if typeof(value) != TYPE_ARRAY:
		return "-"
	var items: Array = value
	if items.is_empty():
		return "-"
	var text_items: Array[String] = []
	for item: Variant in items:
		var key := str(item)
		text_items.append(str(labels.get(key, key)))
	return ", ".join(text_items)


func _join_quest_titles_or_empty(value: Variant) -> String:
	if typeof(value) != TYPE_ARRAY:
		return "-"
	var items: Array = value
	if items.is_empty():
		return "-"
	var text_items: Array[String] = []
	for item: Variant in items:
		text_items.append(_quest_title(str(item)))
	return ", ".join(text_items)


func _join_reward_names_or_empty(value: Variant) -> String:
	if typeof(value) != TYPE_ARRAY:
		return "-"
	var items: Array = value
	if items.is_empty():
		return "-"
	var text_items: Array[String] = []
	for item: Variant in items:
		text_items.append(_reward_name(str(item)))
	return ", ".join(text_items)


func _review_text(snapshot: Dictionary) -> String:
	var completed := _completed_quests_from(snapshot)
	if completed.is_empty():
		return "先从 home 出发，打开 Welcome Box。"
	if completed.has("prologue_letter_box") and not completed.has("prologue_go_to_school"):
		if not completed.has("prologue_room_starter"):
			return "接下来在 home 完成 Room Starter，找到出门要带的物品。"
		if not completed.has("prologue_pet_hello"):
			return "接下来认识 Coco，完成 Pet Hello。"
		if not completed.has("prologue_home_pet_care"):
			return "接下来照顾 Coco，完成 Home Pet Care。"
		return "接下来从 home 出发，完成 First Trip。"
	if completed.has("prologue_go_to_school") and not completed.has("g4_u1_school_tour"):
		return "接下来陪 Mina 继续 Walk With Mina，寻找 story stop。"
	if completed.has("g4_u1_school_tour") and not completed.has("g4_u1_tidy_classroom"):
		return "接下来去 story room，帮 Leo 做 Room Helper。"
	if completed.has("g4_u1_tidy_classroom") and not completed.has("g4_u1_garden_bird"):
		return "接下来去 garden，完成 Bird Watch。"
	if not _has_completed_required_quests(completed):
		return "先回看今天的 Quest clues，再继续下一个 Quest。"
	var completed_reviews: Array = snapshot.get("completed_reviews", [])
	if not completed_reviews.has(REQUIRED_REVIEW_ID):
		return "先完成 25 题 Story Show，再阅读家长摘要。"
	return "回看 Story Show 的 library、book、bird 线索和三句舞台台词。"


func _timeline_text(value: Variant) -> String:
	if typeof(value) != TYPE_ARRAY:
		return "-"
	var events: Array = value
	if events.is_empty():
		return "-"
	var text_items: Array[String] = []
	for event: Variant in events:
		if typeof(event) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = event
		text_items.append("%s %s" % [str(data.get("elapsed_text", "00:00")), str(data.get("label", ""))])
	return "\n".join(text_items)


func _ready_to_finish_playtest(snapshot: Dictionary) -> bool:
	var completed_quests := _completed_quests_from(snapshot)
	if not _has_completed_required_quests(completed_quests) and not _has_completed_legacy_report_quests(completed_quests):
		return false
	var completed_reviews: Array = snapshot.get("completed_reviews", [])
	return completed_reviews.has(REQUIRED_REVIEW_ID)


func _ready_for_parent_bonus(snapshot: Dictionary) -> bool:
	var completed_quests := _completed_quests_from(snapshot)
	if not _has_completed_required_quests(completed_quests):
		return false
	var completed_reviews: Array = snapshot.get("completed_reviews", [])
	return completed_reviews.has(REQUIRED_REVIEW_ID)


func _completed_quests_from(snapshot: Dictionary) -> Array:
	return snapshot.get("completed_quests", [])


func _has_completed_required_quests(completed_quests: Array) -> bool:
	for quest_id in REQUIRED_QUEST_IDS:
		if not completed_quests.has(quest_id):
			return false
	return true


func _has_completed_legacy_report_quests(completed_quests: Array) -> bool:
	for quest_id in LEGACY_REPORT_QUEST_IDS:
		if not completed_quests.has(quest_id):
			return false
	return true


func _parent_bonus_confirmed(snapshot: Dictionary) -> bool:
	var flags: Array = snapshot.get("story_flags", [])
	return flags.has(GameState.PARENT_BONUS_CONFIRM_FLAG) or flags.has(GameState.LEGACY_PARENT_BONUS_CONFIRM_FLAG)


func _on_finish_reading_pressed() -> void:
	if not _ready_to_finish_playtest(_parent_summary_state()):
		report_status_value.text = "请先完成 home-first Quest 和 25 题 Story Show。"
		refresh()
		return
	GameState.record_playtest_event("parent_summary_read", "家长摘要阅读完成")
	GameState.finish_playtest_timer()
	GameState.save_game()
	refresh()
	report_status_value.text = "计时已停止，可导出计时报告。"


func _on_parent_bonus_pressed() -> void:
	if not _ready_to_finish_playtest(_parent_summary_state()):
		report_status_value.text = "请先完成 home-first Quest 和 25 题 Story Show。"
		refresh()
		return
	var result := GameState.confirm_parent_bonus(REQUIRED_QUEST_IDS, REQUIRED_REVIEW_ID)
	GameState.save_game()
	refresh()
	report_status_value.text = str(result.get("message", "Parent Bonus checked."))


func _on_export_report_pressed() -> void:
	if GameState.save_playtest_report():
		var report_path := ProjectSettings.globalize_path(GameState.DEFAULT_PLAYTEST_REPORT_PATH)
		report_status_value.text = "计时报告已导出：%s" % report_path
	else:
		report_status_value.text = "计时报告导出失败。"


func _parent_summary_state() -> Dictionary:
	return GameState.get_parent_summary_state()


func _quest_title(quest_id: String) -> String:
	var quest_data := _load_quest_data(quest_id)
	var title := str(quest_data.get("title", ""))
	if not title.is_empty():
		return title
	return str(QUEST_NAMES.get(quest_id, quest_id))


func _reward_name(reward_id: String) -> String:
	if _reward_name_cache.has(reward_id):
		return str(_reward_name_cache[reward_id])
	var from_quests := _reward_name_from_quest_data(reward_id)
	if not from_quests.is_empty():
		_reward_name_cache[reward_id] = from_quests
		return from_quests
	return str(REWARD_NAMES.get(reward_id, reward_id))


func _reward_name_from_quest_data(reward_id: String) -> String:
	var dir := DirAccess.open(QUEST_DATA_DIR)
	if dir == null:
		return ""
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var quest_id := file_name.get_basename()
			var quest_data := _load_quest_data(quest_id)
			if str(quest_data.get("reward_id", "")) == reward_id:
				dir.list_dir_end()
				return str(quest_data.get("reward_name", ""))
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""


func _load_quest_data(quest_id: String) -> Dictionary:
	if _quest_data_cache.has(quest_id):
		return _quest_data_cache[quest_id]
	var file := FileAccess.open("%s/%s.json" % [QUEST_DATA_DIR, quest_id], FileAccess.READ)
	if file == null:
		_quest_data_cache[quest_id] = {}
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_quest_data_cache[quest_id] = {}
		return {}
	var data: Dictionary = parsed
	_quest_data_cache[quest_id] = data
	return data
