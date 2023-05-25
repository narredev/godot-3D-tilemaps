extends RefCounted
class_name PropertyList
#Helper class to simplify advanced script export

var props: Array[Dictionary] = []

class MethodBind:
	var dict: Dictionary
	
	func _init(edit: Dictionary) -> void:
		dict = edit
	
	func usage(p_usage: int) -> MethodBind:
		dict["usage"] = p_usage
		return MethodBind.new(dict)
		
	func hint(p_hint: PropertyHint, p_hint_string: String = "") -> MethodBind:
		dict["hint"] = p_hint
		dict["hint_string"] = p_hint_string
		return MethodBind.new(dict)

func _init():
	props = []

static func get_type_str(type: int) -> String:
	match type:
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "string"
	return ""

#Only returns user defined properties.
static func get_clean_prop_list(instance: Object) -> Array[Dictionary]:
	var clean_props: Array[Dictionary] = []
	for p_dict in instance.get_property_list(): 
		var exclude: bool = false
		match p_dict.name:
			"Reference", "reference", "script", "Script Variables", "Script", "Resource", "resource":
				exclude = true
			"resource_path", "resource_name", "resource_local_to_scene", "RefCounted": 
				exclude = true
		if exclude: continue
		else: clean_props.push_back(p_dict)
	
	return clean_props

static func get_node_clean_prop_list(instance: Object) -> Array[Dictionary]:
	var clean_props: Array[Dictionary] = []
	for p_dict in get_clean_prop_list(instance): 
		var exclude: bool = false
		match p_dict.name:
			"_import_path", "name", "unique_name_in_owner", "scene_file_path", "owner", "multiplayer":
				exclude = true
			"Process", "process_mode", "process_priority", "Editor Description", "editor_description":
				exclude = true
		if exclude: continue
		else: clean_props.push_back(p_dict)
	
	return clean_props

static func filther_editor_props(_props: Array[Dictionary]) -> Array[Dictionary]:
	var new_props: Array[Dictionary] = []
	for prop in _props: if prop.usage & PROPERTY_USAGE_EDITOR != 0: new_props.append(prop)
	return new_props

static func remove_obj_props(_props: Array[Dictionary], obj: Object) -> Array[Dictionary]:
	var new_props: Array[Dictionary] = []
	var obj_pros := obj.get_property_list()
	
	var obj_props_names: Array[StringName] = []
	for p in obj_pros: obj_props_names.append(p.name)
	
	for i in _props.size():
		if !obj_props_names.has(_props[i].name):
			new_props.append(_props[i])
	
	return new_props

func add_group(p_name: String, gru_hint_string: String = "") -> void:
	props.push_back({
		name = p_name,
		type = TYPE_NIL,
		hint = PROPERTY_HINT_NONE,
		hint_string = gru_hint_string,
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE,
		}
	)

func add_category(p_name: String, cat_hint_string: String = "") -> void:
	props.push_back({
		name = p_name,
		type = TYPE_NIL,
		hint = PROPERTY_HINT_NONE,
		hint_string = cat_hint_string,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE,
	})

