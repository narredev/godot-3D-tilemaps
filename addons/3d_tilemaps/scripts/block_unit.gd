@tool
@icon("res://addons/3d_tilemaps/assets/icons/block_icon.png")
extends Node3D
class_name MapBlockUnit

@export var tile_size: Vector3i = Vector3i.ONE

@export var cord: Vector3i

var TDH := TileDataHelper.new()

var map_theme: MapTheme

func load_theme(_map_theme: MapTheme) -> void:
	map_theme = _map_theme
	set_floor_mesh(1)
	set_ceil_mesh(1)
	set_wall_in_mesh(1)
	
	if map_theme.no_wall_out:
		get_wall_mesh_out(SIDE_TOP).visible = false
		get_wall_mesh_out(SIDE_RIGHT).visible = false
		get_wall_mesh_out(SIDE_BOTTOM).visible = false
		get_wall_mesh_out(SIDE_LEFT).visible = false
		return
	
	set_wall_out_mesh(1)
	
	if !map_theme.scale_wall_out:
		get_wall_mesh_out(SIDE_TOP).scale = Vector3.ONE
		get_wall_mesh_out(SIDE_RIGHT).scale = Vector3.ONE
		get_wall_mesh_out(SIDE_BOTTOM).scale = Vector3.ONE
		get_wall_mesh_out(SIDE_LEFT).scale = Vector3.ONE

func place(pos: Vector3i) -> void:
	cord = pos
	global_transform.origin = Vector3(cord * tile_size)

#if it has a neightboor, delete the wall
func place_auto(pos: Vector3i, front: bool, right: bool, back: bool, left: bool) -> void:
	place(pos)
	
	#vis_wall($WallFront, true, false, true)
	#vis_wall($WallRight, true, false, true)
	#vis_wall($WallBack, true, false, true)
	#vis_wall($WallLeft, true, false, true)
	
	if front: del_wall(SIDE_TOP)
	if right: del_wall(SIDE_RIGHT)
	if back: del_wall(SIDE_BOTTOM)
	if left: del_wall(SIDE_LEFT)

#convert the tiledata bits into walls
func conv_tiledata_terrain(tiledata: TileData) -> void:
	if !TDH.has_top(tiledata): del_wall(SIDE_TOP)
	if !TDH.has_right(tiledata): del_wall(SIDE_RIGHT)
	if !TDH.has_bottom(tiledata): del_wall(SIDE_BOTTOM)
	if !TDH.has_left(tiledata): del_wall(SIDE_LEFT)

#handle outside wall
func remove_walls_out(front: bool, right: bool, back: bool, left: bool) -> void:
	if front: del_wall(SIDE_TOP, false, true)
	if right: del_wall(SIDE_RIGHT, false, true)
	if back: del_wall(SIDE_BOTTOM, false, true)
	if left: del_wall(SIDE_LEFT, false, true)

func get_all_mesh_ins() -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in get_children(): for sub_child in child.get_children():
		if sub_child is MeshInstance3D:
			meshes.append(sub_child)
	
	return meshes

func get_floor() -> CollisionShape3D: 
	return get_node_or_null("Floor")

func get_floor_mesh_ins() -> MeshInstance3D:
	return get_node_or_null("Floor/FloorIn")

func disable_floor(to: bool = true) -> void:
	var flo := get_floor()
	if flo: flo.disabled = to

func del_floor() -> void:
	if get_floor(): get_floor().queue_free()

func set_floor_mesh(id: int) -> void:
	var floor_m := get_floor_mesh_ins()
	if !floor_m || !map_theme || !map_theme.has_floor(): return
	
	if id > 0: floor_m.mesh = map_theme.floor[id-1]
	elif id < 0: floor_m.mesh = map_theme.floor.pick_random()

#func del_floor_col() -> void:
#	if get_floor():
#		var mesh: MeshInstance3D = get_floor_mesh_ins()
#		if mesh != null && !mesh.is_queued_for_deletion():
#			get_floor().remove_child(mesh)
#
#			add_child(mesh)
#			mesh.set_owner(owner)
#			mesh.global_position = get_floor().global_position
#			#await get_tree().process_frame
#
#		get_floor().queue_free()
#		check_empty()
#
#func queue_del_floor_col() -> void:
#	del_queue.append(del_floor_col)

func get_ceil() -> MeshInstance3D:
	return get_node_or_null("Ceil")

