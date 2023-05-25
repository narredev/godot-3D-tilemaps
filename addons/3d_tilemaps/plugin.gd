@tool
extends EditorPlugin
class_name Tile3DPlugin

var resource_previewer: EditorResourcePreview

func _enter_tree() -> void: propagate()

func _ready() -> void:
	name = "Tile3DPlugin"
	resource_previewer = get_editor_interface().get_resource_previewer()
	propagate()

func _save_external_data() -> void: propagate()

#Replace with static variable when implemented
func _handles(object: Object) -> bool:
	if object is Node:
		if object == get_editor_interface().get_edited_scene_root(): return true
		elif object.is_in_group("Tile3D"): return true
	return false

func _edit(object: Object) -> void: propagate()

func propagate() -> void: get_tree().call_group("Tile3D", "set", "plugin", self)

func get_preview(scene: PackedScene, reciver: Object):
	resource_previewer.queue_resource_preview(scene.resource_path, reciver, "set_preview_texture", {})
