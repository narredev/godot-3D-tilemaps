@tool
extends RefCounted
class_name ColMerger

var temp_block: MapBlockUnit

func _init(_temp_block: MapBlockUnit) -> void:
	temp_block = _temp_block

func block_call(blocks: Array[MapBlockUnit], call: StringName) -> void:
	for block in blocks:
		block.call(call)

func get_floor_col_rects(tm: TileMap, total_rect: Rect2, cells: Array[Vector2i]) -> Array[Rect2]:
	##remove no_floor cells
	for cell in cells.duplicate():
		for i in range( 1, tm.get_layers_count() ):
			var td := tm.get_cell_tile_data(i, cell)
			if td && td.get_custom_data("no_floor"):
				cells.erase(cell)
	
	var col_rects: Array[Rect2] = []
	var pos := total_rect.position
	for y in range(pos.y, pos.y + total_rect.size.y): 
		var a := Vector2.ONE * INF
		var new_rect := Rect2()
		for x in range(pos.x, pos.x + total_rect.size.x):
			if cells.has( Vector2i(x,y) ):
				#no floor, change
#				if !get_block(level, Vector2i(x,y)).get_floor():
#				##if TDH.get_tile_custom(tm, Vector2i(x,y), "no_floor", layer):
#					if a != Vector2.ONE * INF:
#						a = Vector2.ONE * INF
#						col_rects.append(Rect2(new_rect))
#					continue
				if a == Vector2.ONE * INF: #first match
					a = Vector2(x,y)
					new_rect = Rect2(a, Vector2.ONE)
				else: #can extend rect
					new_rect = new_rect.expand(Vector2(x+1,y))
			elif a != Vector2.ONE * INF: #no cell, save rect, reset
				col_rects.append(Rect2(new_rect))
				a = Vector2.ONE * INF
		if a != Vector2.ONE * INF: #save last valid rect
			col_rects.append(Rect2(new_rect))
	
	var used_rects: Array[int] = []
	var merged_rects: Array[Rect2] = []
	for rect_a in col_rects:
		#ignore already checked rects
		var a_i: int = col_rects.find(rect_a)
		if used_rects.has(a_i): continue
		
		var merged: Rect2 = Rect2(rect_a)
		used_rects.append(a_i)
		for rect_b in col_rects:
			#ignore already checked rects
			var b_i: int = col_rects.find(rect_b)
			if used_rects.has(b_i): continue
			
			#merge rects with same size, same x pos and compatible end
			if merged.size.x == rect_b.size.x:
				if merged.position.x == rect_b.position.x:
					if merged.end + Vector2.DOWN == rect_b.end:
						merged = merged.expand(rect_b.end)
						used_rects.append(b_i)
		
		merged_rects.append(merged)
	
	return merged_rects

func merge_floor_cols(parent: Node3D, floor_rects: Array[Rect2], blocks := []) -> StaticBody3D:
	var tile_size := temp_block.tile_size
	var base_shape: BoxShape3D = temp_block.get_floor().shape
	
	var body := StaticBody3D.new()
	body.name = "FloorMergedBody"
	parent.add_child(body, true)
	body.owner = parent.get_tree().get_edited_scene_root()
	body.add_to_group("navmesh", true)
	
	for new_rect in floor_rects:
		var shape := BoxShape3D.new()
		shape.size = Vector3(
			new_rect.size.x * tile_size.x, 
			base_shape.size.y, 
			new_rect.size.y * tile_size.z)
		
		var col := CollisionShape3D.new()
		col.shape = shape
		col.name = "ColShapeRow1"
		
		body.add_child(col, true)
		col.owner = body.owner
		
		var rect_pos := new_rect.get_center()
		col.global_position = Vector3(
			rect_pos.x * tile_size.x - tile_size.x * 0.5,
			0, 
			rect_pos.y * tile_size.z - tile_size.z * 0.5 )
		col.position.y = 0
	
	for b_unit in blocks: b_unit.disable_floor()
	
	return body

