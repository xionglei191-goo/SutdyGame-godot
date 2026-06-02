extends SceneTree

var _completed_quests: Array[String] = []


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	game_state.reset_progress()
	game_state.start_playtest_timer(true)

	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	game_state.reset_progress()
	game_state.start_playtest_timer(true)

	var quest_diary: CanvasLayer = main.get_node("QuestDiary")
	quest_diary.quest_completed.connect(func(quest_id: String, _reward_id: String, _reward_name: String) -> void:
		_completed_quests.append(quest_id)
	)
	var town_map: Node = main.get_node("TownMap")
	_assert_runtime_quest_titles(main)
	_assert_scene_structure(town_map)
	town_map.show_scene("home")
	await process_frame
	var feed_button: Button = town_map.get_node("HomeLayer/PetPanel/MarginContainer/VBoxContainer/ActionButtons/FeedButton")
	feed_button.pressed.emit()
	await process_frame
	_assert(game_state.coins == 3, "home pet feed should spend 2 coins from the default 5")
	_assert(int(game_state.get_pet_state().get("hunger", -1)) == 84, "home pet feed should update hunger")
	var mina: Area2D = town_map.get_node("NpcLayer/Mina")
	_assert(mina.dialogue_id == "mina_letter_box_intro", "new home scene should begin with the Welcome Box dialogue")
	mina.interaction_requested.emit(mina.dialogue_id)
	await process_frame
	var dialogue_box: CanvasLayer = main.get_node("DialogueBox")
	dialogue_box._finish()
	await process_frame
	_assert(quest_diary.active, "home Mina intro should start the Welcome Box quest")
	_assert(quest_diary.quest_id == "prologue_letter_box", "home Mina intro should hand off to Welcome Box")
	_assert(quest_diary.event_label.text == "Welcome Box", "Quest Diary should show the starter event name")
	_assert(quest_diary.status_label.text == "Quest open", "Quest Diary should start in open status")
	_assert(quest_diary.prompt_label.text == "Open Mina's welcome box.", "Quest Diary should use Welcome Box prompt")
	_assert(quest_diary.words_label.text.begins_with("Quest clues:"), "Quest Diary should present vocabulary as quest clues")
	_assert(quest_diary.reward_label.text == "Keepsake: Welcome Box Star", "Quest Diary should show the Welcome Box keepsake")
	var parent_summary: CanvasLayer = main.get_node("ParentSummary")
	parent_summary.refresh()
	_assert_parent_summary_empty(parent_summary)
	var finish_reading_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/FinishReadingButton")
	_assert(finish_reading_button.disabled, "empty parent summary should not allow finishing playtest")
	_assert(finish_reading_button.text == "完成 4 个 Quest 和 Story Show 后可用", "empty parent summary should explain finish prerequisite")
	finish_reading_button.pressed.emit()
	_assert(not game_state.playtest_completed, "empty parent summary finish press should not complete playtest")

	quest_diary.check_target("home")
	_assert_not_contains(_completed_quests, "prologue_letter_box", "wrong Welcome Box target should not complete quest")
	_assert(quest_diary.active, "Welcome Box should remain active after wrong target")
	_assert(quest_diary.status_label.text == "Look again", "Quest Diary should show retry status after wrong target")
	quest_diary.check_target("home_letter_box")
	await process_frame
	_assert_contains(_completed_quests, "prologue_letter_box", "Welcome Box completion")
	_assert(game_state.coins == 4, "Welcome Box should add reward_coins from quest data after home pet feed")
	_assert(quest_diary.status_label.text == "Done", "Quest Diary should show done status after Welcome Box completion")
	_assert(town_map.get_node("HomeLayer").visible, "home scene should remain visible after Welcome Box")
	_assert(mina.dialogue_id == "mina_home_intro", "Mina should switch to First Trip dialogue after Welcome Box")
	mina.interaction_requested.emit(mina.dialogue_id)
	await process_frame
	dialogue_box._finish()
	await process_frame
	_assert(quest_diary.active, "home Mina intro should start First Trip after Welcome Box")
	_assert(quest_diary.quest_id == "prologue_go_to_school", "home Mina intro should hand off to First Trip")
	_assert(quest_diary.event_label.text == "First Trip", "Quest Diary should show the prologue event name")
	_assert(quest_diary.prompt_label.text == "Start Mina's first trip.", "Quest Diary should use prologue adventure prompt")
	_assert(quest_diary.reward_label.text == "Keepsake: First Trip Ticket", "Quest Diary should show the prologue keepsake")
	quest_diary.check_target("sunshine_school")
	_assert_contains(_completed_quests, "prologue_go_to_school", "First Trip completion")
	_assert(game_state.coins == 5, "First Trip should add reward_coins from quest data")
	_assert(quest_diary.status_label.text == "Done", "Quest Diary should show done status after completion")

	quest_diary.start_quest("g4_u1_school_tour")
	_assert(quest_diary.event_label.text == "Walk With Mina", "Quest Diary should show the school event name")
	_assert(quest_diary.prompt_label.text == "Find Mina's story stop.", "Quest Diary should use Mina story stop prompt")
	_assert(quest_diary.reward_label.text == "Keepsake: Adventure Star", "Quest Diary should show adventure event keepsake")
	quest_diary.check_target("classroom")
	_assert_not_contains(_completed_quests, "g4_u1_school_tour", "wrong school target should not complete quest")
	_assert(quest_diary.active, "Walk With Mina should remain active after wrong target")
	_assert(quest_diary.status_label.text == "Look again", "Quest Diary should keep retry status for wrong school target")
	quest_diary.check_target("library")
	_assert_contains(_completed_quests, "g4_u1_school_tour", "Walk With Mina completion")
	_assert(game_state.coins == 7, "Walk With Mina should add reward_coins from quest data")
	var completed_after_school_quest := _completed_quests.size()
	quest_diary.check_target("library")
	_assert(_completed_quests.size() == completed_after_school_quest, "completed school quest should not complete twice")
	_assert(town_map.get_node("ClassroomLayer").visible, "classroom scene should be visible after school quest")

	quest_diary.start_quest("g4_u1_tidy_classroom")
	_assert(quest_diary.event_label.text == "Room Helper", "Quest Diary should show the room helper event name")
	_assert(quest_diary.prompt_label.text == "Help Leo set up the story room.", "Quest Diary should use story-room setup prompt")
	_assert(quest_diary.reward_label.text == "Keepsake: Room Helper Badge", "Quest Diary should show room helper keepsake")
	_assert(quest_diary.feedback_label.text == "Set up the story room.", "room helper should explain drag interaction as story setup")
	var drag_game: Node = main.get_node("DragPlaceGame")
	_assert(drag_game.visible, "drag game should be visible for Room Helper quest")
	_assert(not drag_game.place_item("book", "desk"), "wrong drag placement should fail")
	_assert(not drag_game.is_complete(), "wrong drag placement should not complete game")
	_assert_not_contains(_completed_quests, "g4_u1_tidy_classroom", "wrong drag placement should not complete quest")
	_assert(drag_game.place_item("book", "shelf"), "book should fit shelf")
	_assert(drag_game.place_item("pencil", "desk"), "pencil should fit desk")
	_assert(drag_game.place_item("bag", "under_desk"), "bag should fit under desk")
	await process_frame
	_assert_contains(_completed_quests, "g4_u1_tidy_classroom", "tidy classroom completion")
	_assert(game_state.coins == 9, "Room Helper should add reward_coins from quest data")
	_assert(town_map.get_node("GardenLayer").visible, "garden scene should be visible after Room Helper quest")

	quest_diary.start_quest("g4_u1_garden_bird")
	_assert(quest_diary.event_label.text == "Bird Watch", "Quest Diary should show the garden event name")
	_assert(quest_diary.reward_label.text == "Keepsake: Garden Leaf Charm", "Quest Diary should show garden keepsake")
	quest_diary.check_target("bench")
	_assert_not_contains(_completed_quests, "g4_u1_garden_bird", "wrong garden target should not complete quest")
	_assert(quest_diary.active, "Bird Watch quest should remain active after wrong target")
	quest_diary.check_target("bird")
	_assert_contains(_completed_quests, "g4_u1_garden_bird", "garden bird completion")
	_assert(game_state.coins == 12, "Bird Watch should add reward_coins from quest data")
	var story_show: CanvasLayer = main.get_node("StoryShow")
	_assert(story_show.visible, "Story Show should open after final MVP quest")
	parent_summary.refresh()
	var pre_review_finish_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/FinishReadingButton")
	_assert(pre_review_finish_button.disabled, "parent summary should not allow finish before Story Show")
	_assert(pre_review_finish_button.text == "完成 4 个 Quest 和 Story Show 后可用", "parent summary should explain Story Show prerequisite before finish")
	var review_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/ReviewValue")
	_assert(review_value.text.contains("先完成 25 题 Story Show"), "parent summary should explain Story Show prerequisite")
	_complete_story_show(story_show)
	_assert(parent_summary.visible, "parent summary should open after Story Show")
	_assert(not story_show.visible, "Story Show should hide after completion")
	_assert(not main.get_node("RewardPopup").visible, "reward popup should hide before parent summary")
	_assert(not quest_diary.panel.visible, "Quest Diary should hide before parent summary")
	_assert(game_state.has_completed_review(story_show.REVIEW_ID), "Story Show completion should be recorded")
	_assert(not game_state.playtest_completed, "Story Show completion should wait for parent summary reading")
	var completed_review_finish_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/FinishReadingButton")
	_assert(not completed_review_finish_button.disabled, "completed review should allow parent summary reading finish")
	_assert(completed_review_finish_button.text == "完成摘要阅读", "completed review should show finish reading action")
	var parent_bonus_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ParentBonusButton")
	var parent_bonus_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/ParentBonusValue")
	_assert(not parent_bonus_button.disabled, "completed review should allow one parent bonus confirmation")
	_assert(parent_bonus_button.text == "发放 Parent Bonus +2", "completed review should show parent bonus action")
	parent_bonus_button.pressed.emit()
	_assert(game_state.parent_bonus == game_state.PARENT_BONUS_REWARD, "parent bonus confirmation should add the configured reward")
	_assert(game_state.has_story_flag(game_state.PARENT_BONUS_CONFIRM_FLAG), "parent bonus confirmation should write a story flag")
	_assert(parent_bonus_value.text == "2", "parent summary should show confirmed parent bonus value")
	_assert(parent_bonus_button.disabled, "confirmed parent bonus should disable the button")
	_assert(parent_bonus_button.text == "Parent Bonus 已发放", "confirmed parent bonus should show confirmed state")
	var report_status_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ReportStatusValue")
	_assert(report_status_value.text.contains("Parent Bonus added: +2."), "parent bonus confirmation should show status feedback")
	parent_bonus_button.pressed.emit()
	_assert(game_state.parent_bonus == game_state.PARENT_BONUS_REWARD, "parent bonus confirmation should be idempotent")
	completed_review_finish_button.pressed.emit()
	_assert(game_state.playtest_completed, "parent summary reading should finish playtest timer")
	_assert(completed_review_finish_button.text == "摘要阅读已完成", "completed playtest should show finished reading state")
	_assert(report_status_value.text.contains("计时已停止"), "finished parent summary should show stopped timer status")
	_assert(game_state.get_playtest_elapsed_msec() > 0, "playtest timer should record elapsed time")
	var completed_after_garden_quest := _completed_quests.size()
	quest_diary.check_target("bird")
	_assert(_completed_quests.size() == completed_after_garden_quest, "completed garden quest should not complete twice")

	var snapshot: Dictionary = game_state.debug_snapshot()
	_assert(int(snapshot.get("coins", -1)) >= 3, "snapshot should include current coin balance")
	_assert(int(snapshot.get("parent_bonus", -1)) == game_state.PARENT_BONUS_REWARD, "snapshot should include confirmed parent bonus")
	_assert(typeof(snapshot.get("pet_state", {})) == TYPE_DICTIONARY, "snapshot should include pet state dictionary")
	_assert_contains(snapshot["completed_quests"], "prologue_letter_box", "saved Welcome Box")
	_assert_contains(snapshot["completed_quests"], "g4_u1_school_tour", "saved Walk With Mina")
	_assert_contains(snapshot["completed_quests"], "g4_u1_tidy_classroom", "saved tidy classroom")
	_assert_contains(snapshot["completed_quests"], "g4_u1_garden_bird", "saved garden bird")
	_assert_contains(snapshot["story_flags"], game_state.PARENT_BONUS_CONFIRM_FLAG, "saved parent bonus flag")
	_assert_contains(snapshot["learned_words"], "library", "word record library")
	_assert_contains(snapshot["learned_words"], "book", "word record book")
	_assert_contains(snapshot["learned_words"], "bird", "word record bird")
	_assert(int(snapshot["playtest_elapsed_msec"]) > 0, "snapshot should include playtest elapsed msec")
	_assert(str(snapshot["playtest_elapsed_text"]).contains(":"), "snapshot should include formatted playtest time")
	_assert(_has_event(snapshot["playtest_events"], "review_challenge_completed"), "events should include review completion")
	_assert(_has_event(snapshot["playtest_events"], "parent_summary_shown"), "events should include parent summary shown")
	_assert(_has_event(snapshot["playtest_events"], "parent_summary_read"), "events should include parent summary reading completion")
	_assert_playtest_report(game_state.build_playtest_report())

	parent_summary.refresh()
	_assert_parent_summary_completed(parent_summary)
	var report_path := "user://mvp_0_2_smoke_playtest_report.json"
	_assert(game_state.save_playtest_report(report_path), "playtest report save should succeed")
	_assert_report_file(report_path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(report_path))

	var save_path := "user://mvp_0_2_smoke_save.json"
	_assert(game_state.save_game(save_path), "save should succeed")
	game_state.reset_progress()
	_assert(game_state.load_game(save_path), "load should succeed")
	_assert(game_state.get_completed_quests().size() == 5, "load should restore 5 completed quests including the starter event")
	_assert(game_state.playtest_completed, "load should restore completed playtest timer")
	_assert(game_state.get_playtest_elapsed_msec() > 0, "load should restore elapsed playtest time")
	_assert(int(game_state.coins) >= 3, "load should restore coins")
	_assert(int(game_state.parent_bonus) == game_state.PARENT_BONUS_REWARD, "load should restore parent bonus")
	_assert(int(game_state.get_pet_state().get("hunger", -1)) >= 84, "load should restore pet hunger")
	_assert_contains(game_state.get_completed_quests(), "prologue_letter_box", "loaded starter quest")
	_assert_contains(game_state.get_completed_quests(), "prologue_go_to_school", "loaded prologue quest")
	_assert_contains(game_state.get_completed_quests(), "g4_u1_school_tour", "loaded first quest")
	_assert_contains(game_state.get_completed_quests(), "g4_u1_tidy_classroom", "loaded second quest")
	_assert_contains(game_state.get_completed_quests(), "g4_u1_garden_bird", "loaded final quest")
	_assert_contains(game_state.story_flags, game_state.PARENT_BONUS_CONFIRM_FLAG, "load should restore parent bonus confirmation flag")
	_assert(_has_event(game_state.playtest_events, "parent_summary_read"), "load should restore playtest events")
	parent_summary.refresh()
	_assert_parent_summary_completed(parent_summary)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	_assert(game_state.save_game(), "default save should succeed")
	main.queue_free()
	await process_frame
	var restored_main: Node = main_scene.instantiate()
	root.add_child(restored_main)
	await process_frame
	var restored_map: Node = restored_main.get_node("TownMap")
	_assert(restored_map.get_node("GardenLayer").visible, "default save should restore garden scene")
	_assert(restored_main.get_node("ParentSummary").visible, "completed review save should restore parent summary")
	restored_main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))

	game_state.reset_progress()
	game_state.complete_quest("prologue_go_to_school")
	game_state.complete_quest("g4_u1_school_tour")
	game_state.complete_quest("g4_u1_tidy_classroom")
	game_state.complete_quest("g4_u1_garden_bird")
	_assert(game_state.save_game(), "unfinished review default save should succeed")
	var review_restore_main: Node = main_scene.instantiate()
	root.add_child(review_restore_main)
	await process_frame
	_assert(review_restore_main.get_node("StoryShow").visible, "unfinished Story Show should resume Story Show")
	review_restore_main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state.DEFAULT_SAVE_PATH))

	print("MVP 0.2 smoke test passed.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)


func _assert_contains(values: Array, expected: String, label: String) -> void:
	if not values.has(expected):
		push_error("Missing %s: %s" % [label, expected])
		quit(1)


func _assert_not_contains(values: Array, unexpected: String, label: String) -> void:
	if values.has(unexpected):
		push_error("Unexpected %s: %s" % [label, unexpected])
		quit(1)


func _complete_story_show(story_show: CanvasLayer) -> void:
	while story_show.visible:
		var prompt: Dictionary = story_show.prompts[story_show.current_index]
		if prompt.get("mode", "") == "read_aloud":
			story_show._start_reading_timer()
			story_show._on_read_timer_timeout()
		story_show.choose(str(prompt["answer"]))


func _assert_parent_summary_empty(parent_summary: CanvasLayer) -> void:
	var completed_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/CompletedValue")
	var rewards_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/RewardsValue")
	var playtime_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/PlaytimeValue")
	var parent_bonus_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/ParentBonusValue")
	var quests_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/QuestsValue")
	var words_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/WordsValue")
	var patterns_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/PatternsValue")
	var review_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/ReviewValue")
	var timeline_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/TimelineValue")
	var parent_bonus_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ParentBonusButton")
	var export_report_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ExportReportButton")
	_assert(completed_value.text == "0", "empty parent summary should show 0 completed quests, got %s" % completed_value.text)
	_assert(quests_value.text == "-", "empty parent summary should show empty quests state, got %s" % quests_value.text)
	_assert(rewards_value.text == "-", "empty parent summary should show empty rewards state, got %s" % rewards_value.text)
	_assert(playtime_value.text.contains(":"), "empty parent summary should show formatted playtest time")
	_assert(parent_bonus_value.text == "0", "empty parent summary should show 0 parent bonus, got %s" % parent_bonus_value.text)
	_assert(words_value.text == "-", "empty parent summary should show empty words state, got %s" % words_value.text)
	_assert(patterns_value.text == "-", "empty parent summary should show empty patterns state, got %s" % patterns_value.text)
	_assert(review_value.text.contains("Welcome Box"), "empty parent summary should suggest the starter event")
	_assert(timeline_value.text.contains("试玩开始"), "empty parent summary should show start timeline event")
	_assert(parent_bonus_button.disabled, "empty parent summary should not allow parent bonus confirmation")
	_assert(parent_bonus_button.text.contains("完成 Story Show"), "empty parent summary should explain parent bonus prerequisite")
	_assert(export_report_button.disabled, "empty parent summary should not allow report export")


func _assert_scene_structure(town_map: Node) -> void:
	var campus_layer: Node = town_map.get_node("CampusGateLayer")
	var classroom_layer: Node = town_map.get_node("ClassroomLayer")
	var garden_layer: Node = town_map.get_node("GardenLayer")
	_assert(campus_layer.get_node("GateSign") != null, "campus gate should have a visible sign")
	_assert(classroom_layer.get_node("DeskA") != null, "classroom should have a desk")
	_assert(classroom_layer.get_node("Shelf") != null, "classroom should have a shelf")
	_assert(garden_layer.get_node("Tree") != null, "garden should have a tree")
	_assert(garden_layer.get_node("Bird") != null, "garden should have a bird")
	_assert(town_map.get_node("NpcLayer/Mina") != null, "Mina should exist")
	_assert(town_map.get_node("NpcLayer/Leo") != null, "Leo should exist")
	_assert(town_map.get_node("NpcLayer/Nora") != null, "Nora should exist")
	_assert((town_map.get_node("NpcLayer/Mina/NameLabel") as Label).text == "Mina", "Mina label should be correct")
	_assert((town_map.get_node("NpcLayer/Leo/NameLabel") as Label).text == "Leo", "Leo label should be correct")
	_assert((town_map.get_node("NpcLayer/Nora/NameLabel") as Label).text == "Nora", "Nora label should be correct")


func _assert_runtime_quest_titles(main: Node) -> void:
	var controller: RefCounted = main.get("main_flow_controller")
	_assert(controller != null, "Main should expose MainFlowController for runtime title checks")
	for quest_id: String in [
		"prologue_letter_box",
		"prologue_go_to_school",
		"g4_u1_school_tour",
		"g4_u1_tidy_classroom",
		"g4_u1_garden_bird",
		"town_bookshop_find_book"
	]:
		var title := _quest_title_from_data(quest_id)
		_assert(controller.quest_title(quest_id) == title, "MainFlowController.quest_title should read title from quest data: %s" % quest_id)


func _quest_title_from_data(quest_id: String) -> String:
	var file := FileAccess.open("res://data/quests/%s.json" % quest_id, FileAccess.READ)
	_assert(file != null, "quest data should open for title check: %s" % quest_id)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "quest data should parse for title check: %s" % quest_id)
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	return str((parsed as Dictionary).get("title", ""))


