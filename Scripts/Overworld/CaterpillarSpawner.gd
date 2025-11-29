extends "res://Scripts/Globals/PointOnLine.gd"

@export var body_size := 6
@export var caterpillar_speed := 10.0
@export var caterpillar_distance_to_activate := 80.0

var directions = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]
var caterpillar_index: int
const eyes_position_when_dir_right = 30

func _ready():
	get_caterpillar_index()
	initialize_line()
	display_caterpillar_footsteps()
	create_logs()
	create_caterpillar()
	caterpillar_step(0)

var exit_log: StaticBody2D
var enter_log: StaticBody2D

func create_logs():
	var exit_log_facing_dir = sign(path_as_points[1] - path_as_points[0])
	exit_log = create_log(exit_log_facing_dir, path_as_points[0])
	var enter_log_facing_dir = sign(path_as_points[-2] - path_as_points[-1])
	enter_log = create_log(enter_log_facing_dir, path_as_points[-1])
	connect_area_functions()

const eyes_area_multiplier = 1.5

func create_log(dir, log_position):
	var log_v = UID.SCN_CATERPILLAR_LOG.instantiate()
	log_v.position = log_position
	log_v.get_node("Sprite").frame_coords.x = directions.find(dir)
	add_child(log_v)
	rotate_areas(log_v, dir)
	initialize_eyes(log_v, dir)
	log_v.get_node("Areas/Interaction Area/Collider").shape.size.x = caterpillar_distance_to_activate
	log_v.get_node("Areas/Eyes Area/Collider").shape.size.x = caterpillar_distance_to_activate * eyes_area_multiplier
	return log_v

func connect_area_functions():
	var enter_log_eyes_area = enter_log.get_node("Areas/Eyes Area")
	var enter_log_interaction_area = enter_log.get_node("Areas/Interaction Area")
	if enter_log_eyes_area.is_connected("body_entered", Callable(self, "show_eyes")): enter_log_eyes_area.body_entered.disconnect(show_eyes)
	if enter_log_interaction_area.is_connected("body_entered", Callable(self, "move_caterpillar")): enter_log_interaction_area.body_entered.disconnect(move_caterpillar)
	
	exit_log.get_node("Areas/Eyes Area").body_entered.connect(show_eyes)
	exit_log.get_node("Areas/Interaction Area").body_entered.connect(move_caterpillar)

func show_eyes(body):
	if not body.is_in_group("Player"): return
	if moving_caterpillar: return
	exit_log.get_node("Eyes").play()

func distance_exit_log_to_player_in_axis(axis): return exit_log.global_position[axis] - Player.get_global_pos()[axis]

func initialize_eyes(log, dir):
	if dir == Vector2.DOWN: return
	var exit_log_eyes = log.get_node("Eyes")
	if dir == Vector2.UP:
		exit_log_eyes.hide()
		return
	var direction_is_right = 1 if dir == Vector2.RIGHT else -1
	exit_log_eyes.position = Vector2(eyes_position_when_dir_right * direction_is_right, 0)
	match dir:
		Vector2.RIGHT: exit_log_eyes.rotation_degrees = 270
		Vector2.LEFT: exit_log_eyes.rotation_degrees = 90

func rotate_areas(caterpillar_log, dir):
	var areas_rotation = 0
	match dir:
		Vector2.RIGHT: areas_rotation = 270
		Vector2.LEFT: areas_rotation = 90
		Vector2.UP: areas_rotation = 180
	caterpillar_log.get_node("Areas").rotation_degrees = areas_rotation

func move_caterpillar(body):
	if not body.is_in_group("Player"): return
	moving_caterpillar = true
	var exit_log_eyes = exit_log.get_node("Eyes")
	exit_log_eyes.stop()
	exit_log_eyes.frame = 0

var caterpillar_components : Array[Node] = []
var moving_caterpillar := false
var tail_component: Node2D
var head_component: Node2D

func create_caterpillar():
	tail_component = create_component(Enum.CaterpillarComponent.Tail)
	for i in body_size: create_component(Enum.CaterpillarComponent.Body)
	head_component = create_component(Enum.CaterpillarComponent.Head)

func create_component(caterpillar_component: Enum.CaterpillarComponent):
	var component = UID.SCN_CATERPILLAR_COMPONENT.instantiate()
	component.component_type = caterpillar_component
	component.component_index = caterpillar_components.size()
	component.caterpillar_index = caterpillar_index
	caterpillar_components.append(component)
	component.name = Enum.get_component_name(caterpillar_component)
	add_child(component)
	return component

const shown_alpha_exit_distance_threshold = 50
const hidden_alpha_exit_distance_threshold = 25

const shown_alpha_enter_distance_threshold = 85
const hidden_alpha_enter_distance_threshold = 45

