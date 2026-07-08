extends StaticBody2D

@onready var interact_area = $interact

func _ready() -> void:
	# Connect your standard interaction signal
	interact_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	# Freeze the player while they read
	get_tree().paused = true
	
	# Show a helpful tutorial message with a single acknowledgement button
	DialogueManager.show_dialogue(
		"Berong", 
		"Welcome to the training facility! Use WASD to move around, and click or press E to interact with objects like me.", 
		["Got it!"]
	)
	
	# Wait for them to click "Got it!"
	await DialogueManager.choice_selected
	
	# Unfreeze the game so they can keep walking
	get_tree().paused = false