func _assert_parent_summary_completed(parent_summary: CanvasLayer) -> void:
	var completed_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/CompletedValue")
	var rewards_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/RewardsValue")
	var playtime_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/PlaytimeValue")
	var parent_bonus_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/StatsGrid/ParentBonusValue")
	var quests_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/QuestsValue")
	var words_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/WordsValue")
	var patterns_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/PatternsValue")
	var review_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/ReviewValue")
	var timeline_value: Label = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/ContentVBox/TimelineValue")
	var parent_bonus_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ParentBonusButton")
	var export_report_button: Button = parent_summary.get_node("Panel/MarginContainer/VBoxContainer/ExportReportButton")
	_assert(completed_value.text == "5", "parent summary should show 5 completed quests including Welcome Box")
	_assert(quests_value.text.contains("Welcome Box"), "parent summary should show starter quest name")
	_assert(quests_value.text.contains("First Trip"), "parent summary should show prologue quest name")
	_assert(quests_value.text.contains("Walk With Mina"), "parent summary should show school quest name")
	_assert(quests_value.text.contains("Room Helper"), "parent summary should show tidy quest name")
	_assert(quests_value.text.contains("Bird Watch"), "parent summary should show garden quest name")
	_assert(rewards_value.text.contains("Welcome Box Star"), "parent summary should show starter reward")
	_assert(rewards_value.text.contains("First Trip Ticket"), "parent summary should show prologue reward")
	_assert(rewards_value.text.contains("Adventure Star"), "parent summary should show adventure reward")
	_assert(rewards_value.text.contains("Room Helper Badge"), "parent summary should show tidy reward")
	_assert(rewards_value.text.contains("Garden Leaf Charm"), "parent summary should show garden reward")
	_assert(playtime_value.text.contains(":"), "parent summary should show formatted playtest time")
	_assert(parent_bonus_value.text == "2", "parent summary should show confirmed parent bonus")
	_assert(parent_bonus_button.disabled, "completed parent summary should not allow duplicate parent bonus")
	_assert(parent_bonus_button.text == "Parent Bonus 已发放", "completed parent summary should show parent bonus confirmed state")
	_assert(words_value.text.contains("library"), "parent summary should show word record library")
	_assert(words_value.text.contains("book"), "parent summary should show word record book")
	_assert(words_value.text.contains("bird"), "parent summary should show word record bird")
	_assert(patterns_value.text.contains("This is the library."), "parent summary should show school pattern")
	_assert(patterns_value.text.contains("Put the book on the shelf."), "parent summary should show tidy pattern")
	_assert(patterns_value.text.contains("Where is the bird?"), "parent summary should show garden pattern")
	_assert(review_value.text.contains("Story Show"), "parent summary should frame review as Story Show")
	_assert(review_value.text.contains("library、book、bird"), "parent summary should include story clue words")
	_assert(review_value.text.contains("舞台台词"), "parent summary should use stage-line review wording")
	_assert(timeline_value.text.contains("家长摘要阅读完成"), "parent summary should show reading completion timeline event")
	_assert(not export_report_button.disabled, "completed parent summary should allow report export")