func _process(delta):
	if not moving_caterpillar: return
	caterpillar_step(delta)
	if destination_progress == 1 and tail_component.progress >= 1: caterpillar_moved_to_destination()
	if destination_progress == 0 and head_component.progress <= 0: caterpillar_moved_to_destination()

const spacing_between_components = 28
const caterpillar_speed_multiplier = 20

var destination_progress = 1
const player_y_sit_offset = 20

func caterpillar_step(delta):
	for i in range(caterpillar_components.size()):
		var caterpillar_component = caterpillar_components[i]
		var traveled_dist = get_traveled_distance(caterpillar_component.progress)
		var distance_from_end = path_circumference - traveled_dist
		
		var alpha_modulate = 1
		if traveled_dist < shown_alpha_exit_distance_threshold:
			alpha_modulate = inverse_lerp(hidden_alpha_exit_distance_threshold, shown_alpha_exit_distance_threshold, traveled_dist)
		if distance_from_end < shown_alpha_enter_distance_threshold:
			alpha_modulate = inverse_lerp(hidden_alpha_enter_distance_threshold, shown_alpha_enter_distance_threshold, distance_from_end)

		caterpillar_component.modulate.a = alpha_modulate
		var progress_dir_multiplier = 1 if destination_progress else -1
		match caterpillar_component.component_type:
			Enum.CaterpillarComponent.Head: caterpillar_component.progress += delta * caterpillar_speed * progress_dir_multiplier / path_circumference * caterpillar_speed_multiplier
			Enum.CaterpillarComponent.Body: caterpillar_component.progress = get_component_progress(i)
			Enum.CaterpillarComponent.Tail: caterpillar_component.progress = get_component_progress(caterpillar_components.size()-1)
		
		caterpillar_component.position = get_point_on_line(caterpillar_component.progress)
		if Player.sitting_on_caterpillar_component_index == i and Player.sitting_on_caterpillar_index == caterpillar_index and not LeafMode.game_over:
			Player.body.global_position = caterpillar_component.global_position
			Player.update_animation("sit", directions.find(movement_direction))
			if movement_direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN]: Player.body.global_position.y -= player_y_sit_offset
			
			var can_player_get_up = false
			if destination_progress == 1: can_player_get_up = distance_from_end < shown_alpha_enter_distance_threshold
			else: can_player_get_up = traveled_dist < shown_alpha_exit_distance_threshold
			
			if can_player_get_up:
				Player.sitting_on_caterpillar_component_index = -1
				Player.disallowed_caterpillars.append(caterpillar_index)
		
		caterpillar_component.caterpillar_direction = movement_direction
		caterpillar_component.update_sprite()

func get_component_progress(i):
	var head_component_progress = head_component.progress
	return head_component_progress - spacing_between_components / path_circumference * i

func caterpillar_moved_to_destination():
	moving_caterpillar = false
	destination_progress = 0 if destination_progress == 1 else 1
	var previous_exit_log = exit_log
	exit_log = enter_log
	enter_log = previous_exit_log
	Player.disallowed_caterpillars.erase(caterpillar_index)
	connect_area_functions()

func get_caterpillar_index():
	caterpillar_index == -1
	for node in get_parent().get_children():
		if node == self: break
		if node.has_meta("is_caterpillar_spawner"): caterpillar_index += 1

const caterpillar_footstep_size = 8
const footstep_alpha = 0.25

func display_caterpillar_footsteps():
	var current_distance_from_start = 0
	var footstep_position = get_point_on_line(0)
	while current_distance_from_start < path_circumference:
		var progress = current_distance_from_start / path_circumference
		get_point_on_line(progress)
		footstep_position += movement_direction * caterpillar_footstep_size
		var footstep_node = UID.SCN_CATERPILLAR_FOOTSTEP.instantiate()
		footstep_node.position = footstep_position
		var current_footstep_direction = movement_direction
		footstep_node.modulate.a = footstep_alpha
		
		var used_footstep_direction = Vector3(current_footstep_direction.x, current_footstep_direction.y, 1)
		if current_footstep_direction.x: used_footstep_direction.z = -1
		var direction_changed = false
		var next_footstep_progress = (current_distance_from_start + caterpillar_footstep_size) / path_circumference
		get_point_on_line(next_footstep_progress)
		if current_footstep_direction != movement_direction:
			used_footstep_direction = Vector3(used_footstep_direction.x + movement_direction.x, used_footstep_direction.y + movement_direction.y, used_footstep_direction.z)
			direction_changed = true
			
		footstep_node.direction_changed = direction_changed
		footstep_node.direction = used_footstep_direction
		add_child(footstep_node)
		current_distance_from_start += caterpillar_footstep_size
