extends StaticBody2D

@export var fire_scene: PackedScene
@export var interact_action: String = "interact"
@export var starts_on_fire: bool = false
@export var ignition_delay: float = 0.0
@export var automatic_growth_time: float = 5.0 
@export var max_spray_distance: float = 250.0 
@export var aim_correction_degrees: float = 0.0 

@onready var interact_area: Area2D = $interact 
@onready var heat_area: Area2D = $heat_radius 
@onready var indicator = get_node_or_null("interact_indicator")

@onready var fire_placement: CollisionShape2D = get_node_or_null("fire_placement")
@onready var extinguisher_pivot = get_node_or_null("fire_extinguisher")
@onready var spray_sprite = get_node_or_null("fire_extinguisher/AnimatedSprite2D")
@onready var alert_marker = get_node_or_null("AlertMarker") # NEW: The Heartbeat Marker!
@onready var pointing_indicator = get_node_or_null("pointing") # <-- NEW: Reference to the pointer

var fires: Array = []
var fire_scale: float = 0.5
var max_fire_scale: float = 2.0
var is_burning: bool = false
var is_completed: bool = false
var aim_penalty: bool = false

var _player_nearby: bool = false
var is_interacting: bool = false 
var active_player: CharacterBody2D = null 

var is_manual_spraying: bool = false
var spray_mode: String = ""
var sweep_time: float = 0.0
var inactivity_timer: float = 0.0 # <-- NEW: Timer to track how long they stop clicking

# --- EMERGENCY VARIABLES ---
var fail_timer: Timer
var base_marker_scale: Vector2 = Vector2.ONE
var pulse_time: float = 0.0

func _ready() -> void:
	add_to_group("flammable_zone") 
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	
	if indicator: indicator.hide()
	if spray_sprite: spray_sprite.hide()
	if extinguisher_pivot: extinguisher_pivot.hide()
	if pointing_indicator: 
		pointing_indicator.hide() # Start hidden
	
	# Setup the Emergency Timer!
	fail_timer = Timer.new()
	fail_timer.wait_time = 30.0 
	fail_timer.one_shot = true
	add_child(fail_timer)
	fail_timer.timeout.connect(_on_fail_timeout)
	
	if alert_marker:
		alert_marker.hide()
		base_marker_scale = alert_marker.scale
	
	if starts_on_fire:
		if ignition_delay > 0.0:
			# Adding 'false' forces this timer to pause while reading dialogue!
			get_tree().create_timer(ignition_delay, false).timeout.connect(ignite)
		else:
			ignite()

