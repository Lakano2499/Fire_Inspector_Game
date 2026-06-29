extends Node2D

@export var interact_action: String = "interact"

var is_fixed: bool = false
var _player_nearby: bool = false

var tried_water: bool = false
var tried_touch: bool = false

@onready var anim_sprite = $AnimatedSprite2D
@onready var indicator = get_node_or_null("interact_indicator")
@onready var interact_area = $interact 

func _ready():
	anim_sprite.stop()
	anim_sprite.frame = 0
	
	if indicator: 
		indicator.hide()
		
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not is_fixed:
		_player_nearby = true
		Highlightable.apply(anim_sprite) # <-- Applies highlight
		if indicator: 
			indicator.show()

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_nearby = false
		Highlightable.remove(anim_sprite) # <-- Removes highlight on walk away
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
	
	var available_choices: Array = []
	if not tried_water:
		available_choices.append("Pour water")
	if not tried_touch:
		available_choices.append("Touch the Iron")
		
	available_choices.append("Unplug the Iron") 
	
	DialogueManager.show_dialogue(
		"System", 
		"An unattended iron is left plugged in and resting face down. What should you do?", 
		available_choices
	)
	
	var choice_index = await DialogueManager.choice_selected
	var chosen_text = available_choices[choice_index]
	
	if chosen_text == "Pour water":
		tried_water = true 
		DialogueManager.show_dialogue("System", "Ineffective! Pouring water on a plugged-in appliance is an electrocution hazard. Try again.", ["Continue"])
		await DialogueManager.choice_selected
		TaskManager.iron_penalty += 2 
		get_tree().paused = false
		
	elif chosen_text == "Touch the Iron":
		tried_touch = true 
		DialogueManager.show_dialogue("Player", "Ouch, it is hot! Try again.", ["Continue"])
		await DialogueManager.choice_selected
		TaskManager.iron_penalty += 5 
		get_tree().paused = false
		
	elif chosen_text == "Unplug the Iron":
		is_fixed = true
		if indicator: indicator.hide()
		
		Highlightable.remove(anim_sprite) # <-- Removes highlight when finished
		
		TaskManager.complete_task("Unplug the iron")
		get_tree().paused = false
		anim_sprite.play("default")
