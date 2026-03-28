extends CharacterBody2D

const SPEED = 300.0

# Tracks the last direction the player was facing
# Used to pick the correct idle animation when standing still
var last_direction := "front"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# Get 8-directional input (N, S, E, W, NE, NW, SE, SW)
	var input_dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * SPEED

		# Determine facing direction — horizontal takes priority for diagonals
		if input_dir.x > 0:
			last_direction = "right"
		elif input_dir.x < 0:
			last_direction = "left"
		elif input_dir.y < 0:
			last_direction = "back"
		else:
			last_direction = "front"

		# Play walk animation if it exists, otherwise fall back to idle
		var walk_anim := "walk_" + last_direction
		if animated_sprite.sprite_frames.has_animation(walk_anim):
			animated_sprite.play(walk_anim)
		else:
			animated_sprite.play("idle_" + last_direction)
	else:
		velocity = Vector2.ZERO
		# Play idle animation for the last facing direction
		animated_sprite.play("idle_" + last_direction)

	move_and_slide()