# --- THE ZONE DEFENSE AIMING SYSTEM ---
func _process(delta: float) -> void:
	# 1. HEARTBEAT PULSE LOGIC
	if alert_marker and alert_marker.visible and fail_timer and fail_timer.time_left > 0:
		var time_ratio = fail_timer.time_left / fail_timer.wait_time
		var current_speed = lerp(30.0, 6.0, time_ratio)
		pulse_time += delta * current_speed
		var scale_pop = abs(sin(pulse_time)) * 0.4
		alert_marker.scale = base_marker_scale * (1.0 + scale_pop)

	if not is_manual_spraying: return
	
	var targets = []
	if is_burning: targets.append(self)
	
	var all_flammables = get_tree().get_nodes_in_group("flammable_zone")
	for body in all_flammables:
		if body != self and body.has_method("reduce_fire") and body.get("is_burning") == true:
			if global_position.distance_to(body.global_position) <= max_spray_distance:
				targets.append(body)
			
	if targets.size() == 0:
		end_minigame() 
		return
		
	var mouse_pos = get_global_mouse_position()
	var distance_to_fire = global_position.distance_to(mouse_pos)
	
	var is_holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var can_spray = is_holding and (distance_to_fire <= max_spray_distance)
	
	# --- POINTER INACTIVITY LOGIC ---
	if pointing_indicator:
		if can_spray:
			# They are actively spraying! Hide it and reset the clock.
			pointing_indicator.hide()
			inactivity_timer = 0.0
		else:
			# They stopped. Start counting!
			inactivity_timer += delta
			if inactivity_timer >= 3.0:
				pointing_indicator.show()
				pointing_indicator.z_index = 100 # Ensure it stays in front!
				var anim_child = pointing_indicator.get_node_or_null("AnimatedSprite2D")
				if anim_child and not anim_child.is_playing():
					anim_child.play()
	# -------------------------------------
	
	if can_spray:
		if not spray_sprite.visible:
			extinguisher_pivot.show()
			spray_sprite.show()
			spray_sprite.play("pull") 
			$ExtinguisherSound.play()
			
		extinguisher_pivot.global_position = mouse_pos
		extinguisher_pivot.scale.y = 1.0
		
		var closest_target = targets[0]
		var closest_dist = INF
		for t in targets:
			var t_pos = t.global_position
			if t.get_node_or_null("fire_placement"):
				t_pos = t.get_node("fire_placement").global_position
			var d = mouse_pos.distance_to(t_pos)
			if d < closest_dist:
				closest_dist = d
				closest_target = t
				
		var aim_center = closest_target.global_position
		if closest_target.get_node_or_null("fire_placement"):
			aim_center = closest_target.get_node("fire_placement").global_position
			
		extinguisher_pivot.look_at(aim_center)
		extinguisher_pivot.rotation += PI 
		
		var correction = deg_to_rad(aim_correction_degrees)
		if extinguisher_pivot.global_position.x < aim_center.x:
			extinguisher_pivot.rotation -= correction
			extinguisher_pivot.scale.y = -1 
		else:
			extinguisher_pivot.rotation += correction
			extinguisher_pivot.scale.y = 1 
			
		if spray_mode == "sweep":
			sweep_time += delta * 15.0 
			extinguisher_pivot.rotation += (sin(sweep_time) * 0.6)
		elif spray_mode == "random":
			extinguisher_pivot.rotation = randf_range(-PI, PI) 
			
		# --- NEW: PHYSICS-BASED HITBOX DETECTION ---
		# If fire_extinguisher is an Area2D, use its actual collision shape!
		if extinguisher_pivot is Area2D:
			var overlapping = extinguisher_pivot.get_overlapping_areas()
			var hit_flammables = []
			
			for area in overlapping:
				var parent = area.get_parent()
				# Check if the parent is a flammable object and we haven't already reduced it this frame
				if parent and parent.has_method("reduce_fire") and not hit_flammables.has(parent):
					hit_flammables.append(parent)
					
			for target_obj in hit_flammables:
				target_obj.reduce_fire(delta, spray_mode, aim_penalty)
				
		else:
			# Fallback to the old math logic if the Area2D isn't ready
			var nozzle_direction = -extinguisher_pivot.global_transform.x
			for t in targets:
				var t_pos = t.global_position
				if t.get_node_or_null("fire_placement"):
					t_pos = t.get_node("fire_placement").global_position
					
				var direction_to_t = extinguisher_pivot.global_position.direction_to(t_pos)
				
				if nozzle_direction.dot(direction_to_t) > 0.7:
					t.reduce_fire(delta, spray_mode, aim_penalty)
			
	else:
		if spray_sprite.visible:
			spray_sprite.hide()
			spray_sprite.stop()
			extinguisher_pivot.hide()
			$ExtinguisherSound.stop()

# --- FIRE SPREAD & SCALING ---
func ignite() -> void:
	if is_burning or is_completed: return
	is_burning = true
	$FireSound.play()
	
	TaskManager.pass_emergency_active = true
	
	if fail_timer.is_stopped(): fail_timer.start()
	if alert_marker: 
		alert_marker.show()
		if fire_placement:
			alert_marker.position = fire_placement.position + Vector2(0, -40)
	
	var spawn_range_x: float = 25.0
	var spawn_range_y: float = 25.0
	var spawn_center: Vector2 = Vector2.ZERO
	
	if fire_placement and fire_placement.shape:
		var extents = fire_placement.shape.size / 2.0
		spawn_range_x = extents.x
		spawn_range_y = extents.y
		spawn_center = fire_placement.position
	
	# --- NEW: SPACING LOGIC FOR FLAMES ---
	var placed_positions = []
	
	for i in range(randi_range(3, 5)):
		var f = fire_scene.instantiate()
		var random_pos = Vector2.ZERO
		
		# Try up to 10 times to find a spot that is far enough from other flames
		for attempt in range(10):
			var random_x = randf_range(-spawn_range_x, spawn_range_x)
			var random_y = randf_range(-spawn_range_y, spawn_range_y)
			random_pos = spawn_center + Vector2(random_x, random_y)
			
			var too_close = false
			for p in placed_positions:
				if random_pos.distance_to(p) < 40.0: # <-- Requires 40 pixels of space! Change this if you need more/less room.
					too_close = true
					break
					
			if not too_close:
				break # Found a good, spacious spot!
				
		placed_positions.append(random_pos)
		f.position = random_pos
		f.scale = Vector2(fire_scale, fire_scale)
		add_child(f)
		fires.append(f)
		f.get_node("AnimatedSprite2D").play("default")
		
	var spread_timer = Timer.new()
	spread_timer.name = "SpreadTimer"
	spread_timer.wait_time = automatic_growth_time
	spread_timer.autostart = true
	spread_timer.timeout.connect(_grow_fire_penalty)
	add_child(spread_timer)
	
	if _player_nearby and not is_interacting and indicator:
		indicator.show()

