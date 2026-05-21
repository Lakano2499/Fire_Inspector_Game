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
var active_disabled_choices = [] # NEW: Stores which options are locked

func _ready():
	# Hide everything when the game first loads
	hide_dialogue()

func hide_dialogue():
	main_panel.hide()
	name_box.hide()
	choice_box.hide()
	
# NEW: Added 'disabled_choices' array parameter
func show_dialogue(speaker_name: String, text: String, choices: Array = [], disabled_choices: Array = []):
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
	var duration = text.length() * 0.03 
	tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)
	tween.finished.connect(_on_typing_finished)
	
	# 4. Store the choices for later
	active_choices = choices
	active_disabled_choices = disabled_choices
	
	if choices.size() > 0:
		choice_1.text = choices[0]
		# Visually fade the text if it is disabled
		if 0 in disabled_choices:
			choice_1.modulate.a = 0.5
		else:
			choice_1.modulate.a = 1.0
			
		if choices.size() > 1:
			choice_2.text = choices[1]
			choice_2.show()
			# Visually fade the second choice if disabled
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
		
		# Set initial pointer to the first available choice
		current_choice_index = 0
		# If choice 0 is locked, automatically jump the pointer down to choice 1
		if 0 in active_disabled_choices and active_choices.size() > 1:
			current_choice_index = 1
			
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
		# Calculate where the pointer wants to go
		var target_index = 1 - current_choice_index 
		
		# Only move the pointer there if that option is NOT in the disabled list
		if not target_index in active_disabled_choices:
			current_choice_index = target_index 
			update_pointer()
		
	# Confirm choice
	elif event.is_action_pressed("ui_accept"):
		# Final safety check so they can't force-select a locked choice
		if not current_choice_index in active_disabled_choices:
			hide_dialogue() # Close the dialogue box for now
			choice_selected.emit(current_choice_index) # Tell the game what we picked!
