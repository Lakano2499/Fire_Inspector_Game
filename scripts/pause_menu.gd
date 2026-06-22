extends CanvasLayer

# --- NODE REFERENCES ---
@onready var mobile_toggle_btn = $MainPanel/MovementControlPanel/MobileControlToggle
@onready var music_slider = $MainPanel/Box2/music_slider # NEW: The music slider
@onready var sfx_slider = $MainPanel/Box2/sfx_effects_slider # NEW: SFX slider

func _ready():
	$MainPanel/Box1/Resume.pressed.connect(_on_resume_pressed)
	$MainPanel/Box1/Restart.pressed.connect(_on_restart_pressed)
	$MainPanel/Box1/Home.pressed.connect(_on_home_pressed)
	
	var close_btn = get_node_or_null("MainPanel/close/X")
	if close_btn:
		close_btn.pressed.connect(_on_resume_pressed)
		
	if mobile_toggle_btn:
		mobile_toggle_btn.pressed.connect(_on_mobile_toggle_pressed)
		_update_toggle_button_text()

	# --- NEW: Setup Music Slider ---
	if music_slider:
		# Find the internal ID of our "Music" bus
		var music_bus_index = AudioServer.get_bus_index("Music")
		# Set the slider's initial position to match the current volume
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index)) * 100.0
		# Listen for when the player drags it
		music_slider.value_changed.connect(_on_music_slider_changed)

	# --- NEW: Setup SFX Slider ---
	if sfx_slider:
		var sfx_bus_index = AudioServer.get_bus_index("SFX")
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index)) * 100.0
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)

# --- AUDIO SLIDER LOGIC ---
func _on_music_slider_changed(value: float) -> void:
	var music_bus_index = AudioServer.get_bus_index("Music")
	# Convert the 0-100 slider value into Decibels and apply it to the bus
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value / 100.0))

func _on_sfx_slider_changed(value: float) -> void:
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value / 100.0))

# --- TOGGLE LOGIC ---
func _on_mobile_toggle_pressed() -> void:
	TaskManager.is_mobile = not TaskManager.is_mobile
	_update_toggle_button_text()

func _update_toggle_button_text() -> void:
	if TaskManager.is_mobile:
		mobile_toggle_btn.text = "Mobile Mode"
	else:
		mobile_toggle_btn.text = "Computer Mode"

# --- NAVIGATION LOGIC ---
func _on_resume_pressed():
	get_tree().paused = false
	queue_free()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_home_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/System UI/title_screen.tscn")
