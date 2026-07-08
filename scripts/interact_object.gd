extends Area2D
class_name InteractObject

## Emitted when the player is nearby and presses the interact action.
signal interacted

## The input action mapped to interaction.
@export var interact_action: String = "interact"

## Assign the arrow (or any visual indicator) node here in the Inspector.
@export var indicator: CanvasItem

var _player_nearby: bool = false

func _ready() -> void:
	# Ensure signals are connected via code for modularity
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Hide the indicator when the game starts
	if indicator != null:
		indicator.hide()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = true
		# Show the arrow when the player enters the blue area
		if indicator != null:
			indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		# Hide the arrow when the player leaves
		if indicator != null:
			indicator.hide()

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed(interact_action):
		# Prevent other unhandled inputs from firing if we consume the interact
		get_viewport().set_input_as_handled()
		
		# Emit the signal so other scripts can define the actual behavior
		interacted.emit()
	
