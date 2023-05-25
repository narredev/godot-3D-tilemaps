@tool
@icon("res://addons/3d_tilemaps/assets/icons/theme_icon.png")
extends Resource
class_name MapTheme

@export_group("Walls")
@export var wall_in: Array[Mesh]
@export var wall_out: Array[Mesh]
@export var no_wall_out: bool = false
@export var wall_in_out_same: bool = false
@export var scale_wall_out: bool = false

@export_group("Floor&Ceil")
@export var floor: Array[Mesh]
@export var ceil: Array[Mesh]
@export var open_ceil: bool = true

@export_group("Scene Collections")
@export var collections: Array[PackedScene]

var loaded_collections: Dictionary = {}

func validate_array(array: Array) -> bool:
	return !array.is_empty() && array[0]

func has_wall_in() -> bool:
	return validate_array(wall_in)

func has_wall_out() -> bool:
	return !no_wall_out && validate_array(wall_out)

func has_floor() -> bool:
	return validate_array(floor)

func has_ceil() -> bool:
	return validate_array(ceil)

func load_collections() -> void:
	loaded_collections = {}
	
	for packed_scene in collections:
		var scene: Node3D = packed_scene.instantiate()
		for child in scene.get_children():
			var split: Array = Array(child.name.split("_"))
			if split.size() < 2: continue
			var index := int(split.back()) - 1
			
			var data_name: StringName = split[0]
			if !loaded_collections.has(data_name): loaded_collections[data_name] = [] as Array[Node3D]
			if loaded_collections[data_name].size() <= index: 
				loaded_collections[data_name].resize(index)
			scene.remove_child(child)
			loaded_collections[data_name].insert(index, child)

func get_node_in_collection(col_name: StringName, index: int) -> Node3D:
	if loaded_collections.is_empty(): return null
	if !loaded_collections.has(col_name): return null
	if loaded_collections[col_name].size() < index: return null
	
	return loaded_collections[col_name][index].duplicate()
	
