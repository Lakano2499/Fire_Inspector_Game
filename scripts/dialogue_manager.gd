extends CanvasLayer

# --- NODE REFERENCES ---
@onready var main_panel = $MainPanel
@onready var dialogue_text = $MainPanel/DialogueText
@onready var name_box = $NameBox
@onready var name_label = $NameBox/DialogueText2
@onready var choice_box = $ChoiceBox
@onready var choice_1 = $"ChoiceBox/Choice 1"
@onready var choice_2 = $"ChoiceBox/Choice 2"
@onready var choice_pointer = $ChoiceBox/ChoicePointer

signal choice_selected(choice_index)

# --- VARIABLES ---
var is_typing = false
var current_choice_index = 0
var active_choices = []
var active_disabled_choices = [] 
var is_dialogue_active: bool = false
var is_awaiting_choice: bool = false # NEW: Tracks when choices are actually visible

func _ready():
	hide_dialogue()

func hide_dialogue():
	main_panel.hide()
	name_box.hide()
	choice_box.hide()
	is_dialogue_active = false
	is_awaiting_choice = false # Reset choice state
	TaskManager.player_can_move = true

func show_dialogue(speaker_name: String, text: String, choices: Array = [], disabled_choices: Array = []):
	is_dialogue_active = true
	is_awaiting_choice = false # Choices aren't ready yet!
	TaskManager.player_can_move = false
	
	
	# 1. Setup the text
	name_label.text = speaker_name
	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0 
	
	# 2. Show the main boxes
	main_panel.show()
	name_box.show()
	choice_box.hide() 
	
	# 3. Animate the Typewriter effect
	is_typing = true
	var tween = create_tween()
	var duration = text.length() * 0.03 
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	tween.finished.connect(_on_typing_finished)
	
	# 4. Store the choices for later
	active_choices = choices
	active_disabled_choices = disabled_choices
	
	if choices.size() > 0:
		choice_1.text = choices[0]
		if 0 in disabled_choices:
			choice_1.modulate.a = 0.5
		else:
			choice_1.modulate.a = 1.0
			
		if choices.size() > 1:
			choice_2.text = choices[1]
			choice_2.show()
			if 1 in disabled_choices:
				choice_2.modulate.a = 0.5
			else:
				choice_2.modulate.a = 1.0
		else:
			choice_2.hide()

func _on_typing_finished():
	is_typing = false
	if active_choices.size() > 0:
		# Show choices
		choice_box.show()
		
		# --- NEW: Tell the UI that choices are now on screen! ---
		is_awaiting_choice = true 
		
		# Set initial pointer to the first available choice
		current_choice_index = 0
		if 0 in active_disabled_choices and active_choices.size() > 1:
			current_choice_index = 1
			
		update_pointer()

func update_pointer():
	if current_choice_index == 0:
		choice_pointer.global_position.y = choice_1.global_position.y
	elif current_choice_index == 1:
		choice_pointer.global_position.y = choice_2.global_position.y

func _input(event):
	if not choice_box.visible:
		return
		
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		var target_index = 1 - current_choice_index 
		
		if not target_index in active_disabled_choices:
			current_choice_index = target_index 
			update_pointer()
		
	elif event.is_action_pressed("interact"):
		if not current_choice_index in active_disabled_choices:
			# --- NEW: Tell Godot to stop passing this click to the door! ---
			get_viewport().set_input_as_handled() 
			
			hide_dialogue() 
			choice_selected.emit(current_choice_index)
