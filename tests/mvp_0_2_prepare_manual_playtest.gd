extends SceneTree


func _initialize() -> void:
	print("mvp_0_2_prepare_manual_playtest.gd is legacy and no longer cleans manual playtest state.")
	print("Use mvp_0_2_manual_playtest_readiness.gd for read-only status.")
	print("Use mvp_0_2_manual_playtest_preflight.gd for validated cleanup before manual timing.")
	print("Use scripts/dev/run_mvp_0_2_manual_playtest.sh for the guided manual flow.")
	quit(2)
