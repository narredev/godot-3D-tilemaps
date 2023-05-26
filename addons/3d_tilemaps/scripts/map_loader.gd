@tool
@icon("res://addons/3d_tilemaps/assets/icons/map_icon.png")
extends Node3D
class_name MapLoader

enum MERGE_OPT {NONE, CHUNK, ALL}

var TDH := TileDataHelper.new()

signal map_loaded
signal map_cleared

@export_file("*.tscn") var map_file: String = ""

@export var block_packed: PackedScene = preload("res://addons/3d_tilemaps/assets/BlockTall.tscn")
@export var map_theme: MapTheme
#@export var tile_size: Vector3 = Vector3.ONE

@export var _load_map: bool = false:
	set(v): 
		_load_map = false
		if !Engine.is_editor_hint(): return
		if v:
			if get_child_count() > 0:
				clear()
				await get_tree().create_timer(0.1).timeout
			else:
				clear()
			load_map()

@export var _clear_map: bool = false:
	set(v):
		_clear_map = false
		if !Engine.is_editor_hint(): return
		if v: clear()

@export_range(2, 999) var chunk_size: int = 6
@export var merge_floor_mesh: MERGE_OPT = MERGE_OPT.CHUNK
@export var merge_floor_col: MERGE_OPT = MERGE_OPT.ALL
@export var merge_walls_mesh: MERGE_OPT = MERGE_OPT.CHUNK
@export var merge_walls_col: MERGE_OPT = MERGE_OPT.ALL

var block_loaded: MapBlockUnit

var tilemap_scene: Node2D
var map_levels: Array[TileMap] = []

var map_cords: Array[Vector3i]
var map_blocks: Dictionary = {}

func find_block(level: int, cord: Vector2i) -> MapBlockUnit:
	var cord3 := Vector3i(cord.x, level, cord.y)
	for child in get_children():
		if child is MapBlockUnit && child.cord == cord3: 
			return child
	
	return null

func get_block(level: int, cord: Vector2i) -> MapBlockUnit:
	var cord3 := Vector3i(cord.x, level, cord.y)
	if map_blocks.is_empty() || !map_blocks.has(cord3): return null
	
	return map_blocks[cord3]

func get_new_block() -> MapBlockUnit:
	if !block_loaded: 
		block_loaded = block_packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
		if map_theme: block_loaded.load_theme(map_theme)
	return block_loaded.duplicate()

func clear() -> void:
	for child in get_children():
		child.queue_free()
	if block_loaded: block_loaded.queue_free()
	block_loaded = null
	await get_tree().process_frame
	map_cleared.emit()

func load_map() -> void:
	##load map
	if map_file.is_empty(): return
	var packed_scene: PackedScene = load(map_file)
	if map_file == null: return
	tilemap_scene = packed_scene.instantiate()
	
	if get_tree() == null:
		await ready
	var editor_tree := get_tree().get_edited_scene_root()
	
	##load levels
	map_levels = []
	for child in tilemap_scene.get_children():
		if child is TileMap:
			map_levels.append(child)
	
	if map_levels.is_empty(): return
	
	block_loaded = get_new_block()
	if map_theme: map_theme.load_collections()
	await get_tree().process_frame
	
	print("Placing Blocks")
	for level_i in map_levels.size():
		var tm: TileMap = map_levels[level_i]
		var level_tiles: Array[Vector2i] = tm.get_used_cells(0)
		var data_layers := TDH.get_custom_data_layers(tm.tile_set)
		for cord2 in level_tiles:
			var cord3: Vector3i = Vector3i(cord2.x, level_i, cord2.y)
			
			#var neightbors: Array[Vector2i] = tile_map.get_surrounding_tiles(cord)
			var chk := func(dir: Vector2i) -> bool: 
				return level_tiles.has(cord2+dir)
			
			var neigh: Array[bool] = [
				chk.call(Vector2i.UP), 
				chk.call(Vector2i.RIGHT), 
				chk.call(Vector2i.DOWN), 
				chk.call(Vector2i.LEFT)]
			
			var above: bool = false
			if level_i + 1 < map_levels.size():
				var tm_up := map_levels[level_i+1]
				above = tm_up.get_used_cells(0).has(cord2)
