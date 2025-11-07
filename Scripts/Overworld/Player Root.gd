extends Node

@onready var node = $"Player Body"
@onready var body = node
@onready var light = $"Player Body/Light"
@onready var leafNode = $"Player Body/Leaf"
@onready var camera = $"Player Body/Camera"
@onready var hp_particle_point = $"Player Body/Health Particle Point"
@onready var animNode = $"Player Body/Sprite"
@onready var notice = $"Player Body/Notice"

const playableCharacters = ["rabbitek", "xdaforge", "gertofin"]

const player_speed := 250
const fast_movement := 0.625
const normal_move_fast_multiplier_default := 0.35

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

var lilypad_overlaps = 0
var previous_camera_pos = Vector2.ZERO

var initial_camera_offset : Vector2

var footsteps : Array[Dictionary] = []

@onready var intended_leaf_pos = leafNode.position

func _ready():
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
	node.animationNode.animation = anim_name
	if frame is int: node.animationNode.frame = frame

func play_animation(anim_name):
	if can_update_anim(anim_name): return
	if SaveData.selectedCharacter == "ess":
		var new_image_height = 48 if anim_name == "praying" else 36
		set_uniform("image_pixel_height", new_image_height)
	animNode.play(anim_name)

func can_update_anim(anim_name): return climbing_ladder and anim_name != "climb"

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
	var return_pos = previous_camera_pos / Overworld.scaleConst
	await move_camera_to(return_pos.x, return_pos.y, duration)

func move_camera_by(x, y, duration := 1.0):
	var camera_global_pos = camera.global_position / Overworld.scaleConst
	await move_camera_to(camera_global_pos.x + x, camera_global_pos.y + y, duration)

func move_camera_with_marker(marker, duration := 1.0): await move_camera_to(marker.position.x, marker.position.y, duration)

const leaf_mode_fast_movement = 1.25

func get_fast_movement_speed():
	if not LeafMode.enabled(): return leaf_mode_fast_movement
	var staminaPercentage = float(Player.stamina) / Player.maxStamina
	var resulting_speed = 1 + fast_movement * staminaPercentage
	return resulting_speed

func get_shader_material() -> ShaderMaterial:
	var shader_mat = animNode.material
	if shader_mat is not ShaderMaterial:
		push_error("Shader Material not found!")
	return shader_mat

func set_shader_material(mat: ShaderMaterial):
	animNode.material = mat.duplicate()

func set_uniform(parameter, value):
	var shader_mat = get_shader_material()
	shader_mat.set_shader_parameter(parameter, value)

func get_uniform(parameter):
	var shader_mat = get_shader_material()
	return shader_mat.get_shader_parameter(parameter)

func wait(time: float):
	await get_tree().create_timer(time).timeout

func noticed(wait_time := 0.5):
	notice.show()
	await wait(wait_time)
	notice.hide()
