@tool
@icon("res://addons/3d_tilemaps/assets/icons/scene_icon.png")
extends Node2D
class_name ScenePlacer

@export var p_scene: PackedScene:
	set(v):
		p_scene = v
		if !p_scene: scene_data = {}
		else:
			name = p_scene.instantiate().name
			request_preview()
		notify_property_list_changed()

var scene_props: Array[StringName] = []
var scene_data: Dictionary = {}
var scene_metadata: Dictionary = {}

const fall_tex := preload("res://addons/3d_tilemaps/assets/icons/scene_icon.png")
const marker := preload("res://addons/3d_tilemaps/assets/icons/marker.png")
var pre_tex: ImageTexture

func _enter_tree() -> void: 
	update_configuration_warnings()

func _exit_tree() -> void: remove_from_group("Tile3D")

func _ready() -> void: 
	set_notify_transform(true)
	request_preview()

func _get_property_list() -> Array:
	var p := PropertyList.new()
	p.add_prop("scene_props", TYPE_ARRAY).usage(PROPERTY_USAGE_STORAGE)
	p.add_prop("scene_data", TYPE_DICTIONARY).usage(PROPERTY_USAGE_STORAGE)
	p.add_prop("scene_metadata", TYPE_DICTIONARY).usage(PROPERTY_USAGE_STORAGE)
	
	p.add_category("Scene Properties")
	if p_scene:
		var _scene_instance := p_scene.instantiate()
		var _scene_props: Array[Dictionary] = PropertyList.get_node_clean_prop_list(_scene_instance)
		_scene_props = PropertyList.filther_editor_props(_scene_props)
		_scene_props = PropertyList.remove_obj_props(_scene_props, Node3D.new())
		_scene_props = PropertyList.remove_obj_props(_scene_props, StaticBody3D.new())
		_scene_props = PropertyList.remove_obj_props(_scene_props, CharacterBody3D.new())
		_scene_props = PropertyList.remove_obj_props(_scene_props, Area3D.new())
		
		scene_props.clear()
		for pr in _scene_props:
			pr.usage = pr.usage & ~PROPERTY_USAGE_STORAGE
			scene_props.append(pr.name)
		
		p.props.append_array(_scene_props)
	
	return p.props

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED: queue_redraw()
		NOTIFICATION_EDITOR_PRE_SAVE:
			#scene_metadata.clear()
			for meta_name in get_meta_list():
				scene_metadata[meta_name] = get_meta(meta_name)
		#NOTIFICATION_VISIBILITY_CHANGED: request_preview()

func _get_configuration_warnings() -> PackedStringArray:
	if !get_parent() is TileMap:
		return ["Must be parented to a Tilemap"]
	
	return []

func _set(prop: StringName, value) -> bool:
	#print(prop, ": ", value)
	if prop.begins_with("metadata"):
		var meta_prop := prop.split("_")[-1]
		if scene_props.has(meta_prop):
			scene_data[meta_prop] = value
			scene_metadata[prop.split("/")[-1]] = value
			return true
		return false
	
	if scene_props.has(prop):
		scene_data[prop] = value
		return true
	
	if scene_data.has(prop): scene_data.erase(prop)
	return false

func _get(prop: StringName):
	if prop.begins_with("metadata"):
		var meta_prop := prop.split("_")[-1]
		if scene_data.has(meta_prop):
			return scene_data[meta_prop]
		return null
	
	if !scene_data.has(prop): return null
	return scene_data[prop]

func _draw() -> void:
	var tex: Texture = pre_tex if pre_tex else fall_tex
	draw_set_transform_matrix(Transform2D(-global_rotation, Vector2()))
	draw_texture_rect(tex, Rect2(Vector2.ONE * -7, Vector2.ONE * 14), false)
	draw_set_transform(Vector2(), rotation)
	draw_texture_rect(marker, Rect2(Vector2.ONE * -3 + Vector2.DOWN * 5, Vector2.ONE * 6), false)

func request_preview() -> void:
	if !p_scene: return
	Tile3DPlugin.get_preview(p_scene, self)

func set_preview_texture(path: String, preview: Texture2D, thumbnail_preview: Texture2D, userdata) -> void:
	pre_tex = preview
	queue_redraw()

func transfer_data(node: Node) -> void:
	for key in scene_data:
		#print(key, ": ", scene_data[key])
		node.set(key, scene_data[key])
		for meta_prop in scene_metadata:
			node.set_meta(meta_prop, scene_metadata[meta_prop])

func queue_transfer_data(node: Node) -> void:
	node.name = name
	transfer_data.call_deferred(node)
