extends CanvasLayer

# --- PRELOADS ---
const PAUSE_MENU = preload("res://scenes/System UI/pause_menu.tscn")
const CHECKLIST_MENU = preload("res://scenes/System UI/checklist.tscn")
const GAME_OVER_SCREEN = preload("res://scenes/System UI/game_over.tscn")
const TITLE_SCREEN = "res://scenes/System UI/title_screen.tscn"
const ASSESSMENT_SCREEN = "res://scenes/System UI/assessment.tscn"
const VICTORY_SCREEN = preload("res://scenes/System UI/Victory.tscn")
# --- NODE REFERENCES ---
@onready var checklist_button = $CheckList 
@onready var settings_button = $Settings # NEW: Reference to the Settings button
@onready var game_over_test_btn = get_node_or_null("GameOverTest")
@onready var game_finish_test_btn = get_node_or_null("GameFinishTest") 
@onready var timer_label = $TimerLabel 
@onready var danger_overlay = $DangerOverlay
@onready var checklist_pointer = get_node_or_null("CheckList/interact_indicator")

# --- MOBILE CONTROLS REFERENCES ---
@onready var joystick_base = get_node_or_null("MobileControls/JoystickBase")
@onready var joystick_knob = get_node_or_null("MobileControls/JoystickBase/Knob")

# --- NEW: BUTTON REFERENCES ---
@onready var interact_btn = get_node_or_null("MobileControls/Node/InteractButton")
@onready var dialogue_controls = get_node_or_null("MobileControls/Node/ForDialogueChoiceBox")
@onready var up_btn = get_node_or_null("MobileControls/Node/ForDialogueChoiceBox/up")
@onready var down_btn = get_node_or_null("MobileControls/Node/ForDialogueChoiceBox/down")

# --- VARIABLES ---
var checklist_instance = null 
var is_game_over_active = false 
var game_over_timer: Timer
var pulse_time: float = 0.0
var was_danger_active: bool = false

# --- JOYSTICK VARIABLES ---
var is_joystick_active: bool = false
var joystick_touch_id: int = -1
var joystick_center: Vector2
var joystick_max_dist: float = 60.0 

func _ready() -> void:
	TaskManager.reset_game_state()
	
	settings_button.pressed.connect(_on_settings_pressed)
	checklist_button.pressed.connect(_toggle_checklist)
	
	if game_over_test_btn:
		game_over_test_btn.pressed.connect(_trigger_actual_game_over) 
	if game_finish_test_btn:
		game_finish_test_btn.pressed.connect(_trigger_game_success)
	
	TaskManager.game_over_triggered.connect(_trigger_actual_game_over)
	TaskManager.time_ran_out.connect(_on_time_ran_out)
	TaskManager.game_won_automatically.connect(_trigger_game_success)
	
	if joystick_base:
		await get_tree().process_frame 
		joystick_center = joystick_base.global_position + (joystick_base.size / 2.0)

	# --- CONNECT MOBILE BUTTONS ---
	if interact_btn:
		interact_btn.button_down.connect(func():
			_simulate_action("interact", true) 
			_simulate_action("ui_accept", true) 
		)
		interact_btn.button_up.connect(func():
			_simulate_action("interact", false)
			_simulate_action("ui_accept", false)
		)

	if up_btn:
		# Flipped: Physical UP simulates ui_down to move down the visual list
		up_btn.button_down.connect(func(): _simulate_action("ui_down", true))
		up_btn.button_up.connect(func(): _simulate_action("ui_down", false))

	if down_btn:
		# Flipped: Physical DOWN simulates ui_up to move up the visual list
		down_btn.button_down.connect(func(): _simulate_action("ui_up", true))
		down_btn.button_up.connect(func(): _simulate_action("ui_up", false))


	# Start the music player (assuming the node name is InGameMusic)
	if get_node_or_null("InGameMusic"):
		$InGameMusic.play()

