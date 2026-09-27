class_name Interactable
extends Node3D
## Anything the troll can walk up to and press the interact button on.

signal interacted

@export var prompt := "Look"
var radius := 1.6
var enabled := true
var focus_height := 1.0
## Reference to the World so interactables can reach shared systems.
var world: Node


func _enter_tree() -> void:
	add_to_group("interactables")


func get_prompt() -> String:
	return prompt


func can_interact(_player: Node) -> bool:
	return enabled and is_visible_in_tree()


func interact(_player: Node) -> void:
	emit_signal("interacted")


func focus_point() -> Vector3:
	return global_position + Vector3(0, focus_height, 0)
