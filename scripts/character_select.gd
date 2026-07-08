extends Control

# --- NODE REFERENCES ---
@onready var anim_sprite = $NinePatchRect3/AnimatedSprite2D
@onready var name_label = $CharacterName
@onready var details_label = $CharacterName/CharacterDetails
@onready var next_btn = $NinePatchRect4/Next
@onready var prev_btn = $NinePatchRect4/Previous
@onready var back_btn = $BackToMainMenu

# --- NEW NODE REFERENCES ---
@onready var select_btn = $NinePatchRect4/SelectButton
@onready var selected_indicator = $NinePatchRect3/CurrentlySelectedIndicator

# --- SPRITE FRAMES ---
@export var berong_frames: SpriteFrames
@export var mr_inspector_frames: SpriteFrames
@export var coming_soon_frames: SpriteFrames 

# --- VARIABLES ---
var current_index: int = 0
var characters: Array = []

func _ready() -> void:
	# 1. Setup the character database
	characters = [
		{
			"id": "berong",
			"name": "Berong",
			"desc": "A dedicated fire inspector ready to keep the town safe! \n\nAlways prepared for an emergency.",
			"frames": berong_frames,
			"is_locked": false
		},
		{
			"id": "mr_inspector",
			"name": "Mr. Inspector",
			"desc": "An experienced veteran with an eye for hidden hazards. \n\nNothing gets past him.",
			"frames": mr_inspector_frames,
			"is_locked": false
		},
		{
			"id": "coming_soon",
			"name": "Coming Soon",
			"desc": "A new inspector is currently in training. \n\nCheck back in a future update!",
			"frames": coming_soon_frames,
			"is_locked": true
		}
	]
	
	# 2. Connect all buttons
	next_btn.pressed.connect(_on_next_pressed)
	prev_btn.pressed.connect(_on_previous_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	select_btn.pressed.connect(_on_select_pressed) 
	
	# 3. Show the first character
	_update_ui()

func _update_ui() -> void:
	var data = characters[current_index]
	
	# Update the text
	name_label.text = data["name"]
	details_label.text = data["desc"]
	
	# Update the sprite
	if data["frames"] != null:
		anim_sprite.sprite_frames = data["frames"]
		anim_sprite.play("idle_front") 
		anim_sprite.show()
	else:
		anim_sprite.hide() 
		
	# --- Selection & Indicator Logic ---
	if data["is_locked"]:
		# If it's a "Coming Soon" character
		select_btn.disabled = true
		select_btn.text = "Locked"
		selected_indicator.hide()
	else:
		# Check if the character on screen matches the globally saved character
		if TaskManager.selected_character == data["id"]:
			select_btn.disabled = true
			select_btn.text = "Selected"
			selected_indicator.show() # Show the green checkmark!
		else:
			select_btn.disabled = false
			select_btn.text = "Select"
			selected_indicator.hide() # Hide the checkmark!

# --- BUTTON LOGIC ---
func _on_next_pressed() -> void:
	current_index += 1
	if current_index >= characters.size():
		current_index = 0
	_update_ui()

func _on_previous_pressed() -> void:
	current_index -= 1
	if current_index < 0:
		current_index = characters.size() - 1
	_update_ui()

func _on_select_pressed() -> void:
	var data = characters[current_index]
	
	# Only save if the character isn't locked
	if not data["is_locked"]:
		TaskManager.selected_character = data["id"]
		_update_ui() # Instantly refresh the UI so the checkmark pops up!

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/System UI/main_menu.tscn")
