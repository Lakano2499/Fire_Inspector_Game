extends Node

# --- NODE REFERENCES ---
@onready var report_text = $RichTextLabel
@onready var continue_btn = $ContinueButton

# --- VARIABLES ---
var is_showing_phase_2: bool = false

func _ready() -> void:
	# 1. Ensure the game is fully paused while reading the report
	get_tree().paused = true 
	
	# 2. Connect the button
	continue_btn.pressed.connect(_on_continue_pressed)
	
	# 3. Show the scores immediately when the scene loads
	_show_phase_1_scores()

func _show_phase_1_scores() -> void:
	var final_text = "[center][b]--- INSPECTION RESULTS ---[/b][/center]\n\n"
	
	# --- 1. CANDLE SCORE ---
	var candles_done = TaskManager.task_progress.get("Turn off lit candles", 0)
	var candle_score = candles_done * 5
	final_text += "Candles Extinguished: (" + str(candles_done) + "/3) -> [b]" + str(candle_score) + " / 15 Points[/b]\n\n"
	
	# --- 2. STOVE SCORE ---
	var stove_score = 0
	if TaskManager.house_burned_down:
		stove_score = 0
		final_text += "Grease Fire Contained: [color=red]FAILED (House Burned Down!)[/color] -> [b]0 / 10 Points[/b]\n\n"
	elif TaskManager.poured_water_on_grease:
		# Changed from -5 to 5. They get half credit for eventually fixing it!
		stove_score = 5 
		final_text += "Grease Fire Contained: [color=orange]POOR (Poured Water First!)[/color] -> [b]5 / 10 Points[/b]\n\n"
	elif TaskManager.stove_task_completed: # <--- CHECKING IF ACTUALLY DONE
		stove_score = 10
		final_text += "Grease Fire Contained: [color=green]PERFECT (Used Lid)[/color] -> [b]10 / 10 Points[/b]\n\n"
	else:
		# <--- IF NEITHER FAILED NOR COMPLETED, THEY SKIPPED IT!
		stove_score = 0
		final_text += "Grease Fire Contained: [color=red]FAILED (Ignored Hazard!)[/color] -> [b]0 / 10 Points[/b]\n\n"
		
	# --- 3. CLEAR TIME ---
	var total_sec = int(TaskManager.time_elapsed)
	var minutes = total_sec / 60
	var seconds = total_sec % 60
	var time_str = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
	final_text += "Clear Time: -> [b]" + time_str + "[/b]\n\n"
	
	# --- 4. TOTAL SCORE ---
	var total_score = candle_score + stove_score
	final_text += "[center][b]FINAL SCORE: " + str(total_score) + " / 25[/b][/center]"
	
	report_text.text = final_text
	continue_btn.text = "Read Report"

func _show_phase_2_summary() -> void:
	var final_text = "[center][b]--- EDUCATIONAL SUMMARY ---[/b][/center]\n\n"
	
	# --- 1. CANDLE FEEDBACK ---
	var candles_done = TaskManager.task_progress.get("Turn off lit candles", 0)
	if candles_done < 3:
		final_text += "[color=orange]Unattended Candles:[/color] You left a lit candle unattended! Even one candle can easily be knocked over by a breeze or a pet, starting a major fire.\n\n"
	else:
		final_text += "[color=green]Unattended Candles:[/color] Great job finding and putting out all the unattended candles!\n\n"
		
	# --- 2. STOVE FEEDBACK ---
	if TaskManager.house_burned_down:
		final_text += "[color=red]Grease Fire:[/color] You ignored the burning stove for too long! In a real emergency, a grease fire will quickly spread to the cabinets and consume the kitchen.\n\n"
	elif TaskManager.poured_water_on_grease:
		final_text += "[color=orange]Grease Fire:[/color] You poured water on a grease fire. Water causes boiling grease to explode outward, spreading the fire instantly. Always use a lid to cut off the oxygen.\n\n"
	elif TaskManager.stove_task_completed:
		final_text += "[color=green]Grease Fire:[/color] Excellent response to the stove fire! Using a lid safely suffocates the flames without causing a grease explosion.\n\n"
	else:
		# <--- THE SKIPPED HAZARD TEXT
		final_text += "[color=red]Grease Fire:[/color] You finished your inspection without securing the kitchen! Leaving a cooking pan unattended is a major hazard.\n\n"
		
	report_text.text = final_text
	continue_btn.text = "Finish Game"

# --- BUTTON LOGIC ---
func _on_continue_pressed() -> void:
	if not is_showing_phase_2:
		# If we are on Phase 1, clicking moves us to Phase 2
		is_showing_phase_2 = true
		_show_phase_2_summary()
	else:
		# If we are already on Phase 2, clicking ends the game!
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/System UI/title_screen.tscn")