func add_prop(p_name: String, p_type: int, p_hint: PropertyHint = PROPERTY_HINT_NONE, p_hint_string: String = "", p_usage: int = PROPERTY_USAGE_DEFAULT) -> MethodBind:
	#if p_hint == PROPERTY_HINT_NONE && p_hint_string == "":
	#	p_hint_string = get_type_str(p_type)
	
	props.push_back({
		name = p_name,
		type = p_type,
		#value = p_value,
		hint = p_hint,
		hint_string = p_hint_string, 
		usage = p_usage | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	return MethodBind.new(props.back())

#auto checks the type
func auto_prop(ins: Object, p_name: String) -> MethodBind:
	props.push_back({
		name = p_name,
		type = typeof(ins.get(p_name)),
		hint = PROPERTY_HINT_NONE,
		hint_string = "", 
		usage = PROPERTY_USAGE_DEFAULT + PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	return MethodBind.new(props.back())

func add_prop_enum(p_name: String, r_enum: Dictionary, p_type: int = TYPE_INT) -> MethodBind:
	var p_hint_string: String = ""
	for r in r_enum:
		p_hint_string += r+","
	p_hint_string[p_hint_string.length()-1] = ""
	
	props.push_back({
		name = p_name,
		type = p_type,
		#value = 0 if p_type == TYPE_INT else "",
		hint = PROPERTY_HINT_ENUM,
		hint_string = p_hint_string, 
		usage = PROPERTY_USAGE_DEFAULT
	})
	
	return MethodBind.new(props.back())

#v_type is the array[type]
func add_array(p_name: String, v_type: int = -1, v_hint:int = 0, v_hint_string: String = "", p_usage: int = PROPERTY_USAGE_DEFAULT):
	var hint_str: String = ""
	if v_type > -1: 
		hint_str += str(v_type)
		hint_str += str("/", v_hint)
		#if !v_hint_string.empty():
		hint_str+=str(":", v_hint_string)
	
	props.push_back({
		name = p_name,
		type = TYPE_ARRAY,
		#value = [],
		hint = PROPERTY_HINT_TYPE_STRING,
		hint_string = hint_str, 
		usage = p_usage | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	return MethodBind.new(props.back())

func add_array_arg(p_name: String, args: Array, p_usage: int = PROPERTY_USAGE_DEFAULT):
	var hint_str: String = ""
	for i in args.size():
		if i == args.size() -1: hint_str += ":"
		
		hint_str+= str(args[i])
		
		if typeof(args[i]) == TYPE_INT && args[i] == TYPE_ARRAY: hint_str += ":"
		elif i != args.size()-1: hint_str += "/"
	
	props.push_back({
		name = p_name,
		type = TYPE_ARRAY,
		#value = [],
		hint = PROPERTY_HINT_TYPE_STRING,
		hint_string = hint_str, 
		usage = p_usage
	})
	
	return MethodBind.new(props.back())

func add_node_path(p_name: String, valid_type: String = "", p_usage = PROPERTY_USAGE_DEFAULT):
	var hint: int = PROPERTY_HINT_NONE
	if !valid_type.is_empty(): hint = PROPERTY_HINT_NODE_PATH_VALID_TYPES
	
	props.push_back({
		name = p_name,
		type = TYPE_NODE_PATH,
		value = NodePath(""),
		hint = hint,
		hint_string = valid_type, 
		usage = p_usage | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	return MethodBind.new(props.back())

func add_res(p_name: String, res_type: String = "Resource") -> MethodBind:
	add_prop(p_name, TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, res_type)
	props.back()["class_name"] = res_type
	
	return MethodBind.new(props.back())

#Exports a class as a list of separate properties. 
#Must use set_prop_class in _set and get_prop_class in _get
#Add a prefix if you need to export multiple of the same class
func add_class(instance: Object, p_name: String, prefix: String = "",p_hint : int = PROPERTY_HINT_NONE, hint: String = ""):
	add_prop(p_name, TYPE_OBJECT).usage(PROPERTY_USAGE_NO_EDITOR)
	for p_dict in PropertyList.get_clean_prop_list(instance): 
		var type: int = typeof(instance.get(p_dict.name))
		add_prop(prefix+p_dict.name, p_dict.type, p_hint, hint, PROPERTY_USAGE_EDITOR)
	
	return MethodBind.new(props.back())

#Used in _set like this: 
#if PropertyList.set_prop_class(class_instance, property, value): return true
static func set_prop_class(instance: Object, property: String, value, prefix: String = "") -> bool:
#	match property:
#		"Reference", "reference", "script", "Script Variables", "Script", "Resource", "resource", "resource_path", "resource_name", "resource_local_to_scene", "RefCounted": 
#			return false
	var prop: String = property
	
	if prefix != "":
		if property.begins_with(prefix):
			prop = property.trim_prefix(prefix)
		else:
			return false
	
	for p in instance.get_property_list(): 
		if prop == p.name:
			if instance == null: instance = load(instance.script).new()
			instance.set(p.name, value)
			return true
	
	return false

#Used in _get like this:
#var check = PropertyList.get_prop_class(_class, property)
#if check != null: return check
static func get_prop_class(instance: Object, property: String, prefix: String = ""):
#	match property:
#		"Reference", "reference", "script", "Script Variables", "Script", "Resource", "resource", "resource_path", "resource_name", "resource_local_to_scene", "RefCounted": 
#			return null
	
	var prop: String = property
	
	if prefix != "":
		if property.begins_with(prefix):
			prop = property.trim_prefix(prefix)
		else:
			return null
			
	for p in instance.get_property_list(): 
		if prop == p.name:
			if instance == null: instance = load(instance.script).new()
			return instance.get(p.name)
	
	return null