func _process(delta: float) -> void:
	# 1. Clock logic
	var total_seconds = int(TaskManager.time_remaining)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	timer_label.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)

	# --- POINTER VISIBILITY LOGIC ---
	if TaskManager.tutorial_pointer_active:
		if checklist_pointer: checklist_pointer.show()
	else:
		if checklist_pointer: checklist_pointer.hide()

	# 2. Danger Overlay Logic
	var is_danger_active = false
	
	# Check A: Is the main game stove on fire?
	if TaskManager.stove_task_active and not TaskManager.stove_task_completed and TaskManager.stove_time_left > 0:
		is_danger_active = true
		
	# Check B: Is the Tutorial Map emergency active?
	var current_map = get_tree().current_scene
	if current_map and "is_emergency_active" in current_map:
		if current_map.is_emergency_active:
			is_danger_active = true

	# --- NEW Check C: Is the P.A.S.S. extinguisher task active? ---
	if TaskManager.get("pass_emergency_active") == true:
		is_danger_active = true

	# Apply the pulse if ANY condition is true!
	if is_danger_active:
		var constant_speed = 1.5 
		pulse_time += delta * constant_speed
		danger_overlay.modulate.a = abs(sin(pulse_time)) * 0.6 
	else:
		danger_overlay.modulate.a = 0.0
		
	# --- GLOBAL ALARM SOUND LOGIC ---
	if is_danger_active and not was_danger_active:
		if get_node_or_null("AlarmSound"): 
			$AlarmSound.play()
			_fade_music(true) # FADE MUSIC OUT
			
	elif not is_danger_active and was_danger_active:
		if get_node_or_null("AlarmSound"): 
			$AlarmSound.stop()
			_fade_music(false) # FADE MUSIC IN
		
	was_danger_active = is_danger_active
		
	# 3. Dialogue Controls Visibility (UPDATED)
	if dialogue_controls:
		# ONLY show the up/down choice buttons if we are waiting for a choice AND they are on mobile
		if DialogueManager.is_awaiting_choice and TaskManager.is_mobile:
			dialogue_controls.show()
		else:
			dialogue_controls.hide()
			
	# 4. Mobile Controls & UI Visibility Logic (UPDATED)
	if DialogueManager.is_dialogue_active:
		# Hide the joystick and menus during dialogue to keep it clean
		if joystick_base: joystick_base.hide()
		if settings_button: settings_button.hide()
		
		# --- NEW: Show checklist IF the tutorial flag is active! ---
		if TaskManager.force_show_checklist:
			if checklist_button: checklist_button.show()
		else:
			if checklist_button: checklist_button.hide()
			
		if is_joystick_active: _reset_joystick()
	else:
		# Show menus when dialogue is over
		if settings_button: settings_button.show()
		if checklist_button: checklist_button.show()
		
		# Show joystick ONLY if on mobile
		if TaskManager.is_mobile:
			if joystick_base: joystick_base.show()
		else:
			if joystick_base: joystick_base.hide()

	# DEVICE CHECK FOR INTERACT BUTTON 
	if TaskManager.is_mobile:
		if interact_btn: interact_btn.show()
	else:
		if interact_btn: interact_btn.hide()

# --- AUDIO FADE LOGIC ---
var _saved_music_db: float = 0.0 # NEW: Variable to remember the player's volume setting

func _fade_music(fade_out: bool) -> void:
	var music_bus_index = AudioServer.get_bus_index("Music")
	var target_db: float
	
	if fade_out:
		# Save the player's current volume right before the alarm starts!
		_saved_music_db = AudioServer.get_bus_volume_db(music_bus_index)
		target_db = -60.0 # Fade out to nearly silent
	else:
		# Fade back in to whatever volume was saved!
		target_db = _saved_music_db
	
	var tween = create_tween()
	tween.tween_method(
		func(db): AudioServer.set_bus_volume_db(music_bus_index, db),
		AudioServer.get_bus_volume_db(music_bus_index),
		target_db,
		2.0 # Fade duration in seconds
	)

func _on_settings_pressed() -> void:
	var pause_menu_instance = PAUSE_MENU.instantiate()
	add_child(pause_menu_instance)
	get_tree().paused = true

func _toggle_checklist() -> void:
	TaskManager.checklist_tutorial_clicked.emit() 
	
	if checklist_instance == null:
		# Just load the standard checklist since tutorial checklist was deleted
		checklist_instance = CHECKLIST_MENU.instantiate()
		add_child(checklist_instance)
	else:
		if checklist_instance.visible:
			checklist_instance.hide()
		else:
			if checklist_instance.has_method("update_page"):
				checklist_instance.update_page() 
			checklist_instance.show()