func get_wall_col_rects(tm: TileMap, total_rect: Rect2, cells: Array[Vector2i]) -> Dictionary:
	var pos := total_rect.position
	
	var front_walls_rects: Array[Rect2] = []
	var back_walls_rects: Array[Rect2] = []
	
	var TDH := TileDataHelper.new()
	
	for y in range(pos.y, pos.y + total_rect.size.y): 
		var front_a := Vector2.ONE * INF
		var front_rect := Rect2()
		var back_a := Vector2.ONE * INF
		var back_rect := Rect2()
		
		for x in range(pos.x, pos.x + total_rect.size.x):
			var cord2 := Vector2i(x,y)
			if cells.has( cord2 ):
				var td := tm.get_cell_tile_data(0, cord2)
				
				if TDH.has_top(td):
					if front_a == Vector2.ONE * INF:
						front_a = cord2
						front_rect = Rect2(front_a, Vector2.ONE)
					else:
						front_rect = front_rect.expand(Vector2(x+1,y))
				elif front_a != Vector2.ONE * INF:
					front_walls_rects.append(Rect2(front_rect))
					front_a = Vector2.ONE * INF
				
				if TDH.has_bottom(td):
					if back_a == Vector2.ONE * INF:
						back_a = cord2
						back_rect = Rect2(back_a, Vector2.ONE)
					else:
						back_rect = back_rect.expand(Vector2(x+1,y))
				elif back_a != Vector2.ONE * INF:
					back_walls_rects.append(Rect2(back_rect))
					back_a = Vector2.ONE * INF
			else:
				if front_a != Vector2.ONE * INF:
					front_walls_rects.append(Rect2(front_rect))
					front_a = Vector2.ONE * INF
				if back_a != Vector2.ONE * INF:
					back_walls_rects.append(Rect2(back_rect))
					back_a = Vector2.ONE * INF
		
		if front_a != Vector2.ONE * INF: front_walls_rects.append(Rect2(front_rect))
		if back_a != Vector2.ONE * INF: back_walls_rects.append(Rect2(back_rect))
	
	var left_walls_rects: Array[Rect2] = []
	var right_walls_rects: Array[Rect2] = []
	
	for x in range(pos.x, pos.x + total_rect.size.x): 
		var left_a := Vector2.ONE * INF
		var left_rect := Rect2()
		var right_a := Vector2.ONE * INF
		var right_rect := Rect2()
		
		for y in range(pos.y, pos.y + total_rect.size.y):
			var cord2 := Vector2i(x,y)
			if cells.has( cord2 ):
				var td := tm.get_cell_tile_data(0, cord2)
				
				if TDH.has_left(td):
					if left_a == Vector2.ONE * INF:
						left_a = cord2
						left_rect = Rect2(left_a, Vector2.ONE)
					else:
						left_rect = left_rect.expand(Vector2(x,y+1))
				elif left_a != Vector2.ONE * INF:
					left_walls_rects.append(Rect2(left_rect))
					left_a = Vector2.ONE * INF
				
				if TDH.has_right(td):
					if right_a == Vector2.ONE * INF:
						right_a = cord2
						right_rect = Rect2(right_a, Vector2.ONE)
					else:
						right_rect = right_rect.expand(Vector2(x,y+1))
				elif right_a != Vector2.ONE * INF:
					right_walls_rects.append(Rect2(right_rect))
					right_a = Vector2.ONE * INF
				
			else:
				if left_a != Vector2.ONE * INF:
					left_walls_rects.append(Rect2(left_rect))
					left_a = Vector2.ONE * INF
				if right_a != Vector2.ONE * INF:
					right_walls_rects.append(Rect2(right_rect))
					right_a = Vector2.ONE * INF
		
		if left_a != Vector2.ONE * INF: left_walls_rects.append(Rect2(left_rect))
		if right_a != Vector2.ONE * INF: right_walls_rects.append(Rect2(right_rect))
	
	return {
		"front": front_walls_rects, "back": back_walls_rects, 
		"left": left_walls_rects, "right": right_walls_rects
		}

