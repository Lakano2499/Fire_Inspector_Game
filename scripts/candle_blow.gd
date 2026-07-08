extends CanvasLayer

var click_count: int = 0

# --- NEW: Variable to hold our countdown timer ---
var hint_timer: Timer 

@onready var anim: AnimatedSprite2D = $CandleCenter/AnimatedSprite2D
@onready var click_area: Area2D = $CandleCenter/click_flame
@onready var success_label: Label = $SuccessLabel

# --- NEW: Reference to the pointing hand ---
@onready var pointing_hint = $pointing 

# We need references to these to animate them
@onready var bg_rect: ColorRect = $ColorRect
@onready var center_node: Node2D = $CandleCenter

func _ready() -> void:
	# Ensure we start with the right animation
	anim.play("idle_flame")
	success_label.hide()
	
	# Hide the hand by default
	pointing_hint.hide() 
	
	# Connect the Area2D click event
	click_area.input_event.connect(_on_flame_clicked)
	
	# --- NEW: Setup the 3-second Hint Timer ---
	hint_timer = Timer.new()
	hint_timer.wait_time = 3.0
	hint_timer.one_shot = true
	hint_timer.timeout.connect(_on_hint_timeout)
	add_child(hint_timer)
	hint_timer.start() # Start the 3-second countdown!
	
	# ──────────────────────────────────────────────
	# TRANSITION IN (DROP DOWN)
	# ──────────────────────────────────────────────
	# 1. Set starting states
	bg_rect.modulate.a = 0.0
	
	var target_y = center_node.position.y
	center_node.position.y -= get_viewport().get_visible_rect().size.y
	
	# 2. Create the Tween
	var tween = create_tween()
	tween.set_parallel(true) # Make animations happen at the same time
	
	# Fade in the background over 0.3 seconds
	tween.tween_property(bg_rect, "modulate:a", 1.0, 0.3)
	
	# Drop the candle down to its normal position
	# Using TRANS_BACK gives it a bouncy drop effect
	tween.tween_property(center_node, "position:y", target_y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- NEW: Function to trigger when 3 seconds pass ---
func _on_hint_timeout() -> void:
	# Show the pointing hand as long as the task isn't finished
	if click_count < 3:
		pointing_hint.show()

func _on_flame_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click_count += 1
		
		# --- NEW: The player clicked! Hide the hint and restart the 3-second timer ---
		pointing_hint.hide()
		hint_timer.start()
		
		if not $BlowSound.playing:
			$BlowSound.play()
		
		# Optional: A tiny shake effect every time you click!
		var shake_tween = create_tween()
		shake_tween.tween_property(center_node, "position:x", center_node.position.x + 5, 0.05)
		shake_tween.tween_property(center_node, "position:x", center_node.position.x - 5, 0.05)
		
		if click_count >= 3:
			_finish_task()

func _finish_task() -> void:
	# Stop listening for clicks
	click_area.input_event.disconnect(_on_flame_clicked)
	
	# --- NEW: Kill the timer and ensure the hand is hidden ---
	hint_timer.stop() 
	pointing_hint.hide()
	
	# Play the kill flame animation and show text
	anim.play("kill_flame")
	success_label.show()
	
	# Wait for 1.5 seconds so the player can read the text
	await get_tree().create_timer(1.5).timeout
	
	# ──────────────────────────────────────────────
	# TRANSITION OUT (SLIDE UP)
	# ──────────────────────────────────────────────
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out the background and text
	tween.tween_property(bg_rect, "modulate:a", 0.0, 0.3)
	tween.tween_property(success_label, "modulate:a", 0.0, 0.3)
	
	# Slide the candle back up off-screen
	var out_y = center_node.position.y - get_viewport().get_visible_rect().size.y
	tween.tween_property(center_node, "position:y", out_y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	# Wait for the closing animations to finish, THEN call the cleanup function
	tween.chain().tween_callback(_close_scene)

func _close_scene() -> void:
	# Unpause the main game and destroy this popup
	get_tree().paused = false
	queue_free()
