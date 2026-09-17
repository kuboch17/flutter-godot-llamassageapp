@tool
class_name ProceduralSplineMesh
extends MeshInstance3D

@export var start_point: Vector3 = Vector3(-0.18, 0.16, 0.03):
	get:
		return _start_point
	set(value):
		_start_point = value
		_queue_rebuild()

@export var end_point: Vector3 = Vector3(0.18, 0.16, 0.03):
	get:
		return _end_point
	set(value):
		_end_point = value
		_queue_rebuild()

@export_range(0.0, 1.0, 0.001) var arc_height: float = 0.08:
	get:
		return _arc_height
	set(value):
		_arc_height = value
		_queue_rebuild()

@export_range(0.001, 0.1, 0.001) var radius: float = 0.01:
	get:
		return _radius
	set(value):
		_radius = value
		_queue_rebuild()

@export_range(2, 128, 1) var segment_count: int = 32:
	get:
		return _segment_count
	set(value):
		_segment_count = value
		_queue_rebuild()

@export_range(3, 24, 1) var radial_segments: int = 8:
	get:
		return _radial_segments
	set(value):
		_radial_segments = value
		_queue_rebuild()

@export var line_material: Material = preload("res://mats/dotted_line.tres"):
	get:
		return _line_material
	set(value):
		_line_material = value
		_queue_rebuild()

@export var show_path_mesh := false:
	get:
		return _show_path_mesh
	set(value):
		_show_path_mesh = value
		_queue_rebuild()

@export var use_marker_points := true:
	get:
		return _use_marker_points
	set(value):
		_use_marker_points = value
		_queue_rebuild()

@export_range(0, 2, 1) var control_point_count: int = 0:
	get:
		return _control_point_count
	set(value):
		_control_point_count = value
		_queue_rebuild()

@export_node_path("Node3D") var start_marker_path: NodePath = NodePath("StartPoint"):
	get:
		return _start_marker_path
	set(value):
		_start_marker_path = value
		_queue_rebuild()

@export_node_path("Node3D") var control_marker_1_path: NodePath = NodePath("ControlPoint1"):
	get:
		return _control_marker_1_path
	set(value):
		_control_marker_1_path = value
		_queue_rebuild()

@export_node_path("Node3D") var control_marker_2_path: NodePath = NodePath("ControlPoint2"):
	get:
		return _control_marker_2_path
	set(value):
		_control_marker_2_path = value
		_queue_rebuild()

@export_node_path("Node3D") var end_marker_path: NodePath = NodePath("EndPoint"):
	get:
		return _end_marker_path
	set(value):
		_end_marker_path = value
		_queue_rebuild()

var _use_marker_points := true
var _control_point_count := 0
var _start_marker_path := NodePath("StartPoint")
var _control_marker_1_path := NodePath("ControlPoint1")
var _control_marker_2_path := NodePath("ControlPoint2")
var _end_marker_path := NodePath("EndPoint")
var _start_point := Vector3(-0.18, 0.16, 0.03)
var _control_point_1 := Vector3(-0.06, 0.2, 0.03)
var _control_point_2 := Vector3(0.06, 0.2, 0.03)
var _end_point := Vector3(0.18, 0.16, 0.03)
var _arc_height := 0.08
var _radius := 0.01
var _segment_count := 32
var _radial_segments := 8
var _line_material: Material = preload("res://mats/dotted_line.tres")
var _show_path_mesh := false
var _needs_rebuild := false
var _last_start_marker_position := Vector3.INF
var _last_control_marker_1_position := Vector3.INF
var _last_control_marker_2_position := Vector3.INF
var _last_end_marker_position := Vector3.INF


func _ready() -> void:
	_refresh_setup_marker_visibility()
	_rebuild_mesh()


func _process(_delta: float) -> void:
	_refresh_setup_marker_visibility()
	if _use_marker_points:
		_sync_points_from_markers()

	if _needs_rebuild:
		_needs_rebuild = false
		_rebuild_mesh()


func _refresh_setup_marker_visibility() -> void:
	var show_in_editor := Engine.is_editor_hint()
	var start_marker := get_node_or_null(_start_marker_path) as Node3D
	var end_marker := get_node_or_null(_end_marker_path) as Node3D
	var control_marker_1 := get_node_or_null(_control_marker_1_path) as Node3D
	var control_marker_2 := get_node_or_null(_control_marker_2_path) as Node3D

	if start_marker != null:
		start_marker.visible = show_in_editor
	if end_marker != null:
		end_marker.visible = show_in_editor
	if control_marker_1 != null:
		control_marker_1.visible = show_in_editor and _control_point_count >= 1
	if control_marker_2 != null:
		control_marker_2.visible = show_in_editor and _control_point_count >= 2


func set_points(from_point: Vector3, to_point: Vector3) -> void:
	_start_point = from_point
	_end_point = to_point
	_queue_rebuild()


func get_point_at(progress: float) -> Vector3:
	return _sample_curve(clampf(progress, 0.0, 1.0))


func get_tangent_at(progress: float) -> Vector3:
	return _sample_tangent(clampf(progress, 0.0, 1.0))


func _queue_rebuild() -> void:
	_needs_rebuild = true
	if is_inside_tree():
		call_deferred("_rebuild_mesh")


