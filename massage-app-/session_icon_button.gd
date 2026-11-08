extends Button

# Complete button sprites extracted from the supplied Figma navigation SVG.
const BACK_TEXTURE := preload("res://assets/session/back.svg")
const SOUND_TEXTURE := preload("res://assets/session/sound.svg")
var icon_kind := "back"
var muted := false

func _draw() -> void:
	var texture: Texture2D = BACK_TEXTURE if icon_kind == "back" else SOUND_TEXTURE
	draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
	if muted:
		draw_line(size * 0.32, size * 0.68, Color.WHITE, maxf(size.x / 50.0, 1.0), true)
