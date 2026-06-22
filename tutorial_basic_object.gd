extends StaticBody2D

@export var task_name: String = "Task 1" # Set this in the Inspector!
@onready var interact_area = $interact
@onready var highlight_area = $area_seen

var is_completed: bool = false

func _ready() -> void:
	if interact_area:
		interact_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	if is_completed:
		return
		
	var map_director = get_tree().current_scene
	
	# CHECK 1: Is the emergency currently active?
	if map_director.is_emergency_active:
		get_tree().paused = true
		DialogueManager.show_dialogue("System", "Do the other task first.", ["Continue" , "..."])
		await DialogueManager.choice_selected
		get_tree().paused = false
		return # Stop them from completing this task!

	# IF SAFE: Proceed normally
	get_tree().paused = true
	DialogueManager.show_dialogue("Tutor", "You interacted with " + task_name + ".", ["Mark as Done" , "Ignore"])
	await DialogueManager.choice_selected
	get_tree().paused = false
	
	_mark_as_completed(map_director)

func _mark_as_completed(map_director: Node) -> void:
	is_completed = true
	modulate = Color(0.5, 0.5, 0.5) 
	$Sprite2D.play("flame_off")
	
	# Check it off the clipboard
	TaskManager.complete_task(task_name)
	
	# Tell the Map Director we finished a task
	map_director.report_task_finished()
	
	# Disable collisions
	interact_area.set_deferred("monitoring", false)
	interact_area.set_deferred("monitorable", false)
	if highlight_area:
		highlight_area.set_deferred("monitoring", false)
		highlight_area.set_deferred("monitorable", false)
