extends Sprite2D

@export var tap_interval: float = 1.5
@export var ripple_color: Color = Color.WHITE
@export var max_ripple_radius: float = 35.0
# Adjust this Vector to align perfectly with the tip of the pixel art finger
@export var finger_tip_offset: Vector2 = Vector2(-14, -14) 

var current_ripple_radius: float = 0.0
var current_ripple_alpha: float = 0.0

func _ready() -> void:
	# Start the repeating tap animation loop
	_play_tap_animation()

func _play_tap_animation() -> void:
	# --- 1. The Tapping Motion ---
	var tap_tween = create_tween()
	
	# Press down quickly (scale down slightly to simulate depth)
	tap_tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.1).set_trans(Tween.TRANS_SINE)
	
	# Trigger the ripple exactly when the finger "hits" the surface
	tap_tween.tween_callback(_spawn_ripple)
	
	# Release (bounce back to normal scale)
	tap_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Wait for the set interval, then loop the animation again
	tap_tween.tween_interval(tap_interval)
	tap_tween.tween_callback(_play_tap_animation)

func _spawn_ripple() -> void:
	# Reset ripple values for a fresh spawn
	current_ripple_radius = 0.0
	current_ripple_alpha = 1.0
	
	# --- 2. The Ripple Effect ---
	var ripple_tween = create_tween()
	ripple_tween.set_parallel(true) # Animate radius and alpha at the exact same time
	
	# Expand the ring outward
	ripple_tween.tween_property(self, "current_ripple_radius", max_ripple_radius, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Fade the ring to completely transparent
	ripple_tween.tween_property(self, "current_ripple_alpha", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _process(_delta: float) -> void:
	# Tell the engine to redraw the visual frame only when the ripple is actively animating
	if current_ripple_alpha > 0.0:
		queue_redraw()

func _draw() -> void:
	if current_ripple_alpha > 0.0:
		var draw_color = ripple_color
		draw_color.a = current_ripple_alpha
		
		# Draw the expanding, fading ring
		# draw_arc(center_position, radius, start_angle, end_angle, point_count, color, line_width, antialiased)
		draw_arc(finger_tip_offset, current_ripple_radius, 0.0, TAU, 32, draw_color, 2.0, true)
