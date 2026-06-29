extends StaticBody2D

@export var interact_action: String = "interact"
@onready var _area: Area2D = $interact
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var indicator = $interact_indicator

var _player_nearby: bool = false
var is_completed: bool = false

# NEW: Track if the cloth choice was already made
var tried_cloth: bool = false

func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	if indicator:
		indicator.hide()
	$GasSound.play()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or is_completed:
		return
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_trigger_gas_leak_event()

func _trigger_gas_leak_event() -> void:
	get_tree().paused = true
	
	# Dynamically build choices list based on what the player has already tried
	var available_choices: Array = []
	available_choices.append("Turn off the valve")
	available_choices.append("Light a match")
	
	# Only add the cloth option if they haven't tried it yet
	if not tried_cloth:
		available_choices.append("Cover with cloth")
	
	DialogueManager.show_dialogue(
		"System", 
		"You found a leaking LPG gas cylinder! What is the correct action?", 
		available_choices
	)
	var choice_index = await DialogueManager.choice_selected
	
	# Figure out exactly which text they clicked
	var chosen_text = available_choices[choice_index]
	
	if chosen_text == "Turn off the valve":
		# Correct Action
		DialogueManager.show_dialogue("System", "Correct! You turned off the valve and safely secured the area.", ["Continue"])
		await DialogueManager.choice_selected
		
		is_completed = true
		
		# Stop whatever animation is playing and keep it at frame 0
		_sprite.stop()
		_sprite.frame = 0
		
		$GasSound.stop()
		if indicator: 
			indicator.hide()
		Highlightable.remove(_sprite)
		TaskManager.complete_task("Secure the gas leak")
		get_tree().paused = false
		
	elif chosen_text == "Light a match":
		# Fatal Mistake
		DialogueManager.show_dialogue("System", "BOOM! Lighting a match instantly ignited the trapped gas!", ["..."])
		await DialogueManager.choice_selected
		
		TaskManager.game_over_reason = "burned"
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/System UI/ash_baby_reference.tscn")
		
	elif chosen_text == "Cover with cloth":
		# Ineffective Mistake
		tried_cloth = true # Mark it so it doesn't appear next time
		
		DialogueManager.show_dialogue("System", "That won't stop pressurized gas from filling the room! The hazard is still active.", ["Try Again"])
		await DialogueManager.choice_selected
		
		TaskManager.gas_leak_penalty = 5
		
		# Unpause the game first so animations can run!
		get_tree().paused = false
		
		# Play the sequence: first the cover animation, then loop the leak
		_sprite.play("cover_with_cloth")
		await _sprite.animation_finished
		_sprite.play("covered_with_cloth_leak")

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_completed:
		_player_nearby = true
		Highlightable.apply(_sprite)
		if indicator: indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		Highlightable.remove(_sprite)
		if indicator: indicator.hide()
