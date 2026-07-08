extends Node

var button_sound_player: AudioStreamPlayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Make sure it plays sounds even when game is paused!
	
	button_sound_player = AudioStreamPlayer.new()
	button_sound_player.stream = preload("res://assets/sounds&music/button_sound_effect.mp3")
	button_sound_player.bus = "SFX"
	add_child(button_sound_player)
	
	# Connect to all future nodes added to the scene tree
	get_tree().node_added.connect(_on_node_added)
	
	# Connect to all nodes already in the scene tree
	_connect_buttons(get_tree().root)

func _on_node_added(node: Node):
	if node is BaseButton:
		if not node.pressed.is_connected(_play_button_sound):
			node.pressed.connect(_play_button_sound)

func _connect_buttons(node: Node):
	if node is BaseButton:
		if not node.pressed.is_connected(_play_button_sound):
			node.pressed.connect(_play_button_sound)
	for child in node.get_children():
		_connect_buttons(child)

func _play_button_sound():
	# Stop and play again so clicking rapidly restarts the sound
	button_sound_player.stop()
	button_sound_player.play()
