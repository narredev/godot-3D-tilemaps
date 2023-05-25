extends RefCounted
class_name TileDataHelper

func _get_tile_data(tm: TileMap, cord: Vector2i, layer: int = 0) -> TileData:
	if !layer < tm.get_layers_count() || layer < 0: return null
	
	var source_id := tm.get_cell_source_id(layer, cord, false)
	var atlas_cord := tm.get_cell_atlas_coords(layer, cord, false)
	var alt_id := tm.get_cell_alternative_tile(layer, cord, false)
	
	if source_id < 0: return null
	
	var source := tm.tile_set.get_source(source_id) as TileSetAtlasSource
	var tile_data := source.get_tile_data(atlas_cord, alt_id)
	
	return tile_data

func get_tile_custom(tm: TileMap, cord: Vector2i, prop: StringName, layer: int = 0):
	var td := tm.get_cell_tile_data(layer, cord)
	
	if td: return td.get_custom_data(prop)
	else: return null

#func get_tile_type(tm: TileMap, cord: Vector2i, layer: int = 0) -> int:
#	return get_tile_data(tm, cord, layer).get_custom_data("type")

func has_top(tiledata: TileData) -> bool:
	return (
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_SIDE) == -1 &&
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER) == -1 &&
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER) == -1
	)

func has_right(tiledata: TileData) -> bool:
	return (
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_RIGHT_SIDE) == -1 &&
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER) == -1 &&
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER) == -1
	)

func has_bottom(tiledata: TileData) -> bool:
	return (
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_SIDE) == -1 &&
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER) == -1 &&
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER) == -1
	)

func has_left(tiledata: TileData) -> bool:
	return (
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_LEFT_SIDE) == -1 &&
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER) == -1 &&
	tiledata.get_terrain_peering_bit(TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER) == -1
	)

func get_custom_data_layers(tileset: TileSet) -> Dictionary:
	var dict := {}
	for i in tileset.get_custom_data_layers_count():
		dict[tileset.get_custom_data_layer_name(i)] = tileset.get_custom_data_layer_type(i)
	
	return dict
