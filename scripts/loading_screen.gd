extends CanvasLayer

@onready var truck_sprite = $AnimatedSprite2D
@onready var bg_rect = $ColorRect
@onready var loading_text = $LoadingText 

# Make sure this is the exact path to your main game scene!
var target_scene_path = "res://scenes/game_scenes/game.tscn"
var is_transitioning = false

func _ready() -> void:
	# Ensure the shader starts completely solid black
	if bg_rect.material:
		bg_rect.material.set_shader_parameter("progress", 0.0)
	
	# Save the center position where you placed the truck in the editor
	var center_x = truck_sprite.position.x
	
	# Hide the truck at the absolute leftmost part of the screen
	truck_sprite.position.x = -80 
	truck_sprite.modulate.a = 0.0
	
	# Hide the loading text initially
	if loading_text:
		loading_text.modulate.a = 0.0 
	
	# Create the entry animation sequence
	var entry_tween = create_tween()
	
	# 1. FIRST: Fade it from 0 to full visibility while sitting on the left
	entry_tween.tween_property(truck_sprite, "modulate:a", 1.0, 0.5)
	
	# 2. THEN: Drive it to the center with the heavy bounce
	entry_tween.tween_property(truck_sprite, "position:x", center_x, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# 3. FINALLY: Fade in the bouncing loading text!
	if loading_text:
		entry_tween.tween_property(loading_text, "modulate:a", 1.0, 0.3)
	
	# Start loading the heavy game scene in the background
	ResourceLoader.load_threaded_request(target_scene_path)

func _process(_delta: float) -> void:
	# Stop checking if we are already doing the cool transition
	if is_transitioning:
		return

	var progress = []
	var load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		is_transitioning = true
		_perform_transition()
		
	elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
		push_error("Loading failed! Check the file path.")
		set_process(false)

func _perform_transition() -> void:
	# 1. Grab the loaded game and put it BEHIND this black screen
	var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
	var game_instance = new_scene.instantiate()
	
	# Add it to the main tree and tell Godot it's the main scene now
	get_tree().root.add_child(game_instance)
	get_tree().current_scene = game_instance
	
	# 2. Create the Animation Tweens
	var tween = create_tween()
	tween.set_parallel(true) # Make everything animate at the same time
	
	# Fade out the loading text quickly before the truck even gets far
	if loading_text:
		tween.tween_property(loading_text, "modulate:a", 0.0, 0.8)
	
	# Truck drives off screen to the right (takes 0.8 seconds)
	var off_screen_x = get_viewport().get_visible_rect().size.x + 300
	tween.tween_property(truck_sprite, "position:x", off_screen_x, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
	# The wipe chases the truck!
	if bg_rect.material:
		tween.tween_property(bg_rect.material, "shader_parameter/progress", 1.0, 0.65).set_delay(0.6)
	
	# 3. Destroy this loading screen when the animations finish
	tween.chain().tween_callback(queue_free)
