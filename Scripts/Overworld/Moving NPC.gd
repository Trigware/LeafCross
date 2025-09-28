extends CharacterBody2D

@export var agent_type := Enum.AgentType.Uninitialized
var diagonal_path_direction : Vector2
var remainder_path_direction : Vector2

var diagonal_path_position : Vector2
var current_target : Vector2
var final_look_dir := Vector2.ZERO
var speed := Player.player_speed
var go_backwards := false

var controlled_body = Player.node
var stringAnimation : String

var currently_moving = false
@export var agent_variation := Enum.AgentVariation.NoVariation
var follower_index := 0
var base_follower_zindex = 50
var layer_npc_areas = 0

var initial_jump := false
var affected_by_gravity := false
var horizontal_jump_tween
var jump_vertical_destination : float
var near_ground_signal_emitted = false

const jump_height = 200
const jump_gravity = 8
const expected_jump_duration = 1.7
const near_ground_distance = 180
const agent_types_with_variations := [Enum.AgentType.FollowerAgent, Enum.AgentType.CutsceneAgent]

@onready var sprite = $Sprite
@onready var collider = $Collider

@export var on_ready_animation := ""
@export var on_ready_default_scale := true

signal near_ground

#region Initialization
func _ready():
	if agent_type == Enum.AgentType.Uninitialized:
		push_error("Uninitialized agent type for a moving NPC!")
		queue_free()
		return
	sprite.animation_changed.connect(on_animation_changed)
	name = get_appropriate_name()
	if agent_type == Enum.AgentType.PlayerAgent or agent_type == Enum.AgentType.FollowerAgent:
		global_position = Player.get_body_pos()
	if agent_type != Enum.AgentType.PlayerAgent: setup_moving_npc()
	if agent_type == Enum.AgentType.FollowerAgent: set_follower_index()

func setup_moving_npc():
	add_to_group("Moving NPC")
	if agent_variation == Enum.AgentVariation.NoVariation and agent_type in agent_types_with_variations:
		push_error("Excepted agent variation for a " + name + ", but found none!")
		return
	
	sprite.material = UID.SHD_HIDE_SPRITE.duplicate()
	sprite.sprite_frames = UID.SPF_MOVING_NPCS[agent_variation]
	var collider_info = UID.get_agent_collider_info(agent_variation)
	if collider_info != {}:
		collider.shape = collider_info["collider"]
		collider.position = collider_info["position"]
	controlled_body = self
	if on_ready_default_scale: set_to_default_scale()
	if on_ready_animation != "": set_anim(on_ready_animation)
	
	if agent_type != Enum.AgentType.CutsceneAgent: set_walk_animation(Player.node.stringAnimation)

func get_appropriate_name():
	var agent_type_name = MovingNPC.get_agent_type_name(agent_type)
	if agent_variation == Enum.AgentVariation.NoVariation: return agent_type_name
	return MovingNPC.get_agent_variation_as_str(agent_variation) + " (" + agent_type_name + ")"

func set_to_default_scale():
	var default_both_axis_scale = 1
	if agent_type in [Enum.AgentType.PlayerAgent, Enum.AgentType.FollowerAgent]:
		default_both_axis_scale = 3
	match agent_variation:
		Enum.AgentVariation.Nixie: default_both_axis_scale = 1.15
	scale_both_axis(default_both_axis_scale)

func scale_both_axis(new_scale: float):
	scale = Vector2(new_scale, new_scale)
#endregion
#region Animations
func on_animation_changed():
	MovingNPC.set_texture_height(sprite, self)

func set_walk_animation(dir):
	var animation_name = "walk_" + str(dir).to_lower()
	set_anim(animation_name)

func play_walk_animation(dir):
	set_walk_animation(dir)
	play_current()

func set_anim(anim_name):
	sprite.animation = anim_name

func set_direction_animation():
	if final_look_dir == Vector2.ZERO: return
	controlled_body.stringAnimation = get_string_direction(final_look_dir)
	controlled_body.update_walk_animation_frame()

func get_string_direction(dir: Vector2):
	if go_backwards: dir = -dir
	if dir == Vector2.ZERO: return ""
	if dir.x != 0: return "Left" if dir.x < 0 else "Right"
	return "Up" if dir.y < 0 else "Down"

func string_to_vector_direction(str_dir: String) -> Vector2:
	match str_dir:
		"Left": return Vector2.LEFT
		"Right": return Vector2.RIGHT
		"Up": return Vector2.UP
		"Down": return Vector2.DOWN
	push_error("Attempted to parse invalid string direction " + str_dir + "!")
	return Vector2.ZERO

func play_animation(anim_name):
	sprite.play(anim_name)

func play_current():
	sprite.play(sprite.animation)

func get_texture_size():
	return sprite.texture.get_size()
