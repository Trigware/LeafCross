extends Node2D

@export var puzzle_door: Node2D
@export var puzzle_syntax := ""

@export var lever_configurations: Dictionary[Enum.LeverColor, bool]
@export var nested_ladders: Dictionary[Enum.LeverColor, Enum.LeverColor]
@export var lasers_on_ladders : Dictionary[Enum.LeverColor, LeverPuzzleLasers]

@onready var max_x: Marker2D = $"Max X"

const y_ladder_offset = 130
const ladder_spacing = 75

var lever_dict := {}
var laser_list := []
var ladder_nesting_levels : Dictionary[Enum.LeverColor, int] = {}
var ground_level_levers : Array[Enum.LeverColor] = []

func _ready():
	parse_puzzle_syntax()
	construct_ladders()
	print(get_ladder_puzzle_code())

const maximum_distance = 150
const minimum_alpha_modulation = 0.5

func _process(_delta):
	if Player.climbing_ladder_index > -1: return
	var y_delta = global_position.y - Player.get_global_pos().y
	modulate.a = lerp(1.0, minimum_alpha_modulation, min(y_delta / maximum_distance, 1))

var highest_ladder_nesting_level = 0

func construct_ladders():
	set_ladder_nesting_levels()
	for i in range(lever_configurations.size()):
		create_ladder(i)
	for lever_color in lever_dict.keys():
		var lever = lever_dict[lever_color]
		lever.lever_pulled.connect(Callable(puzzle_door, "open_door").bind(lever_dict))
		for laser in laser_list:
			if laser.laser_color != lever_color: continue
			laser.lever_dict = lever_dict
			lever.lever_pulled.connect(Callable(laser, "handle_pulling_of_lever").bind())
			laser.handle_pulling_of_lever()

func create_ladder(i):
	var ladder_instance = UID.SCN_LADDER_LEVER_PUZZLE.instantiate()
	var lever = ladder_instance.get_node("Lever")
	lever.belongs_to_ladder_index = i
	lever.lever_on = lever_configurations.values()[i]
	
	var lever_color_enum = lever_configurations.keys()[i]
	lever.lever_color = Enum.lever_colors[lever_color_enum]
	ladder_instance.position = get_ladder_position(lever_color_enum)
	ladder_instance.set_meta("ladder_index", i)
	if not lever_color_enum in ground_level_levers: ladder_instance.get_node("Shadow").hide()
	if lever_color_enum in nested_ladders.values(): ladder_instance.get_node("Static Body/Top").queue_free()
	
	var ladder_parent_index = -1
	if lever_color_enum in nested_ladders:
		var parent = nested_ladders[lever_color_enum]
		ladder_parent_index = lever_configurations.keys().find(parent)
	ladder_instance.set_meta("ladder_parent_index", ladder_parent_index)
	ladder_instance.name = Enum.get_lever_color_as_name(lever_color_enum) + " Ladder"
	var ladder_nesting_level = ladder_nesting_levels[lever_color_enum]
	ladder_instance.get_node("Layered NPC/Layered Manager").sprite_zindex += highest_ladder_nesting_level - ladder_nesting_level
	
	lever_dict[lever_color_enum] = lever
	add_lasers_to_ladder(ladder_instance, lever_color_enum)
	add_child(ladder_instance)

func get_ladder_position(color):
	if not color in ladder_nesting_levels: push_error("The color '" + Enum.get_lever_color_as_name(color) + "' is not a parent of any lever color!")
	var y_result = ladder_nesting_levels[color] * -y_ladder_offset -y_ladder_offset / 2.0
	if color in ground_level_levers:
		var ground_lever_index = ground_level_levers.find(color)
		return Vector2(get_ladder_x_pos(ground_lever_index), y_result)
	var parent = nested_ladders[color]
	return Vector2(get_ladder_position(parent).x, y_result)

func get_ladder_x_pos(ladder_x):
	return get_center_position(lever_configurations.size() - nested_ladders.size(),\
	max_x.position.x, ladder_spacing, ladder_x, "ladders")

var ladder_parent_trace := []

func set_ladder_nesting_levels():
	ladder_nesting_levels = {}
	ground_level_levers = []
	highest_ladder_nesting_level = 0
	for color in lever_configurations.keys():
		ladder_parent_trace = []
		var lever_nesting_level = get_ladder_nesting_levels(color)
		ladder_nesting_levels[color] = lever_nesting_level
		if lever_nesting_level > highest_ladder_nesting_level: highest_ladder_nesting_level = lever_nesting_level
		if lever_nesting_level == 0: ground_level_levers.append(color)

func get_ladder_nesting_levels(color):
	if not color in nested_ladders: return 0
	var parent = nested_ladders[color]
	if color in ladder_parent_trace:
		push_error("Ladder nesting circular dependency error (ladder parent trace: " + str(ladder_parent_trace) + ")")
		return 0
	ladder_parent_trace.append(color)
	return 1 + get_ladder_nesting_levels(parent)

