extends AudioStreamPlayer

# The exact file names of the scenes where music should STOP
var muted_scenes = ["game.tscn", "assessment.tscn", "ash_baby_reference.tscn", "game_over.tscn"]

func _process(_delta: float) -> void:
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.scene_file_path != "":
		# Extract just the file name (e.g., "game.tscn") from the full path
		var file_name = current_scene.scene_file_path.get_file()
		
		# Check if we are in a muted scene
		if file_name in muted_scenes:
			if playing:
				stop() # Turn music off
		else:
			if not playing:
				play() # Turn music on
