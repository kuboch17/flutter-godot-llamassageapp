import bpy


SOURCE_PATH = r"C:\Users\alena\Documents\massage-app-\HandWithAnimation.glb"
OUTPUT_PATH = r"C:\Users\alena\Documents\massage-app-\HandWithAnimationSmooth.glb"
SUBDIVISION_LEVEL = 1


bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

bpy.ops.import_scene.gltf(filepath=SOURCE_PATH)

hand_meshes = [
    obj
    for obj in bpy.context.scene.objects
    if obj.type == "MESH" and "HandToMaya" in obj.name
]

if not hand_meshes:
    raise RuntimeError("V GLB sa nenasiel mesh ruky.")

for hand in hand_meshes:
    # Povodny FBX ma rovnake vrcholy duplikovane pre kazdu plochu.
    # Bez zvarenia by Catmull-Clark zmensoval kazdu plochu samostatne.
    bpy.context.view_layer.objects.active = hand
    hand.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.remove_doubles(threshold=0.00001, use_unselected=False)
    bpy.ops.object.mode_set(mode="OBJECT")

    for polygon in hand.data.polygons:
        polygon.use_smooth = True

    subdivision = hand.modifiers.new(name="Stylized subdivision", type="SUBSURF")
    subdivision.subdivision_type = "CATMULL_CLARK"
    subdivision.levels = SUBDIVISION_LEVEL
    subdivision.render_levels = SUBDIVISION_LEVEL

    # Subdivision musi byt pred Armature, aby sa nove vrcholy deformovali
    # povodnymi vahami kosti a animacia zostala funkcna.
    while hand.modifiers.find(subdivision.name) > 0:
        bpy.ops.object.modifier_move_up(modifier=subdivision.name)

    bpy.ops.object.modifier_apply(modifier=subdivision.name)
    hand.select_set(False)

bpy.ops.export_scene.gltf(
    filepath=OUTPUT_PATH,
    export_format="GLB",
    export_animations=True,
    export_skins=True,
    export_morph=True,
)

print(f"Vytvorene: {OUTPUT_PATH}")
