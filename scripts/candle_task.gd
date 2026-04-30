extends StaticBody2D

## Drag your candle_blow.tscn file from the FileSystem into this slot in the Inspector
@export var mini_game_scene: PackedScene

@onready var interact_area = $interact

func _ready() -> void:
	# Connect to the custom signal we made in your interact_object.gd
	interact_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	if mini_game_scene != null:
		# Pause the background game so the player can't move around
		get_tree().paused = true
		
		# Spawn the mini-game popup
		var popup = mini_game_scene.instantiate()
		
		# Add it directly to the root so it renders on top of everything
		get_tree().root.add_child(popup)
	else:
		push_warning("Forgot to assign the mini_game_scene in the inspector!")
