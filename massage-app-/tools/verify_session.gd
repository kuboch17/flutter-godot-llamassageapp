extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _assert_centered(session: Node3D) -> void:
	session.camera.global_transform = session._camera_target
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for point in session._collect_active_arrow_points():
		var projected: Vector2 = session.camera.unproject_position(point)
		minimum = minimum.min(projected)
		maximum = maximum.max(projected)
	var viewport_size: Vector2 = session.get_viewport().get_visible_rect().size
	var desired := Vector2(viewport_size.x * 0.5, (session.hud.get_content_top() + viewport_size.y) * 0.5)
	assert(((minimum + maximum) * 0.5).distance_to(desired) < 0.5)
	assert(minimum.y > session.hud.get_content_top())
	assert(maximum.y < viewport_size.y)
	assert(session.camera.global_basis.is_equal_approx(session._camera_basis))

func _verify() -> void:
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size = Vector2i(1920, 1080)
	var runtime = load("res://embedded_runtime.tscn").instantiate()
	root.add_child(runtime)
	current_scene = runtime
	await process_frame
	await process_frame
	assert(runtime.session.get_node("UiLayer").visible)
	runtime._spawn_session(false)
	await process_frame
	assert(runtime.session.process_mode == Node.PROCESS_MODE_DISABLED)
	assert(not runtime.session.get_node("UiLayer").visible)
	var preview_id: int = runtime.session.get_instance_id()
	runtime._on_flutter_message('{"action":"start_session"}')
	await process_frame
	await process_frame
	var session = runtime.session
	session.set_process(false)
	assert(session.get_instance_id() != preview_id)
	assert(session.positions.size() == 2)
	assert(session.hud.get_children().size() == 4)
	assert(session.hud.time_label.text == "05:00")
	assert(session.get_node("WorldEnvironment").environment.background_color == Color("064bef"))
	assert(session.hud.progress.position.y < session.get_viewport().get_visible_rect().size.y * 0.13)

	for resolution in [Vector2i(1920, 1080), Vector2i(2340, 1080), Vector2i(1280, 720)]:
		root.size = resolution
		await process_frame
		await process_frame
		for position_index in range(2):
			session._select_position(position_index)
			_assert_centered(session)
	session._select_position(0)
	session._process(2.0)
	assert(session.phase == session.Phase.RUNNING)
	assert(session.elapsed_seconds == 0.0)
	var initial_mute: bool = AudioServer.is_bus_mute(0)
	session.hud.sound_button.pressed.emit()
	assert(AudioServer.is_bus_mute(0) != initial_mute)
	session.hud.sound_button.pressed.emit()
	assert(AudioServer.is_bus_mute(0) == initial_mute)
	for interval in range(1, 10):
		session._advance_session(30.0)
		assert(session.active_position == interval % 2)
		_assert_centered(session)
	assert(session.hud.time_label.text == "00:30")
	session._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var before_background: float = session.elapsed_seconds
	session._advance_session(100.0)
	assert(session.elapsed_seconds == before_background)
	session._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	session._advance_session(30.0)
	assert(session.phase == session.Phase.COMPLETE)
	assert(session.hud.time_label.text == "00:00")
	assert(session.hud.progress.value == 300.0)
	var completed_id: int = session.get_instance_id()
	runtime._on_flutter_message('{"action":"stop_session"}')
	runtime._on_flutter_message('{"action":"start_session"}')
	await process_frame
	await process_frame
	session = runtime.session
	assert(session.get_instance_id() != completed_id)
	assert(session.elapsed_seconds == 0.0)
	assert(session.phase == session.Phase.INTRO)
	assert(session.active_position == 0)
	# The only navigation button returns directly, without another dialog.
	session.hud.back_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene.scene_file_path == "res://main.tscn")
	print("PASS: four reference HUD controls; exact blue; arrows centered below toolbar at 3 aspect ratios; automatic start; sound toggle; 30s positions; background pause; 5min completion; fresh restart; immediate back")
	quit()