# --- INPUT HANDLING & JOYSTICK LOGIC ---
func _input(event: InputEvent) -> void:
	if is_game_over_active:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_go_to_assessment()
		elif event is InputEventScreenTouch and event.pressed:
			_go_to_assessment()
		return

	# --- NEW: Stop the joystick from stealing inputs while paused! ---
	if get_tree().paused:
		return

	# Don't process joystick touch if it's currently hidden!
	if joystick_base and joystick_knob and joystick_base.visible:
		if event is InputEventScreenTouch:
			var touch_pos = event.position
			
			if event.pressed and not is_joystick_active:
				if touch_pos.distance_to(joystick_center) < 200.0: 
					is_joystick_active = true
					joystick_touch_id = event.index
					_update_joystick(touch_pos)
					
			elif not event.pressed and event.index == joystick_touch_id:
				_reset_joystick()
				
		elif event is InputEventScreenDrag and is_joystick_active and event.index == joystick_touch_id:
			_update_joystick(event.position)

func _update_joystick(touch_pos: Vector2) -> void:
	var offset = touch_pos - joystick_center
	
	if offset.length() > joystick_max_dist:
		offset = offset.normalized() * joystick_max_dist
		
	joystick_knob.global_position = joystick_center + offset - (joystick_knob.size / 2.0)
	
	var input_vector = offset / joystick_max_dist
	
	_simulate_action("ui_right", input_vector.x > 0.2)
	_simulate_action("ui_left", input_vector.x < -0.2)
	_simulate_action("ui_down", input_vector.y > 0.2)
	_simulate_action("ui_up", input_vector.y < -0.2)

func _reset_joystick() -> void:
	is_joystick_active = false
	joystick_touch_id = -1
	
	joystick_knob.global_position = joystick_center - (joystick_knob.size / 2.0)
	
	_simulate_action("ui_right", false)
	_simulate_action("ui_left", false)
	_simulate_action("ui_down", false)
	_simulate_action("ui_up", false)

func _simulate_action(action_name: String, is_pressed: bool) -> void:
	if is_pressed and not Input.is_action_pressed(action_name):
		var ev = InputEventAction.new()
		ev.action = action_name
		ev.pressed = true
		Input.parse_input_event(ev)
	elif not is_pressed and Input.is_action_pressed(action_name):
		var ev = InputEventAction.new()
		ev.action = action_name
		ev.pressed = false
		Input.parse_input_event(ev)

# --- GAME OVER / TIMEOUT LOGIC ---
func _on_time_ran_out() -> void:
	if TaskManager.are_all_tasks_complete():
		_go_to_assessment() 
	else:
		_trigger_actual_game_over() 

func _trigger_actual_game_over() -> void:
	if is_game_over_active:
		return
		
	is_game_over_active = true
	get_tree().paused = true 
	TaskManager.is_timer_running = false 
	
	var game_over_instance = GAME_OVER_SCREEN.instantiate()
	add_child(game_over_instance)
	
	game_over_timer = Timer.new()
	game_over_timer.wait_time = 8.0
	game_over_timer.one_shot = true
	game_over_timer.process_mode = Node.PROCESS_MODE_ALWAYS 
	add_child(game_over_timer)
	game_over_timer.timeout.connect(_go_to_assessment)
	game_over_timer.start()

func _go_to_assessment() -> void:
	is_game_over_active = false
	get_tree().paused = false 
	get_tree().change_scene_to_file(ASSESSMENT_SCREEN)

func _trigger_game_success() -> void:
	# Stop the clock and pause the game so the player and fire stop moving
	TaskManager.is_timer_running = false
	get_tree().paused = true 
	
	# 1. Spawn the Victory screen onto the screen
	var victory_instance = VICTORY_SCREEN.instantiate()
	add_child(victory_instance)
	
	# 2. Create a timer to let them look at it for a few seconds
	var victory_timer = Timer.new()
	victory_timer.wait_time = 4.0 # Change this to show it for more/less seconds!
	victory_timer.one_shot = true
	victory_timer.process_mode = Node.PROCESS_MODE_ALWAYS # Forces timer to run while game is paused
	
	# 3. Connect the timer so it triggers the Assessment screen when it finishes
	add_child(victory_timer)
	victory_timer.timeout.connect(_go_to_assessment)
	victory_timer.start()
