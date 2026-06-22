extends Control

# --- NODE REFERENCES ---
@onready var tutorial_play_btn = $Node/TutorialMap/PlayButton
@onready var map1_play_btn = $Node/Map1/PlayButton
@onready var map1_lock = $Node/Map1/Lock
@onready var back_btn = $Node/Button 
@onready var character_select_btn = $Node/CharacterSelect

func _ready() -> void:
	# 1. Connect all the buttons to their functions
	tutorial_play_btn.pressed.connect(_on_tutorial_pressed)
	map1_play_btn.pressed.connect(_on_map1_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	# Connect the Character Select button
	if character_select_btn:
		character_select_btn.pressed.connect(_on_character_select_pressed)
	
	# 2. Check if Map 1 is unlocked!
	if TaskManager.is_map1_unlocked:
		map1_lock.hide() 
		map1_play_btn.disabled = false 
	else:
		map1_lock.show() 
		map1_play_btn.disabled = true 

# --- NAVIGATION LOGIC ---
func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_scenes/tutorial_map.tscn") 

func _on_map1_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_scenes/game.tscn") 

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/System UI/title_screen.tscn")

# --- Go to Character Select ---
func _on_character_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/System UI/character_select.tscn")
