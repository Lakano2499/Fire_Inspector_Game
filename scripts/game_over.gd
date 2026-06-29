extends CanvasLayer # (Change to 'extends Control' if your root node is a Control node)

@onready var anim_sprite = $AnimatedSprite2D
@onready var game_over_sound = $GameOverSound

func _ready() -> void:
	# 1. Play the correct death animation based on the TaskManager
	if TaskManager.game_over_reason == "electrocute":
		anim_sprite.play("electrocute")
	else:
		# Default to the fire/explosion animation
		anim_sprite.play("burned")
		
	# 2. Play the Game Over sound effect
	game_over_sound.play()
	
	# 3. Wait exactly 3 seconds
	await get_tree().create_timer(3.0).timeout
	
	# 4. Transition to the Assessment screen
	# IMPORTANT: Make sure this file path matches exactly where your assessment scene is located!
	get_tree().change_scene_to_file("res://scenes/System UI/assessment.tscn")
