extends Control

const BRIDGE_NAME := "FlutterGodotBridge"

var _bridge: Object
var _phase := 0.0
var _touch_count := 0
var _paused := false
var _technique := "Slow circular pressure"
var _title_label: Label
var _hint_label: Label


func _ready() -> void:
	set_process(true)
	resized.connect(_layout_labels)
	_create_labels()
	_bridge = Engine.get_singleton(BRIDGE_NAME) if Engine.has_singleton(BRIDGE_NAME) else null
	if _bridge:
		_bridge.connect("flutter_message", _on_flutter_message)
		_send_to_flutter("godot_ready", {"scene": "main"})
	else:
		push_warning("FlutterGodotBridge is unavailable; running in editor mode.")


func _process(delta: float) -> void:
	if not _paused:
		_phase = fmod(_phase + delta * 2.1, TAU)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("17201e"))
	var center := size * Vector2(0.5, 0.5)
	var unit := minf(size.x, size.y)
	var outer_radius := unit * (0.17 + sin(_phase) * 0.012)
	var inner_radius := unit * 0.105

	draw_circle(center, outer_radius, Color(0.42, 0.65, 0.57, 0.18))
	draw_circle(center, inner_radius, Color("7ea99a"))
	draw_circle(center, inner_radius * 0.63, Color("dcebe4"))
	draw_arc(center, outer_radius * 1.18, -PI * 0.7, PI * 0.7, 80, Color("d8b78d"), 7.0, true)


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	var position := Vector2.ZERO
	if event is InputEventScreenTouch:
		pressed = event.pressed
		position = event.position
	elif event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		position = event.position

	if pressed and position.distance_to(size * Vector2(0.5, 0.5)) < minf(size.x, size.y) * 0.2:
		_touch_count += 1
		_hint_label.text = "Release, breathe, and repeat"
		_send_to_flutter("interaction", {"count": _touch_count})
		accept_event()


func _create_labels() -> void:
	_title_label = Label.new()
	_title_label.text = _technique
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.add_theme_color_override("font_color", Color("f7f5ef"))
	add_child(_title_label)

	_hint_label = Label.new()
	_hint_label.text = "Press gently inside the circle"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 28)
	_hint_label.add_theme_color_override("font_color", Color("becdc6"))
	add_child(_hint_label)
	_layout_labels()


func _layout_labels() -> void:
	if not _title_label or not _hint_label:
		return
	_title_label.position = Vector2(32.0, size.y * 0.16)
	_title_label.size = Vector2(size.x - 64.0, 70.0)
	_hint_label.position = Vector2(32.0, size.y * 0.77)
	_hint_label.size = Vector2(size.x - 64.0, 56.0)


func _on_flutter_message(message_json: String) -> void:
	var message = JSON.parse_string(message_json)
	if typeof(message) != TYPE_DICTIONARY:
		push_warning("Ignoring invalid Flutter bridge message.")
		return

	var action: String = str(message.get("action", ""))
	var payload: Dictionary = message.get("payload", {})
	match action:
		"configure":
			_technique = str(payload.get("technique", _technique))
			_title_label.text = _technique
			_paused = false
		"pause":
			_paused = true
			_hint_label.text = "Paused"
		"resume":
			_paused = false
			_hint_label.text = "Press gently inside the circle"
		"reset":
			_touch_count = 0
			_phase = 0.0
			_paused = false
			_hint_label.text = "Press gently inside the circle"


func _send_to_flutter(type: String, payload: Dictionary) -> void:
	if _bridge:
		_bridge.call("sendToFlutter", type, JSON.stringify(payload))
