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
	
	# Start the boiling/steaming animation immediately
	_sprite.play("default") 
	$BoilingSound.play()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or is_completed:
		return
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_trigger_rice_cooker_event()

func _trigger_rice_cooker_event() -> void:
	get_tree().paused = true
	
	DialogueManager.show_dialogue(
		"System", 
		"You found a rice cooker left plugged in and unattended. What should you do?", 
		["Ignore", "Unplug only"]
	)
	var choice = await DialogueManager.choice_selected
	
	if choice == 1:
		# Correct: Unplug it!
		DialogueManager.show_dialogue("System", "Correct! Unplugging heat-producing appliances when unattended prevents electrical fires.", ["Continue"])
		await DialogueManager.choice_selected
		
		is_completed = true
		_sprite.stop() # Stop the animation
		_sprite.frame = 0 # Force it to a specific "off" frame (adjust if needed)
		$BoilingSound.stop()
		
		# --- TURN OFF HIGHLIGHT & INDICATORS ---
		if indicator: 
			indicator.hide()
		
		# Removes the highlight when the task is finished
		Highlightable.remove(_sprite) 
		# Note: If your highlight uses a material directly rather than a global script, use:
		# _sprite.material = null
		# ---------------------------------------
		
		TaskManager.complete_task("Unplug the rice cooker")
		get_tree().paused = false
			
	elif choice == 0:
		# Ignored: Just close the dialogue and resume the game.
		# The player can interact again because is_completed remains false.
		DialogueManager.show_dialogue("System", "You decided to leave the rice cooker alone for now.", ["Continue"])
		await DialogueManager.choice_selected
		
		get_tree().paused = false

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
		
