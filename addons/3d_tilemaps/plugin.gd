@tool
extends EditorPlugin
class_name Tile3DPlugin

static var resource_previewer: EditorResourcePreview

func _ready() -> void:
	resource_previewer = get_editor_interface().get_resource_previewer()

static func get_preview(scene: PackedScene, reciver: Object):
	resource_previewer.queue_resource_preview(scene.resource_path, reciver, "set_preview_texture", {})
