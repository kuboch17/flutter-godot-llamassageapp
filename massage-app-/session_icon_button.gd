extends Button

var icon_kind := "back"
var muted := false

func _draw() -> void:
	var factor := size.x / 55.0
	var ink := Color.WHITE
	var stroke := 1.15 * factor
	if icon_kind == "back":
		draw_polyline(PackedVector2Array([
			Vector2(31, 20) * factor,
			Vector2(24, 27.5) * factor,
			Vector2(31, 35) * factor,
		]), ink, stroke, true)
	else:
		draw_polyline(PackedVector2Array([
			Vector2(17.5, 24) * factor,
			Vector2(22, 24) * factor,
			Vector2(27, 19) * factor,
			Vector2(27, 36) * factor,
			Vector2(22, 31) * factor,
			Vector2(17.5, 31) * factor,
			Vector2(17.5, 24) * factor,
		]), ink, stroke, true)
		if muted:
			draw_line(Vector2(16, 17) * factor, Vector2(38, 38) * factor, ink, stroke, true)
		else:
			for radius in [8.0, 12.0]:
				draw_arc(Vector2(27, 27.5) * factor, radius * factor, -0.8, 0.8, 24, ink, stroke, true)

