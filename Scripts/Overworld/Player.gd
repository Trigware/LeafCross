extends CharacterBody2D

var direction := Vector2.ZERO
var basic_direction := Vector2.ZERO
var latest_basic_dir := Vector2.ZERO
var stringAnimation = "Right"
var is_left_last_horizontal_dir = false
var speedMultiplier = 1
var disableFootsteps = true
var latest_speed : float
var base_follower_zindex = 50
var layer_npc_areas = 0

var previous_stamina = null
var previous_position : Vector2

@onready var animationNode = $"Sprite"
@onready var sprite = animationNode
@onready var cameraNode = $"Camera"
@onready var colliderNode = $"Player Collider"

enum MovementMode {
	STILL,
	WALK,
	RUN
}

func _ready():
	await get_tree().process_frame
	Player.set_shader_material(UID.SHD_HIDE_SPRITE)
	Player.set_uniform("image_pixel_height", 36)

func enable():
	var player_agent_variation = MovingNPC.convert_str_to_agent_variation(SaveData.selectedCharacter)
	animationNode.sprite_frames = UID.SPF_MOVING_NPCS[player_agent_variation]
	disableFootsteps = false
	PresetSystem.fallback = PresetSystem.Preset.RegularDialog
	animationNode.frame = 0
	cameraNode.enabled = true
	Player.show()

func disable():
	disableFootsteps = true
	cameraNode.enabled = false
	Player.hide()

func _process(delta):
	if not Player.visible: return
	var stamina_delta = 4 + (Player.maxStamina - Player.stamina) * Player.time_spend_not_walking / 2
	match handle_motion_actions():
		MovementMode.WALK: stamina_delta = 8
		MovementMode.RUN: stamina_delta = -22 if LeafMode.enabled() else 0
	if stamina_delta != 0: LeafMode.change_stamina(stamina_delta * delta)
	previous_stamina = Player.stamina

func handle_motion_actions():
	basic_direction = Vector2.ZERO
	if not Player.visible or TextSystem.lockAction or CutsceneManager.action_lock or LeafMode.game_over or SaveMenu.menu_openned or Player.inputless_movement:
		return MovementMode.STILL
	direction = Vector2.ZERO
	
	var movementMode = MovementMode.WALK
	speedMultiplier = 1
	if Input.is_action_pressed("move_left"):
		stringAnimation = "Left"
		is_left_last_horizontal_dir = true
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		stringAnimation = "Right"
		is_left_last_horizontal_dir = false
		direction.x += 1
	if Input.is_action_pressed("move_up"):
		stringAnimation = "Up"
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		stringAnimation = "Down"
		direction.y += 1
	
	basic_direction = direction
	latest_basic_dir = direction
	if Input.is_action_pressed("move_fast"):
		speedMultiplier = Player.get_fast_movement_speed()
		movementMode = MovementMode.RUN
	
	previous_position = position
	latest_speed = speedMultiplier * Player.player_speed
	take_step(direction, latest_speed)
	if direction == Vector2.ZERO or previous_position == position: return MovementMode.STILL
	return movementMode

const wall_detection_threshold = -0.5

func take_step(dir, speed):
	direction = dir
	velocity = direction * speed
	move_and_slide()
	position = position.round()
	update_animations()
	for i in range(get_slide_collision_count()): # fixes bug where it would flag a collision if the player was touching a collider but did not move towards it
		var collision = get_slide_collision(i)
		if collision != null and collision.get_normal().dot(dir) < wall_detection_threshold: return true
	return false

func update_animations():
	Player.update_animation(get_animation_name())
	if velocity == Vector2.ZERO:
		animationNode.stop()
		return
	add_to_footstep_targets()
	Player.time_spend_not_walking = 0.0
	on_footstep()
	animationNode.speed_scale = speedMultiplier

func get_animation_name() -> String:
	if Player.climbing_ladder: return "climb"
	return "walk_" + stringAnimation.to_lower()

func on_footstep():
	if disableFootsteps: return
	play_footstep()
	disableFootsteps = true
	await get_tree().create_timer(randf_range(0.23, 0.26) / speedMultiplier).timeout
	disableFootsteps = false

func play_footstep():
	var footstep_type = UID.Footstep.Ground
	if Player.in_water: footstep_type = UID.Footstep.Water
	if Player.in_leaves: footstep_type = UID.Footstep.Leaves
	if Player.climbing_ladder: footstep_type = UID.Footstep.Ladder
	Audio.play_sound(UID.SFX_FOOTSTEPS[footstep_type], 0.3, -5)
	Player.play_animation(get_animation_name())

func add_to_footstep_targets():
	var footstep = {
		"target": global_position,
		"direction": Player.node.stringAnimation,
		"hide_progression": Player.get_uniform("hide_progression")
	}
	Player.footsteps.append(footstep)
	MovingNPC.update_follower_agents()
