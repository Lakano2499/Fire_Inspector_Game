extends Node2D

@export var interact_action: String = "interact"

var is_fixed: bool = false
var _player_nearby: bool = false

# --- NEW: Variables for interval vibration ---
var _base_sprite_pos: Vector2
var _vibrate_timer: float = 0.0
var _is_vibrating: bool = false

@onready var anim_sprite = $AnimatedSprite2D
@onready var indicator = get_node_or_null("interact_indicator")
@onready var interact_area = $interact 

func _ready():
	anim_sprite.stop()
	anim_sprite.frame = 0
	
	# Save the exact starting position so it doesn't slowly drift away
	_base_sprite_pos = anim_sprite.position
	
	# Start by waiting a random amount of time before the first vibration
	_vibrate_timer = randf_range(1.0, 3.0)
	
	if indicator: 
		indicator.hide()
		
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

# --- NEW: Interval Vibration Loop ---
func _process(delta: float) -> void:
	if not is_fixed:
		_vibrate_timer -= delta
		
		# When the timer hits 0, switch states!
		if _vibrate_timer <= 0.0:
			if _is_vibrating:
				# It was vibrating. Stop it, snap to center, and wait 1 to 4 seconds.
				_is_vibrating = false
				anim_sprite.position = _base_sprite_pos
				_vibrate_timer = randf_range(1.0, 4.0) 
			else:
				# It was resting. Start vibrating for a short burst (0.2 to 0.6 seconds).
				_is_vibrating = true
				_vibrate_timer = randf_range(0.2, 0.6)
				
		# Only shake the phone if the state is currently set to vibrating
		if _is_vibrating:
			anim_sprite.position = _base_sprite_pos + Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
			
	else:
		# Once the player unplugs it, snap it perfectly back to the center
		anim_sprite.position = _base_sprite_pos
		
		# Tell Godot to stop running this process loop to save CPU performance
		set_process(false) 

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_fixed:
		_player_nearby = true
		Highlightable.apply(anim_sprite) 
		if indicator: 
			indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		Highlightable.remove(anim_sprite) 
		if indicator: 
			indicator.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or is_fixed: 
		return
	
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		trigger_interaction()

func trigger_interaction():
	if is_fixed:
		return
		
	get_tree().paused = true
	
	DialogueManager.show_dialogue(
		"System", 
		"This phone is actively charging and resting on the bed. What do you want to do?", 
		["Let it charge", "Touch it", "Unplug it"]
	)
	
	var choice = await DialogueManager.choice_selected
	
	if choice == 0:
		get_tree().paused = false
		
	elif choice == 1:
		DialogueManager.show_dialogue("Player", "Oh no the phone is hot!", ["Continue"])
		await DialogueManager.choice_selected
		get_tree().paused = false
		
	elif choice == 2:
		is_fixed = true
		if indicator: indicator.hide()
		
		Highlightable.remove(anim_sprite) 
		
		TaskManager.complete_task("Unplug overcharging phones")
		get_tree().paused = false
		anim_sprite.play("default")
