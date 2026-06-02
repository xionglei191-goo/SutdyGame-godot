extends SceneTree

const QA_TIMING_REPORT := preload("res://scripts/systems/qa_timing_report.gd")
const SUMMARY_EXPORTER := preload("res://tests/helpers/playtest_summary_exporter.gd")
const FINAL_GATE := preload("res://tests/helpers/playtest_manual_final_gate.gd")

var failed := false


func _initialize() -> void:
	var game_state: Node = root.get_node("GameState")
	_assert(not FileAccess.file_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH), "fixture should not start with default report")
	_assert(not FileAccess.file_exists(SUMMARY_EXPORTER.SUMMARY_PATH), "fixture should not start with default summary")

	var report := QA_TIMING_REPORT.build(_fixture_snapshot())
	var summary := SUMMARY_EXPORTER.build_summary(report)
	var pass_errors: Array[String] = FINAL_GATE.validate(report, summary, _passing_timing_record(), _passing_acceptance())
	_assert(pass_errors.is_empty(), "passing manual final gate fixture should pass: %s" % ", ".join(pass_errors))

	var conditional_report := QA_TIMING_REPORT.build(_fixture_snapshot(780))
	var stale_summary_errors: Array[String] = FINAL_GATE.validate(
		report,
		SUMMARY_EXPORTER.build_summary(conditional_report),
		_passing_timing_record(),
		_passing_acceptance()
	)
	_assert(not stale_summary_errors.is_empty(), "stale summary fixture should fail")
	_assert(_has_error_containing(stale_summary_errors, "summary should match current playtest report"), "stale summary fixture should fail on report/summary mismatch")

	var conditional_errors: Array[String] = FINAL_GATE.validate(
		conditional_report,
		SUMMARY_EXPORTER.build_summary(conditional_report),
		_result_timing_record(conditional_report, "conditional_pass", "有条件通过", "人工完整试玩 13:00，主流程无阻塞；记录为有条件通过，原因：儿童首次试玩或慢读会更长。"),
		_pending_acceptance()
	)
	_assert(conditional_errors.is_empty(), "conditional manual final gate fixture should pass: %s" % ", ".join(conditional_errors))
	var conditional_inconsistent_errors: Array[String] = FINAL_GATE.validate(
		conditional_report,
		SUMMARY_EXPORTER.build_summary(conditional_report),
		_result_timing_record(conditional_report, "conditional_pass", "有条件通过", "人工完整试玩 13:00，主流程无阻塞；记录为有条件通过，原因：儿童首次试玩或慢读会更长。"),
		_passing_acceptance()
	)
	_assert(not conditional_inconsistent_errors.is_empty(), "conditional result with checked 2-5 acceptance should fail")
	_assert(_has_error_containing(conditional_inconsistent_errors, "acceptance should keep 2-5 minute skilled-adult item unchecked"), "conditional inconsistent fixture should fail on acceptance state")

	var fail_report := QA_TIMING_REPORT.build(_fixture_snapshot(630))
	var fail_errors: Array[String] = FINAL_GATE.validate(
		fail_report,
		SUMMARY_EXPORTER.build_summary(fail_report),
		_result_timing_record(fail_report, "fail", "不通过", "人工完整试玩 10:30，但当前时长与成人熟练试玩 2-5 分钟参考窗口明显不符，记录为不通过。"),
		_pending_acceptance()
	)
	_assert(fail_errors.is_empty(), "failed manual final gate fixture should pass as a recorded fail result: %s" % ", ".join(fail_errors))

	var pending_errors: Array[String] = FINAL_GATE.validate(report, summary, _pending_timing_record(), _pending_acceptance())
	_assert(not pending_errors.is_empty(), "pending manual final gate fixture should fail")
	_assert(_has_error_containing(pending_errors, "待人工计时"), "pending fixture should fail on pending timing state")
	_assert(_has_error_containing(pending_errors, "exactly one manual result"), "pending fixture should fail on missing manual result")

	var inconsistent_errors: Array[String] = FINAL_GATE.validate(report, summary, _passing_timing_record(), _pending_acceptance())
	_assert(not inconsistent_errors.is_empty(), "inconsistent acceptance fixture should fail")
	_assert(_has_error_containing(inconsistent_errors, "acceptance should check 2-5 minute skilled-adult item"), "inconsistent fixture should fail on acceptance state")

	var malformed_segment_errors: Array[String] = FINAL_GATE.validate(
		report,
		summary,
		_passing_timing_record().replace("| 总用时 | 00:00 | 03:00 | 03:00 | 人工秒表 |", "| 总用时 | 00:00 | 03:00 | three minutes | 人工秒表 |"),
		_passing_acceptance()
	)
	_assert(not malformed_segment_errors.is_empty(), "malformed segment time fixture should fail")
	_assert(_has_error_containing(malformed_segment_errors, "MM:SS"), "malformed segment fixture should fail on MM:SS validation")

	var mismatched_total_errors: Array[String] = FINAL_GATE.validate(
		report,
		summary,
		_passing_timing_record().replace("| 总用时 | 00:00 | 03:00 | 03:00 | 人工秒表 |", "| 总用时 | 00:00 | 01:00 | 01:00 | 人工秒表 |"),
		_passing_acceptance()
	)
	_assert(not mismatched_total_errors.is_empty(), "mismatched manual/report total fixture should fail")
	_assert(_has_error_containing(mismatched_total_errors, "within 60 seconds"), "mismatched total fixture should fail on report elapsed consistency")

	var pass_with_short_manual_total_errors: Array[String] = FINAL_GATE.validate(
		conditional_report,
		SUMMARY_EXPORTER.build_summary(conditional_report),
		_result_timing_record(conditional_report, "pass", "通过", "人工完整试玩 13:00，但错误选择通过。"),
		_passing_acceptance()
	)
	_assert(not pass_with_short_manual_total_errors.is_empty(), "pass result with short manual total should fail")
	_assert(_has_error_containing(pass_with_short_manual_total_errors, "inside target window"), "short pass fixture should fail on manual target window")

	_assert(not FileAccess.file_exists(game_state.DEFAULT_PLAYTEST_REPORT_PATH), "fixture should not write default report")
	_assert(not FileAccess.file_exists(SUMMARY_EXPORTER.SUMMARY_PATH), "fixture should not write default summary")
	if failed:
		quit(1)
		return
	print("MVP 0.2 manual final gate fixture passed.")
	quit(0)