func _grow_fire_penalty() -> void:
	if not is_burning: return
	fire_scale += 0.5
	if fire_scale >= max_fire_scale:
		fire_scale = max_fire_scale
		_spread_fire()
		
	for f in fires:
		if is_instance_valid(f):
			var tween = create_tween()
			tween.tween_property(f, "scale", Vector2(fire_scale, fire_scale), 0.5)

func _spread_fire() -> void:
	var all_flammables = get_tree().get_nodes_in_group("flammable_zone")
	for body in all_flammables:
		if body != self and body.has_method("ignite"):
			if global_position.distance_to(body.global_position) <= max_spray_distance:
				body.ignite()

func reduce_fire(delta: float, mode: String, penalty: bool) -> void:
	if not is_burning: return
	
	var shrink_rate: float = 0.0
	# NEW: Brutal difficulty modifiers!
	if mode == "sweep": 
		shrink_rate = 1.0 # Standard fast clear
	elif mode == "focus": 
		shrink_rate = 0.25 # Extremely hard. Takes 8 solid seconds of perfect aiming!
	elif mode == "random": 
		shrink_rate = 0.05 # Basically nothing. Only visually shrinks slightly.
		
	fire_scale -= shrink_rate * delta
	if fire_scale < 0.0: fire_scale = 0.0
		
	for f in fires:
		if is_instance_valid(f): f.scale = Vector2(fire_scale, fire_scale)
			
	if fire_scale <= 0.05:
		put_out_local_fire()

func put_out_local_fire() -> void:
	is_burning = false
	is_completed = true 
	$FireSound.stop()
	
	if indicator: indicator.hide()
	if pointing_indicator: pointing_indicator.hide() # <-- ADD THIS LINE
	
	var timer = get_node_or_null("SpreadTimer")
	if timer: timer.queue_free()
		
	for f in fires:
		if is_instance_valid(f): f.queue_free()
	fires.clear()

func _on_fail_timeout() -> void:
	TaskManager.house_burned_down = true 
	TaskManager.game_over_triggered.emit()

func end_minigame() -> void:
	is_manual_spraying = false
	is_interacting = false 
	if pointing_indicator: pointing_indicator.hide() # <-- ADD THIS LINE
	
	if spray_sprite:
		spray_sprite.hide()
		spray_sprite.stop()
	if extinguisher_pivot:
		extinguisher_pivot.hide()
	$ExtinguisherSound.stop()
		
	# Master clear: Kill all timers and markers in the zone!
	var all_flammables = get_tree().get_nodes_in_group("flammable_zone")
	for f in all_flammables:
		if f.get("fail_timer") and not f.fail_timer.is_stopped():
			f.fail_timer.stop()
		if f.get("alert_marker") and f.alert_marker:
			f.alert_marker.hide()
			
	# --- NEW: Tell the UI the emergency is over! ---
	TaskManager.pass_emergency_active = false
	
	TaskManager.pass_task_completed = true
	TaskManager.player_can_move = true

# --- INTERACTION & MINIGAME ---
func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or not is_burning or is_completed or is_interacting: return
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_trigger_pass_minigame()

