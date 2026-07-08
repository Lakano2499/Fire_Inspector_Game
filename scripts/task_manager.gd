extends Node

signal tasks_updated
signal time_ran_out 
signal game_won_automatically 
signal game_over_triggered
signal checklist_tutorial_clicked

# --- SAVE DATA VARIABLES ---
var current_user_id: String = "guest"
var current_player_name: String = ""

# --- CLOUD SAVING LOGIC VARIABLES ---
var api_save_url: String = "http://192.168.1.2:8000/api/games/taskmaster/save" # Fallback
var api_load_url: String = "http://192.168.1.2:8000/api/games/taskmaster/load" # Fallback

# --- TIMER VARIABLES ---
var time_elapsed: float = 0.0 
var time_remaining: float = 300.0 
var is_timer_running: bool = true
var is_mobile: bool = true 
var force_show_checklist: bool = false
var tutorial_pointer_active: bool = false
var is_map1_unlocked: bool = false
var selected_character_path: String = "res://characters/berong.tscn"
var selected_character: String = "berong"

# --- SCENE TRANSITION DATA ---
var target_level_path: String = ""

# --- ASSESSMENT TRACKERS ---
var iron_penalty: int = 0
var gas_leak_penalty: int = 0
var octopus_penalty: int = 0 
var poured_water_on_grease: bool = false
var house_burned_down: bool = false
var stove_task_completed: bool = false 
var cigarettes_held: int = 0

# --- THE FIX: These were missing from the top! ---
var pass_task_completed: bool = false
var pass_task_perfect: bool = false
	
# --- NEW: DANGER TRACKERS ---
var stove_task_active: bool = false
var stove_time_left: float = 0.0
var stove_wait_time: float = 30.0
var pass_emergency_active: bool = false
var has_fire_extinguisher: bool = false # <-- NEW VARIABLE

# --- GAME OVER TRACKER ---
var game_over_reason: String = "burned" # Defaults to fire

var master_task_list: Array = []
var task_max: Dictionary = {}
var task_progress: Dictionary = {}
var player_can_move: bool = true 

func _ready() -> void:
	# Only run this if playing in the web browser
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		if window != null:
			var url_params = JavaScriptBridge.create_object("URLSearchParams", window.location.search)
			
			# Grab the user ID
			if url_params.has("user_id"):
				current_user_id = str(url_params.get("user_id"))
				
			# Grab the player name
			if url_params.has("player_name"):
				current_player_name = str(url_params.get("player_name"))
				
		# --- NEW: Dynamically grab the website domain! ---
		var current_domain = JavaScriptBridge.eval("window.location.origin")
		if current_domain != null:
			api_save_url = str(current_domain) + "/api/games/taskmaster/save"
			api_load_url = str(current_domain) + "/api/games/taskmaster/load"
				
	load_progress()
	reset_game_state()
		
# --- RESET GAME STATE ---
func reset_game_state() -> void:
	iron_penalty = 0
	gas_leak_penalty = 0
	octopus_penalty = 0 
	time_elapsed = 0.0
	time_remaining = 480.0 
	is_timer_running = true
	
	poured_water_on_grease = false
	house_burned_down = false
	stove_task_completed = false
	
	stove_task_active = false
	stove_time_left = 0.0
	pass_emergency_active = false
	has_fire_extinguisher = false # <-- ADD THIS LINE
	
	pass_task_completed = false
	pass_task_perfect = false
	
	cigarettes_held = 0 
	
	game_over_reason = "burned"
	
	master_task_list = [
		"Turn off lit candles", 
		"Secure the gas leak",
		"Unplug the rice cooker",
		"Remove foil from microwave",
		"Fix octopus wiring",
		"Collect misplaced cigarettes", 
		"Dispose of cigarettes",
		"Unplug overcharging phones",
		"Unplug the iron" # <-- NEW TASK       
	]
	
	task_max = {
		"Turn off lit candles": 6, # <-- UPDATED FROM 3 TO 6
		"Secure the gas leak": 1,
		"Unplug the rice cooker": 1,
		"Remove foil from microwave": 1,
		"Fix octopus wiring": 3,
		"Collect misplaced cigarettes": 8, 
		"Dispose of cigarettes": 8,
		"Unplug overcharging phones": 4, # <-- NEW TASK TRACKER        
		"Unplug the iron":2 # <-- NEW TASK TRACKER        
	}
	
	# Wipe the checklist clean and rebuild the dictionary
	task_progress.clear()
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
			
# --- -WIN LOGIC ---
func check_for_auto_win() -> void:
	# 1. Check if all standard checklist tasks are maxed out
	for task in master_task_list:
		if task_progress[task] < task_max[task]:
			return # Someone hasn't finished the checklist! Exit.
			
	# 2. Check if the emergency stove task is completely safe
	if not stove_task_completed:
		return # The stove is still a hazard! Exit.
		
	# 3. If we made it this far, EVERYTHING is done! Tell the UI!dw
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

# --- CLOUD SAVING LOGIC ---

func save_progress(map1_unlocked: bool) -> void:
	# Don't try to save to the database if they are just testing locally
	if current_user_id == "guest" or current_user_id == "": 
		return 
		
	var data = {
		"user_id": current_user_id,
		"player_name": current_player_name,
		"map1_unlocked": map1_unlocked
	}
	
	# 1. Create a temporary HTTP Request node
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 2. Tell the node to delete itself automatically when it finishes sending
	http_request.request_completed.connect(func(_result, _response_code, _headers, _body):
		http_request.queue_free()
	)
	
	# 3. Format the data as JSON and send the POST request to the server
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(api_save_url, headers, HTTPClient.METHOD_POST, json_data)


func load_progress() -> void:
	if current_user_id == "guest" or current_user_id == "": 
		return

	# 1. Create a temporary HTTP Request node
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 2. Setup what happens when the server replies
	http_request.request_completed.connect(func(_result, response_code, _headers, body):
		http_request.queue_free() # Clean up the node
		
		# If the server replies with 200 (OK), read the data!
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				
				# Unlock the map if the database says it is unlocked
				if data.has("map1_unlocked") and data["map1_unlocked"] == true:
					is_map1_unlocked = true
					
				# Update the player's name from the database
				if data.has("player_name") and data["player_name"] != null:
					current_player_name = str(data["player_name"])
	)
	
	# 3. Send the GET request 
	# (We append the user_id to the URL so the server knows who to look for)
	var fetch_url = api_load_url + "?user_id=" + str(current_user_id)
	http_request.request(fetch_url)
