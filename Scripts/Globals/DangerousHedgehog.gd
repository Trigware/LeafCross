extends Area2D

var path_as_points : Array[Vector2] = []
var point_distance_from_start_list : Array[float]
var path_circumference : float
var movement_direction : Vector2
var movement_progress = 0

@onready var sprite = $Sprite
@onready var spawner = get_parent()

var hedgehog_speed: float
var boosted_speed: float
var boosted_speed_transition_duration: float
var normal_speed_duration: float
var max_boost_speed_duration: float
var boosted_speed_multiplier: float
var boosted_speed_enabled: bool
var hedgehog_scale : float

func _ready():
	if not boosted_speed_enabled: return
	var next_final_boost = 1
	while true:
		var wait_between_tween_start = normal_speed_duration if next_final_boost == 1 else max_boost_speed_duration
		await get_tree().create_timer(wait_between_tween_start).timeout
		var boosted_speed_tween = create_tween().tween_property(self, "boosted_speed", next_final_boost, boosted_speed_transition_duration)
		await boosted_speed_tween.finished
		next_final_boost = 0 if next_final_boost == 1 else 1

func _process(delta):
	var progress_change = delta * hedgehog_speed * (boosted_speed * boosted_speed_multiplier + 1)
	update_position(progress_change)

func setup_data(point_path, points_from_start, path_circum, base_speed, boost_speed_trans_dur, normal_speed_wait, boost_speed_mult, max_boost_speed_dur, progress_at_start, boost_speed_enab, hedgehog_scale_as_float):
	path_as_points = point_path
	point_distance_from_start_list = points_from_start
	path_circumference = path_circum
	hedgehog_speed = base_speed
	boosted_speed_transition_duration = boost_speed_trans_dur
	normal_speed_duration = normal_speed_wait
	boosted_speed_multiplier = boost_speed_mult
	max_boost_speed_duration = max_boost_speed_dur
	movement_progress = progress_at_start
	boosted_speed_enabled = boost_speed_enab
	hedgehog_scale = hedgehog_scale_as_float
	scale = Vector2(hedgehog_scale, hedgehog_scale)

func update_position(by):
	movement_progress += by
	if movement_progress > 1: movement_progress = movement_progress - 1
	position = get_point_on_line(movement_progress)
	sprite.play(MovingNPC.get_direction_as_string(movement_direction))
	modulate = Color.WHITE.lerp(Color.DEEP_SKY_BLUE, boosted_speed)
	sprite.speed_scale = 1 + boosted_speed

func get_point_on_line(progress) -> Vector2:
	if progress < 0 or progress > 1:
		push_error("The progress parameter must be between the range of 0 to 1!")
		return Vector2.ZERO
	var desired_distance_since_start = path_circumference * progress
	var line_segment_start_index = 0
	
	for i in range(point_distance_from_start_list.size()):
		var distance_since_start = point_distance_from_start_list[i]
		if distance_since_start > desired_distance_since_start:
			line_segment_start_index = i
			break
	var line_segment_end_index = (line_segment_start_index + 1) % path_as_points.size()
	
	var start_distance = 0.0
	if line_segment_start_index > 0: start_distance = point_distance_from_start_list[line_segment_start_index - 1]
	var end_distance = point_distance_from_start_list[line_segment_start_index]

	var local_t = (desired_distance_since_start - start_distance) / (end_distance - start_distance)
	
	var line_segment_start_point = path_as_points[line_segment_start_index]
	var line_segment_end_point = path_as_points[line_segment_end_index]
	
	var resulting_point = lerp(line_segment_start_point, line_segment_end_point, local_t)
	movement_direction = (line_segment_end_point - line_segment_start_point).normalized()
	return resulting_point

func _on_body_entered(body):
	if not body.is_in_group("Player"): return
	LeafMode.modify_hp_with_id(LeafMode.HPChangeID.Hedgehog)

func _on_hedgehog_animation_finished() -> void:
	var player_pos = Player.get_body_pos()
	var distance_from_player = player_pos.distance_to(global_position)
	Audio.play_sound_from_distance(UID.SFX_HEDGEHOG_FOOTSTEP, distance_from_player, 0.2)