const maximum_laser_y_pos = -22.5
const laser_spacing = 15

func add_lasers_to_ladder(ladder, lever_color):
	if not lever_color in lasers_on_ladders: return
	var lasers_resource = lasers_on_ladders[lever_color]
	if lasers_resource == null:
		push_error("Lasers resource is missing for color " + Enum.get_lever_color_as_name(lever_color) + "!")
		return
	var ladder_lasers = lasers_resource.lasers
	var laser_index = 0
	for laser_color in ladder_lasers:
		var laser_instance = UID.SCN_LADDER_LASER.instantiate()
		laser_instance.laser_color = laser_color
		laser_instance.negated_laser = laser_color in lasers_on_ladders[lever_color].negated_lasers
		laser_instance.position.y = get_center_position(ladder_lasers.size(), maximum_laser_y_pos, laser_spacing, laser_index, "lasers", -maximum_laser_y_pos)
		laser_list.append(laser_instance)
		ladder.add_child(laser_instance)
		laser_index += 1

func get_center_position(elements_count, maximum_pos, element_spacing, element_index, element_name, mimimum_pos = 0):
	var available_width = abs(maximum_pos - mimimum_pos)
	var total_length = (elements_count - 1) * element_spacing
	var start = (available_width - total_length) / 2.0
	if start < 0: push_error("Unable to fit " + str(elements_count) + " "  + element_name + " to this space! (start: " + str(start) + ")")
	return start + element_index * element_spacing - mimimum_pos

var lever_signature = ""

func parse_puzzle_syntax():
	if puzzle_syntax == "": return
	lever_configurations = {}
	nested_ladders = {}
	lasers_on_ladders = {}
	for ch in puzzle_syntax:
		if ch == ';':
			parse_lever()
			continue
		lever_signature += ch
	parse_lever()

func parse_lever():
	if lever_signature == "":
		push_error("Empty lever signature found!")
		return
	var initial_lever_state = lever_signature[0]
	var lever_color = get_color(1)
	match initial_lever_state:
		"T": lever_configurations[lever_color] = true
		"F": lever_configurations[lever_color] = false
		_: push_error("Unrecognized boolean symbol '" + initial_lever_state + "'!")
	
	var lever_puzzle_lasers_resource = LeverPuzzleLasers.new()
	while termination_symbol != ')':
		var laser_color = get_color(latest_end_index + 1, true)
		if termination_symbol == "": break
		if laser_color == -1: continue
		lever_puzzle_lasers_resource.lasers.append(laser_color)
		if latest_negated: lever_puzzle_lasers_resource.negated_lasers.append(laser_color)
	lasers_on_ladders[lever_color] = lever_puzzle_lasers_resource
	var parent_lever_color = get_color(latest_end_index + 1)
	if parent_lever_color != -1: nested_ladders[lever_color] = parent_lever_color
	lever_signature = ""

var latest_end_index: int
var termination_symbol: String
var latest_negated := false

func get_color(start_index, allow_negation = false):
	var lever_color = ""
	termination_symbol = ''
	var i = start_index
	while i < lever_signature.length():
		var ch = lever_signature[i]
		if ch in ['(', ')', ',']:
			termination_symbol = ch
			break
		lever_color += ch
		i += 1
	latest_end_index = i
	var include_exclamation = lever_color.begins_with("!")
	if allow_negation: latest_negated = include_exclamation
	if latest_negated and allow_negation: lever_color = lever_color.substr(1)
	return Enum.get_lever_color_from_str(lever_color)

func get_ladder_puzzle_code():
	var puzzle_code = ""
	for i in range(lever_configurations.size()):
		var color = lever_configurations.keys()[i]
		var lever_state = lever_configurations[color]
		puzzle_code += "T" if lever_state else "F"
		puzzle_code += Enum.lever_colors_shortened[color]
		var color_parent = ""
		if color in nested_ladders: color_parent = Enum.lever_colors_shortened[nested_ladders[color]]
		var lasers_list_str = ""
		var lasers_resource = null if not color in lasers_on_ladders else lasers_on_ladders[color]
		var lasers_list = [] if not color in lasers_on_ladders else lasers_resource.lasers
		for j in range(lasers_list.size()):
			var laser_color = lasers_list[j]
			var laser_str = Enum.lever_colors_shortened[laser_color]
			if laser_color in lasers_resource.negated_lasers: laser_str = "!" + laser_str
			lasers_list_str += laser_str
			if j < lasers_list.size() - 1: lasers_list_str += ","
		if lasers_list_str != "" or color_parent != "":  lasers_list_str = "(" + lasers_list_str + ")"
		puzzle_code += lasers_list_str
		puzzle_code += color_parent
		if i < lever_configurations.size() - 1: puzzle_code += ";"
	return puzzle_code
