extends MeshInstance3D

@export var spin_speed := Vector3(0.0, 1.2, 0.0)

func _process(delta: float) -> void:
	rotation += spin_speed * delta
