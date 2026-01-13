extends Node

@onready var node = $"Player Body"
@onready var body = node
@onready var light = $"Player Body/Light"
@onready var leafNode = $"Player Body/Leaf"
@onready var camera = $"Player Body/Camera"
@onready var hp_particle_point = $"Player Body/Health Particle Point"
@onready var animNode = $"Player Body/Sprite"
@onready var notice = $"Player Body/Notice"
@onready var gameover_rect = $"Player Body/GameOver Rect"
@onready var player_collider = $"Player Body/Player Collider"

const playableCharacters = ["rabbitek", "xdaforge", "gertofin"]

const player_speed := 250
const fast_movement := 0.45
const normal_move_fast_multiplier_default := 0.35
var initial_leaf_scale: Vector2

var playerMaxHealth = 138
var playerHealth = playerMaxHealth
var maxStamina := 100.0
var stamina := maxStamina

var leafTween : Tween
var time_spend_not_walking := 0.0

var leaf_flash_disabled = false
var in_water = false
var in_leaves = false
var on_lilypad = false
var is_sinking = false
var inputless_movement = false
var sinked_times = 0
var whilst_showing_room = false
var climbing_ladder := false
var climbing_ladder_index := -1
var sitting_on_caterpillar_component_index := -1
var sitting_on_caterpillar_index := -1
var disallowed_caterpillars : Array[int] = []
var show_lever_pull_notice = true
var in_title_screen = false

var lilypad_overlaps = 0
var previous_camera_pos = Vector2.ZERO

var initial_camera_offset : Vector2
var initial_leaf_position : Vector2

var footsteps : Array[Dictionary] = []

signal lilypad_exited

@onready var intended_leaf_pos = leafNode.position

