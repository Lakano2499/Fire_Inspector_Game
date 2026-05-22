extends Node

signal tasks_updated
signal time_ran_out 
signal game_won_automatically 
signal game_over_triggered # (Just making sure this is declared!)

# --- TIMER VARIABLES ---
var time_elapsed: float = 0.0 
var time_remaining: float = 60.0 
var is_timer_running: bool = true

# --- ASSESSMENT TRACKERS ---
var poured_water_on_grease: bool = false
var house_burned_down: bool = false
var stove_task_completed: bool = false 

# --- NEW: DANGER TRACKERS ---
var stove_task_active: bool = false
var stove_time_left: float = 0.0
var stove_wait_time: float = 30.0

var master_task_list: Array = [
	"Turn off lit candles", 
]

var task_max: Dictionary = {
	"Turn off lit candles": 3, 
}

var task_progress: Dictionary = {}

var player_can_move: bool = true 

func _ready() -> void:
	# We intentionally leave this blank because the UI will trigger the reset!
	pass
		
# --- RESET GAME STATE ---
func reset_game_state() -> void:
	time_elapsed = 0.0
	time_remaining = 60.0 # Reset to 1 minute!
	is_timer_running = true
	
	poured_water_on_grease = false
	house_burned_down = false
	stove_task_completed = false
	
	stove_task_active = false
	stove_time_left = 0.0
	
	# Wipe the checklist clean
	for task in master_task_list:
		task_progress[task] = 0

func _process(delta: float) -> void:
	if is_timer_running:
		time_elapsed += delta 
		time_remaining -= delta # Count down!
		
		# Did the clock hit zero?
		if time_remaining <= 0.0:
			time_remaining = 0.0
			is_timer_running = false
			time_ran_out.emit()
			
# --- AUTO-WIN LOGIC ---
func check_for_auto_win() -> void:
	# 1. Check if all standard checklist tasks are maxed out
	for task in master_task_list:
		if task_progress[task] < task_max[task]:
			return # Someone hasn't finished the checklist! Exit.
			
	# 2. Check if the emergency stove task is completely safe
	if not stove_task_completed:
		return # The stove is still a hazard! Exit.
		
	# 3. If we made it this far, EVERYTHING is done! Tell the UI!
	game_won_automatically.emit()

func complete_task(task_name: String) -> void:
	if task_progress.has(task_name) and task_progress[task_name] < task_max[task_name]:
		task_progress[task_name] += 1
		print("Checklist updated: ", task_name, " ", task_progress[task_name], "/", task_max[task_name])
		
		tasks_updated.emit()
		check_for_auto_win() # <-- Check if this was the final task!

func are_all_tasks_complete() -> bool:
	for task in master_task_list:
		if task_progress[task] < task_max[task]:
			return false 
	if not stove_task_completed:
		return false 	
	
	return true
