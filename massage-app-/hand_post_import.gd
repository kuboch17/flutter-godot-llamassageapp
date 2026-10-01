@tool
extends EditorScenePostImport

const HAND_MATERIAL := preload("res://mats/hand_stylized_material.tres")


func _post_import(scene: Node) -> Object:
	_apply_stylized_material(scene)
	return scene


func _apply_stylized_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		# Povodny skinned mesh, normaly, vahy kosti a animacie nechame bez zmeny.
		# Prebudovanie ArrayMesh sposobovalo, ze po importe zostal iba skeleton.
		mesh_instance.material_override = HAND_MATERIAL

	for child in node.get_children():
		_apply_stylized_material(child)
