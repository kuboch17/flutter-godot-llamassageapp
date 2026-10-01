@tool
class_name ArrowPathIndicator
extends Node3D

const ARROW_PLANE_NORMAL := Vector3.UP
const ARROW_GEOMETRY_REVISION := 7

@export_storage var spline_path: NodePath = NodePath(".."):
	get:
		return _spline_path
	set(value):
		_spline_path = value
		_refresh()

@export_storage var moving_progress: float = 0.0:
	get:
		return _moving_progress
	set(value):
		_moving_progress = value
		_refresh()

var speed: float = 0.28
## Cas, pocas ktoreho sipka po resete pocka na zaciatku, zatial co sa ruky
## priamo a plynulo vratia z End do Start.
var hand_reset_duration: float = 0.45
var arrow_length: float = 0.12:
	get:
		return _arrow_length
	set(value):
		_arrow_length = value
		_rebuild_arrow_meshes()

var arrow_width: float = 0.055:
	get:
		return _arrow_width
	set(value):
		_arrow_width = value
		_rebuild_arrow_meshes()

var shaft_width: float = 0.04:
	get:
		return _shaft_width
	set(value):
		_shaft_width = value
		_rebuild_arrow_meshes()

var surface_offset: float = 0.018:
	get:
		return _surface_offset
	set(value):
		_surface_offset = value
		_refresh()

var moving_arrow_lift: float = 0.0:
	get:
		return _moving_arrow_lift
	set(value):
		_moving_arrow_lift = value
		_refresh()

var static_arrow_color := Color(0.7, 0.7, 0.7, 0.58):
	get:
		return _static_arrow_color
	set(value):
		_static_arrow_color = value
		_apply_materials()

var moving_arrow_color := Color(1.0, 1.0, 1.0, 1.0):
	get:
		return _moving_arrow_color
	set(value):
		_moving_arrow_color = value
		_apply_materials()

var animate_in_editor := true

@export_storage var mirror_enabled := false:
	get:
		return _mirror_enabled
	set(value):
		_mirror_enabled = value
		_refresh()

@export_storage var mirror_reference_path: NodePath = NodePath("../MirrorReference"):
	get:
		return _mirror_reference_path
	set(value):
		_mirror_reference_path = value
		_refresh()

@export_tool_button("Toggle Mirror") var toggle_mirror_button = _toggle_mirror
## X = normalizovana pozicia na trase, Y = nasobitel globalnej rychlosti.
@export var speed_curve: Curve

var _spline_path := NodePath("..")
var _moving_progress := 0.0
var _arrow_length := 0.12
var _arrow_width := 0.055
var _shaft_width := 0.04
var _surface_offset := 0.018
var _moving_arrow_lift := 0.0
var _static_arrow_color := Color(0.7, 0.7, 0.7, 0.58)
var _moving_arrow_color := Color(1.0, 1.0, 1.0, 1.0)
var _static_arrow: MeshInstance3D
var _moving_arrow: MeshInstance3D
var _static_arrow_mirror: MeshInstance3D
var _moving_arrow_mirror: MeshInstance3D
var _static_material: ShaderMaterial
var _moving_material: ShaderMaterial
var _mirror_enabled := false
var _mirror_reference_path := NodePath("../MirrorReference")
var _reset_pause_remaining := 0.0
var _last_static_start := Vector3.INF
var _last_static_mid := Vector3.INF
var _last_static_end := Vector3.INF
var _last_static_arrow_length := -1.0
var _last_static_arrow_width := -1.0
var _last_static_shaft_width := -1.0
var _last_static_surface_offset := -1.0
var _last_static_plane_normal := Vector3.INF
var _last_static_geometry_revision := -1