#endregion
#region Shaders
func set_uniform(parameter: String, value):
	var shader_mat = get_shader_material()
	shader_mat.set_shader_parameter(parameter, float(value))

func get_uniform(parameter: String):
	var shader_mat = get_shader_material()
	return shader_mat.get_shader_parameter(parameter)

func get_shader_material() -> ShaderMaterial:
	return sprite.material

func tween_hide_progression(final, duration):
	var visibility_tween = create_tween()
	visibility_tween.tween_method(
		func(val):
			set_uniform("hide_progression", val + 0.01),
		get_uniform("hide_progression"),
		final,
		duration
	)
	visibility_tween.set_ease(Tween.EASE_IN_OUT)
	visibility_tween.set_trans(Tween.TRANS_EXPO)
	await visibility_tween.finished
#endregion
#region Movement

func move_by(x_offset, y_offset):
	await move_to_target(controlled_body.global_position + Vector2(x_offset, y_offset) * Overworld.scaleConst)

func move_to(x, y):
	await move_to_target(Vector2(x, y) * Overworld.scaleConst)

func move_to_target(target: Vector2):
	if currently_moving: return
	currently_moving = true
	current_target = target
	get_diagonal_path_info()
	await move_to_point(diagonal_path_position, diagonal_path_direction)
	await move_to_point(current_target, remainder_path_direction)
	set_direction_animation()
	currently_moving = false

func move_to_point(point: Vector2, dir: Vector2):
	if dir == Vector2.ZERO: return
	var previous_distance_to_point = INF
	controlled_body.stringAnimation = get_string_direction(dir)
	while true:
		var current_position = controlled_body.global_position
		var distance_to_point = point.distance_to(current_position)
		if distance_to_point < 1 or distance_to_point >= previous_distance_to_point: return
		var hit_wall = controlled_body.take_step(dir, speed * Player.player_speed)
		if hit_wall: return
		previous_distance_to_point = distance_to_point
		await get_tree().process_frame

func get_diagonal_path_info():
	var current_position = controlled_body.global_position
	var delta = current_target - current_position
	var local_diagonal_path = get_dialogal_path(delta)
	diagonal_path_direction = get_movement_direction(local_diagonal_path)
	diagonal_path_position = current_position + local_diagonal_path
	var remainder_distance = current_target - diagonal_path_position
	remainder_path_direction = get_movement_direction(remainder_distance)

func get_dialogal_path(delta: Vector2):
	var smallest_value = min(abs(delta.x), abs(delta.y))
	return Vector2(sign(delta.x) * smallest_value, sign(delta.y) * smallest_value)

func get_movement_direction(vec: Vector2):
	return Vector2(sign(vec.x), sign(vec.y))

func jump_to_point(point: Vector2):
	near_ground_signal_emitted = false
	jump_vertical_destination = point.y
	initial_jump = true
	affected_by_gravity = true
	horizontal_jump_tween = create_tween()
	horizontal_jump_tween.tween_property(self, "global_position:x", point.x, expected_jump_duration)
	horizontal_jump_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _physics_process(_delta):
	if agent_type != Enum.AgentType.CutsceneAgent: return
	var notice_vertical_position = jump_vertical_destination - near_ground_distance
	if not near_ground_signal_emitted and global_position.y > notice_vertical_position:
		emit_signal("near_ground")
		near_ground_signal_emitted = true
	if global_position.y > jump_vertical_destination:
		velocity = Vector2.ZERO
		affected_by_gravity = false
		if horizontal_jump_tween != null: horizontal_jump_tween.kill()
	if affected_by_gravity:
		velocity.y += jump_gravity
	if initial_jump:
		velocity.y = -jump_height
		initial_jump = false
	move_and_slide()
#endregion
#region Effects
func spawn_damage_label(text, color := Color.WHITE, offset_x := 0.0, offset_y := 0.0):
	var instance = UID.SCN_HEALTH_CHANGE_INFO.instantiate()
	Player.hp_particle_point.add_child(instance)
	instance.global_position = global_position + Vector2(offset_x, offset_y)
	instance.modulate = color
	instance.play_anim(text)

func nail_swing(text_key):
	if agent_variation != Enum.AgentVariation.Nixie:
		push_error("Nail swing function is reserved for Nixie only!")
		return
	play_animation("nail_swing")
	await wait(0.5)
	Audio.play_sound(UID.SFX_NAIL_SWING)
	spawn_damage_label(Localization.get_text(text_key), Color.LIGHT_PINK, -175, -50)

func wait(time: float):
	await get_tree().create_timer(time).timeout
#endregion
#region FollowerAgent

func set_follower_index():
	follower_index = MovingNPC.follower_agents.size() + 1

func update_follower(footstep):
	global_position = footstep["target"]
	play_walk_animation(footstep["direction"])
	set_uniform("hide_progression", footstep["hide_progression"])

#endregion
