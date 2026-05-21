extends CanvasLayer

# --- PRELOADS ---
const PAUSE_MENU = preload("res://scenes/System UI/pause_menu.tscn")
const CHECKLIST_MENU = preload("res://scenes/System UI/checklist.tscn")
# Added exact paths based on your folder structure!
const GAME_OVER_SCREEN = preload("res://scenes/System UI/game_over.tscn")
const TITLE_SCREEN = "res://scenes/System UI/title_screen.tscn"

# --- NODE REFERENCES ---
@onready var checklist_button = $CheckList # Your clipboard button
@onready var game_over_test_btn = $GameOverTest # Reference your test button

# --- VARIABLES ---
var checklist_instance = null 
var is_game_over_active = false # A flag to know if we are waiting for a screen tap
var game_over_timer: Timer

func _ready():
	# Connect the Settings button's pressed signal
	$Settings.pressed.connect(_on_settings_pressed)
	
	# Connect our new Checklist button
	checklist_button.pressed.connect(_toggle_checklist)
	
	# Connect the Game Over test button
	game_over_test_btn.pressed.connect(_on_game_over_pressed)

func _on_settings_pressed():
	# 1. Create a fresh copy of the pause menu
	var pause_menu_instance = PAUSE_MENU.instantiate()
	
	# 2. Add it to the screen
	add_child(pause_menu_instance)
	
	# 3. Pause the underlying game!
	get_tree().paused = true

func _toggle_checklist():
	# 1. If the menu hasn't been created yet, spawn it!
	if checklist_instance == null:
		checklist_instance = CHECKLIST_MENU.instantiate()
		add_child(checklist_instance)
		# PAUSE REMOVED FROM HERE
	else:
		# 2. If it already exists, just flip it on or off!
		if checklist_instance.visible:
			checklist_instance.hide()
			# UNPAUSE REMOVED FROM HERE
		else:
			# Update the page to catch any new checkmarks before showing!
			if checklist_instance.has_method("update_page"):
				checklist_instance.update_page() 
				
			checklist_instance.show()
			# PAUSE REMOVED FROM HERE

# --- GAME OVER LOGIC ---
func _on_game_over_pressed():
	if is_game_over_active:
		return
		
	is_game_over_active = true
	get_tree().paused = true # Freeze the game world
	
	# Spawn the red Game Over screen
	var game_over_instance = GAME_OVER_SCREEN.instantiate()
	add_child(game_over_instance)
	
	# Create an 8-second timer in the background
	game_over_timer = Timer.new()
	game_over_timer.wait_time = 8.0
	game_over_timer.one_shot = true
	game_over_timer.process_mode = Node.PROCESS_MODE_ALWAYS # Let timer run while paused!
	
	add_child(game_over_timer)
	game_over_timer.timeout.connect(_go_to_title_screen)
	game_over_timer.start()

func _input(event):
	# If the Game Over screen is showing, listen for screen taps or mouse clicks
	if is_game_over_active:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_go_to_title_screen()
		elif event is InputEventScreenTouch and event.pressed:
			_go_to_title_screen()

func _go_to_title_screen():
	# Safety check so we don't trigger this twice if the timer and a click happen at the same time
	if not is_game_over_active:
		return
		
	is_game_over_active = false
	
	# VERY IMPORTANT: Unpause the game engine before switching scenes! 
	# Otherwise, your Title Screen will be permanently frozen.
	get_tree().paused = false 
	
	# Transition to the title screen
	get_tree().change_scene_to_file(TITLE_SCREEN)
