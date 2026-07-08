extends Area2D
class_name ObjectSeen

## The Node to highlight (e.g. Sprite2D) OR a custom Highlightable component.
@export var highlight_node: Node

func _ready() -> void:
	# Ensure signals are connected via code for modularity
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if highlight_node:
			if highlight_node.has_method("enable"):
				highlight_node.enable()
			elif highlight_node is CanvasItem:
				Highlightable.apply(highlight_node)

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		if highlight_node:
			if highlight_node.has_method("disable"):
				highlight_node.disable()
			elif highlight_node is CanvasItem:
				Highlightable.remove(highlight_node)
