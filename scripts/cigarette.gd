extends Node2D

@export var interact_action: String = "interact"

@onready var interact_area: Area2D = $interact
@onready var indicator = get_node_or_null("interact_indicator")

var _player_nearby: bool = false

func _ready() -> void:
	if indicator: indicator.hide()
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby: return
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_collect_cigarette()

func _collect_cigarette() -> void:
	# Add to our checklist progress
	TaskManager.task_progress["Collect misplaced cigarettes"] += 1
	# Add to our physical "pocket"
	TaskManager.cigarettes_held += 1 
	# Update the UI!
	TaskManager.tasks_updated.emit()
	
	# --- THE FIX: Force the game to check if you just won! ---
	TaskManager.check_for_auto_win()
	
	DialogueManager.show_dialogue("System", "You collected a misplaced cigarette.", ["Got it"])
	queue_free() # Remove the cigarette from the map

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = true
		if indicator: indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		if indicator: indicator.hide()
