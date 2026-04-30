class_name Highlightable
extends RefCounted

# ──────────────────────────────────────────────
# Highlightable Helper
# ──────────────────────────────────────────────
# Provides static methods to easily apply or 
# remove a shader-based highlight on CanvasItems.
# ──────────────────────────────────────────────

static var _material: ShaderMaterial = null

static func get_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://assets/shaders/outline.gdshader")
		_material.set_shader_parameter("line_color", Color(1.0, 0.9, 0.1, 1.0))
		_material.set_shader_parameter("line_thickness", 3.0)
	return _material

static func apply(node: CanvasItem) -> void:
	if node:
		node.material = get_material()

static func remove(node: CanvasItem) -> void:
	if node:
		node.material = null
