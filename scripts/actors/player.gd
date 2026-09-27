class_name Player
extends CharacterBody3D
## The player troll.

signal focus_changed(target: Interactable)

const WALK_SPEED := 4.4
const RUN_SPEED := 7.4
const ACCEL := 14.0
const GRAVITY := 22.0
const MAX_WADE_DEPTH := 1.25

var model: CharacterModel
var rig: CameraRig
var world: Node
var busy := false
var carrying := false
var focus: Interactable
var _focus_shown := false
var facing := Vector3(0, 0, 1)
var _step_timer := 0.0
var _last_safe := Vector3.ZERO
var _mode_lock := 0.0
var _locked_mode := ""

const LOOK := {
	"skin": Color(0.6, 0.53, 0.45), "hair": Color(0.45, 0.62, 0.3), "hair_style": "moss",
	"scarf": Color(0.8, 0.25, 0.22), "belly": Color(0.7, 0.62, 0.52), "nose": 1.1, "size": 1.0,
}


func _ready() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.6
	cap.height = 2.3
	cs.shape = cap
	cs.position = Vector3(0, 1.15, 0)
	add_child(cs)
	model = CharacterModel.new()
	model.build_troll(LOOK)
	add_child(model)
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.6
	_last_safe = global_position


func face_toward(p: Vector3) -> void:
	var d := p - global_position
	d.y = 0
	if d.length() > 0.01:
		facing = d.normalized()
		model.rotation.y = atan2(facing.x, facing.z)


## Temporarily force an animation (e.g. "lift", "shake", "wave").
func play_mode(mode_name: String, seconds: float) -> void:
	_locked_mode = mode_name
	_mode_lock = seconds


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if not busy and Game.playing:
		input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var dir := Vector3.ZERO
	if rig and input.length() > 0.05:
		dir = (rig.flat_forward() * input.y + rig.flat_right() * input.x)
		if dir.length() > 1.0:
			dir = dir.normalized()
	var running := Input.is_action_pressed("run") and not busy
	var speed := RUN_SPEED if running else WALK_SPEED
	if carrying:
		speed = WALK_SPEED * 0.7
	var want := dir * speed
	var hv := Vector3(velocity.x, 0, velocity.z)
	hv = hv.move_toward(want, ACCEL * delta * (1.0 if want.length() > 0.1 else 1.4) * speed * 0.3)
	velocity.x = hv.x
	velocity.z = hv.z
	if is_on_floor():
		velocity.y = -1.0
	else:
		velocity.y -= GRAVITY * delta
	var before := global_position
	move_and_slide()
	# keep out of deep water
	if world and world.has_method("water_depth_at"):
		var depth: float = world.water_depth_at(global_position)
		if depth > MAX_WADE_DEPTH:
			global_position = Vector3(before.x, global_position.y, before.z)
			velocity.x = 0
			velocity.z = 0
	if global_position.y < -20.0:
		global_position = _last_safe + Vector3(0, 2, 0)
		velocity = Vector3.ZERO
	elif is_on_floor():
		_last_safe = global_position
	# facing / animation
	var hs := Vector2(velocity.x, velocity.z).length()
	if dir.length() > 0.1:
		var yaw := lerp_angle(model.rotation.y, atan2(dir.x, dir.z), clampf(delta * 12.0, 0.0, 1.0))
		model.rotation.y = yaw
		facing = Vector3(sin(yaw), 0, cos(yaw))
	if _mode_lock > 0.0:
		_mode_lock -= delta
		model.set_mode(_locked_mode)
	elif carrying:
		model.set_mode("carry")
	elif busy:
		model.set_mode("talk" if hs < 0.2 else "idle")
	else:
		model.set_mode("idle")
	model.animate(delta, hs)
	# footsteps
	if hs > 0.5 and is_on_floor():
		_step_timer -= delta * hs
		if _step_timer <= 0.0:
			_step_timer = 2.4
			Sound.sfx("step", randf_range(0.8, 1.0), -14.0)
	# interaction focus
	if not busy:
		_update_focus()
	elif _focus_shown:
		focus = null
		_focus_shown = false
		emit_signal("focus_changed", null)


func _update_focus() -> void:
	# note: a freed object compares equal to null, so track validity explicitly
	if not is_instance_valid(focus):
		focus = null
	var best: Interactable = null
	var best_score := 1e9
	var pos := global_position
	for n in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.can_interact(self):
			continue
		var d := it.global_position - pos
		var dist := Vector2(d.x, d.z).length()
		var reach := it.radius + 1.3
		if dist > reach or absf(d.y) > 3.5:
			continue
		var fd := Vector2(d.x, d.z).normalized() if dist > 0.01 else Vector2.ZERO
		var score := dist - fd.dot(Vector2(facing.x, facing.z)) * 0.9
		if score < best_score:
			best_score = score
			best = it
	if best != focus or (best == null and _focus_shown):
		focus = best
		_focus_shown = best != null
		emit_signal("focus_changed", focus)


func _unhandled_input(event: InputEvent) -> void:
	if busy or not Game.playing:
		return
	if event.is_action_pressed("interact") and focus != null and is_instance_valid(focus):
		get_viewport().set_input_as_handled()
		face_toward(focus.global_position)
		var f := focus
		focus = null
		_focus_shown = false
		emit_signal("focus_changed", null)
		f.interact(self)
