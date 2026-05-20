extends CanvasLayer
signal choice_selected(choice_index)

# --- NODE REFERENCES ---
@onready var main_panel = $MainPanel
@onready var dialogue_text = $MainPanel/DialogueText
@onready var name_box = $NameBox
@onready var name_label = $NameBox/DialogueText2
@onready var choice_box = $ChoiceBox
@onready var choice_1 = $"ChoiceBox/Choice 1"
@onready var choice_2 = $"ChoiceBox/Choice 2"
@onready var choice_pointer = $ChoiceBox/ChoicePointer

# --- VARIABLES ---
var is_typing = false
var current_choice_index = 0
var active_choices = []

func _ready():
	# Hide everything when the game first loads
	hide_dialogue()

func hide_dialogue():
	main_panel.hide()
	name_box.hide()
	choice_box.hide()
	
func show_dialogue(speaker_name: String, text: String, choices: Array = []):
	# 1. Setup the text
	name_label.text = speaker_name
	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0 # Make text invisible for typewriter effect
	
	# 2. Show the main boxes
	main_panel.show()
	name_box.show()
	choice_box.hide() # Keep choices hidden until typing finishes
	
	# 3. Animate the Typewriter effect
	is_typing = true
	var tween = create_tween()
	# The duration scales with the text length (0.03 seconds per letter)
	var duration = text.length() * 0.03 
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	tween.finished.connect(_on_typing_finished)
	
	# 4. Store the choices for later
	active_choices = choices
	if choices.size() > 0:
		choice_1.text = choices[0]
		if choices.size() > 1:
			choice_2.text = choices[1]
			choice_2.show()
		else:
			choice_2.hide()

func _on_typing_finished():
	is_typing = false
	if active_choices.size() > 0:
		# Show choices and reset pointer to the top option
		choice_box.show()
		current_choice_index = 0
		update_pointer()

func update_pointer():
	# Snap the pointer's Y position to match the currently selected text
	if current_choice_index == 0:
		choice_pointer.global_position.y = choice_1.global_position.y
	elif current_choice_index == 1:
		choice_pointer.global_position.y = choice_2.global_position.y

func _input(event):
	# Only allow input if the choice box is actually visible
	if not choice_box.visible:
		return
		
	# Move pointer up and down
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up"):
		# This is a neat math trick to toggle between 0 and 1
		current_choice_index = 1 - current_choice_index 
		update_pointer()
		
# Confirm choice
	elif event.is_action_pressed("ui_accept"):
		hide_dialogue() # Close the box	
		choice_selected.emit(current_choice_index) # Tell the game what we picked!
