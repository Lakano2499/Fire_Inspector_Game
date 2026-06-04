extends CanvasLayer

# --- PRELOADS ---
const PAUSE_MENU = preload("res://scenes/System UI/pause_menu.tscn")
const CHECKLIST_MENU = preload("res://scenes/System UI/checklist.tscn")
const GAME_OVER_SCREEN = preload("res://scenes/System UI/game_over.tscn")
const TITLE_SCREEN = "res://scenes/System UI/title_screen.tscn"
const ASSESSMENT_SCREEN = "res://scenes/System UI/assessment.tscn" 

# --- NODE REFERENCES ---
@onready var checklist_button = $CheckList 
@onready var game_over_test_btn = $GameOverTest 
@onready var game_finish_test_btn = get_node_or_null("GameFinishTest") # Used get_node_or_null just in case you deleted this button
@onready var timer_label = $TimerLabel 
@onready var danger_overlay = $DangerOverlay


# --- VARIABLES ---
var checklist_instance = null 
var is_game_over_active = false 
var game_over_timer: Timer
var pulse_time: float = 0.0

func _ready() -> void:
	# 1. WIPE THE SLATE CLEAN EVERY TIME THE LEVEL LOADS!
	TaskManager.reset_game_state()
	
	# 2. Connect standard buttons
	$Settings.pressed.connect(_on_settings_pressed)
	checklist_button.pressed.connect(_toggle_checklist)
	
	# Connect test buttons safely
	if game_over_test_btn:
		game_over_test_btn.pressed.connect(_trigger_actual_game_over) 
	if game_finish_test_btn:
		game_finish_test_btn.pressed.connect(_trigger_game_success)
	
	# 3. Listen for global TaskManager signals!
	TaskManager.game_over_triggered.connect(_trigger_actual_game_over)
	TaskManager.time_ran_out.connect(_on_time_ran_out)
	
	# THIS WAS MISSING! It tells the UI to route to success when the tasks are done.
	TaskManager.game_won_automatically.connect(_trigger_game_success)

func _process(delta: float) -> void:
	# 1. The standard clock logic
	var total_seconds = int(TaskManager.time_remaining)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	timer_label.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)

	# 2. THE DANGER OVERLAY LOGIC (Updated for accessibility)
	# Check if the fire is active, NOT completed, and the timer is actually ticking
	if TaskManager.stove_task_active and not TaskManager.stove_task_completed and TaskManager.stove_time_left > 0:
		
		# Lock the pulse to a constant, slow, comfortable speed
		var constant_speed = 1.5 
		
		pulse_time += delta * constant_speed
		
		# Use absolute sine wave to bounce between 0.0 (invisible) and 1.0 (fully red)
		var alpha_pop = abs(sin(pulse_time))
		
		# We multiply by 0.6 so the red is never 100% opaque, keeping the game visible
		danger_overlay.modulate.a = alpha_pop * 0.6 
		
	else:
		# If the task is safe (or hasn't started), keep the screen totally clear!
		danger_overlay.modulate.a = 0.0

func _on_settings_pressed() -> void:
	var pause_menu_instance = PAUSE_MENU.instantiate()
	add_child(pause_menu_instance)
	get_tree().paused = true

func _toggle_checklist() -> void:
	if checklist_instance == null:
		checklist_instance = CHECKLIST_MENU.instantiate()
		add_child(checklist_instance)
	else:
		if checklist_instance.visible:
			checklist_instance.hide()
		else:
			if checklist_instance.has_method("update_page"):
				checklist_instance.update_page() 
			checklist_instance.show()

# --- GAME OVER / TIMEOUT LOGIC ---
func _on_time_ran_out() -> void:
	if TaskManager.are_all_tasks_complete():
		_go_to_assessment() # They survived and finished the tasks!
	else:
		_trigger_actual_game_over() # They ran out of time before finishing!

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

func _input(event: InputEvent) -> void:
	if is_game_over_active:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_go_to_assessment()
		elif event is InputEventScreenTouch and event.pressed:
			_go_to_assessment()

func _go_to_assessment() -> void:
	is_game_over_active = false
	get_tree().paused = false 
	get_tree().change_scene_to_file(ASSESSMENT_SCREEN)

# --- SUCCESS LOGIC (THIS WAS MISSING!) ---
func _trigger_game_success() -> void:
	# Stop the clock to lock in their final time
	TaskManager.is_timer_running = false
	
	# Ensure the tree is unpaused so the assessment screen works properly
	get_tree().paused = false 
	
	# Bypass the Game Over screen entirely
	get_tree().change_scene_to_file(ASSESSMENT_SCREEN)
