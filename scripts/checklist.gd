extends Node2D

# --- NODE REFERENCES ---
@onready var task_slots = [
	$Sprite2D/NinePatchRect,
	$Sprite2D/NinePatchRect2,
	$Sprite2D/NinePatchRect3,
	$Sprite2D/NinePatchRect4
]

@onready var next_btn = $Sprite2D/NextButton
@onready var prev_btn = $Sprite2D/PrevButton
@onready var close_btn = $Sprite2D/CloseButton

# --- VARIABLES ---
var current_page: int = 0
var tasks_per_page: int = 4

func _ready() -> void:
	next_btn.pressed.connect(_on_next_pressed)
	prev_btn.pressed.connect(_on_prev_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	
	TaskManager.tasks_updated.connect(update_page)
	
	# Pause logic
	visibility_changed.connect(_on_visibility_changed)
	
	update_page()

func _on_visibility_changed() -> void:
	if visible:
		get_tree().paused = true
	else:
		get_tree().paused = false

func update_page() -> void:
	var total_tasks = TaskManager.master_task_list.size()
	var start_index = current_page * tasks_per_page
	
	for i in range(tasks_per_page):
		var target_task_index = start_index + i
		
		if target_task_index < total_tasks:
			task_slots[i].show()
			
			var task_name = TaskManager.master_task_list[target_task_index]
			var current = TaskManager.task_progress[task_name]
			var max_count = TaskManager.task_max[task_name]
			
			# Check if the task is completely finished
			var is_done = (current >= max_count)
			
			# TEXT FORMATTING: If it requires more than 1, add the (0/3) tag!
			if max_count > 1:
				task_slots[i].get_node("TaskText").text = task_name + " (" + str(current) + "/" + str(max_count) + ")"
			else:
				task_slots[i].get_node("TaskText").text = task_name
			
			task_slots[i].get_node("CheckIcon").visible = is_done
			
		else:
			task_slots[i].hide()

	prev_btn.visible = (current_page > 0)
	next_btn.visible = (start_index + tasks_per_page < total_tasks)

# --- BUTTON LOGIC ---
func _on_next_pressed() -> void:
	current_page += 1
	update_page()

func _on_prev_pressed() -> void:
	current_page -= 1
	update_page()

func _on_close_pressed() -> void:
	hide()
