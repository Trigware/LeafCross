extends Node2D

@export var puzzle_door: Node2D
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

func _ready(): construct_ladders()

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
			lever.lever_pulled.connect(Callable(laser, "handle_pulling_of_lever").bind(lever_dict))
			laser.handle_pulling_of_lever(lever_dict)

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
	var y_result = ladder_nesting_levels[color] * -y_ladder_offset -y_ladder_offset / 2
	if color in ground_level_levers:
		var ground_lever_index = ground_level_levers.find(color)
		return Vector2(get_ladder_x_pos(ground_lever_index), y_result)
	var parent = nested_ladders[color]
	return Vector2(get_ladder_position(parent).x, y_result)

func get_ladder_x_pos(ladder_x):
	return get_center_position(lever_configurations.size() - nested_ladders.size(),\
	max_x.position.x, ladder_spacing, ladder_x, "ladders")

func set_ladder_nesting_levels():
	ladder_nesting_levels = {}
	ground_level_levers = []
	highest_ladder_nesting_level = 0
	for color in lever_configurations.keys():
		var lever_nesting_level = get_ladder_nesting_levels(color)
		ladder_nesting_levels[color] = lever_nesting_level
		if lever_nesting_level > highest_ladder_nesting_level: highest_ladder_nesting_level = lever_nesting_level
		if lever_nesting_level == 0: ground_level_levers.append(color)

func get_ladder_nesting_levels(color):
	if not color in nested_ladders: return 0
	var parent = nested_ladders[color]
	return 1 + get_ladder_nesting_levels(parent)

const maximum_laser_y_pos = -22.5
const laser_spacing = 15

func add_lasers_to_ladder(ladder, color):
	if not color in lasers_on_ladders: return
	var lasers_resource = lasers_on_ladders[color]
	if lasers_resource == null:
		push_error("Lasers resource is missing for color " + Enum.get_lever_color_as_name(color) + "!")
		return
	var ladder_lasers = lasers_resource.lasers
	var laser_index = 0
	for laser_color in ladder_lasers:
		var laser_instance = UID.SCN_LADDER_LASER.instantiate()
		laser_instance.laser_color = laser_color
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