func _passing_timing_record() -> String:
	return """# MVP 0.2 试玩计时记录

> 用途：记录成人熟练试玩是否形成 2-5 分钟闭环，并为儿童首次试玩更长时长保留人工说明。  
> 状态：人工计时完成。

## 导出报告核对
%s

| 项目 | 记录 |
|---|---|
| 是否点击“完成摘要阅读” | 是 |
| 是否点击“导出计时报告” | 是 |
| 报告路径 | `user://mvp_0_2_playtest_report.json` |
| 报告 `playtest_elapsed_text` | 03:00 |
| 报告 `elapsed_vs_target_seconds` | below_min: 0 / above_max: 0 / within_window: true |
| 报告 `fixed_review_read_aloud.total_seconds` | 30 |
| 报告 `playtest_events_monotonic` | true |
| 报告 `timeline_coverage_complete` | true |
| 报告 `manual_result` | pass |

## 结果

- [x] 通过
- [ ] 有条件通过
- [ ] 不通过

记录：

```text
人工完整试玩 03:00，主流程无阻塞，摘要已阅读，报告字段与 postflight 摘要一致；儿童首次试玩预期更长。
```
""" % _filled_manual_info_and_segments(180)


func _result_timing_record(report: Dictionary, manual_result: String, checked_label: String, notes: String) -> String:
	var target: Dictionary = report.get("elapsed_vs_target_seconds", {})
	return """# MVP 0.2 试玩计时记录

> 用途：记录成人熟练试玩是否形成 2-5 分钟闭环，并为儿童首次试玩更长时长保留人工说明。  
> 状态：人工计时完成。

## 导出报告核对
%s

| 项目 | 记录 |
|---|---|
| 是否点击“完成摘要阅读” | 是 |
| 是否点击“导出计时报告” | 是 |
| 报告路径 | `user://mvp_0_2_playtest_report.json` |
| 报告 `playtest_elapsed_text` | %s |
| 报告 `elapsed_vs_target_seconds` | below_min: %s / above_max: %s / within_window: %s |
| 报告 `fixed_review_read_aloud.total_seconds` | 30 |
| 报告 `playtest_events_monotonic` | true |
| 报告 `timeline_coverage_complete` | true |
| 报告 `manual_result` | %s |

## 结果

%s

记录：

```text
%s
```
""" % [
		_filled_manual_info_and_segments(int(report.get("playtest_elapsed_seconds", 0))),
		str(report.get("playtest_elapsed_text", "")),
		str(target.get("below_min", "")),
		str(target.get("above_max", "")),
		str(target.get("within_window", "")),
		manual_result,
		_result_checklist(checked_label),
		notes
	]


