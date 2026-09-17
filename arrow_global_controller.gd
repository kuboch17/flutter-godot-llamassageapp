@tool
class_name ArrowGlobalController
extends Node

@export_group("Animation")
@export_range(0.0, 2.0, 0.001) var speed := 0.13
## Ako dlho sa ruky plynulo presuvaju priamo z End naspat do Start.
@export_range(0.1, 2.0, 0.05) var hand_reset_duration := 0.45
@export var animate_in_editor := true

@export_group("Geometry")
@export_range(0.005, 0.2, 0.001) var arrow_length := 0.052
@export_range(0.005, 0.15, 0.001) var arrow_width := 0.055
@export_range(0.002, 0.08, 0.001) var shaft_width := 0.04
@export_range(0.0, 0.1, 0.001) var surface_offset := 0.0
@export_range(0.0, 0.05, 0.0005) var moving_arrow_lift := 0.0

@export_group("Colors")
@export var completed_arrow_color := Color(1.0, 1.0, 1.0, 0.2784314)
@export var remaining_arrow_color := Color.WHITE

var _last_signature := 0
var _configured_arrows: Dictionary = {}


func _ready() -> void:
	set_process(true)
	call_deferred("_apply_to_all_arrows")


func _process(_delta: float) -> void:
	var signature := _settings_signature()
	if signature != _last_signature:
		_last_signature = signature
		_configured_arrows.clear()
	_apply_to_all_arrows()


func _apply_to_all_arrows() -> void:
	if not is_inside_tree():
		return
	var root := get_parent()
	if root == null:
		return
	for child in root.find_children("*", "ArrowPathIndicator", true, false):
		var arrow := child as ArrowPathIndicator
		if arrow == null:
			continue
		var instance_id := arrow.get_instance_id()
		if _configured_arrows.has(instance_id):
			continue
		arrow.speed = speed
		arrow.hand_reset_duration = hand_reset_duration
		arrow.animate_in_editor = animate_in_editor
		arrow.arrow_length = arrow_length
		arrow.arrow_width = arrow_width
		arrow.shaft_width = shaft_width
		arrow.surface_offset = surface_offset
		arrow.moving_arrow_lift = moving_arrow_lift
		arrow.static_arrow_color = completed_arrow_color
		arrow.moving_arrow_color = remaining_arrow_color
		_configured_arrows[instance_id] = true


func _settings_signature() -> int:
	return hash([
		speed,
		hand_reset_duration,
		animate_in_editor,
		arrow_length,
		arrow_width,
		shaft_width,
		surface_offset,
		moving_arrow_lift,
		completed_arrow_color,
		remaining_arrow_color,
	])