func _ready() -> void:
	_ensure_children()
	_rebuild_arrow_meshes()
	_apply_materials()
	_refresh()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not animate_in_editor:
		_refresh()
		return

	if _reset_pause_remaining > 0.0:
		_reset_pause_remaining = maxf(_reset_pause_remaining - delta, 0.0)
		_refresh()
		return

	var local_speed_multiplier := 1.0
	if speed_curve != null:
		local_speed_multiplier = maxf(speed_curve.sample_baked(_moving_progress), 0.01)
	_moving_progress += delta * speed * local_speed_multiplier
	if _moving_progress >= 1.0:
		_moving_progress = 0.0
		_reset_pause_remaining = hand_reset_duration
	_refresh()


func _ensure_children() -> void:
	if _static_arrow == null:
		_static_arrow = get_node_or_null("StaticArrow") as MeshInstance3D
	if _static_arrow == null:
		_static_arrow = MeshInstance3D.new()
		_static_arrow.name = "StaticArrow"
		add_child(_static_arrow)
	_static_arrow.sorting_offset = 0.0

	if _moving_arrow == null:
		_moving_arrow = get_node_or_null("MovingArrow") as MeshInstance3D
	if _moving_arrow == null:
		_moving_arrow = MeshInstance3D.new()
		_moving_arrow.name = "MovingArrow"
		add_child(_moving_arrow)
	_moving_arrow.sorting_offset = 100.0

	if _static_arrow_mirror == null:
		_static_arrow_mirror = get_node_or_null("StaticArrowMirror") as MeshInstance3D
	if _static_arrow_mirror == null:
		_static_arrow_mirror = MeshInstance3D.new()
		_static_arrow_mirror.name = "StaticArrowMirror"
		add_child(_static_arrow_mirror)
	_static_arrow_mirror.sorting_offset = 1.0

	if _moving_arrow_mirror == null:
		_moving_arrow_mirror = get_node_or_null("MovingArrowMirror") as MeshInstance3D
	if _moving_arrow_mirror == null:
		_moving_arrow_mirror = MeshInstance3D.new()
		_moving_arrow_mirror.name = "MovingArrowMirror"
		add_child(_moving_arrow_mirror)
	_moving_arrow_mirror.sorting_offset = 101.0


func _rebuild_arrow_meshes() -> void:
	# Exportovane settery sa volaju uz pocas deserializacie PackedScene.
	# Vtedy este existujuce deti nemusia byt nacitane a _ensure_children()
	# by vytvoril duplikaty s rovnakymi nazvami.
	if not is_inside_tree():
		return
	# Staticka siva sipka pouziva cache, zatial co biela sa generuje kazdy frame.
	# Pri zmene geometrie musime cache zneplatnit, aby sa otocili obe rovnako.
	_last_static_start = Vector3.INF
	_last_static_mid = Vector3.INF
	_last_static_end = Vector3.INF
	_last_static_arrow_length = -1.0
	_last_static_arrow_width = -1.0
	_last_static_shaft_width = -1.0
	_last_static_surface_offset = -1.0
	_last_static_plane_normal = Vector3.INF
	_last_static_geometry_revision = -1
	_ensure_children()
	_refresh()


