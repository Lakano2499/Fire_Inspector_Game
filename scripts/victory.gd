extends CanvasLayer # (Change to Control or Node2D depending on your root node type)

@onready var player = $player1
@onready var victory_sound = $AudioStreamPlayer

func _ready() -> void:
	# 1. Stop background music if you have a music autoload playing!
	# (e.g., YourMusicAutoloadName.stop() or mute the Music bus)
	
	# 2. Play the Victory sound effect
	victory_sound.play()
	
	# 3. Make the character jump repeatedly
	_start_jumping_animation()
	
	# 4. Wait exactly 3 seconds
	await get_tree().create_timer(4.5).timeout
	
	# 5. Transition to the Assessment screen
	# IMPORTANT: Make sure this file path matches exactly where your assessment scene is located!
	get_tree().change_scene_to_file("res://scenes/System UI/assessment.tscn")

func _start_jumping_animation() -> void:
	# Store the player's starting Y position so they don't drift away
	var start_y = player.position.y
	
	# Create a tween and tell it to loop infinitely
	var jump_tween = create_tween().set_loops()
	
	# Jump up! Move Y up by 15 pixels over 0.2 seconds
	jump_tween.tween_property(player, "position:y", start_y - 15.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Fall back down! Return to the start_y over 0.2 seconds
	jump_tween.tween_property(player, "position:y", start_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Wait for 0.1 seconds before jumping again so it feels natural
	jump_tween.tween_interval(0.1)
