extends StaticBody2D

@export var interact_action: String = "interact"
@onready var _area: Area2D = $interact
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var indicator = get_node_or_null("interact_indicator")

# References to your spark nodes
@onready var spark1 = get_node_or_null("spark")
@onready var spark2 = get_node_or_null("spark2")
@onready var spark3 = get_node_or_null("spark3")

var _player_nearby: bool = false
var is_completed: bool = false

# Array to hold our randomized timers
var spark_timers: Array = []

func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	if indicator: indicator.hide()
	
	# Stop the animation and force it to frame 0 (the loaded state)
	_sprite.stop()
	_sprite.frame = 0
	$SparkSound.play()
	
	# Setup random flashing timers for each spark node
	for spark in [spark1, spark2, spark3]:
		if spark:
			var timer = Timer.new()
			timer.one_shot = true
			timer.timeout.connect(func(): _toggle_spark(spark, timer))
			add_child(timer)
			spark_timers.append(timer)
			_toggle_spark(spark, timer) # Kick off the loop

func _toggle_spark(spark_node: Node2D, timer: Timer) -> void:
	# If the task is done, permanently hide the spark and stop the loop
	if is_completed:
		spark_node.hide()
		return
		
	spark_node.visible = !spark_node.visible
	
	# If the spark is visible, hide it quickly. If hidden, wait a bit to flash again.
	if spark_node.visible:
		timer.start(randf_range(0.1, 0.3)) # Flash duration
	else:
		timer.start(randf_range(0.5, 2.0)) # Wait before next flash

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or is_completed: return
	
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_trigger_octopus_event()

func _trigger_octopus_event() -> void:
	get_tree().paused = true
	
	DialogueManager.show_dialogue(
		"System", 
		"This extension cord is overloaded with too many plugs (octopus wiring) and is actively sparking! How do you handle it?", 
		["Pour water", "Remove all quickly", "Use rubber gloves"]
	)
	var choice = await DialogueManager.choice_selected
	
	if choice == 0:
		# Fatal Mistake: Game Over
		DialogueManager.show_dialogue("System", "Water conducts electricity! Pouring water on an active electrical hazard caused a fatal shock.", ["..."])
		await DialogueManager.choice_selected
		
		get_tree().paused = false
		TaskManager.game_over_reason = "electrocute"
		TaskManager.game_over_triggered.emit()
		
	elif choice == 1:
		# Mistake: Penalty!
		DialogueManager.show_dialogue("System", "Ouch! You got a painful electrical shock pulling them barehanded while it sparked. The hazard is still active.", ["Try Again"])
		await DialogueManager.choice_selected
		
		TaskManager.octopus_penalty = 5 # Apply the deduction
		get_tree().paused = false
		
	elif choice == 2:
		# Correct: Full points!
		DialogueManager.show_dialogue("System", "Correct! Using rubber gloves protects you from electrocution while you safely unplug the overloaded sockets.", ["Continue"])
		await DialogueManager.choice_selected
		
		is_completed = true
		$SparkSound.stop()
		
		# --- TURN OFF HIGHLIGHT & INDICATORS ---
		if indicator: indicator.hide()
		
		Highlightable.remove(_sprite)
		
		# Ensure all sparks instantly disappear
		if spark1: spark1.hide()
		if spark2: spark2.hide()
		if spark3: spark3.hide()
		
		TaskManager.complete_task("Fix octopus wiring")
		
		# Unpause the game first so the animation can play
		get_tree().paused = false
		
		# Play the animation! (Since looping is off, it will stop naturally at frame 11)
		_sprite.play("default")

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_completed:
		_player_nearby = true
		Highlightable.apply(_sprite)
		if indicator: indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		Highlightable.remove(_sprite)
		if indicator: indicator.hide()
