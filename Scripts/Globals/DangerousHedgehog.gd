extends "res://Scripts/Globals/PointOnLine.gd"

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
	position = get_point_on_line(movement_progress)
	sprite.play(MovingNPC.get_direction_as_string(movement_direction))
	modulate = Color.WHITE.lerp(Color.DEEP_SKY_BLUE, boosted_speed)
	sprite.speed_scale = 1 + boosted_speed

func _on_body_entered(body):
	if not body.is_in_group("Player"): return
	LeafMode.modify_hp_with_id(LeafMode.HPChangeID.Hedgehog)

func _on_hedgehog_animation_finished() -> void:
	var player_pos = Player.get_body_pos()
	var distance_from_player = player_pos.distance_to(global_position)
	Audio.play_sound_from_distance(UID.SFX_HEDGEHOG_FOOTSTEP, distance_from_player, 0.2)
