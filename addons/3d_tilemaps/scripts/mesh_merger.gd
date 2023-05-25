@tool
extends RefCounted
class_name MeshMerger

var temp_block: MapBlockUnit

func _init(_temp_block: MapBlockUnit) -> void:
	temp_block = _temp_block

func merge_meshes(parent: Node3D, blocks: Array[MapBlockUnit], mesh_path: String) -> void:
	if blocks.is_empty(): return
	
	var editor_tree := parent.get_tree().get_edited_scene_root()
	#var cord3 := parent.position / Vector3(temp_block.tile_size)
	
	var temp_mesh_ins := temp_block.get_node_or_null(mesh_path)
	if !temp_mesh_ins: return
	if !temp_mesh_ins.visible: return
	
	var mult_m_node_base := MultiMeshInstance3D.new()
	mult_m_node_base.layers = temp_mesh_ins.layers
	
	mult_m_node_base.material_override = temp_mesh_ins.material_override
	mult_m_node_base.material_overlay = temp_mesh_ins.material_overlay
	mult_m_node_base.transparency = temp_mesh_ins.transparency
	mult_m_node_base.cast_shadow = temp_mesh_ins.cast_shadow
	mult_m_node_base.extra_cull_margin = temp_mesh_ins.extra_cull_margin
	mult_m_node_base.custom_aabb = temp_mesh_ins.custom_aabb
	mult_m_node_base.lod_bias = temp_mesh_ins.lod_bias
	mult_m_node_base.ignore_occlusion_culling = temp_mesh_ins.ignore_occlusion_culling
	
	mult_m_node_base.gi_mode = temp_mesh_ins.gi_mode
	mult_m_node_base.gi_lightmap_scale = temp_mesh_ins.gi_lightmap_scale
	
	mult_m_node_base.visibility_range_begin = temp_mesh_ins.visibility_range_begin
	mult_m_node_base.visibility_range_begin_margin = temp_mesh_ins.visibility_range_begin_margin
	mult_m_node_base.visibility_range_end = temp_mesh_ins.visibility_range_end
	mult_m_node_base.visibility_range_end_margin = temp_mesh_ins.visibility_range_end_margin
	mult_m_node_base.visibility_range_fade_mode = temp_mesh_ins.visibility_range_fade_mode
	
	var meshes: Array[Mesh] = []
	var inst_by_mesh: Array[Array] = []
	for block in blocks:
		if !is_instance_valid(block): continue
		var mesh_ins: MeshInstance3D = block.get_node_or_null(mesh_path)
		if mesh_ins: mesh_ins.visible = false
		else: continue
		if !meshes.has(mesh_ins.mesh): 
			meshes.append(mesh_ins.mesh)
			inst_by_mesh.append([])
		var index: int = meshes.find(mesh_ins.mesh)
		inst_by_mesh[index].append(mesh_ins)
	
	for i in meshes.size():
		var mult_m: MultiMesh = MultiMesh.new()
		mult_m.transform_format = MultiMesh.TRANSFORM_3D
		mult_m.mesh = meshes[i]
		if mult_m.mesh.surface_get_material(0) == null:
			mult_m.mesh.surface_set_material(0, temp_mesh_ins.get_active_material(0))
		
		mult_m.instance_count = inst_by_mesh[i].size()
		for j in inst_by_mesh[i].size():
			var mesh_ins: MeshInstance3D = inst_by_mesh[i][j]
			var trans := Transform3D(
				mesh_ins.global_transform.basis,
				mesh_ins.global_position - parent.position
				)
			mult_m.set_instance_transform(j, trans)
		
		var mult_m_node := mult_m_node_base.duplicate()
		mult_m_node.multimesh = mult_m
		mult_m_node.name = str(mesh_path.replace("/", "-"),"Mesh-id:", i)
		parent.add_child(mult_m_node, true)
		mult_m_node.set_owner(editor_tree)