func _create_path_arrow_mesh(
	spline: Node,
	end_progress: float = 1.0,
	extra_lift: float = 0.0,
	mirrored: bool = false,
	start_progress: float = 0.0
) -> ArrayMesh:
	var sample_count := 40
	var points := PackedVector3Array()
	var distances := PackedFloat32Array()
	var total_length := 0.0
	var clamped_end_progress := clampf(end_progress, 0.0, 1.0)
	var clamped_start_progress := clampf(start_progress, 0.0, clamped_end_progress)

	for i in range(sample_count + 1):
		var progress := lerpf(
			clamped_start_progress,
			clamped_end_progress,
			float(i) / float(sample_count)
		)
		var point := _sample_spline_point(spline, progress, mirrored)
		if points.size() > 0:
			total_length += points[points.size() - 1].distance_to(point)
		points.append(point)
		distances.append(total_length)

	if total_length <= 0.001:
		return ArrayMesh.new()

	var head_length := minf(_arrow_length, total_length)
	# Ked zostava iba cast hlavicky, zmensi jej dlzku aj sirku rovnakym
	# pomerom. Trojuholnik tak ostava podobny povodnemu a nemeni svoje uhly.
	var head_scale := clampf(head_length / maxf(_arrow_length, 0.0001), 0.0, 1.0)
	var head_width := _arrow_width * head_scale
	var head_start_distance := maxf(total_length - head_length, 0.0)
	var shaft_points := PackedVector3Array()

	for i in range(points.size()):
		if distances[i] < head_start_distance:
			shaft_points.append(points[i])

	shaft_points.append(_point_at_distance(points, distances, head_start_distance))

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	# Rovina sipky je otocena o 90 stupnov okolo smeru krivky, aby mesh
	# lezal naplocho namiesto toho, aby stal na svojej hrane.
	var plane_normal := ARROW_PLANE_NORMAL
	var previous_side := Vector3.RIGHT
	var previous_normal := plane_normal

	for i in range(shaft_points.size()):
		var tangent := _tangent_for_points(shaft_points, i)
		var side := tangent.cross(plane_normal)
		if side.is_zero_approx():
			side = previous_side
		else:
			side = side.normalized()
		if side.dot(previous_side) < 0.0:
			side = -side
		var normal := side.cross(tangent).normalized()
		previous_side = side
		previous_normal = normal
		var lift := normal * (_surface_offset + extra_lift)
		vertices.append(shaft_points[i] - side * (_shaft_width * 0.5) + lift)
		vertices.append(shaft_points[i] + side * (_shaft_width * 0.5) + lift)
		normals.append(normal)
		normals.append(normal)

	for i in range(shaft_points.size() - 1):
		var a := i * 2
		var b := a + 1
		var c := a + 2
		var d := a + 3
		indices.append(a)
		indices.append(c)
		indices.append(b)
		indices.append(b)
		indices.append(c)
		indices.append(d)

	# Biela hlavicka je vzdy presne podobna sivej hlavicke. Nepocita si smer
	# z kratkeho zvysku krivky; iba sa skaluje smerom k rovnakemu hrotu.
	var full_head := _get_full_head_frame(spline, mirrored)
	var tip: Vector3 = full_head.tip
	var full_head_start: Vector3 = full_head.start
	var head_start := tip.lerp(full_head_start, head_scale)
	var head_side: Vector3 = full_head.side
	var head_normal: Vector3 = full_head.normal
	var head_base_index := vertices.size()
	var head_lift := head_normal * (_surface_offset + extra_lift)
	vertices.append(head_start - head_side * (head_width * 0.5) + head_lift)
	vertices.append(head_start + head_side * (head_width * 0.5) + head_lift)
	vertices.append(tip + head_lift)
	normals.append(head_normal)
	normals.append(head_normal)
	normals.append(head_normal)
	indices.append(head_base_index)
	indices.append(head_base_index + 2)
	indices.append(head_base_index + 1)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _get_full_head_frame(spline: Node, mirrored: bool) -> Dictionary:
	var sample_count := 40
	var points := PackedVector3Array()
	var distances := PackedFloat32Array()
	var total_length := 0.0
	for i in range(sample_count + 1):
		var progress := float(i) / float(sample_count)
		var point := _sample_spline_point(spline, progress, mirrored)
		if not points.is_empty():
			total_length += points[points.size() - 1].distance_to(point)
		points.append(point)
		distances.append(total_length)

	var full_head_length := minf(_arrow_length, total_length)
	var head_start_distance := maxf(total_length - full_head_length, 0.0)
	var head_start := _point_at_distance(points, distances, head_start_distance)
	var tip := points[points.size() - 1]

	# Zrekonstruuj presne rovnaky posledny rez tela ako pri generovani
	# statickej sipky. Hlavicka tak zdedi tangentu, bocnu os aj normalu
	# priamo zo shaftu a v spoji nemoze vzniknut zlom.
	var shaft_points := PackedVector3Array()
	for i in range(points.size()):
		if distances[i] < head_start_distance:
			shaft_points.append(points[i])
	shaft_points.append(head_start)

	var previous_side := Vector3.RIGHT
	var previous_normal := ARROW_PLANE_NORMAL
	for i in range(shaft_points.size()):
		var tangent := _tangent_for_points(shaft_points, i)
		var side := tangent.cross(ARROW_PLANE_NORMAL)
		if side.is_zero_approx():
			side = previous_side
		else:
			side = side.normalized()
		if side.dot(previous_side) < 0.0:
			side = -side
		var normal := side.cross(tangent).normalized()
		if normal.is_zero_approx():
			normal = previous_normal
		previous_side = side
		previous_normal = normal

	return {
		"start": head_start,
		"tip": tip,
		"side": previous_side,
		"normal": previous_normal,
	}


