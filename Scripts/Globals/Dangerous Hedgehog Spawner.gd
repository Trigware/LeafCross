extends Node2D

@export var walking_path: Line2D
@export_group("Speed")
@export var base_speed: float = 0.15
@export var boosted_speed_enabled := true
@export_subgroup("Boosted Speed")
@export var boosted_speed_transition_duration: float = 1
@export var boosted_speed_multiplier: float = 0.5
@export var normal_speed_duration: float = 3
@export var max_boost_speed_duration: float = 0.5

@export_group("Groups")
@export var gap_between_start_and_end: float
@export var group_member_counts: Array[int]
@export var group_gaps_lengths: Array[float]
@export var hedgehog_scale := 1.25

var path_circumference : float
var latest_added_point : Vector2
var path_as_points : Array[Vector2] = []
var point_distance_from_start_list : Array[float]
var hedgehog_list: Array[Area2D]

func _ready():
	walking_path.width = 0
	if walking_path.points.size() < 2:
		push_error("Walk path requires at least 2 or more points to function!")
		return
	normalize_line()
	get_point_distances_from_start()
	create_hedgehog_groups()
	add_leaf_mode_trigger()

func normalize_line():
	var path_point_count = walking_path.points.size()
	latest_added_point = walking_path.points[0]
	path_as_points = [latest_added_point]
	
	for i in range(1, path_point_count):
		var point = walking_path.points[i]
		normalize_point(point)
	
	path_as_points.pop_back()
	var saved_latest_added_pt = latest_added_point
	latest_added_point = walking_path.points[0]
	normalize_point(saved_latest_added_pt)

func normalize_point(point):
	var point_delta = abs(point - latest_added_point)
	if point_delta.x > point_delta.y: latest_added_point.x = point.x
	else: latest_added_point.y = point.y
	path_as_points.append(latest_added_point)

func get_point_distances_from_start():
	point_distance_from_start_list = []
	var start_point = path_as_points[0]
	var previous_point = start_point
	path_circumference = 0
	
	for i in range(1, path_as_points.size()):
		var point = path_as_points[i]
		add_new_line_segment_length(previous_point, point)
		previous_point = point
	add_new_line_segment_length(previous_point, start_point)

func add_new_line_segment_length(point1, point2):
	var closing_length = point1.distance_to(point2)
	path_circumference += closing_length
	point_distance_from_start_list.append(path_circumference)

func create_dangerous_hedgehog(progress_at_start):
	var hedgehog_instance = UID.SCN_DANGEROUS_HEDGEHOG.instantiate()
	hedgehog_instance.setup_data(path_as_points, point_distance_from_start_list, path_circumference,\
		base_speed, boosted_speed_transition_duration, normal_speed_duration, boosted_speed_multiplier,\
		max_boost_speed_duration, progress_at_start, boosted_speed_enabled, hedgehog_scale)
	add_child(hedgehog_instance)
	hedgehog_list.append(hedgehog_instance)

var previous_hedgehog_spawn = 0
var minimum_gap_between_hedgehogs = 0.03 * hedgehog_scale
var gap_between_hedgehogs: float

func create_hedgehog_groups():
	if group_member_counts.size() != group_gaps_lengths.size() + 1:
		push_error("The amount of groups must be exactly one more than the amount of gaps!")
		return
	
	compute_gap_between_hedgehogs()
	for i in range(group_member_counts.size()):
		var group_members = group_member_counts[i]
		for j in group_members:
			create_dangerous_hedgehog(previous_hedgehog_spawn)
			previous_hedgehog_spawn += gap_between_hedgehogs
			if previous_hedgehog_spawn > 1:
				push_error("Some hedgehogs were spawned on top of each other! Consider lowering the amount of hedgehogs in some groups.")
				return
		if i >= group_gaps_lengths.size(): return
		var group_gap_length = group_gaps_lengths[i]
		previous_hedgehog_spawn += group_gap_length * gap_between_hedgehogs

const gap_computation_precision = 50
const FLOAT_EPSILON = 1E-06

func compute_gap_between_hedgehogs():
	var lowest_gap_length = minimum_gap_between_hedgehogs
	var highest_gap_length = 1
	var latest_remaining_empty_space: float
	
	for i in range(gap_computation_precision):
		var midpoint = (lowest_gap_length + highest_gap_length) / 2
		latest_remaining_empty_space = compute_remaining_empty_space(midpoint)
		if latest_remaining_empty_space < 0: highest_gap_length = midpoint
		if latest_remaining_empty_space > 0: lowest_gap_length = midpoint
	
	if latest_remaining_empty_space < -FLOAT_EPSILON:
		push_error("There is no valid gap for which all hedgehogs and gaps can fit! Consider lowering the amount of hedgehogs in some groups.")
		return
	gap_between_hedgehogs = lowest_gap_length

func compute_remaining_empty_space(tested_gap_between_hedgehogs):
	var hedgehog_occupation_space = 0
	for hedgehog_count_in_group in group_member_counts:
		hedgehog_occupation_space += hedgehog_count_in_group * tested_gap_between_hedgehogs
	
	var total_gap_length = 0
	for gap_length in group_gaps_lengths:
		total_gap_length += gap_length * tested_gap_between_hedgehogs
	total_gap_length += gap_between_start_and_end * tested_gap_between_hedgehogs
	
	var remaining_empty_space = 1 - (hedgehog_occupation_space + total_gap_length)
	return remaining_empty_space

func add_leaf_mode_trigger():
	var leaf_mode_trigger_instance = UID.SCN_LEAF_MODE_TRIGGER.instantiate()
	get_bounding_box_of_path_area()
	add_child(leaf_mode_trigger_instance)
	
	var rectangle_size = most_bottom_right_point - most_top_left_point
	var shape_extents = rectangle_size / 2
	var center_position = most_top_left_point + shape_extents
	
	var rectangle_shape = RectangleShape2D.new()
	rectangle_shape.size = rectangle_size
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = rectangle_shape
	collision_shape.position = center_position
	leaf_mode_trigger_instance.add_child(collision_shape)

var most_top_left_point: Vector2
var most_bottom_right_point: Vector2
const shape_boundary_offset = 50

func get_bounding_box_of_path_area():
	var lowest_x := INF
	var lowest_y := INF
	var highest_x := -INF
	var highest_y := -INF
	
	for point in path_as_points:
		if point.x < lowest_x: lowest_x = point.x
		if point.y < lowest_y: lowest_y = point.y
		if point.x > highest_x: highest_x = point.x
		if point.y > highest_y: highest_y = point.y
	
	most_top_left_point = Vector2(lowest_x - shape_boundary_offset, lowest_y - shape_boundary_offset)
	most_bottom_right_point = Vector2(highest_x + shape_boundary_offset, highest_y + shape_boundary_offset)
