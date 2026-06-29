extends Control

# --- NODE REFERENCES ---
@onready var tutorial_play_btn = $Node/TutorialMap/PlayButton
@onready var map1_play_btn = $Node/Map1/PlayButton
@onready var map1_lock = $Node/Map1/Lock
@onready var back_btn = $Node/Button 
@onready var character_select_btn = $NinePatchRect/CharacterSelect
@onready var skip_tutorial_btn = $Node/SkipTutorial # Added Node/ to the path!

func _ready() -> void:
	# 1. Connect all the buttons to their functions
	tutorial_play_btn.pressed.connect(_on_tutorial_pressed)
	map1_play_btn.pressed.connect(_on_map1_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	# Connect the Character Select button
	if character_select_btn:
		character_select_btn.pressed.connect(_on_character_select_pressed)
		
	# Connect the Skip Tutorial button
	if skip_tutorial_btn:
		skip_tutorial_btn.pressed.connect(_on_skip_tutorial_pressed)
	
	# 2. Check if Map 1 is unlocked!
	if TaskManager.is_map1_unlocked:
		map1_lock.hide() 
		map1_play_btn.disabled = false 
		# Hide the skip button if the map is already unlocked
		if skip_tutorial_btn:
			skip_tutorial_btn.hide()
	else:
		map1_lock.show() 
		map1_play_btn.disabled = true 
		# Show the skip button if the map is still locked
		if skip_tutorial_btn:
			skip_tutorial_btn.show()

# --- NAVIGATION LOGIC ---
func _on_tutorial_pressed() -> void:
	# 1. Tell the brain where we want to go
	TaskManager.target_level_path = "res://scenes/game_scenes/tutorial_map.tscn"
	# 2. Instantly jump to the loading screen!
	get_tree().change_scene_to_file("res://scenes/System UI/loading_screen.tscn") 

func _on_map1_pressed() -> void:
	# 1. Tell the brain where we want to go
	TaskManager.target_level_path = "res://scenes/game_scenes/game.tscn"
	# 2. Instantly jump to the loading screen!
	get_tree().change_scene_to_file("res://scenes/System UI/loading_screen.tscn") 

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/System UI/title_screen.tscn")

# --- Go to Character Select ---
func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/System UI/character_select.tscn")

# --- Skip Tutorial Logic ---
func _on_skip_tutorial_pressed() -> void:
	# 1. Update the global progress
	TaskManager.is_map1_unlocked = true
	
	# 2. Visually unlock Map 1
	map1_lock.hide()
	map1_play_btn.disabled = false
	
	# 3. Hide the skip button now that it has been used
	skip_tutorial_btn.hide()