func set_ceil_mesh(id: int) -> void:
	var ceil_m := get_ceil()
	if !ceil_m || !map_theme || !map_theme.has_ceil(): return
	
	if id > 0: ceil_m.mesh = map_theme.ceil[id-1]
	elif id < 0: ceil_m.mesh = map_theme.ceil.pick_random()

func has_any_wall() -> bool:
	return $WallFront || $WallRight || $WallBack || $WallLeft

func get_wall(side: Side) -> CollisionShape3D:
	match side:
		SIDE_TOP: return get_node_or_null("WallFront")
		SIDE_RIGHT: return get_node_or_null("WallRight")
		SIDE_BOTTOM: return get_node_or_null("WallBack")
		SIDE_LEFT: return get_node_or_null("WallLeft")
	
	return null

func get_wall_mesh_in(side: int) -> MeshInstance3D:
	if !get_wall(side): return null
	return get_wall(side).get_node_or_null("WallIn")

func get_wall_mesh_out(side: int) -> MeshInstance3D:
	if !get_wall(side): return null
	return get_wall(side).get_node_or_null("WallOut")

func disable_wall(side: int, to: bool = true) -> void:
	var wall := get_wall(side)
	if wall: wall.disabled = to

func del_wall(side: int, del_in: bool = true, del_out: bool = true) -> void:
	if del_in && del_out: get_wall(side).queue_free()
	else:
		if del_in: get_wall_mesh_in(side).queue_free()
		if del_out: get_wall_mesh_out(side).queue_free()

func del_all_walls(del_in: bool = true, del_out: bool = true) -> void:
	del_wall(SIDE_TOP, del_in, del_out)
	del_wall(SIDE_RIGHT, del_in, del_out)
	del_wall(SIDE_BOTTOM, del_in, del_out)
	del_wall(SIDE_LEFT, del_in, del_out)

func vis_wall(wall: Side, vis_in: bool = true, vis_out: bool = false, shadow: bool = false) -> void:
	get_wall_mesh_in(wall).visible = vis_in
	get_wall_mesh_out(wall).visible = vis_out
	get_wall(wall).get_node("Shadow").visible = shadow

func set_wall_in_mesh(id: int) -> void:
	if !map_theme || !map_theme.has_wall_in(): return
	var mesh: Mesh
	
	if id > 0: mesh = map_theme.wall_in[id-1]
	elif id < 0: mesh = map_theme.wall_in.pick_random()
	else: return
	
	var walls: Array[MeshInstance3D] = [
		get_wall_mesh_in(SIDE_TOP),
		get_wall_mesh_in(SIDE_RIGHT),
		get_wall_mesh_in(SIDE_BOTTOM),
		get_wall_mesh_in(SIDE_LEFT)
	]
	
	for wall in walls:
		if wall: wall.mesh = mesh

func set_wall_out_mesh(id: int) -> void:
	if !map_theme || !map_theme.has_wall_out(): return
	if id == 0: return
	var mesh: Mesh
	
	if map_theme.wall_in_out_same:
		if id > 0: mesh = map_theme.wall_in[id-1]
		elif id < 0: mesh = map_theme.wall_in.pick_random()
	else:
		if id > 0: mesh = map_theme.wall_out[id-1]
		elif id < 0: mesh = map_theme.wall_out.pick_random()
	
	var walls: Array[MeshInstance3D] = [
		get_wall_mesh_out(SIDE_TOP),
		get_wall_mesh_out(SIDE_RIGHT),
		get_wall_mesh_out(SIDE_BOTTOM),
		get_wall_mesh_out(SIDE_LEFT)
	]
	
	for wall in walls:
		if wall: wall.mesh = mesh

func check_empty() -> void:
	if get_child_count() == 0: queue_free()
	else:
		var counter: int = 0
		for child in get_children(): 
			if child.is_queued_for_deletion() || !is_instance_valid(child): counter += 1
		
		if counter >= get_child_count(): queue_free()

func clean_up() -> void:
	var force_free := func(node) -> bool: 
		if node is MeshInstance3D && !node.visible: 
			node.queue_free()
			return true
		elif node is CollisionShape3D && node.disabled: 
			node.queue_free()
			return true
		return false
	
	for child in get_children():
		var child_deleted := force_free.call(child)
		for subchild in child.get_children():
			var subchild_deleted := force_free.call(subchild)
			if !subchild_deleted && child_deleted:
				subchild.reparent(self)
				subchild.set_owner(owner)
	
	check_empty()
