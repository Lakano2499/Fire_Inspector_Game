extends StaticBody2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var interact_area = $interact
@onready var highlight_area = $area_seen

# We use get_node_or_null just in case you haven't added it yet!
@onready var alert_marker = get_node_or_null("AlertMarker") 

var is_completed = false
var has_poured_water = false

func _ready() -> void:
	# 1. Start safely at default state
	anim_sprite.play("default_state")
	
	# 2. Hide marker and disable all interactions while waiting
	if alert_marker:
		alert_marker.hide()
	_set_interactions_enabled(false)
	
	# 3. Connect our signals
	interact_area.interacted.connect(_on_interacted)
	anim_sprite.animation_finished.connect(_on_animation_finished)
	
	# 4. Start the hidden timer! 
	# CHANGE THIS TO 120.0 LATER FOR THE 2-MINUTE MARK
	var timer = get_tree().create_timer(5.0) 
	timer.timeout.connect(_start_fire)

func _start_fire() -> void:
	# The timer popped! Start the initial fire animation
	anim_sprite.play("burning_pan")
	
	# Turn on the map alert so the player knows there's an emergency!
	if alert_marker:
		alert_marker.show()

func _on_animation_finished() -> void:
	# Godot checks this function every time ANY animation finishes.
	
	if anim_sprite.animation == "burning_pan":
		# The initial spark finished, now loop the fire and let the player interact!
		anim_sprite.play("burning_pan_looping")
		_set_interactions_enabled(true)
		
	elif anim_sprite.animation == "burning_pan_pour_water":
		# The water splash finished, time for the consequences!
		anim_sprite.play("burning_pan_big_flame_loop")
		_set_interactions_enabled(true) # Let them try again
		
	elif anim_sprite.animation == "burning_pan_closing_with_lid":
		# The lid is securely on. End the task entirely!
		_mark_as_completed()

func _on_interacted() -> void:
	if is_completed:
		return
		
	# Pause the game and stop the player from moving
	get_tree().paused = true
	
	if not has_poured_water:
		# First attempt
		DialogueManager.show_dialogue("Berong", "Oh no! The pan is burning! What should we do to put it out?!", ["Close with Lid", "Pour Water"])
	else:
		# Second attempt (Water was a bad idea)
		# Notice the [1] at the end! That tells the manager to disable the "Pour Water" option.
		DialogueManager.show_dialogue("Berong", "Pouring water is a wrong choice, we should just close the lid!", ["Close with Lid", "Pour Water"], [1])
		
	var choice = await DialogueManager.choice_selected
	
	# Unpause the game immediately so animations can actually play
	get_tree().paused = false
	
	if choice == 0: # "Close with Lid"
		_set_interactions_enabled(false) # Disable clicks while animating
		if alert_marker:
			alert_marker.hide() # Turn off the quest marker!
		anim_sprite.play("burning_pan_closing_with_lid")
		
	elif choice == 1: # "Pour Water"
		has_poured_water = true
		_set_interactions_enabled(false) # Disable clicks while animating
		anim_sprite.play("burning_pan_pour_water")

# A quick helper function so we don't have to copy-paste this 4 times
func _set_interactions_enabled(enabled: bool) -> void:
	# Note: using set_deferred prevents physics glitching if disabled mid-collision
	interact_area.set_deferred("monitoring", enabled)
	interact_area.set_deferred("monitorable", enabled)
	highlight_area.set_deferred("monitoring", enabled)
	highlight_area.set_deferred("monitorable", enabled)

func _mark_as_completed() -> void:
	is_completed = true
	_set_interactions_enabled(false)
