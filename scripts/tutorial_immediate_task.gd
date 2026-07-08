extends StaticBody2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var interact_area = $interact
@onready var highlight_area = $area_seen

var is_completed = false
var is_ignited = false # Prevents interaction before it's on fire

func _ready() -> void:
	is_ignited = false
	
	# 1. Force the animation to be safe. 
	# (Make sure "default_state" is exactly what your safe animation is named in the SpriteFrames!)
	anim_sprite.play("default_state") 
	
	# 2. CRITICAL: Hide the warning marker on startup!
	var alert_marker = get_node_or_null("AlertMarker")
	if alert_marker:
		alert_marker.hide()
		
	# 3. Connect the interaction
	if interact_area:
		interact_area.interacted.connect(_on_interacted)

# The Map Director calls this function after 2 tasks are done
# The Map Director calls this function after 2 tasks are done
func start_emergency() -> void:
	is_ignited = true
	
	# 1. Turn the red marker back on!
	var alert_marker = get_node_or_null("AlertMarker")
	if alert_marker:
		alert_marker.show()
		
	# 2. Play the fire animation (Change this name if your candle uses a different fire animation!)
	anim_sprite.play("burning_pan_looping")

func _on_interacted() -> void:
	if is_completed or not is_ignited:
		return
		
	get_tree().paused = true
	DialogueManager.show_dialogue("Tutorial", "Nice, you found the immediate task!", ["Continue"])
	await DialogueManager.choice_selected
	get_tree().paused = false
	
	_mark_as_completed()

func _mark_as_completed() -> void:
	is_completed = true
	is_ignited = false
	
	# NEW: Force the animation to play only once and stop!
	anim_sprite.sprite_frames.set_animation_loop("burning_pan_closing_with_lid", false)
	anim_sprite.play("burning_pan_closing_with_lid")
	
	# Hide the warning marker!
	var alert_marker = get_node_or_null("AlertMarker")
	if alert_marker:
		alert_marker.hide()
	
	# Tell the Map Director the emergency is over
	var map_director = get_tree().current_scene
	map_director.report_emergency_finished()
	
	interact_area.set_deferred("monitoring", false)
	interact_area.set_deferred("monitorable", false)
	if highlight_area:
		highlight_area.set_deferred("monitoring", false)
		highlight_area.set_deferred("monitorable", false)
