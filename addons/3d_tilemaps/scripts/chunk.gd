@tool
@icon("res://addons/3d_tilemaps/assets/icons/chunk_icon.png")
extends Node3D
class_name Chunk

@export var cord3: Vector3i
@export var level: int
var rect: Rect2
var cells: Array[Vector2i] = []
var cells_local: Array[Vector2] = []
var blocks: Array[MapBlockUnit] = []

var temp_block: MapBlockUnit

func has_cord2(cord2: Vector2i) -> bool:
	return cells.has(cord2)

func has_cord2_local(cord2: Vector2i) -> bool:
	return cells_local.has(cord2)

func has_cord3(cord3: Vector3i) -> bool:
	return level == cord3.y && cells.has(Vector2i(cord3.x, cord3.z))
