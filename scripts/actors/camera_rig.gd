class_name CameraRig
extends Node3D
## Third person follow camera with a fixed, cosy pitch. Rotate with Z/C,
## right-mouse drag or the right stick; zoom with the mouse wheel or +/-.

var target: Node3D
var cam: Camera3D
var yaw := 0.0
var yaw_target := 0.0
var pitch := deg_to_rad(-36.0)
var distance := 12.0
var distance_target := 12.0
var focus := Vector3.ZERO
var enabled_input := true
var terrain: Terrain
## Optional override used by cutscenes: [position, look_at]
var override_pose: Array = []
var _drag := false
var _cur_dist := 13.0
## Extra tilt so the player can look up at the sky (radians, positive = look up).
var tilt := 0.0


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 42.0
	cam.near = 0.3
	cam.far = 1400.0
	add_child(cam)
	cam.current = true


func snap() -> void:
	if target:
		focus = target.global_position + Vector3(0, 1.6, 0)
	yaw = yaw_target
	distance = distance_target
	_cur_dist = distance
	_update_transform(1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled_input:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance_target = clampf(distance_target - 1.0, 7.0, 22.0)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance_target = clampf(distance_target + 1.0, 7.0, 22.0)
	elif event is InputEventMouseMotion and _drag:
		yaw_target -= (event as InputEventMouseMotion).relative.x * 0.008
		tilt = clampf(tilt + (event as InputEventMouseMotion).relative.y * 0.006, -0.35, 0.95)


func _process(delta: float) -> void:
	if enabled_input:
		var turn := Input.get_axis("cam_left", "cam_right")
		yaw_target -= turn * delta * 1.8
		var z := Input.get_axis("zoom_in", "zoom_out")
		distance_target = clampf(distance_target + z * delta * 10.0, 7.0, 22.0)
		var tl := Input.get_axis("tilt_down", "tilt_up")
		tilt = clampf(tilt + tl * delta * 1.2, -0.35, 0.95)
		# drift back to the normal view once the troll walks on
		if absf(tl) < 0.1 and not _drag and target is CharacterBody3D:
			var v := (target as CharacterBody3D).velocity
			if Vector2(v.x, v.z).length() > 1.0:
				tilt = move_toward(tilt, 0.0, delta * 0.6)
	yaw = lerp_angle(yaw, yaw_target, clampf(delta * 8.0, 0.0, 1.0))
	distance = lerpf(distance, distance_target, clampf(delta * 6.0, 0.0, 1.0))
	if target:
		var want := target.global_position + Vector3(0, 1.6, 0)
		focus = focus.lerp(want, clampf(delta * 7.0, 0.0, 1.0))
	_update_transform(delta)


func _update_transform(delta: float) -> void:
	if not override_pose.is_empty():
		var p: Vector3 = override_pose[0]
		var l: Vector3 = override_pose[1]
		cam.global_position = cam.global_position.lerp(p, clampf(delta * 2.5, 0.0, 1.0))
		var cur := cam.global_transform
		var goal := cur.looking_at(l, Vector3.UP)
		cam.global_transform = Transform3D(cur.basis.slerp(goal.basis, clampf(delta * 3.0, 0.0, 1.0)).orthonormalized(), cam.global_position)
		return
	pitch = deg_to_rad(lerpf(-22.0, -40.0, clampf((distance - 7.0) / 15.0, 0.0, 1.0))) + tilt
	pitch = clampf(pitch, deg_to_rad(-70.0), deg_to_rad(12.0))
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var want := distance
	# keep the camera out of rocks and buildings
	if is_inside_tree():
		var space := get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(focus, focus + b * Vector3(0, 0, distance + 0.5), 2 | 16)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			want = maxf(2.5, focus.distance_to(hit["position"]) - 0.6)
	if want < _cur_dist:
		_cur_dist = want
	else:
		_cur_dist = lerpf(_cur_dist, want, clampf(delta * 2.5, 0.0, 1.0))
	var pos := focus + b * Vector3(0, 0, _cur_dist)
	if terrain:
		var g := terrain.height_at(pos.x, pos.z) + 1.5
		if pos.y < g:
			pos.y = g
	cam.global_position = pos
	if tilt > 0.05:
		# looking up: aim above the troll towards the sky
		var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
		cam.look_at(focus + fwd * 6.0 + Vector3(0, tilt * 9.0, 0), Vector3.UP)
	else:
		cam.look_at(focus, Vector3.UP)


## Horizontal forward direction of the camera (for camera-relative movement).
func flat_forward() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw))


func flat_right() -> Vector3:
	return Vector3(cos(yaw), 0, -sin(yaw))