func _has_event(events: Array, event_id: String) -> bool:
	for event: Variant in events:
		if typeof(event) == TYPE_DICTIONARY and str(event.get("id", "")) == event_id:
			return true
	return false


func _assert_playtest_report(report: Dictionary) -> void:
	_assert(int(report.get("schema_version", 0)) == 2, "report should include schema version")
	_assert(str(report.get("report_type", "")) == "mvp_0_2_playtest_timing", "report should include report type")
	_assert(bool(report.get("manual_verdict_required", false)), "report should require manual verdict")
	_assert(report.has("manual_result"), "report should include manual result placeholder")
	_assert(report.has("manual_notes"), "report should include manual notes placeholder")
	_assert(str(report.get("manual_result", "")) == "", "report should not auto-fill manual result")
	_assert(str(report.get("manual_timing_hint", "")).ends_with("_manual_review_required"), "report should keep timing hint manual")
	_assert(not report.has("auto_pass"), "report should not include auto pass field")
	_assert(not report.has("passed"), "report should not include passed field")
	_assert(not report.has("is_passed"), "report should not include is_passed field")
	_assert(not report.has("qa_passed"), "report should not include qa_passed field")
	_assert(typeof(report.get("manual_context", {})) == TYPE_DICTIONARY, "report should include manual context")
	var checklist: Dictionary = report.get("manual_checklist_required", {})
	_assert(bool(checklist.get("real_play_required", false)), "report should require real play check")
	_assert(bool(checklist.get("child_reading_pressure_required", false)), "report should require reading pressure check")
	_assert(bool(checklist.get("input_feel_required", false)), "report should require input feel check")
	_assert(bool(checklist.get("visual_review_required", false)), "report should require visual review")
	var target_duration: Dictionary = report.get("target_duration_minutes", {})
	_assert(int(target_duration.get("min", 0)) == 2, "report should include minimum target duration")
	_assert(int(target_duration.get("max", 0)) == 5, "report should include maximum target duration")
	var target_seconds: Dictionary = report.get("target_duration_seconds", {})
	_assert(int(target_seconds.get("min", 0)) == 120, "report should include minimum target seconds")
	_assert(int(target_seconds.get("max", 0)) == 300, "report should include maximum target seconds")
	var duration_delta: Dictionary = report.get("elapsed_vs_target_seconds", {})
	_assert(duration_delta.has("below_min"), "report should include below-min duration delta")
	_assert(duration_delta.has("above_max"), "report should include above-max duration delta")
	_assert(duration_delta.has("within_window"), "report should include within-window evidence")
	var fixed_review: Dictionary = report.get("fixed_review_read_aloud", {})
	_assert(int(fixed_review.get("review_prompt_count", 0)) == 25, "report should include review prompt count")
	_assert(int(fixed_review.get("prompt_count", 0)) == 6, "report should include timed read-aloud prompt count")
	_assert(int(fixed_review.get("total_seconds", 0)) == 30, "report should include fixed read-aloud seconds")
	_assert(str(fixed_review.get("total_text", "")) == "00:30", "report should include formatted fixed read-aloud time")
	_assert_int_array(fixed_review.get("seconds_by_prompt", []), [5, 5, 5, 5, 5, 5], "report fixed read-aloud sequence")
	_assert(int(report.get("minimum_fixed_wait_seconds", 0)) == 30, "report should include minimum fixed wait seconds")
	_assert(bool(report.get("playtest_completed", false)), "report should include completed duration evidence")
	_assert(int(report.get("playtest_elapsed_msec", 0)) > 0, "report should include elapsed msec")
	_assert(str(report.get("playtest_elapsed_text", "")).contains(":"), "report should include elapsed text")
	_assert(bool(report.get("playtest_events_monotonic", false)), "report should confirm monotonic events")
	var events: Array = report.get("playtest_events", [])
	_assert(events.size() >= 10, "report should include event list")
	_assert(bool(report.get("timeline_coverage_complete", false)), "report should include complete timeline coverage")
	_assert_event_coverage(report.get("event_ids_present", {}))
	_assert_event_deltas(report.get("event_elapsed_deltas", []), events.size())
	_assert(_has_event(events, "playtest_started"), "report should include playtest start event")
	_assert(_has_event(events, "g4_u1_school_tour_started"), "report should include Walk With Mina start event")
	_assert(_has_event(events, "g4_u1_school_tour_completed"), "report should include Walk With Mina completion event")
	_assert(_has_event(events, "g4_u1_tidy_classroom_started"), "report should include Room Helper start event")
	_assert(_has_event(events, "g4_u1_tidy_classroom_completed"), "report should include Room Helper completion event")
	_assert(_has_event(events, "g4_u1_garden_bird_started"), "report should include Bird Watch start event")
	_assert(_has_event(events, "g4_u1_garden_bird_completed"), "report should include Bird Watch completion event")
	_assert(_has_event(events, "review_challenge_started"), "report should include review start event")
	_assert(_has_event(events, "review_challenge_completed"), "report should include review completion event")
	_assert(_has_event(events, "parent_summary_shown"), "report should include parent summary shown event")
	_assert(_has_event(events, "parent_summary_read"), "report should include parent summary read event")
	_assert(_has_event(events, "playtest_completed"), "report should include playtest completion event")
	_assert_events_complete_and_monotonic(events)
	_assert_contains(report.get("completed_quests", []), "g4_u1_garden_bird", "report completed quest")
	_assert_contains(report.get("completed_reviews", []), "mvp_0_2_review_challenge", "report completed review")


