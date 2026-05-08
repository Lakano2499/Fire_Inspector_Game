extends CanvasLayer

# This preloads your pause menu scene file into memory
const PAUSE_MENU = preload("res://scenes/System UI/pause_menu.tscn")

func _ready():
	# Connect the Settings button's pressed signal to our custom function
	$Settings.pressed.connect(_on_settings_pressed)

func _on_settings_pressed():
	# 1. Create a fresh copy (instance) of the pause menu
	var pause_menu_instance = PAUSE_MENU.instantiate()
	
	# 2. Add it to the screen as a child of the Game UI
	add_child(pause_menu_instance)
	
	# 3. Actually pause the underlying game!
	get_tree().paused = true