#				if above: 
#					##change
#					var tdc = TDH.get_tile_custom(tm_up, cord2, "no_floor", 1)
#					if tdc != null: above = !tdc
			
			var below: bool = false
			if level_i - 1 >= 0:
				below = map_levels[level_i-1].get_used_cells(0).has(cord2)
			
			var block_unit: MapBlockUnit = get_new_block()
			
			block_unit.name = str(block_unit.name, cord3)
			add_child(block_unit, true)
			block_unit.scene_file_path = ""
			block_unit.set_owner(editor_tree)
			#block_unit.set_meta("_edit_lock_", true)
			block_unit.set_meta("_edit_group_", true)
			
			for child in block_unit.get_children(): 
				child.set_owner(editor_tree)
				for sub_child in child.get_children():
					sub_child.set_owner(editor_tree)
			
			if TDH.get_tile_custom(tm, cord2, "auto"):
				block_unit.place_auto(cord3, neigh[0], neigh[1], neigh[2], neigh[3])
			else:
				block_unit.place(cord3)
				var td := tm.get_cell_tile_data(0, cord2)
				block_unit.conv_tiledata_terrain(td)
			
			if !above && map_theme.open_ceil: block_unit.get_ceil().queue_free()
			
			block_unit.remove_walls_out(neigh[0], neigh[1], neigh[2], neigh[3])
			
			randomize()
			
			##set custom data layers
			##Missing: progagate wall id
			for layer in range(1, tm.get_layers_count()):
				var td: TileData = tm.get_cell_tile_data(layer, cord2)
				if !td: continue
				
				if td.get_custom_data("no_floor"): block_unit.del_floor()
				if !map_theme: continue
				block_unit.map_theme = map_theme
				block_unit.set_floor_mesh(td.get_custom_data("floor_id"))
				block_unit.set_wall_in_mesh(td.get_custom_data("wall_id"))
				block_unit.set_wall_out_mesh(td.get_custom_data("wall_id"))
				
				for i in data_layers.size():
					if i < 5: continue
					if data_layers.values()[i] != TYPE_INT: continue
					var col_name: StringName = data_layers.keys()[i]
					var index: int = td.get_custom_data(col_name)
					if index <= 0: continue
					
					var node := map_theme.get_node_in_collection(col_name, index-1)
					var y_offset: float = node.position.y
					add_child(node, true)
					node.set_owner(editor_tree)
					node.global_position = Vector3(cord3 * block_unit.tile_size)
					node.global_position.y += y_offset
			
			map_blocks[cord3] = block_unit
			map_cords.append(cord3)
		
		##add custom scenes
		for child in tm.get_children():
			if child is ScenePlacer:
				if !child.p_scene: continue
				var cord2 := tm.local_to_map(child.position)
				var cord3 := Vector3i(cord2.x, level_i, cord2.y)
				
				var node: Node3D = child.p_scene.instantiate()
				var y_offset: float = node.position.y
				add_child(node, true)
				node.set_owner(editor_tree)
				node.global_position = Vector3(cord3 * block_loaded.tile_size)
				node.global_position.y += y_offset
				node.rotation.y = child.rotation * -2
				node.visible = child.visible
				
				child.queue_transfer_data(node)
	
	await get_tree().process_frame
	var chunks_levels: Array[Array] = make_chunks_levels()
	
	#OPTIMIZE MESHES
	await get_tree().process_frame
	merge_meshes(chunks_levels)
	
	#OPTIMIZE COLLIDERS
	await get_tree().process_frame
	merge_colliders(chunks_levels)
	
	#DO NOT REMOVE
	await get_tree().process_frame
	await get_tree().process_frame
	map_blocks = {}
	for child in get_children(): if child is MapBlockUnit: child.clean_up()
	
	await get_tree().process_frame
	map_loaded.emit()
	
	for child in get_children(): child.set_display_folded(true)
	set_display_folded(true)

func merge_meshes(chunks_levels: Array[Array]):
	var mesh_merger := MeshMerger.new(get_new_block())
	
	if merge_floor_mesh == MERGE_OPT.ALL: 
		print("Merge all Floor && Ceil Mesh")
		mesh_merger.merge_meshes(self, map_blocks.values(), "Floor/FloorIn")
		mesh_merger.merge_meshes(self, map_blocks.values(), "Floor/Shadow")
		mesh_merger.merge_meshes(self, map_blocks.values(), "Ceil")
	elif merge_floor_mesh == MERGE_OPT.CHUNK: 
		print("Merge Floor && Ceil Mesh by chunks")
		for level_chunks in chunks_levels: for chunk in level_chunks:
			mesh_merger.merge_meshes(chunk, chunk.blocks, "Floor/FloorIn")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "Floor/Shadow")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "Ceil")
	
	if merge_walls_mesh == MERGE_OPT.ALL:
		print("Merge all Wall Mesh")
		
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallFront/WallIn")
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallFront/WallOut")
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallFront/Shadow")
		
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallBack/WallIn")
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallBack/WallOut")
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallBack/Shadow")
		
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallLeft/WallIn")
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallLeft/WallOut")
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallLeft/Shadow")
		
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallRight/WallIn")
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallRight/WallOut")
		mesh_merger.merge_meshes(self, map_blocks.values(), "WallRight/Shadow")
		
	elif merge_walls_mesh == MERGE_OPT.CHUNK:
		print("Merge Walls Mesh by chunks")
		for level_chunks in chunks_levels: for chunk in level_chunks:
			#chunk.temp_block = get_new_block()
			
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallFront/WallIn")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallFront/WallOut")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallFront/Shadow")
			
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallBack/WallIn")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallBack/WallOut")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallBack/Shadow")
			
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallLeft/WallIn")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallLeft/WallOut")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallLeft/Shadow")
			
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallRight/WallIn")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallRight/WallOut")
			mesh_merger.merge_meshes(chunk, chunk.blocks, "WallRight/Shadow")