func _rebuild_mesh() -> void:
	if _use_marker_points:
		_sync_points_from_markers()

	if not _show_path_mesh or _start_point.is_equal_approx(_end_point):
		mesh = null
		return

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var lengths := PackedFloat32Array()
	var total_length := 0.0
	var previous_point := _sample_curve(0.0)

	lengths.append(0.0)
	for i in range(1, _segment_count + 1):
		var t := float(i) / float(_segment_count)
		var point := _sample_curve(t)
		total_length += previous_point.distance_to(point)
		lengths.append(total_length)
		previous_point = point

	for i in range(_segment_count + 1):
		var t := float(i) / float(_segment_count)
		var center := _sample_curve(t)
		var tangent := _sample_tangent(t)
		var frame := _make_frame(tangent)

		for j in range(_radial_segments):
			var angle := TAU * float(j) / float(_radial_segments)
			var normal := (frame[0] * cos(angle) + frame[1] * sin(angle)).normalized()
			vertices.append(center + normal * _radius)
			normals.append(normal)
			uvs.append(Vector2(lengths[i], float(j) / float(_radial_segments)))

	for i in range(_segment_count):
		for j in range(_radial_segments):
			var next_j := (j + 1) % _radial_segments
			var a := i * _radial_segments + j
			var b := i * _radial_segments + next_j
			var c := (i + 1) * _radial_segments + j
			var d := (i + 1) * _radial_segments + next_j

			indices.append(a)
			indices.append(c)
			indices.append(b)
			indices.append(b)
			indices.append(c)
			indices.append(d)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var generated_mesh := ArrayMesh.new()
	generated_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = generated_mesh

	if _line_material != null:
		set_surface_override_material(0, _line_material)


func _sample_curve(t: float) -> Vector3:
	var clamped_t := clampf(t, 0.0, 1.0)
	if _control_point_count == 1:
		return _sample_quadratic_bezier(_start_point, _control_point_1, _end_point, clamped_t)
	if _control_point_count >= 2:
		return _sample_cubic_bezier(_start_point, _control_point_1, _control_point_2, _end_point, clamped_t)

	var midpoint := (_start_point + _end_point) * 0.5 + Vector3.UP * _arc_height
	return _sample_quadratic_bezier(_start_point, midpoint, _end_point, clamped_t)


func _sample_quadratic_bezier(start: Vector3, control: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus_t := 1.0 - t
	return one_minus_t * one_minus_t * start \
		+ 2.0 * one_minus_t * t * control \
		+ t * t * end


func _sample_cubic_bezier(start: Vector3, control_1: Vector3, control_2: Vector3, end: Vector3, t: float) -> Vector3:
	var one_minus_t := 1.0 - t
	return one_minus_t * one_minus_t * one_minus_t * start \
		+ 3.0 * one_minus_t * one_minus_t * t * control_1 \
		+ 3.0 * one_minus_t * t * t * control_2 \
		+ t * t * t * end


func _sample_tangent(t: float) -> Vector3:
	var delta := 0.002
	var before := _sample_curve(maxf(t - delta, 0.0))
	var after := _sample_curve(minf(t + delta, 1.0))
	var tangent := after - before
	if tangent.is_zero_approx():
		tangent = _end_point - _start_point
	return tangent.normalized()


func _make_frame(tangent: Vector3) -> Array[Vector3]:
	var reference := Vector3.UP
	if abs(tangent.dot(reference)) > 0.92:
		reference = Vector3.RIGHT

	var normal_x := tangent.cross(reference).normalized()
	var normal_y := normal_x.cross(tangent).normalized()
	return [normal_x, normal_y]


func _sync_points_from_markers() -> void:
	var start_marker := get_node_or_null(_start_marker_path) as Node3D
	var end_marker := get_node_or_null(_end_marker_path) as Node3D
	if start_marker == null or end_marker == null:
		return

	var next_start := to_local(start_marker.global_position)
	var next_end := to_local(end_marker.global_position)
	var next_control_1 := _control_point_1
	var next_control_2 := _control_point_2

	var control_marker_1 := get_node_or_null(_control_marker_1_path) as Node3D
	if control_marker_1 != null:
		next_control_1 = to_local(control_marker_1.global_position)

	var control_marker_2 := get_node_or_null(_control_marker_2_path) as Node3D
	if control_marker_2 != null:
		next_control_2 = to_local(control_marker_2.global_position)

	var points_unchanged := next_start.is_equal_approx(_last_start_marker_position) and next_end.is_equal_approx(_last_end_marker_position)
	points_unchanged = points_unchanged and next_control_1.is_equal_approx(_last_control_marker_1_position)
	points_unchanged = points_unchanged and next_control_2.is_equal_approx(_last_control_marker_2_position)
	if points_unchanged:
		return

	_start_point = next_start
	_control_point_1 = next_control_1
	_control_point_2 = next_control_2
	_end_point = next_end
	_last_start_marker_position = next_start
	_last_control_marker_1_position = next_control_1
	_last_control_marker_2_position = next_control_2
	_last_end_marker_position = next_end
	_needs_rebuild = true


func _get_curve_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	points.append(_start_point)
	if _control_point_count >= 1:
		points.append(_control_point_1)
	if _control_point_count >= 2:
		points.append(_control_point_2)
	points.append(_end_point)
	return points


func _sample_catmull_rom_path(points: Array[Vector3], t: float) -> Vector3:
	var clamped_t := clampf(t, 0.0, 1.0)
	var path_segment_count := points.size() - 1
	if path_segment_count <= 0:
		return _start_point

	var scaled_t := clamped_t * float(path_segment_count)
	var segment_index := mini(floori(scaled_t), path_segment_count - 1)
	var local_t := scaled_t - float(segment_index)

	var p0 := points[maxi(segment_index - 1, 0)]
	var p1 := points[segment_index]
	var p2 := points[segment_index + 1]
	var p3 := points[mini(segment_index + 2, points.size() - 1)]
	return _catmull_rom(p0, p1, p2, p3, local_t)


func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
