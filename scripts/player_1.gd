extends CharacterBody2D

const SPEED = 300.0

@export var berong_frames: SpriteFrames
@export var mr_inspector_frames: SpriteFrames

# Tracks the last direction the player was facing
var last_direction := "front"

@onready var anim_sprite = $AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# --- THE FIX: Always unlock movement when the player spawns! ---
	TaskManager.player_can_move = true 
	
	if TaskManager.selected_character == "mr_inspector" and mr_inspector_frames != null:
		anim_sprite.sprite_frames = mr_inspector_frames
	elif TaskManager.selected_character == "berong" and berong_frames != null:
		anim_sprite.sprite_frames = berong_frames

func _physics_process(_delta: float) -> void:
	# Stop movement entirely if locked in dialogue or a minigame
	if not TaskManager.player_can_move:
		velocity = Vector2.ZERO
		animated_sprite.play("idle_" + last_direction)
		move_and_slide() 
		return

	# Get 8-directional input
	var input_dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * SPEED

		if input_dir.x > 0:
			last_direction = "right"
		elif input_dir.x < 0:
			last_direction = "left"
		elif input_dir.y < 0:
			last_direction = "back"
		else:
			last_direction = "front"

		var walk_anim := "walk_" + last_direction
		if animated_sprite.sprite_frames.has_animation(walk_anim):
			animated_sprite.play(walk_anim)
		else:
			animated_sprite.play("idle_" + last_direction)
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle_" + last_direction)

	move_and_slide()