func _trigger_pass_minigame() -> void:
	# --- NEW: CHECK FOR EXTINGUISHER ---
	if not TaskManager.has_fire_extinguisher:
		get_tree().paused = true
		DialogueManager.show_dialogue("Player", "The fire is too big! I need to find a fire extinguisher first!", ["I'll find it!"])
		await DialogueManager.choice_selected
		get_tree().paused = false
		return # Stop the rest of the function from running!
	# -----------------------------------

	# --- THE FIX: Lock down EVERY cabinet in the zone! ---
	var all_flammables = get_tree().get_nodes_in_group("flammable_zone")
	for f in all_flammables:
		f.is_interacting = true # Tell all neighboring cabinets to ignore inputs!
		if f.has_method("_set_interactions_enabled"):
			f._set_interactions_enabled(false) # Shut off their collision areas
		if f.get("indicator") and f.indicator:
			f.indicator.hide() # Force all their arrows to hide
			
	get_tree().paused = true
	
	var flawless_run: bool = true
	# STEP 1
	var step1_choices = ["Twist the valve", "Pull the pin", "Pull the hose"]
	var passed_step1 = false
	var disabled_step1: Array = [] 
	while not passed_step1:
		DialogueManager.show_dialogue("System", "STEP 1: What is the first thing you do?", step1_choices, disabled_step1)
		var choice = await DialogueManager.choice_selected
		if choice == 1: passed_step1 = true
		else:
			flawless_run = false
			_grow_fire_penalty()
			disabled_step1.append(choice) 
			DialogueManager.show_dialogue("System", "Wrong! The fire is growing faster!", ["Try Again"])
			await DialogueManager.choice_selected
			
	# STEP 2
	var step2_choices = ["Aim at the top of the flames", "Aim at the smoke", "Aim at the base of the fire"]
	DialogueManager.show_dialogue("System", "STEP 2: Where do you aim the nozzle?", step2_choices)
	var choice2 = await DialogueManager.choice_selected
	if choice2 != 2: flawless_run = false
		
	# STEP 3
	var step3_choices = ["Shake the cylinder", "Squeeze the lever", "Press the pressure gauge"]
	var passed_step3 = false
	var disabled_step3: Array = [] 
	while not passed_step3:
		DialogueManager.show_dialogue("System", "STEP 3: How do you release the agent?", step3_choices, disabled_step3)
		var choice3 = await DialogueManager.choice_selected
		if choice3 == 1: passed_step3 = true
		else:
			flawless_run = false
			_grow_fire_penalty()
			disabled_step3.append(choice3) 
			DialogueManager.show_dialogue("System", "Wrong! The fire is spreading!", ["Try Again"])
			await DialogueManager.choice_selected

	# STEP 4
	DialogueManager.show_dialogue("System", "STEP 4: How do you apply the spray?", ["Focus the spray", "Random spray", "Sweep spray"])
	var choice4 = await DialogueManager.choice_selected
	if choice4 != 2: flawless_run = false
	
	get_tree().paused = false
	
	spray_mode = "focus"
	if choice4 == 1: spray_mode = "random"
	elif choice4 == 2: spray_mode = "sweep"
	
	TaskManager.pass_task_perfect = flawless_run
	
	# THE PUNISHMENT LOGIC
	if flawless_run:
		# (We removed the 'var' here to fix that previous red error!)
		all_flammables = get_tree().get_nodes_in_group("flammable_zone")
		for f in all_flammables:
			if f.get("fail_timer") and not f.fail_timer.is_stopped():
				f.fail_timer.stop()
				
		DialogueManager.show_dialogue("System", "Perfect P.A.S.S.! Hold Left Click/Touch to sweep the fire!", ["Got it"])
	else:
		if choice4 != 2: 
			# Chose the wrong spray mode! Give them a harsh 10-second penalty timer
			fail_timer.start(10.0)
			DialogueManager.show_dialogue("System", "WARNING: Incorrect method! You have 10 seconds to stop the fire!", ["Got it"])
		else:
			# Made mistakes early on, but chose Sweep. Let the original timer continue.
			DialogueManager.show_dialogue("System", "Hold Left Click/Touch to sweep the fire!", ["Got it"])

	await DialogueManager.choice_selected
	
	TaskManager.player_can_move = false
	
	# 1. Grace period: guarantees the player has lifted their finger from the dialogue box.
	await get_tree().create_timer(0.5).timeout
	
	is_manual_spraying = true
	sweep_time = 0.0
	
	# 2. Start at 3.0 so the pointer appears instantly on the first frame!
	inactivity_timer = 3.0
	
	if pointing_indicator:
		pointing_indicator.show()
		pointing_indicator.z_index = 100 # Force it to render OVER the fire!
		var anim_child = pointing_indicator.get_node_or_null("AnimatedSprite2D")
		if anim_child:
			anim_child.play()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = true
		active_player = body 
		if is_burning and not is_completed and not is_interacting:
			if indicator: indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		if not is_interacting: active_player = null 
		if indicator: indicator.hide()
