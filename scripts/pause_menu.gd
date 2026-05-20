extends CanvasLayer

func _ready():
	# Connect the buttons to their respective functions automatically
	$MainPanel/Box1/Resume.pressed.connect(_on_resume_pressed)
	$MainPanel/Box1/Restart.pressed.connect(_on_restart_pressed)
	$MainPanel/Box1/Home.pressed.connect(_on_home_pressed)
	
	# Connect the 'X' button to do the exact same thing as Resume
	$MainPanel/close/X.pressed.connect(_on_resume_pressed)

func _on_resume_pressed():
	# 1. Unpause the game engine
	get_tree().paused = false
	# 2. Delete this pause menu instance from the screen
	queue_free()

func _on_restart_pressed():
	# MUST unpause before reloading, otherwise the new game starts frozen!
	get_tree().paused = false
	# Load the main game scene again
	get_tree().change_scene_to_file("res://scenes/game_scenes/game.tscn")

func _on_home_pressed():
	get_tree().paused = false
	# Load the title screen
	# NOTE: Check your FileSystem to make sure this is the exact path to your title screen!
	get_tree().change_scene_to_file("res://scenes/System UI/title_screen.tscn")
