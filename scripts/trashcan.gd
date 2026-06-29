extends Node2D

@export var interact_action: String = "interact"

@onready var interact_area: Area2D = $interact
@onready var indicator = get_node_or_null("interact_indicator")
# --- NEW: Grab the animation node! ---
@onready var anim_sprite = $AnimatedSprite2D 

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
		_throw_away_cigarettes()

func _throw_away_cigarettes() -> void:
	var held = TaskManager.cigarettes_held
	
	if held > 0:
		# Add whatever we are holding to the dispose task
		TaskManager.task_progress["Dispose of cigarettes"] += held
		# Empty our pockets
		TaskManager.cigarettes_held = 0
		# Update UI
		TaskManager.tasks_updated.emit()
		$TrashSound.play()
		
		# --- THE FIX: Force the game to check if you just won! ---
		TaskManager.check_for_auto_win()
		
		# (Keep your animation and dialogue code exactly the same below here!)
		if get_node_or_null("AnimatedSprite2D"):
			$AnimatedSprite2D.play("default")
		DialogueManager.show_dialogue("System", "You safely disposed of " + str(held) + " cigarette(s) in the trash.", ["Nice"])

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = true
		if indicator: indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		if indicator: indicator.hide()
