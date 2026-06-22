extends Control

# --- PRELOADS ---
# Make sure this path matches exactly where your settings scene is saved!
const SETTINGS_MENU = preload("res://scenes/System UI/settings.tscn")

@onready var play_button = $ButtonContainer/PlayButton
@onready var settings_button = $ButtonContainer/SettingsButton
@onready var quit_button = $ButtonContainer/QuitButton

func _ready() -> void:
	# Connect the settings button to open the menu
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)

func _on_play_button_pressed() -> void:
	if play_button:
		play_button.disabled = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/System UI/main_menu.tscn")

# --- NEW: Open Settings Panel ---
func _on_settings_button_pressed() -> void:
	var settings_instance = SETTINGS_MENU.instantiate()
	add_child(settings_instance)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
