extends Node2D

@export var interact_action: String = "interact"

var is_picked_up: bool = false
var _player_nearby: bool = false
var _is_emergency_active: bool = false

@onready var interact_area = $interact 
@onready var area_seen = $area_seen
@onready var indicator = $interact_indicator
@onready var sprite = $Sprite2D

func _ready():
	# 1. Hide the indicator and the red area_seen circle by default
	if indicator: indicator.hide()
	if area_seen: area_seen.hide()
		
	# 2. Completely disable the collision areas
	_set_areas_enabled(false)
		
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# 3. Constantly check if the emergency has started. 
	if TaskManager.pass_emergency_active and not _is_emergency_active and not is_picked_up:
		_is_emergency_active = true
		
		# Enable the collision areas and show the red circle
		_set_areas_enabled(true)
		if area_seen:
			area_seen.show()
			
		if indicator and not _player_nearby:
			indicator.hide()

func _set_areas_enabled(enabled: bool) -> void:
	interact_area.set_deferred("monitoring", enabled)
	interact_area.set_deferred("monitorable", enabled)
	if area_seen:
		area_seen.set_deferred("monitoring", enabled)
		area_seen.set_deferred("monitorable", enabled)

func _on_body_entered(body: Node2D) -> void:
	# --- THE FIX: Ignore any physics collisions before the fire starts! ---
	if not TaskManager.pass_emergency_active: 
		return
		
	if body is CharacterBody2D and not is_picked_up:
		_player_nearby = true
		Highlightable.apply(sprite)
		if indicator: indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		Highlightable.remove(sprite)
		if indicator: indicator.hide()

func _unhandled_input(event: InputEvent) -> void:
	# --- THE FIX: Block interaction inputs before the fire starts! ---
	if not _player_nearby or is_picked_up or not TaskManager.pass_emergency_active: 
		return
		
	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_pickup_extinguisher()

func _pickup_extinguisher() -> void:
	get_tree().paused = true
	DialogueManager.show_dialogue("System", "You grabbed the Fire Extinguisher! Hurry back and stop the fire!", ["Got it"])
	await DialogueManager.choice_selected
	
	is_picked_up = true
	TaskManager.has_fire_extinguisher = true
	
	if indicator: indicator.hide()
	Highlightable.remove(sprite)
	get_tree().paused = false
	
	hide()
