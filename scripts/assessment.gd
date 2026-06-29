extends CanvasLayer

@onready var report_text = $RichTextLabel
@onready var continue_btn = $NinePatchRect/ContinueButton

var is_showing_phase_2: bool = false
var final_total_score: int = 0 # <-- NEW: Variable to hold the score for the website
var task_scores_breakdown: Dictionary = {} # <-- NEW: Holds the individual scores

func _ready() -> void:
	get_tree().paused = true 
	continue_btn.pressed.connect(_on_continue_pressed)
	_show_phase_1_scores()

func _show_phase_1_scores() -> void:
	var final_text = "[center][b]--- INSPECTION RESULTS ---[/b][/center]\n\n"
	
	# 1. Candles (Max 12 -> 6 items @ 2 pts each)
	var candles_done = TaskManager.task_progress.get("Turn off lit candles", 0)
	var candle_score = candles_done * 2
	final_text += "Candles Extinguished: (" + str(candles_done) + "/6) -> [b]" + str(candle_score) + " / 12 Points[/b]\n\n"
	
	# 2. Stove (Max 10)
	var stove_score = 0
	if TaskManager.house_burned_down:
		stove_score = 0
		final_text += "Grease Fire Contained: [color=red]FAILED (House Burned Down!)[/color] -> [b]0 / 10 Points[/b]\n\n"
	elif TaskManager.poured_water_on_grease:
		stove_score = 5 
		final_text += "Grease Fire Contained: [color=orange]POOR (Poured Water First!)[/color] -> [b]5 / 10 Points[/b]\n\n"
	elif TaskManager.stove_task_completed: 
		stove_score = 10
		final_text += "Grease Fire Contained: [color=green]PERFECT (Used Lid)[/color] -> [b]10 / 10 Points[/b]\n\n"
	else:
		final_text += "Grease Fire Contained: [color=red]FAILED (Ignored Hazard!)[/color] -> [b]0 / 10 Points[/b]\n\n"
		
	# 3. Gas Leak (Max 10)
	var gas_leak_score = 0
	var gas_done = TaskManager.task_progress.get("Secure the gas leak", 0)
	if gas_done > 0:
		if TaskManager.gas_leak_penalty > 0:
			gas_leak_score = max(0, 10 - TaskManager.gas_leak_penalty)
			final_text += "Gas Leak Secured: [color=orange]POOR (Used Cloth First!)[/color] -> [b]" + str(gas_leak_score) + " / 10 Points[/b]\n\n"
		else:
			gas_leak_score = 10
			final_text += "Gas Leak Secured: [color=green]PERFECT (Turned off Valve)[/color] -> [b]10 / 10 Points[/b]\n\n"
	else:
		final_text += "Gas Leak Secured: [color=red]FAILED (Ignored Hazard!)[/color] -> [b]0 / 10 Points[/b]\n\n"
		
	# 4. Rice Cooker (Max 5)
	var rice_score = 0
	var rice_done = TaskManager.task_progress.get("Unplug the rice cooker", 0)
	if rice_done > 0:
		rice_score = 5
		final_text += "Rice Cooker Unplugged: [color=green]PERFECT[/color] -> [b]5 / 5 Points[/b]\n\n"
	else:
		final_text += "Rice Cooker Unplugged: [color=red]FAILED (Ignored Hazard!)[/color] -> [b]0 / 5 Points[/b]\n\n"
		
	# 5. Microwave (Max 5)
	var microwave_score = 0
	var microwave_done = TaskManager.task_progress.get("Remove foil from microwave", 0)
	if microwave_done > 0:
		microwave_score = 5
		final_text += "Microwave Foil Removed: [color=green]PERFECT[/color] -> [b]5 / 5 Points[/b]\n\n"
	else:
		final_text += "Microwave Foil Removed: [color=red]FAILED (Ignored Hazard!)[/color] -> [b]0 / 5 Points[/b]\n\n"

	# 6. Octopus Wiring (Max 10)
	var octopus_score = 0
	var octopus_done = TaskManager.task_progress.get("Fix octopus wiring", 0)
	if octopus_done > 0:
		if TaskManager.octopus_penalty > 0:
			octopus_score = max(0, 10 - TaskManager.octopus_penalty)
			final_text += "Octopus Wiring Fixed: [color=orange]POOR (Got shocked!)[/color] -> [b]" + str(octopus_score) + " / 10 Points[/b]\n\n"
		else:
			octopus_score = 10
			final_text += "Octopus Wiring Fixed: [color=green]PERFECT (Used Gloves)[/color] -> [b]10 / 10 Points[/b]\n\n"
	else:
		final_text += "Octopus Wiring Fixed: [color=red]FAILED (Ignored Hazard!)[/color] -> [b]0 / 10 Points[/b]\n\n"

	# 7. P.A.S.S. (Max 10)
	var pass_score = 0
	if TaskManager.pass_task_completed:
		if TaskManager.pass_task_perfect:
			pass_score = 10
			final_text += "Extinguisher Usage: [color=green]PERFECT (Flawless P.A.S.S.)[/color] -> [b]10 / 10 Points[/b]\n\n"
		else:
			pass_score = 5
			final_text += "Extinguisher Usage: [color=orange]POOR (Made mistakes)[/color] -> [b]5 / 10 Points[/b]\n\n"
	else:
		final_text += "Extinguisher Usage: [color=red]FAILED[/color] -> [b]0 / 10 Points[/b]\n\n"

	# 8. Cigarettes (Max 16 -> 8 items @ 2 pts each)
	var cigarette_score = 0
	var cigarettes_done = TaskManager.task_progress.get("Dispose of cigarettes", 0)
	cigarette_score = cigarettes_done * 2
	if cigarettes_done == 8:
		final_text += "Cigarette Disposal: [color=green]PERFECT (8/8)[/color] -> [b]" + str(cigarette_score) + " / 16 Points[/b]\n\n"
	elif cigarettes_done > 0:
		final_text += "Cigarette Disposal: [color=orange]POOR (" + str(cigarettes_done) + "/8)[/color] -> [b]" + str(cigarette_score) + " / 16 Points[/b]\n\n"
	else:
		final_text += "Cigarette Disposal: [color=red]FAILED[/color] -> [b]0 / 16 Points[/b]\n\n"

	# 9. Phones (Max 12 -> 4 items @ 3 pts each)
	var phone_score = 0
	var phones_done = TaskManager.task_progress.get("Unplug overcharging phones", 0)
	phone_score = phones_done * 3
	if phones_done == 4:
		final_text += "Phones Unplugged: [color=green]PERFECT (4/4)[/color] -> [b]" + str(phone_score) + " / 12 Points[/b]\n\n"
	elif phones_done > 0:
		final_text += "Phones Unplugged: [color=orange]POOR (" + str(phones_done) + "/4)[/color] -> [b]" + str(phone_score) + " / 12 Points[/b]\n\n"
	else:
		final_text += "Phones Unplugged: [color=red]FAILED[/color] -> [b]0 / 12 Points[/b]\n\n"
		
	# 10. Iron (Max 10)
	var iron_score = 0
	var iron_done = TaskManager.task_progress.get("Unplug the iron", 0)
	if iron_done > 0:
		if TaskManager.iron_penalty > 0:
			iron_score = max(0, 10 - TaskManager.iron_penalty)
			final_text += "Iron Unplugged: [color=orange]POOR (Made mistakes!)[/color] -> [b]" + str(iron_score) + " / 10 Points[/b]\n\n"
		else:
			iron_score = 10
			final_text += "Iron Unplugged: [color=green]PERFECT (Safe handling)[/color] -> [b]10 / 10 Points[/b]\n\n"
	else:
		final_text += "Iron Unplugged: [color=red]FAILED (Ignored Hazard!)[/color] -> [b]0 / 10 Points[/b]\n\n"

	# Calculate Total Math
	var total_sec = int(TaskManager.time_elapsed)
	var minutes = total_sec / 60
	var seconds = total_sec % 60
	var time_str = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
	final_text += "Clear Time: -> [b]" + time_str + "[/b]\n\n"
	
	var total_score = candle_score + stove_score + gas_leak_score + rice_score + microwave_score + octopus_score + pass_score + cigarette_score + phone_score + iron_score
	
	# --- NEW: Save the individual breakdown ---
	task_scores_breakdown = {
		"candles": candle_score,
		"stove": stove_score,
		"gas_leak": gas_leak_score,
		"rice_cooker": rice_score,
		"microwave": microwave_score,
		"octopus_wiring": octopus_score,
		"pass_extinguisher": pass_score,
		"cigarettes": cigarette_score,
		"phones": phone_score,
		"iron": iron_score
	}
	# ----------------------------------------
	
	# --- NEW: Save the score to the global variable! ---
	final_total_score = total_score 
	
	final_text += "[center][b]FINAL SCORE: " + str(total_score) + " / 100[/b][/center]"
	
	report_text.text = final_text
	continue_btn.text = "Read Report"