func _assert_report_file(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "report file should be readable")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_assert(typeof(parsed) == TYPE_DICTIONARY, "report file should parse as JSON object")
	_assert_playtest_report(parsed)


func _assert_events_complete_and_monotonic(events: Array) -> void:
	var previous_msec := -1
	for event: Variant in events:
		_assert(typeof(event) == TYPE_DICTIONARY, "report event should be a dictionary")
		var data: Dictionary = event
		_assert(not str(data.get("id", "")).is_empty(), "report event should include id")
		_assert(not str(data.get("label", "")).is_empty(), "report event should include label")
		var elapsed_msec := int(data.get("elapsed_msec", -1))
		_assert(elapsed_msec >= 0, "report event should include elapsed msec")
		_assert(elapsed_msec >= previous_msec, "report events should be monotonic")
		_assert(str(data.get("elapsed_text", "")).contains(":"), "report event should include elapsed text")
		previous_msec = elapsed_msec


func _assert_event_coverage(coverage: Dictionary) -> void:
	for event_id in [
		"playtest_started",
		"g4_u1_school_tour_started",
		"g4_u1_school_tour_completed",
		"g4_u1_tidy_classroom_started",
		"g4_u1_tidy_classroom_completed",
		"g4_u1_garden_bird_started",
		"g4_u1_garden_bird_completed",
		"review_challenge_started",
		"review_challenge_completed",
		"parent_summary_shown",
		"parent_summary_read",
		"playtest_completed"
	]:
		_assert(bool(coverage.get(event_id, false)), "report should mark event present: %s" % event_id)


func _assert_event_deltas(deltas: Array, event_count: int) -> void:
	_assert(deltas.size() == event_count - 1, "report should include one delta between each event")
	for delta: Variant in deltas:
		_assert(typeof(delta) == TYPE_DICTIONARY, "event delta should be a dictionary")
		var data: Dictionary = delta
		_assert(not str(data.get("from", "")).is_empty(), "event delta should include from id")
		_assert(not str(data.get("to", "")).is_empty(), "event delta should include to id")
		_assert(int(data.get("delta_msec", -1)) >= 0, "event delta should be non-negative")
		_assert(str(data.get("delta_text", "")).contains(":"), "event delta should include formatted text")


func _assert_int_array(actual: Variant, expected: Array, label: String) -> void:
	_assert(typeof(actual) == TYPE_ARRAY, "%s should be an array" % label)
	var actual_array: Array = actual
	_assert(actual_array.size() == expected.size(), "%s size mismatch" % label)
	for i in range(expected.size()):
		_assert(int(actual_array[i]) == int(expected[i]), "%s mismatch at index %d" % [label, i])
