extends StaticBody2D

@export var interact_action: String = "interact"
@onready var _area: Area2D = $interact
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var indicator = get_node_or_null("interact_indicator")

var _player_nearby: bool = false
var is_completed: bool = false

func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	if indicator:
		indicator.hide()
	
	# Start the dangerous sparking animation!
	_sprite.play("default") 
	$MicrowaveHum.play()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or is_completed:
		return
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_trigger_microwave_event()

func _trigger_microwave_event() -> void:
	get_tree().paused = true
	
	DialogueManager.show_dialogue(
		"System", 
		"Sparks are flying inside the microwave! Someone left aluminum foil inside. What should you do?", 
		["Ignore" , "Remove the foil"]
	)
	var choice = await DialogueManager.choice_selected
	
	if choice == 0:
		# Ignored: Just close the dialogue and resume the game.
		# The player can interact again because is_completed remains false.
		DialogueManager.show_dialogue("System", "You decided to leave the sparking microwave alone for now.", ["Continue"])
		await DialogueManager.choice_selected
		
		get_tree().paused = false
		
	elif choice == 1:
		# Correct: Remove the hazard!
		DialogueManager.show_dialogue("System", "Correct! Metal causes dangerous electrical arcing inside microwaves and easily starts fires.", ["Continue"])
		await DialogueManager.choice_selected
		
		is_completed = true
		$MicrowaveHum.stop()
		$MicrowaveDing.play()
		
		# --- TURN OFF HIGHLIGHT & INDICATORS ---
		if indicator: 
			indicator.hide()
			
		# Removes the highlight immediately upon finishing the task
		Highlightable.remove(_sprite)
		
		TaskManager.complete_task("Remove foil from microwave")
		
		# 1. Unpause the game FIRST so the animation is allowed to run
		get_tree().paused = false
		
		# 2. Play the animation! (Since looping is off, it will stop naturally at frame 10)
		_sprite.play("remove_foil")
		
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