func _show_phase_2_summary() -> void:
	var final_text = "[center][b]--- EDUCATIONAL SUMMARY ---[/b][/center]\n\n"
	
	var candles_done = TaskManager.task_progress.get("Turn off lit candles", 0)
	if candles_done < 6: # <-- UPDATED FROM 3 TO 6
		final_text += "[color=orange]Unattended Candles:[/color] You left a lit candle unattended! Even one candle can easily be knocked over by a breeze or a pet, starting a major fire.\n\n"
	else:
		final_text += "[color=green]Unattended Candles:[/color] Great job finding and putting out all the unattended candles!\n\n"
		
	if TaskManager.house_burned_down:
		final_text += "[color=red]Grease Fire:[/color] You ignored the burning stove for too long! In a real emergency, a grease fire will quickly spread to the cabinets and consume the kitchen.\n\n"
	elif TaskManager.poured_water_on_grease:
		final_text += "[color=orange]Grease Fire:[/color] You poured water on a grease fire. Water causes boiling grease to explode outward, spreading the fire instantly. Always use a lid to cut off the oxygen.\n\n"
	elif TaskManager.stove_task_completed:
		final_text += "[color=green]Grease Fire:[/color] Excellent response to the stove fire! Using a lid safely suffocates the flames without causing a grease explosion.\n\n"
	else:
		final_text += "[color=red]Grease Fire:[/color] You finished your inspection without securing the kitchen! Leaving a cooking pan unattended is a major hazard.\n\n"
		
	var gas_done = TaskManager.task_progress.get("Secure the gas leak", 0)
	if gas_done > 0:
		if TaskManager.gas_leak_penalty > 0:
			final_text += "[color=orange]Gas Leak:[/color] You tried to cover a pressurized leak with a cloth before turning off the valve. Always shut off the source immediately and ventilate the area.\n\n"
		else:
			final_text += "[color=green]Gas Leak:[/color] Perfect response to the gas leak! Shutting off the valve and avoiding sparks prevents a catastrophic explosion.\n\n"
	else:
		final_text += "[color=red]Gas Leak:[/color] You left a leaking LPG cylinder unsecured! This highly flammable gas could have easily caused a massive explosion.\n\n"

	var rice_done = TaskManager.task_progress.get("Unplug the rice cooker", 0)
	if rice_done > 0:
		final_text += "[color=green]Rice Cooker:[/color] Great job! Unplugging heat-producing appliances when not in use is a major step in preventing electrical fires.\n\n"
	else:
		final_text += "[color=red]Rice Cooker:[/color] You left the rice cooker plugged in! Appliances that generate heat can easily overheat and ignite if left unattended.\n\n"

	var microwave_done = TaskManager.task_progress.get("Remove foil from microwave", 0)
	if microwave_done > 0:
		final_text += "[color=green]Microwave:[/color] Excellent catch! You safely removed the metal foil, preventing electrical arcing and a guaranteed fire.\n\n"
	else:
		final_text += "[color=red]Microwave:[/color] You missed the sparking microwave! Metal objects reflect microwaves, causing intense sparks that will quickly ignite the appliance.\n\n"

	var octopus_done = TaskManager.task_progress.get("Fix octopus wiring", 0)
	if octopus_done > 0:
		if TaskManager.octopus_penalty > 0:
			final_text += "[color=orange]Octopus Wiring:[/color] You eventually fixed it, but you grabbed a sparking wire barehanded first! Always use insulated protective gear like rubber gloves before touching an active electrical hazard.\n\n"
		else:
			final_text += "[color=green]Octopus Wiring:[/color] Great safety awareness! Using rubber gloves safely insulated you while unplugging the overloaded extension cord.\n\n"
	else:
		final_text += "[color=red]Octopus Wiring:[/color] You ignored an overloaded extension cord! 'Octopus wiring' is a leading cause of electrical fires due to extreme overheating.\n\n"

	# P.A.S.S. FEEDBACK
	if TaskManager.pass_task_completed:
		if TaskManager.pass_task_perfect:
			final_text += "[color=green]Extinguisher Usage:[/color] Outstanding! You remembered the P.A.S.S. method perfectly: Pull, Aim, Squeeze, Sweep.\n\n"
		else:
			final_text += "[color=orange]Extinguisher Usage:[/color] You put out the fire, but struggled with the extinguisher. Remember P.A.S.S.: Pull the pin, Aim at the base, Squeeze the lever, and Sweep side to side.\n\n"
	else:
		final_text += "[color=red]Extinguisher Usage:[/color] You failed to extinguish the spreading fire! Always sweep at the base of the flames.\n\n"

	# --- NEW: CIGARETTE FEEDBACK ---
	var cigarettes_done = TaskManager.task_progress.get("Dispose of cigarettes", 0)
	if cigarettes_done == 8:
		final_text += "[color=green]Cigarette Disposal:[/color] Excellent work finding and disposing of all the misplaced cigarettes. Improperly discarded smoking materials are a leading cause of fires.\n\n"
	elif cigarettes_done > 0:
		final_text += "[color=orange]Cigarette Disposal:[/color] You found some, but left a few cigarettes lying around. Even one smoldering butt can ignite nearby flammables.\n\n"
	else:
		final_text += "[color=red]Cigarette Disposal:[/color] You completely ignored the misplaced cigarettes! Discarded smoking materials are extremely dangerous and must be disposed of properly.\n\n"

	# --- OVERCHARGING PHONE FEEDBACK ---
	var phones_done = TaskManager.task_progress.get("Unplug overcharging phones", 0)
	if phones_done == 4:
		final_text += "[color=green]Overcharging Phones:[/color] Excellent work unplugging all the phones! Leaving charging devices on soft, flammable surfaces like beds is a major fire hazard.\n\n"
	elif phones_done > 0:
		final_text += "[color=orange]Overcharging Phones:[/color] You found some, but missed a few overcharging phones. Always unplug devices when fully charged to prevent the batteries from overheating.\n\n"
	else:
		final_text += "[color=red]Overcharging Phones:[/color] You completely ignored the overcharging phones! Batteries left plugged in on beds can easily overheat, melt, and ignite the surrounding fabric.\n\n"

	# --- IRON FEEDBACK ---
	var iron_done = TaskManager.task_progress.get("Unplug the iron", 0)
	if iron_done > 0:
		if TaskManager.iron_penalty > 0:
			final_text += "[color=orange]Unattended Iron:[/color] You secured the iron, but made dangerous mistakes first. Never pour water on a plugged-in appliance, and never touch the hot metal plate.\n\n"
		else:
			final_text += "[color=green]Unattended Iron:[/color] Excellent work! You safely unplugged the hot iron. Unattended irons left face-down are a major cause of rapid house fires.\n\n"
	else:
		final_text += "[color=red]Unattended Iron:[/color] You left a hot iron plugged in! This is a major fire hazard.\n\n"

	report_text.text = final_text
	continue_btn.text = "Finish Game"
	
func _on_continue_pressed() -> void:
	if not is_showing_phase_2:
		is_showing_phase_2 = true
		_show_phase_2_summary()
	else:
		TaskManager.save_progress(true)
		
		# --- UPDATED: SEND FULL SCORE DATA TO WEBSITE ---
		# Only run this if the game is being played in a web browser!
		if OS.has_feature("web"):
			# 1. Package everything into one clean dictionary
			var payload = {
				"type": "TASK_MASTER_WON",
				"score": final_total_score,
				"breakdown": task_scores_breakdown
			}
			
			# 2. Convert it into a JSON string that JavaScript can read
			var payload_json = JSON.stringify(payload)
			
			# 3. Inject it into the postMessage command
			var js_command = "window.parent.postMessage(" + payload_json + ", '*');"
			JavaScriptBridge.eval(js_command)
		# ------------------------------------------------
		
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/System UI/title_screen.tscn")