func _result_checklist(checked_label: String) -> String:
	var lines: Array[String] = []
	for label in ["通过", "有条件通过", "不通过"]:
		lines.append("- [%s] %s" % ["x" if label == checked_label else " ", label])
	return "\n".join(lines)


func _filled_manual_info_and_segments(total_seconds: int) -> String:
	var prologue_end: int = min(6, max(1, total_seconds - 12))
	var mina_end: int = min(15, max(prologue_end + 1, total_seconds - 11))
	var l1_end: int = min(30, max(mina_end + 1, total_seconds - 10))
	var leo_end: int = min(40, max(l1_end + 1, total_seconds - 9))
	var l2_end: int = min(70, max(leo_end + 1, total_seconds - 8))
	var nora_end: int = min(80, max(l2_end + 1, total_seconds - 7))
	var l3_end: int = min(100, max(nora_end + 1, total_seconds - 6))
	var review_end: int = max(l3_end + 1, total_seconds - 5)
	var summary_end: int = max(review_end + 1, total_seconds - 1)
	return """
## 建议记录

| 项目 | 记录 |
|---|---|
| 测试日期 | 2026-05-31 |
| 测试者 | QA Fixture |
| Godot 版本 | 4.6.3 |
| 设备/分辨率 | Linux / 1280x720 |
| 输入方式 | 鼠标 |
| 玩家类型 | 成人模拟 |
| 是否首次游玩 | 是 |

## 分段计时

| 阶段 | 开始时间 | 结束时间 | 用时 | 备注 |
|---|---:|---:|---:|---|
| First Trip 完成 | %s | %s | %s | 正常 |
| 新存档进入到 Mina 对话结束 | %s | %s | %s | 正常 |
| Walk With Mina 完成 | %s | %s | %s | 正常 |
| Leo 对话结束 | %s | %s | %s | 正常 |
| Room Helper 完成 | %s | %s | %s | 正常 |
| Nora 对话结束 | %s | %s | %s | 正常 |
| Bird Watch 完成 | %s | %s | %s | 正常 |
| Story Show 25 题完成 | %s | %s | %s | 6 道朗读等待 |
| 家长摘要阅读并点击完成 | %s | %s | %s | 已阅读 |
| 总用时 | %s | %s | %s | 人工秒表 |
""" % [
		_format_seconds(0), _format_seconds(prologue_end), _format_duration(0, prologue_end),
		_format_seconds(prologue_end), _format_seconds(mina_end), _format_duration(prologue_end, mina_end),
		_format_seconds(mina_end), _format_seconds(l1_end), _format_duration(mina_end, l1_end),
		_format_seconds(l1_end), _format_seconds(leo_end), _format_duration(l1_end, leo_end),
		_format_seconds(leo_end), _format_seconds(l2_end), _format_duration(leo_end, l2_end),
		_format_seconds(l2_end), _format_seconds(nora_end), _format_duration(l2_end, nora_end),
		_format_seconds(nora_end), _format_seconds(l3_end), _format_duration(nora_end, l3_end),
		_format_seconds(l3_end), _format_seconds(review_end), _format_duration(l3_end, review_end),
		_format_seconds(review_end), _format_seconds(summary_end), _format_duration(review_end, summary_end),
		_format_seconds(0), _format_seconds(total_seconds), _format_seconds(total_seconds)
	]


