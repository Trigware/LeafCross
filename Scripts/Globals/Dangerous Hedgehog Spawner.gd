extends "res://Scripts/Globals/PointOnLine.gd"

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

var hedgehog_list: Array[Area2D]

func _ready():
	initialize_line()
	create_hedgehog_groups()

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

func create_dangerous_hedgehog(progress_at_start):
	var hedgehog_instance = UID.SCN_DANGEROUS_HEDGEHOG.instantiate()
	hedgehog_instance.setup_data(path_as_points, point_distance_from_start_list, path_circumference,\
		base_speed, boosted_speed_transition_duration, normal_speed_duration, boosted_speed_multiplier,\
		max_boost_speed_duration, progress_at_start, boosted_speed_enabled, hedgehog_scale)
	add_child(hedgehog_instance)
	hedgehog_list.append(hedgehog_instance)

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
