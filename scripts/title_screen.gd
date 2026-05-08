extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	# Change this path to exactly where your main game scene is!
	get_tree().change_scene_to_file("res://scenes/game_scenes/game.tscn")


func _on_quit_button_pressed() -> void:
	# Closes the game
	get_tree().quit()
