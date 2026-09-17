extends Control

const SETTINGS_PATH := "user://profile.cfg"

var user_name := ""
var selected_button: Button
var intro_tween: Tween

@onready var setup_overlay: ColorRect = $SetupOverlay
@onready var name_input: LineEdit = $SetupOverlay/Panel/SetupContent/NameInput
@onready var save_name_button: Button = $SetupOverlay/Panel/SetupContent/SaveNameButton
@onready var welcome_label: Label = $ScrollContainer/Content/Header/WelcomeLabel
@onready var header: ColorRect = $ScrollContainer/Content/Header
@onready var body: Panel = $ScrollContainer/Content/Body
@onready var content: Control = $ScrollContainer/Content
@onready var button_grid: GridContainer = $ScrollContainer/Content/Body/BodyContent/ButtonGrid
@onready var detail_screen: Control = $DetailScreen
@onready var detail_gradient: Control = $DetailScreen/DetailGradient
@onready var detail_title: Label = $DetailScreen/DetailCard/DetailContent/DetailTitle
@onready var detail_info: Label = $DetailScreen/DetailCard/DetailContent/DetailInfo
@onready var start_massage_button: Button = $DetailScreen/DetailCard/DetailContent/StartMassageButton

func _ready() -> void:
	_apply_main_menu_window_mode()
	get_viewport().size_changed.connect(_sync_layout_to_viewport)
	_connect_massage_buttons()
	_hide_detail_screen_immediately()
	_sync_layout_to_viewport()
	user_name = _load_saved_name()
	if user_name.is_empty():
		_show_setup_overlay()
		name_input.grab_focus()
	else:
		setup_overlay.visible = false
		_set_welcome_text("Welcome back %s" % user_name)
		call_deferred("_play_intro_animation")

func _sync_layout_to_viewport() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var header_height: float = 430.0
	var body_top: float = 330.0
	var bottom_padding: float = 96.0
	var minimum_body_height: float = maxf(viewport_size.y - body_top, viewport_size.x * 1.7)
	var total_height: float = body_top + minimum_body_height + bottom_padding

	content.custom_minimum_size = Vector2(viewport_size.x, total_height)
	body.custom_minimum_size = Vector2(viewport_size.x, minimum_body_height + bottom_padding)
	body.offset_top = body_top
	body.offset_bottom = total_height
	header.custom_minimum_size = Vector2(viewport_size.x, header_height)

func _on_name_input_text_changed(new_text: String) -> void:
	var fixed_text := _format_name(new_text)
	if fixed_text != new_text:
		var caret := name_input.caret_column
		name_input.text = fixed_text
		name_input.caret_column = min(caret, fixed_text.length())
	save_name_button.disabled = fixed_text.strip_edges().is_empty()

func _on_name_input_text_submitted(_new_text: String) -> void:
	_save_setup_name()

func _on_save_name_button_pressed() -> void:
	_save_setup_name()

func _on_massage_button_pressed(button: Button) -> void:
	selected_button = button
	_show_detail_screen(button)

func _on_detail_back_button_pressed() -> void:
	_hide_detail_screen()

func _on_start_massage_button_pressed() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(detail_screen, "modulate:a", 0.0, 0.18)
	tween.tween_callback(get_tree().change_scene_to_file.bind("res://cube_scene.tscn"))

func _save_setup_name() -> void:
	var next_name := _format_name(name_input.text).strip_edges()
	if next_name.is_empty():
		return
	user_name = next_name

	var config := ConfigFile.new()
	config.set_value("profile", "name", user_name)
	config.save(SETTINGS_PATH)

	setup_overlay.visible = false
	_set_welcome_text("Welcome %s" % user_name)
	_sync_layout_to_viewport()
	call_deferred("_play_intro_animation")

func _load_saved_name() -> String:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return ""
	return str(config.get_value("profile", "name", "")).strip_edges()

func _format_name(value: String) -> String:
	var clean_value := value.strip_edges()
	if clean_value.is_empty():
		return ""
	return clean_value.substr(0, 1).to_upper() + clean_value.substr(1)

func _set_welcome_text(value: String) -> void:
	welcome_label.text = value

func _connect_massage_buttons() -> void:
	for child in button_grid.get_children():
		if child is Button:
			var button: Button = child as Button
			button.pressed.connect(_on_massage_button_pressed.bind(button))

func _show_setup_overlay() -> void:
	setup_overlay.visible = true
	setup_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(setup_overlay, "modulate:a", 1.0, 0.25)

func _play_intro_animation() -> void:
	if intro_tween:
		intro_tween.kill()
	_sync_layout_to_viewport()
	modulate.a = 1.0
	var original_header_position := header.position
	var original_body_position := body.position
	var original_content_position := content.position

	header.position = original_header_position + Vector2(0, -28)
	body.position = original_body_position + Vector2(0, 42)
	content.position = original_content_position + Vector2(0, 34)
	header.modulate.a = 0.0
	body.modulate.a = 0.0
	content.modulate.a = 0.0

	intro_tween = create_tween()
	intro_tween.set_parallel(true)
	intro_tween.set_trans(Tween.TRANS_CUBIC)
	intro_tween.set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(header, "position", original_header_position, 0.45)
	intro_tween.tween_property(header, "modulate:a", 1.0, 0.35)
	intro_tween.tween_property(body, "position", original_body_position, 0.5)
	intro_tween.tween_property(body, "modulate:a", 1.0, 0.35)
	intro_tween.tween_property(content, "position", original_content_position, 0.6).set_delay(0.08)
	intro_tween.tween_property(content, "modulate:a", 1.0, 0.35).set_delay(0.08)

func _show_detail_screen(button: Button) -> void:
	detail_title.text = button.text
	detail_info.text = str(button.get("info_text"))

	var left_color: Color = button.get("gradient_left")
	var right_color: Color = button.get("gradient_right")
	detail_gradient.set("gradient_left", left_color)
	detail_gradient.set("gradient_right", right_color)
	start_massage_button.set("gradient_left", left_color)
	start_massage_button.set("gradient_right", right_color)

	var screen_width: float = get_viewport_rect().size.x
	detail_screen.visible = true
	detail_screen.modulate.a = 1.0
	detail_screen.position = Vector2(screen_width, 0.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(detail_screen, "position:x", 0.0, 0.42)

func _hide_detail_screen() -> void:
	var screen_width: float = get_viewport_rect().size.x
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(detail_screen, "position:x", screen_width, 0.34)
	tween.tween_callback(_hide_detail_screen_immediately)

func _hide_detail_screen_immediately() -> void:
	detail_screen.visible = false
	detail_screen.position = Vector2(get_viewport_rect().size.x, 0.0)
	detail_screen.modulate.a = 1.0

func _apply_main_menu_window_mode() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	if OS.has_feature("mobile"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var preferred_size := Vector2i(540, 900)
	var maximum_size := Vector2i(
		maxi(int(usable_rect.size.x * 0.9), 320),
		maxi(int(usable_rect.size.y * 0.85), 480)
	)
	var window_size := Vector2i(
		mini(preferred_size.x, maximum_size.x),
		mini(preferred_size.y, maximum_size.y)
	)
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position(usable_rect.position + (usable_rect.size - window_size) / 2)
