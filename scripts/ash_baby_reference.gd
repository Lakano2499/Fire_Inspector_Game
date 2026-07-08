extends CanvasLayer # (Change to Control or Node2D depending on your root node type)

@onready var color_rect = $ColorRect
@onready var flash_bang = $FlashBang
@onready var ash_baby_sound = $AshBabySound

func _ready() -> void:
	# 1. Ensure the ColorRect covers the screen and is pure white
	color_rect.color = Color(1, 1, 1, 1)
	
	# 2. Set the pivot point to the exact center of the ColorRect
	color_rect.pivot_offset = color_rect.size / 2.0
	
	# 3. Start the ColorRect at scale 0 (infinitely small in the center)
	color_rect.scale = Vector2.ZERO
	color_rect.modulate.a = 1.0 # Ensure it is fully opaque
	
	# 4. Create the rapid center-out flashbang effect
	var tween = create_tween()
	# Scale up from 0 to 1 rapidly (0.05 seconds) using an exponential curve for extra punch
	tween.tween_property(color_rect, "scale", Vector2(1.0, 1.0), 0.05).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Slowly fade the opacity slightly to simulate the "blinding" effect wearing off
	tween.tween_property(color_rect, "modulate:a", 0.8, 3.0) 
	
	# 5. Play the initial Flashbang sound effect immediately
	flash_bang.play()
	
	# 6. Wait exactly 1.5 seconds
	await get_tree().create_timer(0.5).timeout
	
	# 7. Play the Ash Baby sound effect
	ash_baby_sound.play()
	
	# 8. Wait for the Ash Baby sound to finish playing entirely
	await ash_baby_sound.finished
	
	# 9. Transition to the actual Game Over screen
	get_tree().change_scene_to_file("res://scenes/System UI/game_over.tscn")
