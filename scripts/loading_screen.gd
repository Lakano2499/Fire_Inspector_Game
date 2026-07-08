extends CanvasLayer

# Reference to the shader material so we can animate the wipe effect
@onready var color_rect = $ColorRect

var progress: Array = []

func _ready() -> void:
	var path = TaskManager.target_level_path
	if path == "":
		return

	# Check if main_menu already started the request.
	# If it hasn't (e.g. loading screen launched from somewhere else), start it now.
	var status = ResourceLoader.load_threaded_get_status(path, progress)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		# Request was NOT already started — start it now
		ResourceLoader.load_threaded_request(path)

func _process(delta: float) -> void:
	var path = TaskManager.target_level_path
	if path == "": return

	var load_status = ResourceLoader.load_threaded_get_status(path, progress)

	# --- Animate the shader wipe to reflect real load progress ---
	if color_rect and color_rect.material is ShaderMaterial:
		var current_progress = 0.0
		if progress.size() > 0:
			current_progress = progress[0]
		# Smoothly animate the shader's progress uniform
		var current_shader_val = color_rect.material.get_shader_parameter("progress")
		var target_val = current_progress * 0.85 # leave last 15% for the scene swap flash
		color_rect.material.set_shader_parameter(
			"progress",
			lerp(current_shader_val, target_val, delta * 4.0)
		)

	if load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass # Still loading — animation above handles feedback

	elif load_status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)

		var new_scene = ResourceLoader.load_threaded_get(path)

		if new_scene is PackedScene:
			# Finish the wipe animation before swapping
			if color_rect and color_rect.material is ShaderMaterial:
				color_rect.material.set_shader_parameter("progress", 1.3)
			get_tree().call_deferred("change_scene_to_packed", new_scene)
		else:
			push_error("CRITICAL ERROR: Loaded resource is not a valid scene!")

	elif load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		push_error("CRITICAL ERROR: Failed to load the scene at path: " + path)
		set_process(false)
