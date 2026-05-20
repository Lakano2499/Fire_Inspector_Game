extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	# 1. Stop the player from double-clicking the button while it fades
	$ButtonContainer/PlayButton.disabled = true
	
	# 2. Create a smooth fade-out transition
	var tween = create_tween()
	
	# Fade out the entire TitleScreen (self) over 0.5 seconds
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	
	# 3. Wait for the animation to completely finish...
	await tween.finished
	
	# 4. ...THEN change the scene!
	get_tree().change_scene_to_file("res://scenes/System UI/loading_screen.tscn")


func _on_quit_button_pressed() -> void:
	# Closes the game
	get_tree().quit()
