extends Node3D

@export_range(0.0, 0.45, 0.01) var arrow_screen_margin: float = 0.16
@export_range(2, 64, 1) var camera_fit_samples_per_arrow: int = 24
@export_range(0.0, 0.25, 0.005) var arrow_mesh_world_padding: float = 0.04
@export_range(1.0, 3.0, 0.05) var camera_zoom_out: float = 1.6
@export var duration_seconds: float = 300.0
@export var position_seconds: float = 30.0
@export var camera_transition_seconds: float = 1.4

const HUD_SCRIPT := preload("res://session_hud.gd")
enum Phase { INTRO, RUNNING, COMPLETE }
var phase := Phase.INTRO
var elapsed_seconds := 0.0
var active_position := 0
var positions: Array[Node3D] = []
var _last_active_arrows_signature := ""
var _camera_target := Transform3D.IDENTITY
var _intro_from := Transform3D.IDENTITY
var _intro_elapsed := 0.0
var _camera_ready := false
var _camera_basis := Basis.IDENTITY
var _application_active := true
var _exit_sent := false
var hud: Control
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	_camera_basis = camera.global_basis.orthonormalized()
	camera.make_current()
	$UiLayer.layer = 100
	$UiLayer.visible = true
	if not Engine.has_singleton("FlutterGodotBridge"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	get_tree().auto_accept_quit = false
	var environment := $WorldEnvironment.environment.duplicate() as Environment
	environment.background_color = Color("064bef")
	$WorldEnvironment.environment = environment
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	for child in get_children():
		if child is Node3D and _contains_arrow(child):
			positions.append(child)
	hud = Control.new()
	hud.set_script(HUD_SCRIPT)
	$UiLayer.add_child(hud)
	hud.back_requested.connect(request_exit)
	call_deferred("_initialize_session")

func _contains_arrow(node: Node) -> bool:
	if node is ProceduralSplineMesh:
		return true
	for child in node.get_children():
		if _contains_arrow(child):
			return true
	return false

func _initialize_session() -> void:
	if not is_inside_tree() or positions.is_empty():
		return
	_select_position(0)
	_camera_ready = true
	_intro_from = _camera_target
	_intro_from.origin += _camera_target.basis.z * maxf(camera.global_position.distance_to(_camera_target.origin), 0.7)
	camera.global_transform = _intro_from
	_set_animation_running(false)
	hud.update_progress(0.0, duration_seconds)

func _process(delta: float) -> void:
	if not _camera_ready or not _application_active:
		return
	if phase == Phase.INTRO:
		_intro_elapsed += delta
		var t := clampf(_intro_elapsed / 1.8, 0.0, 1.0)
		camera.global_transform = _intro_from.interpolate_with(_camera_target, 1.0 - pow(1.0 - t, 3.0))
		if t >= 1.0:
			_start_massage()
	else:
		camera.global_transform = camera.global_transform.interpolate_with(_camera_target, 1.0 - exp(-5.0 * delta / maxf(camera_transition_seconds, 0.01)))
		if phase == Phase.RUNNING:
			_advance_session(delta)

func _start_massage() -> void:
	if phase != Phase.INTRO:
		return
	phase = Phase.RUNNING
	fit_camera_to_active_arrows()
	_set_animation_running(true)

func _advance_session(delta: float) -> void:
	if phase != Phase.RUNNING or not _application_active:
		return
	elapsed_seconds = minf(elapsed_seconds + delta, duration_seconds)
	if elapsed_seconds >= duration_seconds:
		phase = Phase.COMPLETE
		fit_camera_to_active_arrows()
		_set_animation_running(false)
	else:
		var next_position := int(elapsed_seconds / maxf(position_seconds, 0.01)) % positions.size()
		if next_position != active_position:
			_select_position(next_position)
	hud.update_progress(elapsed_seconds, duration_seconds)

func _select_position(index: int) -> void:
	active_position = index
	for i in range(positions.size()):
		positions[i].visible = i == index
		positions[i].process_mode = Node.PROCESS_MODE_INHERIT if i == index else Node.PROCESS_MODE_DISABLED
	for node in positions[index].find_children("*", "", true, false):
		if node is ArrowPathIndicator:
			node.moving_progress = 0.0
	$MassageHandsController.set_active_spline(_first_spline(positions[index]))
	fit_camera_to_active_arrows()
	_set_animation_running(phase == Phase.RUNNING)

func _first_spline(node: Node) -> ProceduralSplineMesh:
	if node is ProceduralSplineMesh:
		return node
	for child in node.get_children():
		var spline := _first_spline(child)
		if spline != null:
			return spline
	return null

func _set_animation_running(running: bool) -> void:
	for position in positions:
		for node in position.find_children("*", "", true, false):
			if node is ArrowPathIndicator:
				node.set_process(running and position.visible)
	$MassageHandsController.set_process(running)

func request_exit() -> void:
	_leave_session()

func _leave_session() -> void:
	if _exit_sent:
		return
	_exit_sent = true
	_set_animation_running(false)
	if Engine.has_singleton("FlutterGodotBridge"):
		Engine.get_singleton("FlutterGodotBridge").sendToFlutter("back_to_menu", "{}")
	else:
		get_tree().change_scene_to_file("res://main.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_application_active = false
		if is_node_ready():
			_set_animation_running(false)
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_application_active = true
		if is_node_ready():
			_set_animation_running(phase == Phase.RUNNING)
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_node_ready():
			request_exit()

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

	# Always retain the authored angle; fit only position and distance.
	var camera_basis := _camera_basis
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
	var content_top: float = hud.get_content_top() if is_instance_valid(hud) else viewport_size.y * 61.0 / 501.0
	var content_fraction := (viewport_size.y - content_top) / maxf(viewport_size.y, 1.0)
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var projection_tangent := tan(deg_to_rad(camera.fov) * 0.5)
	var vertical_tangent := projection_tangent * usable_screen * content_fraction
	var horizontal_tangent := projection_tangent * usable_screen * aspect
	var vertical_distance := vertical_half_extent / maxf(vertical_tangent, 0.001)
	var horizontal_distance := horizontal_half_extent / maxf(horizontal_tangent, 0.001)
	var distance := maxf(vertical_distance, horizontal_distance) + depth_half_extent
	distance = maxf(distance, depth_half_extent + camera.near * 2.0)
	distance *= camera_zoom_out
	_camera_target = Transform3D(camera_basis, center + backward * distance)
	var desired_center := Vector2(0.5, (content_top + viewport_size.y) / (2.0 * maxf(viewport_size.y, 1.0)))
	_center_projected_arrows(points, desired_center, projection_tangent, aspect, distance)


func _center_projected_arrows(points: PackedVector3Array, desired: Vector2, tangent: float, aspect: float, distance: float) -> void:
	# Solve against projected extrema, including depth and mirrored paths. This
	# centers the arrow group exactly in the space below the toolbar.
	for axis in range(2):
		var direction := _camera_basis.x if axis == 0 else _camera_basis.y
		var origin := _camera_target.origin
		var low := -distance * tangent * maxf(aspect, 1.0)
		var high := -low
		for iteration in range(28):
			var offset := (low + high) * 0.5
			var candidate := origin + direction * offset
			var minimum := INF
			var maximum := -INF
			for point in points:
				var relative := point - candidate
				var depth := maxf(-relative.dot(_camera_basis.z), camera.near)
				var coordinate := 0.5 + relative.dot(_camera_basis.x) / (2.0 * depth * tangent * aspect) if axis == 0 else 0.5 - relative.dot(_camera_basis.y) / (2.0 * depth * tangent)
				minimum = minf(minimum, coordinate)
				maximum = maxf(maximum, coordinate)
			var midpoint := (minimum + maximum) * 0.5
			if (axis == 0 and midpoint > desired.x) or (axis == 1 and midpoint < desired.y):
				low = offset
			else:
				high = offset
		_camera_target.origin = origin + direction * ((low + high) * 0.5)


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
