extends Node

var follower_agents := {}
const follower_distance = 15

@warning_ignore("unused_signal")
signal near_ground

func _process(_delta):
	if LeafMode.game_over: return
	update_followers_zindex()

func create_simple_moving_npc(agent_type, agent_variation := Enum.AgentVariation.NoVariation):
	if agent_type == Enum.AgentType.PlayerAgent: Player.inputless_movement = true
	var instance = UID.SCN_MOVINGNPC.instantiate()
	instance.agent_type = agent_type
	instance.agent_variation = agent_variation
	add_child(instance)
	return instance

func initialize_player_agent(instance, x, y, to, final_look_dir, speed, go_backwards):
	instance.speed = speed
	instance.final_look_dir = final_look_dir
	instance.go_backwards = go_backwards
	if to: await instance.move_to(x, y)
	else: await instance.move_by(x, y)
	instance.queue_free()
	Player.inputless_movement = false

func move_player(x, y, to, final_look_dir, speed, backwards = false):
	var instance = create_simple_moving_npc(Enum.AgentType.PlayerAgent)
	await initialize_player_agent(instance, x, y, to, final_look_dir, speed, backwards)

func move_player_by(x, y = 0, speed := 1.0, final_look_dir := Vector2.ZERO):
	await move_player(x, y, false, final_look_dir, speed)

func move_player_by_backwards(x, y = 0, speed := 1.0, final_look_dir := Vector2.ZERO):
	await move_player(x, y, false, final_look_dir, speed, true)

func move_player_to(x, y, speed := 1.0, final_look_dir := Vector2.ZERO):
	await move_player(x, y, true, final_look_dir, speed)

func get_agent_type_name(agent_type: Enum.AgentType):
	return Enum.AgentType.find_key(agent_type)

func create_follower_agents():
	Player.footsteps.clear()
	for follower in follower_agents.values():
		follower.queue_free()
	follower_agents.clear()
	for follower in Overworld.party_members:
		var follower_variation = convert_str_to_agent_variation(follower)
		follower_agents[follower_variation] = create_simple_moving_npc(Enum.AgentType.FollowerAgent, follower_variation)

func update_followers_zindex():
	var player_followers_arr := []
	player_followers_arr.append({"follower": Player.node, "y": Player.get_body_pos().y})
	for follower in follower_agents.values():
		player_followers_arr.append({"follower": follower, "y": follower.position.y})
	player_followers_arr.sort_custom(
		func(a, b): return a["y"] < b["y"]
	)
	
	var sorted_follower_index = 0
	for sorted_follower_info in player_followers_arr:
		var follower = sorted_follower_info["follower"]
		follower.z_index = follower.base_follower_zindex + sorted_follower_index
		sorted_follower_index += 1

func get_agent_variation_as_str(agent_variation: Enum.AgentVariation) -> String:
	return Enum.AgentVariation.find_key(agent_variation)

func convert_str_to_agent_variation(agent_variation: String) -> Enum.AgentVariation:
	return Enum.AgentVariation[agent_variation]

func set_texture_height(anim_node, uniform_func_scope):
	await get_tree().process_frame
	var spr_frames = anim_node.sprite_frames
	var frame_texture = spr_frames.get_frame_texture(anim_node.animation, anim_node.frame)
	if frame_texture == null: return
	var texture_size = frame_texture.get_size()
	uniform_func_scope.set_uniform("image_pixel_height", texture_size.y)
	return texture_size.y

func update_follower_agents():
	for follower_agent in follower_agents.values():
		var used_distance = follower_distance * follower_agent.follower_index
		var footstep_count = Player.footsteps.size()
		if footstep_count <= used_distance: used_distance = footstep_count
		var footstep = Player.footsteps[footstep_count - used_distance]
		follower_agent.update_follower(footstep)

func get_direction_as_string(movement_direction):
	if movement_direction == Vector2.LEFT: return "walk_left"
	if movement_direction == Vector2.RIGHT: return "walk_right"
	if movement_direction == Vector2.UP: return "walk_up"
	if movement_direction == Vector2.DOWN: return "walk_down"
