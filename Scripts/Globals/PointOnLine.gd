extends Node2D

@export var walking_path: Line2D
@export var line_closed := true
@export var leaf_mode_trigger := true

var path_circumference : float
var latest_added_point : Vector2
var path_as_points : Array[Vector2] = []
var point_distance_from_start_list : Array[float]

func normalize_line():
	var path_point_count = walking_path.points.size()
	latest_added_point = walking_path.points[0]
	path_as_points = [latest_added_point]
	
	for i in range(1, path_point_count):
		var point = walking_path.points[i]
		normalize_point(point)
	
	path_as_points.pop_back()
	var saved_latest_added_pt = latest_added_point
	if line_closed: latest_added_point = walking_path.points[0]
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
	if line_closed: add_new_line_segment_length(previous_point, start_point)

func add_new_line_segment_length(point1, point2):
	var closing_length = point1.distance_to(point2)
	path_circumference += closing_length
	point_distance_from_start_list.append(path_circumference)

func add_leaf_mode_trigger():
	if not leaf_mode_trigger: return
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

func initialize_line():
	if walking_path == null:
		push_error("Assign a path node to your a node which utililizes points on a line!")
		return
	walking_path.width = 0
	if walking_path.points.size() < 2:
		push_error("Walk path requires at least 2 or more points to function!")
		return
	normalize_line()
	get_point_distances_from_start()
	add_leaf_mode_trigger()
