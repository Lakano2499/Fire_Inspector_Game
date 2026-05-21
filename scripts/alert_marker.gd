extends Node2D

@export var target: Node2D # The object this alert belongs to
@export var hover_offset := Vector2(0, -50) # Floating height
@export var edge_margin := 20.0 # Screen edge padding

@onready var editor_ghost = $EditorGhost
@onready var real_marker = $UILayer/RealMarker

func _ready() -> void:
	# Hide the editor visual so we only see the UI one in-game!
	editor_ghost.hide()

func _process(_delta: float) -> void:
	# 1. THE VISIBILITY FIX: Make the CanvasLayer listen to the root node
	if not visible:
		real_marker.hide()
		return # Stop doing math if it's invisible!
	else:
		real_marker.show()
		
	if target == null:
		return
		
	# 2. THE MATH FIX: The correct 2D way to convert world position to UI pixels
	var screen_pos = target.get_global_transform_with_canvas().origin
	
	# Get the size of the player's screen/window
	var screen_size = get_viewport().get_visible_rect().size
	var screen_rect = Rect2(Vector2.ZERO, screen_size)
	
	if screen_rect.has_point(screen_pos):
		# ON SCREEN: Float above target
		real_marker.global_position = screen_pos + hover_offset
		real_marker.rotation = 0 
	else:
		# OFF SCREEN: Clamp to UI edges
		var clamped_x = clamp(screen_pos.x, edge_margin, screen_size.x - edge_margin)
		var clamped_y = clamp(screen_pos.y, edge_margin, screen_size.y - edge_margin)
		
		real_marker.global_position = Vector2(clamped_x, clamped_y)
		
		# Point the tip toward where the target is off-screen
		real_marker.look_at(screen_pos)
		real_marker.rotation += deg_to_rad(90)
