extends Node3D

## Vzdialenost najvysieho a najnizsieho bodu aktivnych sipiek od okraja
## obrazovky (0.1 = 10 % vysky obrazovky). Hodnotu mozes menit v Inspectore.
@export_range(0.0, 0.45, 0.01) var arrow_screen_margin: float = 0.1
@export_range(2, 64, 1) var camera_fit_samples_per_arrow: int = 24
@export_range(0.0, 0.25, 0.005) var arrow_mesh_world_padding: float = 0.04

@onready var camera: Camera3D = $Camera3D

var _last_active_arrows_signature := ""
var _initial_camera_fit_frames := 8

func _ready() -> void:
	_apply_cube_window_mode()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	# Sipky si vytvaraju mesh az v _ready(), preto kameru nastavime o frame neskor.
	call_deferred("_refresh_camera_for_active_arrows")

func _process(_delta: float) -> void:
	# Node3D nema signal pre zmenu visibility. Lacny podpis zabezpeci, ze sa
	# kamera prepocita aj ked sa visibility prepne priamo v inom skripte.
	var signature := _get_active_arrows_signature()
	if signature != _last_active_arrows_signature or _initial_camera_fit_frames > 0:
		_last_active_arrows_signature = signature
		fit_camera_to_active_arrows()
		_initial_camera_fit_frames = maxi(_initial_camera_fit_frames - 1, 0)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _apply_cube_window_mode() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)
	if OS.has_feature("mobile"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	_fit_desktop_window(Vector2i(980, 640))


func _fit_desktop_window(preferred_size: Vector2i) -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var maximum_size := Vector2i(
		maxi(int(usable_rect.size.x * 0.9), 320),
		maxi(int(usable_rect.size.y * 0.85), 240)
	)
	var window_size := Vector2i(
		mini(preferred_size.x, maximum_size.x),
		mini(preferred_size.y, maximum_size.y)
	)
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position(usable_rect.position + (usable_rect.size - window_size) / 2)


## Odporucany sposob aktivacie/deaktivacie sipky z ineho skriptu.
## Kamera sa po zmene automaticky prepocita.
func set_arrow_active(arrow: Node3D, active: bool) -> void:
	if arrow == null:
		return
	arrow.visible = active
	call_deferred("_refresh_camera_for_active_arrows")


func _refresh_camera_for_active_arrows() -> void:
	_last_active_arrows_signature = _get_active_arrows_signature()
	fit_camera_to_active_arrows()


## Vycentruje kameru a nastavi jej vzdialenost tak, aby boli vsetky viditelne
## ProceduralSplineMesh sipky v obraze vratane arrow_screen_margin.
func fit_camera_to_active_arrows() -> void:
	if camera == null or not is_instance_valid(camera):
		return

	var points := _collect_active_arrow_points()
	if points.is_empty():
		return

	var camera_basis := camera.global_basis.orthonormalized()
	var camera_right := camera_basis.x
	var backward := camera_basis.z
	var camera_up := camera_basis.y
	var reference := points[0]
	var min_right := 0.0
	var max_right := 0.0
	var min_up := 0.0
	var max_up := 0.0
	var min_depth := 0.0
	var max_depth := 0.0
	for point in points:
		var offset := point - reference
		var right_position := offset.dot(camera_right)
		var up_position := offset.dot(camera_up)
		var depth_position := offset.dot(backward)
		min_right = minf(min_right, right_position)
		max_right = maxf(max_right, right_position)
		min_up = minf(min_up, up_position)
		max_up = maxf(max_up, up_position)
		min_depth = minf(min_depth, depth_position)
		max_depth = maxf(max_depth, depth_position)

	# Stred je presne medzi najvyssim a najnizsim aktivnym bodom. Pri sipkach
	# leziacich v rovnakej rovine tak vznikne rovnaky horny aj dolny okraj.
	var center := reference
	center += camera_right * ((min_right + max_right) * 0.5)
	center += camera_up * ((min_up + max_up) * 0.5)
	center += backward * ((min_depth + max_depth) * 0.5)

	var vertical_half_extent := (max_up - min_up) * 0.5 + arrow_mesh_world_padding
	var horizontal_half_extent := (max_right - min_right) * 0.5 + arrow_mesh_world_padding
	var depth_half_extent := (max_depth - min_depth) * 0.5
	var usable_screen := maxf(1.0 - arrow_screen_margin * 2.0, 0.1)
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var vertical_tangent := tan(deg_to_rad(camera.fov) * 0.5) * usable_screen
	var horizontal_tangent := vertical_tangent * aspect
	var vertical_distance := vertical_half_extent / maxf(vertical_tangent, 0.001)
	var horizontal_distance := horizontal_half_extent / maxf(horizontal_tangent, 0.001)
	var distance := maxf(vertical_distance, horizontal_distance) + depth_half_extent
	distance = maxf(distance, depth_half_extent + camera.near * 2.0)
	camera.global_position = center + backward * distance
	camera.look_at(center, camera_up)


func _on_viewport_size_changed() -> void:
	call_deferred("_refresh_camera_for_active_arrows")


func _collect_active_arrow_points() -> PackedVector3Array:
	var points := PackedVector3Array()
	# find_children type filter nie je spolahlivy pre GDScript class_name triedy.
	# Prejdeme vsetky uzly a typ overime operatorom `is`.
	for node in find_children("*", "", true, false):
		if not node is ProceduralSplineMesh:
			continue
		var spline := node as ProceduralSplineMesh
		if not _is_arrow_active(spline):
			continue
		var sample_count := maxi(camera_fit_samples_per_arrow, 2)
		for index in range(sample_count + 1):
			var progress := float(index) / float(sample_count)
			points.append(spline.to_global(spline.get_point_at(progress)))

		var indicator := spline.get_node_or_null("ArrowPathIndicator")
		if indicator != null and indicator.get("mirror_enabled") == true:
			var mirror_reference := spline.get_node_or_null("MirrorReference") as Node3D
			if mirror_reference != null:
				var mirror_x := mirror_reference.position.x
				for index in range(sample_count + 1):
					var progress := float(index) / float(sample_count)
					var local_point := spline.get_point_at(progress)
					local_point.x = mirror_x * 2.0 - local_point.x
					points.append(spline.to_global(local_point))
	return points


func _get_active_arrows_signature() -> String:
	var active_ids := PackedStringArray()
	for node in find_children("*", "", true, false):
		if not node is ProceduralSplineMesh:
			continue
		var spline := node as ProceduralSplineMesh
		if _is_arrow_active(spline):
			var start := spline.to_global(spline.get_point_at(0.0))
			var middle := spline.to_global(spline.get_point_at(0.5))
			var end := spline.to_global(spline.get_point_at(1.0))
			active_ids.append("%s:%s:%s:%s" % [spline.get_instance_id(), start, middle, end])
	active_ids.sort()
	return ",".join(active_ids)


func _is_arrow_active(spline: ProceduralSplineMesh) -> bool:
	if spline == null or not spline.is_visible_in_tree():
		return false
	var indicator := spline.get_node_or_null("ArrowPathIndicator") as Node3D
	return indicator != null and indicator.is_visible_in_tree()