func merge_colliders(chunks_levels: Array[Array]):
	var col_merger := ColMerger.new(get_new_block())
	var tile_size := get_new_block().tile_size
	
	if merge_floor_col == MERGE_OPT.ALL:
		print("Merge all Floor Colliders")
		for level in map_levels.size():
			var tm := map_levels[level]
			var cells := tm.get_used_cells(0)
			var rects: Array[Rect2] = col_merger.get_floor_col_rects(tm, tm.get_used_rect(), cells)
			
			col_merger.merge_floor_cols(self, rects, map_blocks.values()).global_position.y = level * tile_size.y
	elif merge_floor_col == MERGE_OPT.CHUNK:
		print("Merge Floor Colliders by chunks")
		for level_chunks in chunks_levels: for chunk in level_chunks:
			var rects := col_merger.get_floor_col_rects(map_levels[chunk.level], chunk.rect, chunk.cells)
			col_merger.merge_floor_cols(chunk, rects, chunk.blocks)
			#chunk.merge_floor_cols(rects)
	
	print_rich("[color=orange]auto type tiles don't support merging walls cols yet [/color]")
	if merge_walls_col == MERGE_OPT.ALL:
		print("Merge all Walls Colliders")
		for level in map_levels.size():
			var tm := map_levels[level]
			var cells := tm.get_used_cells(0)
			var rects := col_merger.get_wall_col_rects(tm, tm.get_used_rect(), cells)
			col_merger.merge_walls_col(self, rects, map_blocks.values()).global_position.y = level * tile_size.y
	elif merge_walls_col == MERGE_OPT.CHUNK:
		print("Merge Walls Colliders by chunks")
		for level_chunks in chunks_levels: for chunk in level_chunks:
			var rects := col_merger.get_wall_col_rects(map_levels[chunk.level], chunk.rect, chunk.cells)
			col_merger.merge_walls_col(chunk, rects, chunk.blocks)

func make_chunks(tm: TileMap, level: int, layer: int = 0) -> Array[Chunk]:
	if chunk_size < 2: 
		print("Chunk size must be greater than 1")
		return []
	var editor_tree := get_tree().get_edited_scene_root()
	var rect := tm.get_used_rect()
	
	var x_chunks: int = ceil(float(rect.size.x) / chunk_size)
	var y_chunks: int = ceil(float(rect.size.y) / chunk_size)
	
	var chunks: Array[Chunk] = []
	for x in x_chunks: for y in y_chunks:
		var chunk_v := Vector2(x * chunk_size, y * chunk_size)
		var new_chunk: Chunk = Chunk.new()
		new_chunk.rect = Rect2(rect.position + Vector2i(chunk_v), Vector2(chunk_size, chunk_size))
		new_chunk.level = level
		var center := new_chunk.rect.get_center()
		new_chunk.cord3 = Vector3(center.x, level, center.y)
		
		chunks.append(new_chunk)
	
	var used_cells := tm.get_used_cells(layer)
	
	#print("layer ", layer, " cells: ", used_cells.size())
	for cord2 in used_cells: 
		for chunk in chunks:
			if chunk.rect.has_point(cord2): 
				chunk.cells.append(cord2)
				chunk.cells_local.append(Vector2(cord2) - chunk.rect.position)
				var block: MapBlockUnit = get_block(level, cord2)
				if block && !block.is_queued_for_deletion(): chunk.blocks.append(block)
	
	for chunk in chunks:
		if chunk.blocks.is_empty(): continue
		var center := chunk.rect.get_center()
		chunk.name = str("Chunk [",center.x,", ",level,", ",center.y,"]")
		add_child(chunk)
		chunk.set_owner(editor_tree)
		chunk.global_position = Vector3(chunk.cord3) * Vector3(get_new_block().tile_size)
	
	return chunks

func make_chunks_levels(map := map_levels) -> Array[Array]:
	var chunk_levels: Array[Array] = []
	for level in map.size():
		chunk_levels.append( make_chunks(map[level], level) )
	
	return chunk_levels