func merge_walls_col(parent: Node3D, col_rects: Dictionary, blocks := []) -> StaticBody3D:
	var base_shape: BoxShape3D = temp_block.get_wall(SIDE_TOP).shape
	var depth: float = base_shape.size.z
	var height_size: float = base_shape.size.y
	
	var tile_size := temp_block.tile_size
	var body := StaticBody3D.new()
	body.name = "WallsMergedBody"
	parent.add_child(body, true)
	body.owner = parent.get_tree().get_edited_scene_root()
	body.add_to_group("navmesh", true)
		
	for front_rect in col_rects.front:
		var shape := BoxShape3D.new()
		shape.size = Vector3((front_rect.size.x) * tile_size.x, height_size, depth)
		
		var col := CollisionShape3D.new()
		col.shape = shape
		col.name = "WallFrontColShape"
		
		body.add_child(col, true)
		col.owner = body.owner
		
		var temp_wall := temp_block.get_wall(SIDE_TOP)
		var rect_pos: Vector2 = front_rect.get_center()
		col.global_position = Vector3(rect_pos.x, 0, rect_pos.y) * Vector3(tile_size)
		col.position.y = 0
		col.global_position += temp_wall.position
		col.global_position.x -= tile_size.x * 0.5
		col.global_position.z -= tile_size.z * 0.5
	
	for back_rect in col_rects.back:
		var shape := BoxShape3D.new()
		shape.size = Vector3((back_rect.size.x) * tile_size.x, height_size, depth)
		
		var col := CollisionShape3D.new()
		col.shape = shape
		col.name = "WallBackColShape"
		
		body.add_child(col, true)
		col.owner = body.owner
		
		var temp_wall := temp_block.get_wall(SIDE_BOTTOM)
		var rect_pos: Vector2 = back_rect.get_center()
		col.global_position = Vector3(rect_pos.x, 0, rect_pos.y) * Vector3(tile_size)
		col.position.y = 0
		col.global_position += temp_wall.position
		col.global_position.x -= tile_size.x * 0.5
		col.global_position.z -= tile_size.z * 0.5
	
	for left_rect in col_rects.left:
		var shape := BoxShape3D.new()
		shape.size = Vector3(depth, height_size, (left_rect.size.y) * tile_size.z)
		
		var col := CollisionShape3D.new()
		col.shape = shape
		col.name = "WallLeftColShape"
		
		body.add_child(col, true)
		col.owner = body.owner
		
		var temp_wall := temp_block.get_wall(SIDE_LEFT)
		var rect_pos: Vector2 = left_rect.get_center()
		col.global_position = Vector3(rect_pos.x, 0, rect_pos.y) * Vector3(tile_size)
		col.position.y = 0
		col.global_position += temp_wall.position
		col.global_position.x -= tile_size.x * 0.5
		col.global_position.z -= tile_size.z * 0.5
	
	for right_rect in col_rects.right:
		var shape := BoxShape3D.new()
		shape.size = Vector3(depth, height_size, (right_rect.size.y) * tile_size.z)
		
		var col := CollisionShape3D.new()
		col.shape = shape
		col.name = "WallRightColShape"
		
		body.add_child(col)
		col.owner = body.owner
		
		var temp_wall := temp_block.get_wall(SIDE_RIGHT)
		var rect_pos: Vector2 = right_rect.get_center()
		col.global_position = Vector3(rect_pos.x, 0, rect_pos.y) * Vector3(tile_size)
		col.position.y = 0
		col.global_position += temp_wall.position
		col.global_position.x -= tile_size.x * 0.5
		col.global_position.z -= tile_size.z * 0.5
		
	for block in blocks:
		block.disable_wall(SIDE_TOP)
		block.disable_wall(SIDE_BOTTOM)
		block.disable_wall(SIDE_LEFT)
		block.disable_wall(SIDE_RIGHT)
	
	return body
