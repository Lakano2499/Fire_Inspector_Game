extends StaticBody2D

@export var mini_game_scene: PackedScene

# --- ADDED SPRITE REFERENCE ---
@onready var anim_sprite = $AnimatedSprite2D 

@onready var interact_area = $interact
@onready var highlight_area = $area_seen 
@onready var interact_indicator = $interact_indicator 

var is_completed = false 

func _ready() -> void:
	# Make sure it defaults to the burning animation when the scene loads!
	anim_sprite.play("candle") 
	
	interact_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	if is_completed:
		return
		
	# Freeze the entire game engine
	get_tree().paused = true
		
	# Show the Dialogue Box
	DialogueManager.show_dialogue("Berong", "There is a lit candle! What should we do?!", ["Put out candle", "Ignore"])
	
	# WAIT here until the player makes a choice
	var choice = await DialogueManager.choice_selected
	
	# Handle the choice!
	if choice == 0: # "Put out candle"
		_start_mini_game()
	elif choice == 1: # "Ignore"
		# Unfreeze the game so they can walk away
		get_tree().paused = false

func _start_mini_game() -> void:
	if mini_game_scene != null:
		var popup = mini_game_scene.instantiate()
		get_tree().root.add_child(popup)
		
		await popup.tree_exited
		
		# Unfreeze the game after the minigame is beaten
		get_tree().paused = false
		
		# Permanently disable this candle
		_mark_as_completed()
	else:
		push_warning("Forgot to assign the mini_game_scene in the inspector!")

func _mark_as_completed() -> void:
	is_completed = true
	
	# --- CHANGE THE ANIMATION TO UNLIT ---
	anim_sprite.play("candle_no_flame")
	
	# This EXACT string links to your Task Manager to make the (0/3) go up!
	TaskManager.complete_task("Turn off lit candles")
	
	# Turn off the interaction collision entirely
	interact_area.set_deferred("monitoring", false)
	interact_area.set_deferred("monitorable", false)
	
	# Turn off the highlight collision so it no longer glows
	highlight_area.set_deferred("monitoring", false)
	highlight_area.set_deferred("monitorable", false)
	
	# Hide the E/Interact prompt just in case it was showing
	interact_indicator.hide()
