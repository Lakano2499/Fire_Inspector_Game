extends StaticBody2D

@export var mini_game_scene: PackedScene

@onready var interact_area = $interact
@onready var highlight_area = $area_seen # The area that triggers the highlight outline
@onready var interact_indicator = $interact_indicator # The E/Click prompt

# A flag so we know if the task is already done
var is_completed = false 

func _ready() -> void:
	interact_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	# 1. Stop if already completed!
	if is_completed:
		return
		
	# 2. Pause the background game so the player can't walk away during dialogue
	get_tree().paused = true
		
	# 3. Show the Dialogue Box
	DialogueManager.show_dialogue("Berong", "There is a lit candle! What should we do?!", ["Put out candle", "Ignore"])
	
	# 4. WAIT here until the player makes a choice
	var choice = await DialogueManager.choice_selected
	
	# 5. Handle the choice!
	if choice == 0: # "Put out candle"
		_start_mini_game()
	elif choice == 1: # "Ignore"
		get_tree().paused = false # Just unpause and let them walk away

func _start_mini_game() -> void:
	if mini_game_scene != null:
		# Spawn the mini-game
		var popup = mini_game_scene.instantiate()
		get_tree().root.add_child(popup)
		
		# WAIT here until the popup is destroyed (meaning the player finished it)
		await popup.tree_exited
		
		# Unpause the game and permanently disable this candle
		get_tree().paused = false
		_mark_as_completed()
	else:
		push_warning("Forgot to assign the mini_game_scene in the inspector!")

func _mark_as_completed() -> void:
	is_completed = true
	
	# Turn off the interaction collision entirely
	interact_area.monitoring = false
	interact_area.monitorable = false
	
	# Turn off the highlight collision so it no longer glows
	highlight_area.monitoring = false
	highlight_area.monitorable = false
	
	# Hide the E/Interact prompt just in case it was showing
	interact_indicator.hide()
	
	# Optional: If you have an unlit frame in your AnimatedSprite2D, you could play it here!
	# $AnimatedSprite2D.play("unlit")
