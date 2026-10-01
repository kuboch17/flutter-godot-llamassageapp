extends Node

@export_node_path("ProceduralSplineMesh") var spline_path := NodePath("../ProceduralSplineMesh")
@export_node_path("Node3D") var source_pivot_path := NodePath("../handpivot")
@export var hand_material: Material = preload("res://mats/massage_hand_outline.tres")
@export var flip_hands_horizontally := true
## Lokalny rotacny offset pivotu po zarovnani so smerom spline.
@export var rotation_offset_degrees := Vector3.ZERO
## Jednotna velkost oboch ruk okolo ich pivotu (1.0 = povodna velkost).
@export_range(0.1, 3.0, 0.05) var hand_scale := 1.0

var _spline: ProceduralSplineMesh
var _indicator: ArrowPathIndicator
var _left_pivot: Node3D
var _right_pivot: Node3D
var _pivot_basis_relative := Basis.IDENTITY
var _last_progress := 0.0
var _returning_to_start := false
var _return_elapsed := 0.0
var _return_from := Transform3D.IDENTITY


func _ready() -> void:
	set_process(false)
	_spline = get_node_or_null(spline_path) as ProceduralSplineMesh
	_left_pivot = get_node_or_null(source_pivot_path) as Node3D
	if _spline == null or _left_pivot == null:
		return
	_indicator = _spline.get_node_or_null("ArrowPathIndicator") as ArrowPathIndicator
	if _indicator == null:
		return
	call_deferred("_initialize_hands")


func _initialize_hands() -> void:
	if not is_inside_tree() or not is_instance_valid(_left_pivot):
		return
	_freeze_internal_animation(_left_pivot)
	_apply_hand_material(_left_pivot)
	_right_pivot = _left_pivot.duplicate(Node.DUPLICATE_USE_INSTANTIATION) as Node3D
	_right_pivot.name = "MassageHandPivotRight"
	_left_pivot.get_parent().add_child(_right_pivot)
	_freeze_internal_animation(_right_pivot)
	_apply_hand_material(_right_pivot)

	# Autorsku rotaciu pivotu vzdy odvodzuj od pevneho Start frame.
	# Aktualny moving_progress sa moze v editore medzi spusteniami lisit,
	# co predtym vytvaralo nahodny rotacny offset.
	var reference_frame := _path_frame(0.0)
	_pivot_basis_relative = reference_frame.basis.inverse() * _left_pivot.basis
	if flip_hands_horizontally:
		_pivot_basis_relative *= Basis.from_scale(Vector3(-1.0, 1.0, 1.0))
	_update_hands()
	_last_progress = _indicator.moving_progress
	set_process(true)


func _process(delta: float) -> void:
	var progress := _indicator.moving_progress
	if progress + 0.5 < _last_progress:
		_returning_to_start = true
		_return_elapsed = 0.0
		_return_from = _left_pivot.transform

	if _returning_to_start:
		_update_return_to_start(delta)
	else:
		_update_hands()
	_last_progress = progress


func _update_hands() -> void:
	if not is_inside_tree():
		return
	if not is_instance_valid(_left_pivot) or not is_instance_valid(_right_pivot):
		set_process(false)
		return
	if not _left_pivot.is_inside_tree() or not _right_pivot.is_inside_tree():
		return
	var frame := _path_frame(_indicator.moving_progress)
	var left_transform := Transform3D(_pivot_basis_for_frame(frame), frame.origin)
	_left_pivot.transform = left_transform
	_right_pivot.transform = _mirror_transform(left_transform)


func _update_return_to_start(delta: float) -> void:
	if not is_instance_valid(_left_pivot) or not is_instance_valid(_right_pivot):
		return
	_return_elapsed += delta
	var duration := maxf(_indicator.hand_reset_duration, 0.001)
	var linear_t := clampf(_return_elapsed / duration, 0.0, 1.0)
	var smooth_t := smoothstep(0.0, 1.0, linear_t)
	var start_frame := _path_frame(0.0)
	var start_transform := Transform3D(
		_pivot_basis_for_frame(start_frame),
		start_frame.origin
	)
	var left_transform := _return_from.interpolate_with(start_transform, smooth_t)
	_left_pivot.transform = left_transform
	_right_pivot.transform = _mirror_transform(left_transform)
	if linear_t >= 1.0:
		_returning_to_start = false


func _pivot_basis_for_frame(frame: Transform3D) -> Basis:
	var rotation_radians := rotation_offset_degrees * (PI / 180.0)
	var offset_basis := Basis.from_euler(rotation_radians)
	var scale_basis := Basis.from_scale(Vector3.ONE * hand_scale)
	return frame.basis * _pivot_basis_relative * offset_basis * scale_basis


func _path_frame(progress: float) -> Transform3D:
	var point := _spline.transform * _spline.get_point_at(progress)
	var tangent := (_spline.basis * _spline.get_tangent_at(progress)).normalized()
	var up := (_spline.basis * Vector3.UP).normalized()
	var side := tangent.cross(up).normalized()
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	up = side.cross(tangent).normalized()
	return Transform3D(Basis(side, up, -tangent), point)


func _mirror_transform(value: Transform3D) -> Transform3D:
	var mirror_reference := _spline.get_node_or_null("MirrorReference") as Node3D
	if mirror_reference == null:
		return value
	var mirror_in_parent := _spline.transform * mirror_reference.transform
	var local := mirror_in_parent.affine_inverse() * value
	local.origin.x = -local.origin.x
	local.basis.x.x = -local.basis.x.x
	local.basis.y.x = -local.basis.y.x
	local.basis.z.x = -local.basis.z.x
	return mirror_in_parent * local


func _apply_hand_material(hand: Node) -> void:
	for child in hand.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		mesh_instance.material_override = hand_material
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _freeze_internal_animation(hand: Node) -> void:
	for child in hand.find_children("*", "AnimationPlayer", true, false):
		var player := child as AnimationPlayer
		player.stop()
		player.active = false
		player.process_mode = Node.PROCESS_MODE_DISABLED
	for child in hand.find_children("*", "AnimationTree", true, false):
		var tree := child as AnimationTree
		tree.active = false
		tree.process_mode = Node.PROCESS_MODE_DISABLED


func _exit_tree() -> void:
	set_process(false)