func _ready():
	initial_leaf_scale = leafNode.scale
	initial_leaf_position = leafNode.position
	update_game_over_rect(0)
	notice.hide()
	disable()
	var current_flash_final = 1
	initial_camera_offset = camera.offset
	while true:
		if leaf_flash_disabled: return
		leafTween = create_tween()
		var duration = lerp(0.25, 4.0, float(Player.playerHealth) / Player.playerMaxHealth)
		leafTween.tween_property(leafNode, "modulate:v", current_flash_final, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		current_flash_final = 0.5 if current_flash_final == 1 else 1.0
		await leafTween.finished

func _process(delta):
	time_spend_not_walking += delta

func end_leaf_flashes():
	leaf_flash_disabled = true
	leafTween.kill()

func enable():
	node.enable()

func disable():
	node.disable()

func get_global_pos() -> Vector2:
	return node.colliderNode.global_position

func get_body_pos() -> Vector2:
	return node.global_position

func get_newest_dir():
	return node.basic_direction

func update_animation(anim_name, frame = null):
	if can_update_anim(anim_name): return
	if not animation_exists(anim_name):
		push_error("The animation '" + anim_name + "' does not exist!")
		return
	node.animationNode.animation = anim_name
	if frame is int: node.animationNode.frame = frame

func animation_exists(anim_name): return anim_name in node.animationNode.sprite_frames.get_animation_names()

func play_animation(anim_name):
	if can_update_anim(anim_name): return
	if SaveData.selectedCharacter == "ess":
		var new_image_height = 48 if anim_name == "praying" else 36
		set_uniform("image_pixel_height", new_image_height)
	if not animation_exists(anim_name): return
	animNode.play(anim_name)

func can_update_anim(anim_name): return climbing_ladder and anim_name != "climb"

func make_latest_movement_vector() -> Vector2: return Vector2(node.latest_basic_dir_x, node.latest_basic_dir_y)

func set_pos(pos: Vector2):
	node.global_position = pos

func tween_color(final):
	create_tween().tween_property(animNode, "modulate", final, 1)

func tween_light_energy(final):
	create_tween().tween_property(light, "energy", final, 1)
	
func tween_leaf_alpha(final):
	create_tween().tween_property(leafNode, "modulate:a", final, 1)

func tween_value(final):
	create_tween().tween_property(animNode, "modulate:v", final, 1)

func reset_camera_smoothing():
	camera.reset_smoothing()

func get_player_animation():
	return animNode.animation

func go_outside_water(ignore_water_rule = false):
	if (not in_water or is_sinking) and not ignore_water_rule: return
	leafNode.position = intended_leaf_pos
	in_water = false
	set_uniform("hide_progression", 0.0)

func move_camera_to(x, y, duration := 1.0):
	previous_camera_pos = camera.global_position
	var position = Vector2(x, y) * Overworld.scaleConst
	var move_tween = create_tween()
	move_tween.tween_property(camera, "global_position", position, duration)
	move_tween.set_trans(Tween.TRANS_CUBIC)
	move_tween.set_ease(Tween.EASE_IN)
	await move_tween.finished

func return_camera(duration := 1.0):
	await Helper.tween(camera, "position", Vector2.ZERO, duration)

func move_camera_by(x, y, duration := 1.0):
	var camera_global_pos = camera.global_position / Overworld.scaleConst
	await move_camera_to(camera_global_pos.x + x, camera_global_pos.y + y, duration)

func move_camera_with_marker(marker: Marker2D, duration := 1.0): await move_camera_to(marker.position.x, marker.position.y, duration)

const leaf_mode_fast_movement = 1.25

func get_fast_movement_speed():
	if not LeafMode.enabled(): return leaf_mode_fast_movement
	var staminaPercentage = float(Player.stamina) / Player.maxStamina
	var resulting_speed = 1 + fast_movement * staminaPercentage
	return resulting_speed

func get_shader_material(already_checked := false) -> ShaderMaterial:
	var shader_mat = animNode.material
	if shader_mat is not ShaderMaterial:
		if already_checked:
			push_error("Shader Material not found!")
			return null
		await get_tree().process_frame
		return await get_shader_material(true)
	return shader_mat

func set_shader_material(mat: ShaderMaterial):
	animNode.material = mat.duplicate()

func set_uniform(parameter, value):
	var shader_mat = await get_shader_material()
	shader_mat.set_shader_parameter(parameter, value)

func get_uniform(parameter):
	var shader_mat = await get_shader_material()
	return shader_mat.get_shader_parameter(parameter)

func wait(time: float):
	await get_tree().create_timer(time).timeout

func noticed(wait_time := 0.5):
	notice.show()
	await wait(wait_time)
	notice.hide()

func update_game_over_rect(rect_size: float):
	gameover_rect.offset_left = -rect_size
	gameover_rect.offset_top = -rect_size
	gameover_rect.offset_right = rect_size
	gameover_rect.offset_bottom = rect_size

func tween_game_over_rect(final, speed):
	var update_tween = create_tween()
	var overall_change = abs(final - gameover_rect.offset_right)
	update_tween.tween_method(
		func(value):
			update_game_over_rect(value),
		gameover_rect.offset_right,
		final,
		overall_change / speed
	)
	update_tween.set_trans(Tween.TRANS_SPRING)
	await update_tween.finished

const shallow_water_sink = 0.225
const image_pixel_height = 36.0

func on_entering_shallow_water():
	if in_water or on_lilypad: return
	Effects.effect_end(Effects.ID.Burning)
	in_water = true
	set_uniform("hide_progression", shallow_water_sink)
	leafNode.position.y += shallow_water_sink * image_pixel_height
	Audio.play_sound(UID.SFX_SHALLOW_WATER_SPLASH, 0.2, 5)

func start_to_sink(river_fail_point):
	Player.sinked_times += 1
	Player.is_sinking = true
	create_tween().tween_property(Player.leafNode, "modulate:a", 0, 0.7).set_ease(Tween.EASE_IN_OUT)
	TextSystem.lockAction = true
	Audio.play_sound(UID.SFX_DEEP_WATER_SPLASH, 0.2, 5)
	
	player_river_damage()
	await sink_tween(1, 1.5)
	Player.animNode.hide()
	LeafMode.post_river_fail(river_fail_point)

func player_river_damage():
	await get_tree().create_timer(1).timeout
	LeafMode.modify_hp_with_id(LeafMode.HPChangeID.SinkUnderwater)

func sink_tween(final, duration):
	var sink_tween_v = create_tween()
	sink_tween_v.tween_method(
		func(val):
			Player.set_uniform("hide_progression", val + 0.01),
		await Player.get_uniform("hide_progression"),
		final,
		duration
	).set_ease(Tween.EASE_IN_OUT)
	await sink_tween_v.finished

func handle_ladder_trigger_behaviour(exiting, is_bottom, layer_trigger_area, reset_climbing_index, ladder_node):
	Player.climbing_ladder = not exiting
	if not is_bottom:
		handle_top_behaviour()
		return
	
	if reset_climbing_index: Player.climbing_ladder_index = -1
	else:
		var ladder_index = ladder_node.get_parent().get_meta("ladder_index")
		Player.climbing_ladder_index = ladder_node.get_parent().get_meta("ladder_parent_index") if exiting else ladder_index
	
	Player.update_animation("walk_down" if exiting else "climb")
	if not exiting or Player.climbing_ladder_index == -1:
		Player.body.set_collision_mask_value(4, exiting)
		Player.body.set_collision_mask_value(5, not exiting)
	if layer_trigger_area != null: layer_trigger_area.monitoring = exiting

func handle_top_behaviour():
	Player.climbing_ladder = not Player.climbing_ladder
	Player.update_animation(Player.node.get_animation_name())
