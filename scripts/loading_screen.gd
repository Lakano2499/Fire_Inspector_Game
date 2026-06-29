extends CanvasLayer

var progress: Array = []

func _ready() -> void:
	var path = TaskManager.target_level_path
	if path != "":
		# --- THE FIX: Removed 'true'. OpenGL Compatibility cannot handle sub-threads! ---
		ResourceLoader.load_threaded_request(path)
	else:
		print("ERROR: No target level path provided!")

func _process(_delta: float) -> void:
	var path = TaskManager.target_level_path
	if path == "": return
	
	var load_status = ResourceLoader.load_threaded_get_status(path, progress)
	
	if load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass 
		
	elif load_status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false) 
		
		var new_scene = ResourceLoader.load_threaded_get(path)
		
		if new_scene is PackedScene:
			get_tree().call_deferred("change_scene_to_packed", new_scene)
		else:
			print("CRITICAL ERROR: Loaded resource is not a valid scene!")
		
	elif load_status == ResourceLoader.THREAD_LOAD_FAILED or load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		print("CRITICAL ERROR: Failed to load the scene!")
		set_process(false)
