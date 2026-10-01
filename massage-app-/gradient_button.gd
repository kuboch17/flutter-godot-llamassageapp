@tool
extends Button

@export var gradient_left: Color = Color(0.12, 0.48, 0.95, 1.0):
	set(value):
		gradient_left = value
		queue_redraw()

@export var gradient_right: Color = Color(0.0, 0.78, 0.92, 1.0):
	set(value):
		gradient_right = value
		queue_redraw()

@export_range(96, 320, 1) var button_height: float = 190.0:
	set(value):
		button_height = value
		_apply_button_size()
		queue_redraw()

@export_range(28, 88, 1) var label_font_size: int = 54:
	set(value):
		label_font_size = value
		queue_redraw()

@export_range(16, 96, 1) var label_left_padding: float = 48.0:
	set(value):
		label_left_padding = value
		queue_redraw()

@export_range(0, 40, 1) var corner_radius: float = 18.0:
	set(value):
		corner_radius = value
		queue_redraw()

@export var center_label: bool = false:
	set(value):
		center_label = value
		queue_redraw()

@export var info_text: String = "":
	set(value):
		info_text = value

@export var keep_square: bool = true:
	set(value):
		keep_square = value
		_apply_button_size()
		queue_redraw()

var _press_tween: Tween

func _ready() -> void:
	_apply_button_size()
	focus_mode = Control.FOCUS_NONE
	flat = true
	add_theme_color_override("font_color", Color(1, 1, 1, 0))
	add_theme_color_override("font_hover_color", Color(1, 1, 1, 0))
	add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0))
	add_theme_color_override("font_focus_color", Color(1, 1, 1, 0))
	pivot_offset = size * 0.5
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	if not button_down.is_connected(_animate_pressed):
		button_down.connect(_animate_pressed)
	if not button_up.is_connected(_animate_released):
		button_up.connect(_animate_released)
	if not mouse_entered.is_connected(_animate_hovered):
		mouse_entered.connect(_animate_hovered)
	if not mouse_exited.is_connected(_animate_released):
		mouse_exited.connect(_animate_released)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_apply_button_size()
		queue_redraw()

func _on_resized() -> void:
	pivot_offset = size * 0.5
	_apply_button_size()

func _draw() -> void:
	var radius: float = minf(corner_radius, minf(size.x, size.y) * 0.5)
	var steps: int = 160
	var step_width: float = size.x / float(steps)
	for index in range(steps):
		var amount: float = float(index) / float(steps - 1)
		var color: Color = gradient_left.lerp(gradient_right, amount)
		var x: float = step_width * float(index)
		var inset: float = _rounded_vertical_inset(x + step_width * 0.5, radius)
		var rect := Rect2(Vector2(x, inset), Vector2(step_width + 1.0, size.y - inset * 2.0))
		draw_rect(rect, color)

	for index in range(steps):
		var x: float = step_width * float(index)
		var inset: float = _rounded_vertical_inset(x + step_width * 0.5, radius)
		var shine_height: float = maxf(size.y * 0.42 - inset, 0.0)
		var shine_rect := Rect2(Vector2(x, inset), Vector2(step_width + 1.0, shine_height))
		draw_rect(shine_rect, Color(1, 1, 1, 0.14))

	var font: Font = get_theme_font("font")
	if center_label:
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, label_font_size)
		var text_position := Vector2(0.0, (size.y + text_size.y) * 0.5 - 8.0)
		draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, label_font_size, Color(1, 1, 1, 0.86))
	else:
		var bottom_padding: float = 28.0
		var text_position := Vector2(label_left_padding, size.y - bottom_padding)
		draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, size.x - label_left_padding * 2.0, label_font_size, Color(1, 1, 1, 0.5))

func _animate_pressed() -> void:
	_run_scale_animation(Vector2(0.97, 0.97), 0.08)

func _animate_hovered() -> void:
	_run_scale_animation(Vector2(1.015, 1.015), 0.12)

func _animate_released() -> void:
	_run_scale_animation(Vector2.ONE, 0.16)

func _run_scale_animation(target_scale: Vector2, duration: float) -> void:
	if _press_tween:
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.set_trans(Tween.TRANS_QUAD)
	_press_tween.set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(self, "scale", target_scale, duration)

func _apply_button_size() -> void:
	var next_height: float = button_height
	if keep_square and size.x > 1.0:
		next_height = size.x
	custom_minimum_size = Vector2(custom_minimum_size.x, next_height)

func _rounded_vertical_inset(x: float, radius: float) -> float:
	if radius <= 0.0:
		return 0.0
	var left_distance: float = radius - x
	var right_distance: float = x - (size.x - radius)
	var distance: float = maxf(left_distance, right_distance)
	if distance <= 0.0:
		return 0.0
	return radius - sqrt(maxf(radius * radius - distance * distance, 0.0))
