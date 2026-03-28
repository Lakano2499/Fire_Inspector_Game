extends StaticBody2D

# ──────────────────────────────────────────────
# Door – Fire Inspector Game
# ──────────────────────────────────────────────
# Behaviour:
#   default  → frame 0 of "open_door" (closed look)
#   press E  → plays "open_door"  (frames 0→3, stops at 3)
#   press E  → plays "close_door" (frames 0→3, stops at 3)
# ──────────────────────────────────────────────

## Input action mapped to the interact key (default: E).
@export var interact_action: String = "interact"

## Start the door already open.
@export var start_open: bool = false

# ── state ───────────────────────────────────────
var _is_open: bool = false
var _player_nearby: bool = false
var _animating: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _body_col = $CollisionShape2D
@onready var _area: Area2D = $Area2D


func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	_sprite.animation_finished.connect(_on_anim_finished)

	# Disable looping so animation_finished fires and the door stops at frame 3
	_sprite.sprite_frames.set_animation_loop("open_door", false)
	_sprite.sprite_frames.set_animation_loop("close_door", false)

	if start_open:
		_sprite.stop()
		_sprite.animation = "open_door"
		_sprite.frame = 3
		_body_col.set_deferred("disabled", true)
		_is_open = true
	else:
		# Default closed state – show frame 0
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
	if _animating:
		return

	# Only allow opening via interaction now
	if not _is_open:
		_is_open = true
		_animating = true
		_body_col.set_deferred("disabled", true)
		_sprite.play("open_door") # frames 0→3, stops at frame 3


func _on_anim_finished() -> void:
	_animating = false
	_sprite.stop()
	_sprite.frame = 3 # explicitly hold the last frame so it doesn't snap to 0
	if not _is_open:
		_body_col.set_deferred("disabled", false)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = true


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		
		# Auto-close the door when the player leaves the area
		if _is_open and not _animating:
			_is_open = false
			_animating = true
			_sprite.play("close_door")
