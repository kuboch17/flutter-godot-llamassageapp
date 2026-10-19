extends Node

# Loading and rendering once behind the menu warms resources and GPU pipelines.
const MASSAGE_SCENE := preload("res://cube_scene.tscn")
var session: Node3D
var _bridge: Object

func _ready() -> void:
	if Engine.has_singleton("FlutterGodotBridge"):
		_bridge = Engine.get_singleton("FlutterGodotBridge")
		_bridge.flutter_message.connect(_on_flutter_message)
	# Direct editor runs have no Flutter menu or bridge to start the session.
	_spawn_session(_bridge == null)
	if _bridge != null:
		_bridge.sendToFlutter("godot_ready", "{}")

func _spawn_session(active: bool) -> void:
	if is_instance_valid(session):
		remove_child(session)
		session.queue_free()
	session = MASSAGE_SCENE.instantiate()
	add_child(session)
	session.get_node("UiLayer").visible = active
	if not active:
		session.process_mode = Node.PROCESS_MODE_DISABLED
		session.get_node("UiLayer").visible = false

func _on_flutter_message(message_json: String) -> void:
	var message = JSON.parse_string(message_json)
	if not message is Dictionary:
		return
	match message.get("action", ""):
		"ping":
			if _bridge != null:
				_bridge.sendToFlutter("godot_ready", "{}")
		"start_session":
			_spawn_session(true)
		"stop_session":
			if is_instance_valid(session):
				session.process_mode = Node.PROCESS_MODE_DISABLED
				session.get_node("UiLayer").visible = false
		"request_exit":
			if is_instance_valid(session):
				session.request_exit()
