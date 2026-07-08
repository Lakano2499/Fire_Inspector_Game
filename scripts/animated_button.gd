extends TextureButton

# These export variables will let you drag and drop your frames in the Inspector
@export var frame_1: Texture2D
@export var frame_2: Texture2D
@export var frame_3: Texture2D

var is_pressing = false

func _ready():
	# Connect the built-in button signals to our custom animation functions
	button_down.connect(_on_press_down)
	button_up.connect(_on_release)

func _on_press_down():
	is_pressing = true
	
	# 1. Swap to the in-between middle frame
	texture_normal = frame_2
	
	# 2. Wait a tiny fraction of a second (0.05s)
	await get_tree().create_timer(0.05).timeout
	
	# 3. If the user is still holding the click, swap to the fully pressed frame
	if is_pressing: 
		texture_normal = frame_3

func _on_release():
	is_pressing = false
	
	# 1. Swap back to the middle frame for a smooth release animation
	texture_normal = frame_2
	
	# 2. Wait a tiny fraction of a second
	await get_tree().create_timer(0.05).timeout
	
	# 3. Return to the original unpressed state
	texture_normal = frame_1
