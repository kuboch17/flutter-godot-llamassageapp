extends Control

signal back_requested

const ICON_BUTTON := preload("res://session_icon_button.gd")
const REFERENCE_HEIGHT := 501.0
var back_button: Button
var sound_button: Button
var progress: ProgressBar
var time_label: Label
var _initial_muted := false

func _ready() -> void:
	name = "SessionHUD"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	var ui_font := SystemFont.new()
	ui_font.font_names = PackedStringArray(["SF Pro Display", "Segoe UI", "Roboto", "sans-serif"])
	ui_theme.default_font = ui_font
	theme = ui_theme
	back_button = _icon_button("back", "Back")
	back_button.name = "BackButton"
	add_child(back_button)
	back_button.pressed.connect(func(): back_requested.emit())
	sound_button = _icon_button("sound", "Mute sound")
	sound_button.name = "SoundButton"
	add_child(sound_button)
	_initial_muted = AudioServer.is_bus_mute(0)
	sound_button.muted = _initial_muted
	sound_button.pressed.connect(_toggle_sound)
	_update_sound_tooltip()

	progress = ProgressBar.new()
	progress.name = "Timebar"
	progress.show_percentage = false
	progress.max_value = 300
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_stylebox_override("background", _style(Color(1, 1, 1, 0.16), 999))
	progress.add_theme_stylebox_override("fill", _style(Color.WHITE, 999))
	add_child(progress)
	time_label = Label.new()
	time_label.name = "TimeRemaining"
	time_label.text = "05:00"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(time_label)
	resized.connect(_layout)
	_layout()

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(0)
	style.anti_aliasing = true
	return style

func _icon_button(icon: String, tooltip: String) -> Button:
	var button := Button.new()
	button.set_script(ICON_BUTTON)
	button.icon_kind = icon
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.085), 999))
	button.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.14), 999))
	button.add_theme_stylebox_override("pressed", _style(Color(1, 1, 1, 0.21), 999))
	return button

func _layout() -> void:
	if not is_instance_valid(back_button):
		return
	var factor := size.y / REFERENCE_HEIGHT
	var diameter := 55.0 * factor
	back_button.position = Vector2(48, 29) * factor
	back_button.size = Vector2.ONE * diameter
	sound_button.position = Vector2(size.x - 54.0 * factor - diameter, 29.0 * factor)
	sound_button.size = Vector2.ONE * diameter
	var width := minf(275.0 * factor, size.x * 0.27)
	progress.position = Vector2((size.x - width) * 0.5, 54.0 * factor)
	progress.size = Vector2(width, 7.0 * factor)
	time_label.add_theme_font_size_override("font_size", maxi(roundi(20.0 * factor), 12))
	time_label.position = Vector2(sound_button.position.x - 84.0 * factor, 29.0 * factor)
	time_label.size = Vector2(60.0, 55.0) * factor
	back_button.queue_redraw()
	sound_button.queue_redraw()

func get_content_top() -> float:
	return progress.position.y + progress.size.y

func update_progress(elapsed: float, duration: float) -> void:
	progress.max_value = duration
	progress.value = elapsed
	var remaining := maxi(ceili(duration - elapsed), 0)
	time_label.text = "%02d:%02d" % [remaining / 60, remaining % 60]

func _toggle_sound() -> void:
	sound_button.muted = not sound_button.muted
	AudioServer.set_bus_mute(0, sound_button.muted)
	sound_button.queue_redraw()
	_update_sound_tooltip()

func _update_sound_tooltip() -> void:
	sound_button.tooltip_text = "Unmute sound" if sound_button.muted else "Mute sound"

func _exit_tree() -> void:
	AudioServer.set_bus_mute(0, _initial_muted)

