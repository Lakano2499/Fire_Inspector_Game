extends CanvasLayer

# --- NODE REFERENCES ---
# Paths are based exactly on your scene tree layout in image_421541.jpg
@onready var close_btn = $MainPanel/close/X
@onready var mobile_toggle_btn = $MainPanel/MovementControlPanel/MobileControlToggle
@onready var music_slider = $MainPanel/Box2/music_slider

func _ready() -> void:
	# 1. Connect buttons and sliders
	close_btn.pressed.connect(_on_close_pressed)
	mobile_toggle_btn.pressed.connect(_on_mobile_toggle_pressed)
	
	if music_slider:
		var music_bus_index = AudioServer.get_bus_index("Music")
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index)) * 100.0
		music_slider.value_changed.connect(_on_music_slider_changed)
		
	# 2. Automatically remember and display the current saved state!
	_update_toggle_button_text()

# --- TOGGLE LOGIC ---
func _on_mobile_toggle_pressed() -> void:
	# Flip the global variable saved in TaskManager
	TaskManager.is_mobile = not TaskManager.is_mobile
	_update_toggle_button_text()

func _update_toggle_button_text() -> void:
	if TaskManager.is_mobile:
		mobile_toggle_btn.text = "Mobile Mode"
	else:
		mobile_toggle_btn.text = "Computer Mode"

# --- AUDIO LOGIC ---
func _on_music_slider_changed(value: float) -> void:
	var music_bus_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value / 100.0))

# --- CLOSE LOGIC ---
func _on_close_pressed() -> void:
	# Safely removes the settings overlay from the Title Screen
	queue_free()
