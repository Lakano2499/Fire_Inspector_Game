extends StaticBody2D

# --- Standard Door Variables ---
@export var interact_action: String = "interact"
var _is_open: bool = false
var _player_nearby: bool = false
var _animating: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _body_col = $CollisionShape2D

# Make sure this matches your exact node name in the scene tree (either $Area2D or $interact)
@onready var _area: Area2D = $interact 

func _ready() -> void:
	# Connect the standard body entered/exited signals
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	_sprite.animation_finished.connect(_on_anim_finished)

	_sprite.sprite_frames.set_animation_loop("open_door", false)
	_sprite.sprite_frames.set_animation_loop("close_door", false)

	# Start closed
	_sprite.stop()
	_sprite.animation = "open_door"
	_sprite.frame = 0
	_body_col.set_deferred("disabled", false)
	_is_open = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby:
		return
	if not event.is_action_pressed(interact_action):
		return
	if _animating or _is_open:
		return

	var map_director = get_tree().current_scene
	
	# ONLY checks if you have finished at least 2 tasks!
	if map_director.basic_tasks_completed >= 2:
		# Just open the door and let the player pass!
		_is_open = true
		_animating = true
		_body_col.set_deferred("disabled", true)
		_sprite.play("open_door") 
		Highlightable.remove(_sprite)
		
	else:
		# NOT DONE YET! Stop them.
		get_tree().paused = true
		DialogueManager.show_dialogue("System", "Do 2 tasks first to unlock the door.", ["Continue"])
		await DialogueManager.choice_selected
		get_tree().paused = false

func _on_anim_finished() -> void:
	_animating = false
	_sprite.stop()
	_sprite.frame = 3 
	if not _is_open:
		_body_col.set_deferred("disabled", false)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = true
		if not _is_open:
			Highlightable.apply(_sprite)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		Highlightable.remove(_sprite)
		
		if _is_open and not _animating:
			_is_open = false
			_animating = true
			_sprite.play("close_door")
