class_name SimpleObject
extends Interactable
## Generic interactable that forwards to a callable (bed, cauldron, signs...).

var action: Callable
var prompt_fn: Callable
var available_fn: Callable


func setup(p: String, fn: Callable, r := 1.6, h := 1.2) -> SimpleObject:
	prompt = p
	action = fn
	radius = r
	focus_height = h
	return self


func get_prompt() -> String:
	if prompt_fn.is_valid():
		return prompt_fn.call()
	return prompt


func can_interact(_p: Node) -> bool:
	if available_fn.is_valid() and not available_fn.call():
		return false
	return enabled and is_visible_in_tree()


func interact(player: Node) -> void:
	if action.is_valid():
		action.call(player)
