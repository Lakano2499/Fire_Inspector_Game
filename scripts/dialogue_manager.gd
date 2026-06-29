extends CanvasLayer

@onready var main_panel = $MainPanel
@onready var dialogue_text = $MainPanel/DialogueText
@onready var name_box = $NameBox
@onready var name_label = $NameBox/DialogueText2
@onready var choice_box = $ChoiceBox
@onready var choice_1 = $"ChoiceBox/Choice 1"
@onready var choice_2 = $"ChoiceBox/Choice 2"
@onready var choice_3 = get_node_or_null("ChoiceBox/Choice 3") # NEW!
@onready var choice_pointer = $ChoiceBox/ChoicePointer

signal choice_selected(choice_index)

var is_typing = false
var current_choice_index = 0
var active_choices = []
var active_disabled_choices = [] 
var is_dialogue_active: bool = false
var is_awaiting_choice: bool = false 

func _ready():
	hide_dialogue()

func hide_dialogue():
	main_panel.hide()
	name_box.hide()
	choice_box.hide()
	is_dialogue_active = false
	is_awaiting_choice = false 
	TaskManager.player_can_move = true

func show_dialogue(speaker_name: String, text: String, choices: Array = [], disabled_choices: Array = []):
	is_dialogue_active = true
	is_awaiting_choice = false 
	TaskManager.player_can_move = false
	
	name_label.text = speaker_name
	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0 
	
	main_panel.show()
	name_box.show()
	choice_box.hide() 
	
	is_typing = true
	var tween = create_tween()
	var duration = text.length() * 0.03 
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	tween.finished.connect(_on_typing_finished)
	
	active_choices = choices
	active_disabled_choices = disabled_choices
	
	# Setup Choice 1
	if choices.size() > 0:
		choice_1.text = choices[0]
		choice_1.modulate.a = 0.5 if 0 in disabled_choices else 1.0
	
	# Setup Choice 2
	if choices.size() > 1:
		choice_2.text = choices[1]
		choice_2.show()
		choice_2.modulate.a = 0.5 if 1 in disabled_choices else 1.0
	else:
		choice_2.hide()
		
	# Setup Choice 3
	if choices.size() > 2 and choice_3:
		choice_3.text = choices[2]
		choice_3.show()
		choice_3.modulate.a = 0.5 if 2 in disabled_choices else 1.0
	elif choice_3:
		choice_3.hide()

func _on_typing_finished():
	is_typing = false
	if active_choices.size() > 0:
		choice_box.show()
		is_awaiting_choice = true 
		
		current_choice_index = 0
		while current_choice_index in active_disabled_choices and current_choice_index < active_choices.size() - 1:
			current_choice_index += 1
			
		update_pointer()

func update_pointer():
	if current_choice_index == 0:
		choice_pointer.global_position.y = choice_1.global_position.y
	elif current_choice_index == 1:
		choice_pointer.global_position.y = choice_2.global_position.y
	elif current_choice_index == 2 and choice_3:
		choice_pointer.global_position.y = choice_3.global_position.y

func _input(event):
	if not choice_box.visible:
		return
		
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		var direction = 1 if event.is_action_pressed("ui_down") else -1
		var steps = 0
		var target_index = current_choice_index
		
		# Safely loop through choices even if some are disabled
		while steps < active_choices.size():
			target_index = (target_index + direction + active_choices.size()) % active_choices.size()
			if not target_index in active_disabled_choices:
				current_choice_index = target_index
				update_pointer()
				break
			steps += 1
		
	elif event.is_action_pressed("interact"):
		if not current_choice_index in active_disabled_choices:
			get_viewport().set_input_as_handled() 
			hide_dialogue() 
			choice_selected.emit(current_choice_index)
