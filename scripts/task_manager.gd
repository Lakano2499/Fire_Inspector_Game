extends Node

signal tasks_updated

# 1. The Master List
var master_task_list: Array = [
	"Turn off lit candles", # Your grouped task
	"Cover the burning pan",
	"Unplug the iron",
	"Check the smoke alarm"
]

# 2. Set the REQUIRED amount to finish a task
var task_max: Dictionary = {
	"Turn off lit candles": 3, # Requires 3 candles!
	"Cover the burning pan": 1,
	"Unplug the iron": 1,
	"Check the smoke alarm": 1
}

# 3. This tracks the CURRENT progress (0, 1, 2, etc.)
var task_progress: Dictionary = {}

# Keep your player lock variable here!
var player_can_move: bool = true 

func _ready() -> void:
	# Automatically set progress to 0 for everything when the game starts
	for task in master_task_list:
		task_progress[task] = 0

func complete_task(task_name: String) -> void:
	# Check if the task exists and isn't fully maxed out yet
	if task_progress.has(task_name) and task_progress[task_name] < task_max[task_name]:
		task_progress[task_name] += 1
		print("Checklist updated: ", task_name, " ", task_progress[task_name], "/", task_max[task_name])
		
		# Tell the checklist UI to redraw
		tasks_updated.emit()
