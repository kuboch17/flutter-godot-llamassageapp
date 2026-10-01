extends SceneTree


func _initialize() -> void:
	var source := load("res://HandWithAnimation.fbx") as PackedScene
	if source == null:
		push_error("HandWithAnimation.fbx sa nepodarilo nacitat.")
		quit(1)
		return

	var hand_scene := source.instantiate()
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var append_error := document.append_from_scene(hand_scene, state)
	if append_error != OK:
		push_error("Konverzia sceny zlyhala: %s" % error_string(append_error))
		quit(2)
		return

	var write_error := document.write_to_filesystem(state, "res://HandWithAnimation.glb")
	if write_error != OK:
		push_error("Zapis GLB zlyhal: %s" % error_string(write_error))
		quit(3)
		return

	print("Vytvorene: res://HandWithAnimation.glb")
	quit()
