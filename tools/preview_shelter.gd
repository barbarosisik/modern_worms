extends SceneTree
## Disposable shelter playtest. Stages: fresh, rescued (default), complete.
## Uses isolated saves/settings and never loads the owner's campaign.

var _scratch_paths: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var stage := "rescued"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--stage="):
			stage = argument.trim_prefix("--stage=")
	if stage not in ["fresh", "rescued", "complete"]:
		push_error("Use --stage=fresh, --stage=rescued or --stage=complete.")
		quit(1)
		return
	var app := preload("res://scenes/main.tscn").instantiate()
	app.settings_path = "user://shelter_preview_settings_%d.cfg" % OS.get_process_id()
	app.campaign_checkpoint_path = "user://shelter_preview_run_%d.cfg" % OS.get_process_id()
	_scratch_paths = [app.settings_path, app.campaign_checkpoint_path, app.campaign_checkpoint_path + ".pending"]
	app.tree_exiting.connect(_cleanup)
	root.add_child(app)
	app.campaign.begin(PackedInt32Array([0, 1]))
	if stage != "fresh":
		app.campaign.complete(0, 1)
	if stage == "complete":
		app.campaign.complete(1, 0)
	app._enter_shelter()
	root.title = "Signal Fires - Shelter playtest (isolated progress)"


func _cleanup() -> void:
	for path in _scratch_paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