func _pending_timing_record() -> String:
	return """# MVP 0.2 试玩计时记录

> 用途：记录成人熟练试玩是否形成 2-5 分钟闭环，并为儿童首次试玩更长时长保留人工说明。  
> 状态：待人工计时。

| 报告 `playtest_elapsed_text` |  |
| 报告 `elapsed_vs_target_seconds` | below_min: / above_max: / within_window: |
| 报告 `playtest_events_monotonic` | true / false |
| 报告 `timeline_coverage_complete` | true / false |

- [ ] 通过
- [ ] 有条件通过
- [ ] 不通过

记录：

```text

```
"""


func _passing_acceptance() -> String:
	return """# MVP 0.2 验收记录

## 3. 主流程验收

- [x] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录。
"""


func _pending_acceptance() -> String:
	return """# MVP 0.2 验收记录

## 3. 主流程验收

- [ ] 成人熟练试玩可形成 2-5 分钟闭环，儿童首次试玩预期更长需单独记录。
"""

func _fixture_snapshot(total_seconds: int = 180) -> Dictionary:
	var l1_start: int = 15
	var l1_end: int = 30
	var l2_start: int = 40
	var l2_end: int = 70
	var l3_start: int = 80
	var l3_end: int = 100
	var review_start: int = 120
	var review_end: int = max(review_start + 1, total_seconds - 30)
	var summary_shown: int = max(review_end + 1, total_seconds - 10)
	var summary_read: int = max(summary_shown + 1, total_seconds - 5)
	var event_specs := [
		["playtest_started", "试玩开始", 0],
		["prologue_go_to_school_started", "First Trip 开始", 3],
		["prologue_go_to_school_completed", "First Trip 完成", 6],
		["g4_u1_school_tour_started", "Walk With Mina 开始", l1_start],
		["g4_u1_school_tour_completed", "Walk With Mina 完成", l1_end],
		["g4_u1_tidy_classroom_started", "Room Helper 开始", l2_start],
		["g4_u1_tidy_classroom_completed", "Room Helper 完成", l2_end],
		["g4_u1_garden_bird_started", "Bird Watch 开始", l3_start],
		["g4_u1_garden_bird_completed", "Bird Watch 完成", l3_end],
		["review_challenge_started", "Story Show 开始", review_start],
		["review_challenge_completed", "Story Show 完成", review_end],
		["parent_summary_shown", "家长摘要显示", summary_shown],
		["parent_summary_read", "家长摘要阅读完成", summary_read],
		["playtest_completed", "试玩完成", total_seconds]
	]
	var events: Array[Dictionary] = []
	for spec: Array in event_specs:
		var elapsed_seconds := int(spec[2])
		events.append({
			"id": str(spec[0]),
			"label": str(spec[1]),
			"elapsed_msec": elapsed_seconds * 1000,
			"elapsed_seconds": elapsed_seconds,
			"elapsed_text": _format_seconds(elapsed_seconds)
		})
	return {
		"completed_quests": ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"],
		"completed_tasks": ["prologue_go_to_school", "g4_u1_school_tour", "g4_u1_tidy_classroom", "g4_u1_garden_bird"],
		"rewards": ["first_trip_ticket", "school_star_piece", "tidy_badge_piece", "garden_leaf_piece"],
		"learned_words": ["library", "book", "bird"],
		"learned_patterns": ["This is the library.", "Put the book on the shelf.", "Where is the bird?"],
		"completed_reviews": ["mvp_0_2_review_challenge"],
		"playtest_elapsed_msec": total_seconds * 1000,
		"playtest_elapsed_seconds": total_seconds,
		"playtest_elapsed_text": _format_seconds(total_seconds),
		"playtest_completed": true,
		"playtest_events": events
	}

func _format_seconds(total_seconds: int) -> String:
	var minutes := int(total_seconds / 60)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _format_duration(start_seconds: int, end_seconds: int) -> String:
	return _format_seconds(max(0, end_seconds - start_seconds))


func _has_error_containing(errors: Array[String], needle: String) -> bool:
	for error: String in errors:
		if error.contains(needle):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failed = true
		quit(1)
