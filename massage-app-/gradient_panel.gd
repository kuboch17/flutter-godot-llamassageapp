@tool
extends Control

@export var gradient_left: Color = Color(0.12, 0.48, 0.95, 1.0):
	set(value):
		gradient_left = value
		queue_redraw()

@export var gradient_right: Color = Color(0.0, 0.78, 0.92, 1.0):
	set(value):
		gradient_right = value
		queue_redraw()

func _draw() -> void:
	var steps: int = 48
	var step_width: float = size.x / float(steps)
	for index in range(steps):
		var amount: float = float(index) / float(steps - 1)
		var color: Color = gradient_left.lerp(gradient_right, amount)
		var rect := Rect2(Vector2(step_width * float(index), 0.0), Vector2(step_width + 1.0, size.y))
		draw_rect(rect, color)
