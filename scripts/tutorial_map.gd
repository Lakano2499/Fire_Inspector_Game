extends Node2D

@export var fire_task_node: StaticBody2D 

var basic_tasks_completed: int = 0
var is_emergency_active: bool = false
var is_emergency_done: bool = false

func _ready() -> void:
	# 1. Reset everything first (this wipes out any old data)
	TaskManager.reset_game_state()
	
	# 2. OVERWRITE the main game tasks with the tutorial tasks
	TaskManager.master_task_list = ["Task 1", "Task 2", "Task 3"]
	TaskManager.task_max = {"Task 1": 1, "Task 2": 1, "Task 3": 1}
	
	# 3. Rebuild the progress dictionary so the checklist doesn't crash
	TaskManager.task_progress.clear()
	for task in TaskManager.master_task_list:
		TaskManager.task_progress[task] = 0
		
	TaskManager.is_timer_running = false
	
	# Start the interactive tutorial sequence!
	_run_intro_sequence()

# --- THE 6-STEP TUTORIAL SEQUENCE ---
func _run_intro_sequence() -> void:
	# Wait just half a second for the map to load visually before pausing
	await get_tree().create_timer(0.5).timeout 
	
	get_tree().paused = true
	
	# Step 1 & 2: Greet and ask for device
	DialogueManager.show_dialogue("System", "Welcome to the Fire Inspector Tutorial! What device are you playing on?", ["Mobile", "Computer"])
	var choice = await DialogueManager.choice_selected
	
	# Step 3: Explain the controls based on their choice
	if choice == 0:
		TaskManager.is_mobile = true
		DialogueManager.show_dialogue("System", "Mobile selected. Use the on-screen joystick to move, and the bottom-right button to interact.", ["Continue"])
		await DialogueManager.choice_selected
	else:
		TaskManager.is_mobile = false
		DialogueManager.show_dialogue("System", "Computer selected. Press W,A,S,D to move, and 'F' to interact.", ["Continue"])
		await DialogueManager.choice_selected
		
	# --- Introduce the Checklist ---
	TaskManager.force_show_checklist = true 
	TaskManager.tutorial_pointer_active = true 
	
	DialogueManager.show_dialogue("System", "Tap the clipboard icon with the arrow pointing to it to open your Checklist.", [])
	
	await TaskManager.checklist_tutorial_clicked
	
	TaskManager.tutorial_pointer_active = false 
	
	DialogueManager.show_dialogue("System", "Great! You can check this anytime to see your required tasks.", ["Got it"])
	await DialogueManager.choice_selected
	
	TaskManager.force_show_checklist = false 
		
	# Step 4: Tell them the objective
	DialogueManager.show_dialogue("System", "To pass this tutorial, find all the highlighted objects in this room and inspect them.", ["Start"])
	await DialogueManager.choice_selected


func report_task_finished() -> void:
	basic_tasks_completed += 1	
	
	if basic_tasks_completed == 2:
		is_emergency_active = true
		if fire_task_node:
			fire_task_node.start_emergency()
			
		# Step 5: The Emergency Callout
		get_tree().paused = true
		DialogueManager.show_dialogue("System", "WARNING: An immediate fire hazard has appeared! Emergencies always come first. Go put it out!", ["Understood"])
		await DialogueManager.choice_selected
		get_tree().paused = false
			
	check_tutorial_complete()

func report_emergency_finished() -> void:
	is_emergency_active = false
	is_emergency_done = true
	
	# Step 6: The Wrap-up Callout
	get_tree().paused = true
	DialogueManager.show_dialogue("System", "Great job handling the emergency! Now, finish inspecting the remaining highlighted object.", ["Continue"])
	await DialogueManager.choice_selected
	get_tree().paused = false
	
	check_tutorial_complete()

func check_tutorial_complete() -> void:
	if basic_tasks_completed == 3 and is_emergency_done:
		get_tree().paused = true
		
		DialogueManager.show_dialogue("System", "Tutorial Complete! You unlocked Map 1. Returning to Main Menu.", ["Continue"])
		await DialogueManager.choice_selected
		get_tree().paused = false
		
		TaskManager.is_map1_unlocked = true
		get_tree().change_scene_to_file("res://scenes/System UI/main_menu.tscn")