func _apply_materials() -> void:
	if not is_inside_tree():
		return
	_ensure_children()
	_static_material = _make_arrow_material(_static_arrow_color)
	_moving_material = _make_arrow_material(_moving_arrow_color)
	_static_material.render_priority = 120
	_moving_material.render_priority = 127
	_static_arrow.material_override = _static_material
	_moving_arrow.material_override = _moving_material
	_static_arrow_mirror.material_override = _static_material
	_moving_arrow_mirror.material_override = _moving_material


func _make_arrow_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, depth_draw_never, cull_disabled, blend_mix;

uniform vec4 arrow_color : source_color = vec4(1.0);
uniform float opacity_scale : hint_range(0.0, 1.0) = 1.0;

void vertex() {
	// Sipka je vzdy nad telom, ale pod rukami. Godot 4 pouziva reversed-Z;
	// ruky su v rozsahu 0.98+, preto sipku drzime o kus hlbsie.
	vec4 clip_position = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float original_depth = clip_position.z / clip_position.w;
	clip_position.z = clip_position.w * (0.94 + original_depth * 0.01);
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = arrow_color.rgb;
	ALPHA = arrow_color.a * opacity_scale;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("arrow_color", color)
	return material


func _refresh() -> void:
	if not is_inside_tree():
		return
	_ensure_children()
	var spline := get_node_or_null(_spline_path)
	if spline == null or not spline.has_method("get_point_at") or not spline.has_method("get_tangent_at"):
		return
	_static_arrow.visible = true
	_moving_arrow.visible = true

	_static_arrow.transform = Transform3D.IDENTITY
	_moving_arrow.transform = Transform3D.IDENTITY
	_static_arrow_mirror.transform = Transform3D.IDENTITY
	_moving_arrow_mirror.transform = Transform3D.IDENTITY
	_rebuild_static_arrow_if_needed(spline)
	if _moving_material != null:
		_moving_material.set_shader_parameter("opacity_scale", 1.0)
	# Biela vrstva zobrazuje este neprejdenu cast. Jej spodny koniec sa hybe
	# spolu s palcami a cela biela sipka sa smerom ku koncu skracuje.
	_moving_arrow.mesh = _create_path_arrow_mesh(
		spline,
		1.0,
		0.0,
		false,
		_moving_progress
	)
	_refresh_mirror_arrows(spline)


func _rebuild_static_arrow_if_needed(spline: Node) -> void:
	var current_start: Vector3 = spline.get_point_at(0.0)
	var current_mid: Vector3 = spline.get_point_at(0.5)
	var current_end: Vector3 = spline.get_point_at(1.0)
	var path_changed := not current_start.is_equal_approx(_last_static_start) or not current_mid.is_equal_approx(_last_static_mid) or not current_end.is_equal_approx(_last_static_end)
	var shape_changed := not is_equal_approx(_last_static_arrow_length, _arrow_length) or not is_equal_approx(_last_static_arrow_width, _arrow_width) or not is_equal_approx(_last_static_shaft_width, _shaft_width)
	shape_changed = shape_changed or not _last_static_plane_normal.is_equal_approx(ARROW_PLANE_NORMAL)
	shape_changed = shape_changed or _last_static_geometry_revision != ARROW_GEOMETRY_REVISION
	var offset_changed := not is_equal_approx(_last_static_surface_offset, _surface_offset)
	if not path_changed and not shape_changed and not offset_changed:
		return

	_static_arrow.mesh = _create_path_arrow_mesh(spline, 1.0, 0.0)
	_last_static_start = current_start
	_last_static_mid = current_mid
	_last_static_end = current_end
	_last_static_arrow_length = _arrow_length
	_last_static_arrow_width = _arrow_width
	_last_static_shaft_width = _shaft_width
	_last_static_surface_offset = _surface_offset
	_last_static_plane_normal = ARROW_PLANE_NORMAL
	_last_static_geometry_revision = ARROW_GEOMETRY_REVISION


func _refresh_mirror_arrows(spline: Node) -> void:
	var mirror_reference := get_node_or_null(_mirror_reference_path) as Node3D
	var should_show_mirror := _mirror_enabled and mirror_reference != null
	_static_arrow_mirror.visible = should_show_mirror
	_moving_arrow_mirror.visible = should_show_mirror
	if not should_show_mirror:
		_static_arrow_mirror.mesh = null
		_moving_arrow_mirror.mesh = null
		return

	_static_arrow_mirror.mesh = _create_path_arrow_mesh(spline, 1.0, 0.0, true)
	_moving_arrow_mirror.mesh = _create_path_arrow_mesh(
		spline,
		1.0,
		0.0,
		true,
		_moving_progress
	)


func _sample_spline_point(spline: Node, progress: float, mirrored: bool) -> Vector3:
	var spline_node := spline as Node3D
	if spline_node == null:
		return Vector3.ZERO

	var local_point: Vector3 = spline.get_point_at(progress)
	# ArrowPathIndicator je potomok spline. Pocitame iba z lokalnych transformov,
	# aby generovanie fungovalo aj pri instantiate(), kym uzly este nie su v SceneTree.
	var point_in_indicator := transform.affine_inverse() * local_point
	if not mirrored:
		return point_in_indicator

	var mirror_reference := get_node_or_null(_mirror_reference_path) as Node3D
	if mirror_reference == null:
		return point_in_indicator

	var mirror_local := mirror_reference.transform.affine_inverse() * local_point
	mirror_local.x = -mirror_local.x
	var mirrored_point_in_spline := mirror_reference.transform * mirror_local
	return transform.affine_inverse() * mirrored_point_in_spline


func _toggle_mirror() -> void:
	mirror_enabled = not _mirror_enabled


func _point_at_distance(points: PackedVector3Array, distances: PackedFloat32Array, target_distance: float) -> Vector3:
	for i in range(1, points.size()):
		if distances[i] >= target_distance:
			var segment_length := distances[i] - distances[i - 1]
			if segment_length <= 0.0001:
				return points[i]
			var weight := (target_distance - distances[i - 1]) / segment_length
			return points[i - 1].lerp(points[i], weight)
	return points[points.size() - 1]


func _tangent_for_points(points: PackedVector3Array, index: int) -> Vector3:
	if points.size() < 2:
		return Vector3.UP
	if index <= 0:
		return (points[1] - points[0]).normalized()
	if index >= points.size() - 1:
		return (points[index] - points[index - 1]).normalized()
	return (points[index + 1] - points[index - 1]).normalized()


func _normal_for_tangent(tangent: Vector3, preferred_normal: Vector3) -> Vector3:
	var normal := preferred_normal.normalized()
	if abs(tangent.normalized().dot(normal)) > 0.95:
		normal = Vector3.UP
	return normal


func _side_from_tangent(tangent: Vector3, plane_normal: Vector3) -> Vector3:
	var side := tangent.normalized().cross(plane_normal).normalized()
	if side.is_zero_approx():
		side = Vector3.RIGHT
	return side
