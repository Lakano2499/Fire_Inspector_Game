extends StaticBody2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var interact_area = $interact
@onready var highlight_area = $area_seen

# We use get_node_or_null just in case you haven't added it yet!
@onready var alert_marker = get_node_or_null("AlertMarker") 

var is_completed = false
var has_poured_water = false
var fail_timer: Timer

# --- BEATING MARKER VARIABLES ---
var base_marker_scale: Vector2 = Vector2.ONE
var pulse_time: float = 0.0

func _ready() -> void:
	# 1. Start safely at default state
	anim_sprite.play("default_state")
	
	# 2. Hide marker and disable all interactions while waiting
	if alert_marker:
		alert_marker.hide()
		base_marker_scale = alert_marker.scale
	_set_interactions_enabled(false)
	
	fail_timer = Timer.new()
	fail_timer.wait_time = 30.0 # 30 seconds to fix the fire!
	fail_timer.one_shot = true
	add_child(fail_timer)
	fail_timer.timeout.connect(_on_fail_timeout)
	
	# 3. Connect our signals
	interact_area.interacted.connect(_on_interacted)
	anim_sprite.animation_finished.connect(_on_animation_finished)
	
	# 4. Start the hidden timer! 
	# (Using a standard Timer node ensures it freezes when the game is paused for dialogue)
	var start_timer = Timer.new()
	start_timer.wait_time = 120.0 # 2-Minute mark to start the fire
	start_timer.one_shot = true
	add_child(start_timer)
	start_timer.timeout.connect(_start_fire)
	start_timer.start()
	
func _process(delta: float) -> void:
	# 1. Constantly tell the global manager how much time is left!
	if fail_timer and not fail_timer.is_stopped():
		TaskManager.stove_time_left = fail_timer.time_left
		TaskManager.stove_wait_time = fail_timer.wait_time
	else:
		TaskManager.stove_time_left = 0.0
		
	# 2. THE HEARTBEAT LOGIC
	if alert_marker and alert_marker.visible and fail_timer and fail_timer.time_left > 0:
		var time_ratio = fail_timer.time_left / fail_timer.wait_time
		var current_speed = lerp(30.0, 6.0, time_ratio)
		
		pulse_time += delta * current_speed
		var scale_pop = abs(sin(pulse_time)) * 0.4
		
		var safe_scale = base_marker_scale
		if safe_scale == Vector2.ZERO:
			safe_scale = Vector2(1.0, 1.0)
			
		alert_marker.scale = safe_scale * (1.0 + scale_pop)

func _start_fire() -> void:
	# The timer popped! Start the initial fire animation
	anim_sprite.play("burning_pan")
	
	fail_timer.start()
	
	# Turn on the map alert so the player knows there's an emergency!
	if alert_marker:
		alert_marker.show()
	
	TaskManager.stove_task_active = true
		
func _on_fail_timeout() -> void:
	TaskManager.house_burned_down = true 
	TaskManager.game_over_triggered.emit()

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
		
		# --- NEW: Tell the Brain about the mistake! ---
		TaskManager.poured_water_on_grease = true 
		
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
	
	# Stop the fail timer, they saved the house!
	if fail_timer:
		fail_timer.stop() 
		
	if alert_marker:
		alert_marker.scale = base_marker_scale
		
	# 1. TELL THE MANAGER THE STOVE IS SAFE FIRST!
	TaskManager.stove_task_completed = true
	
	# 2. THEN ASK IT TO CHECK FOR THE WIN!
	TaskManager.check_for_auto_win()
