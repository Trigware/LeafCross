extends Node

var FinishedCutscenes := []
var action_lock = false
var latest_cutscene_name = ""
var cutscene_nodes : Dictionary = {}

enum Cutscene
{
	None,
	ChoosePlayer,
	SpawnRoom,
	Legend,
	CemetaryGate,
	Nixie_Introductory,
	Character_Dialog_Tester,
	LeverPuzzle_Tutorial,
	LeverPuzzle_Exclamation_Tutorial
}

signal cutscene_completed
signal player_sit

var time_since_player_sat_on_bench: float
var time_since_waiting_to_sit: float
var sitting_wait_time: float
var was_any_movement_or_continue_key_pressed := true

func _process(delta):
	time_since_player_sat_on_bench += delta
	time_since_waiting_to_sit += delta
	if Helper.is_any_movement_or_continue_key_pressed() and not was_any_movement_or_continue_key_pressed: was_any_movement_or_continue_key_pressed = true
	if time_since_waiting_to_sit >= sitting_wait_time: player_sit.emit()

func wait(duration):
	await get_tree().create_timer(duration).timeout

func get_enum_name(cutscene: Cutscene):
	return Cutscene.find_key(cutscene)

func add_finished_cutscene_flag(cutscene: Cutscene):
	FinishedCutscenes.append(get_enum_name(cutscene))

func is_cutscene_finished(cutscene: Cutscene):
	return get_enum_name(cutscene) in FinishedCutscenes

func after_cutscene_finished(cutscene: Cutscene):
	action_lock = false
	if latest_cutscene_finished_early: return
	add_finished_cutscene_flag(cutscene)
	if cutscene == Cutscene.Nixie_Introductory:
		NPCData.set_data(NPCData.ID.BibleInteractPrompt_SAVEINTROROOM, NPCData.Field.Deactivated, true)

var latest_cutscene_finished_early := false

func complete_cutscene(returned_early := false):
	await get_tree().process_frame
	latest_cutscene_finished_early = returned_early
	emit_signal("cutscene_completed")

func let_cutscene_play_out(cutscene: Cutscene, cutscene_nodes_override := {}):
	if is_cutscene_finished(cutscene): return
	latest_cutscene_name = get_enum_name(cutscene)
	var function_name = "play_" + latest_cutscene_name.to_lower() + "_cutscene"
	if not has_method(function_name):
		push_error("Attempted to play the " + latest_cutscene_name + " cutscene which doesn't have an associated function!")
		return
	action_lock = true
	add_cutscene_nodes(cutscene_nodes_override)
	call(function_name)
	await cutscene_completed
	after_cutscene_finished(cutscene)

func add_cutscene_nodes(cutscene_node_override):
	cutscene_nodes = {}
	for node_name in cutscene_node_override.keys():
		var cutscene_node = cutscene_node_override[node_name]
		var renamed_node = node_name.to_lower()
		cutscene_nodes[renamed_node] = cutscene_node

func play_spawnroom_cutscene():
	Player.update_animation("spawn")
	await wait(2)
	Player.update_animation("walk_right")
	complete_cutscene()
	await Audio.play_sound(UID.SFX_GET_UP)
	Audio.play_music("Weird Forest", 0.1)

func play_cemetarygate_cutscene():
	var camera_destination_marker = cutscene_nodes["camera_dest"]
	await Player.move_camera_with_marker(camera_destination_marker)
	await wait(1)
	await print_cutscene_sequence({}, PresetSystem.Preset.OverworldTreeTalk)
	await Player.return_camera()
	complete_cutscene()

func play_nixie_introductory_cutscene():
	var nixie = cutscene_nodes["nixie"]
	nixie_introductory_jump(nixie)
	await nixie_fall_finished
	Audio.play_music("The Self-Proclaimed Queen")
	await TextMethods.print_sequence("Cutscene_NixieIntroductory_Tester")
	complete_cutscene()

func nixie_introductory_jump(nixie):
	nixie.set_to_default_scale()
	nixie.set_uniform("moving_speed", 0.3)
	nixie.hide()
	nixie.set_anim("walk_left")
	nixie.set_uniform("hide_progression", 1)
	await wait(0.8)
	nixie.show()
	nixie.tween_hide_progression(0, 0.75)
	Player.update_animation("walk_up")
	await wait(1)
	var player_pos = Player.get_body_pos()
	nixie.jump_to_point(Vector2(player_pos.x, player_pos.y - 10))
	emit_signal("nixie_jumps")
	await nixie.near_ground
	TextMethods.clear_text(true)
	await Player.noticed(0.35)
	await MovingNPC.move_player_by_backwards(-50)
	await nixie.nail_swing("AttackMessage_MISS")
	emit_signal("nixie_fall_finished")

signal nixie_fall_finished
signal nixie_jumps

func play_character_dialog_tester_cutscene():
	await print_cutscene_sequence({
		"has_mushroom": Inventory.has_item(Inventory.Item.GLOWING_MUSHROOM)
	})
	complete_cutscene()

func print_cutscene_sequence(variables := {}, preset := PresetSystem.Preset.RegularDialog):
	var base_key = "Cutscene_" + CutsceneManager.latest_cutscene_name
	await TextMethods.print_sequence(base_key, variables, preset, "root")

func play_leverpuzzle_exclamation_tutorial_cutscene():
	var lever_puzzle = cutscene_nodes["lever_puzzle"]
	var camera_destination_marker = cutscene_nodes["camera_dest"]
	await TextMethods.print_sequence("Cutscene_LeverPuzzle_Tutorial", {"lever_puzzle*": lever_puzzle, "cam_dest*": camera_destination_marker})
	complete_cutscene()

var stop_flipping_lever = false

func flip_lever_continuously(lever_puzzle, lever_color, revert_back, intial_call = true):
	var lever_to_be_flipped = lever_puzzle.lever_dict[lever_color]
	if intial_call:
		stop_flipping_lever = false
		lever_state_before_toggling = lever_to_be_flipped.lever_on
	var current_state_matches_at_start = lever_to_be_flipped.lever_on == lever_state_before_toggling
	if stop_flipping_lever and (current_state_matches_at_start or not revert_back):
		stop_flipping_lever = false
		emit_signal("lever_flipping_stopped")
		return
	await lever_to_be_flipped.interact_with_lever(true)
	var wait_duration = 1 if stop_flipping_lever else 2
	await wait(wait_duration)
	flip_lever_continuously(lever_puzzle, lever_color, revert_back, false)

signal text_event_completed
signal lever_flipping_stopped

func complete_text_event():
	if is_function_called_with_await: emit_signal("text_event_completed")

var is_function_called_with_await := false

func start_text_event(function: Function):
	var called_function_name = "play_text_event_" + function.function_name.to_lower()
	if not has_method(called_function_name):
		push_error("Attempted to call a non-existent text event referred to as " + function.function_name + "!")
		return
	is_function_called_with_await = function.awaited_function_call
	callv(called_function_name, function.arguments)
	if is_function_called_with_await: await text_event_completed

func play_text_event_wait(wait_time: float):
	await wait(wait_time)
	complete_text_event()

func play_text_event_auto():
	TextSystem.text_finished.emit()
	TextSystem.want_next_text.emit()
	complete_text_event()

func play_text_event_textvisibility(visibility_status: bool):
	TextSystem.textNode.visible = visibility_status
	TextSystem.textboxNode.visible = visibility_status
	if visibility_status and TextSystem.current_speaking_character != TextSystem.SpeakingCharacter.Narrator: TextSystem.show_portrait()
	else: TextSystem.hide_portrait()
	complete_text_event()

func play_text_event_move_camera(marker: Marker2D, duration := 1.0):
	await Player.move_camera_with_marker(marker, duration)
	complete_text_event()

func play_text_event_return_camera(duration := 1.0):
	await Player.return_camera(duration)
	complete_text_event()

func play_text_event_require_input():
	TextSystem.show_wait_leaf()
	await TextSystem.dialog_continue_key_pressed
	TextSystem.latest_text_called_require_input = true
	complete_text_event()

var lever_color_to_continuously_toggle := Enum.LeverColor.None
var lever_state_before_toggling := false

func play_text_event_toggle_lever_continuously(lever_puzzle: Node2D):
	lever_color_to_continuously_toggle = lever_puzzle.get_color_to_pull_randomly()
	flip_lever_continuously(lever_puzzle, lever_color_to_continuously_toggle, true)

func play_text_event_stop_toggling(): stop_flipping_lever = true
func play_text_event_toggle_stopped():
	while true:
		await get_tree().process_frame
		if stop_flipping_lever == false: break
	complete_text_event()

const wait_before_puzzle_start_construction = 0.75

func play_text_event_show_full_puzzle(lever_puzzle: Node2D):
	await lever_puzzle.tween_all_lasers_and_levers(1, 0)
	Audio.play_sound(UID.SFX_COLLAPSING_LADDERS_PUZZLE, 0, 5)
	await lever_puzzle.tween_all_ladders_hide_progression(0, 1)
	await wait(wait_before_puzzle_start_construction)
	lever_puzzle.puzzle_syntax = "FR(!B);TB(Y);FG(!O,Gr)B;TY;FP(Y,!Gr)Y;FO(R,B)P;FGr(Pi,!R);FW(O,!P,!G)Gr;TPi(P,B)"
	lever_puzzle.construct_ladders()
	lever_puzzle.set_all_lasers_and_ladders_alpha(0)
	Audio.play_sound(UID.SFX_COLLAPSING_LADDERS_PUZZLE, 0, 5)
	await lever_puzzle.tween_all_ladders_hide_progression(1, 0)
	lever_puzzle.tween_all_lasers_and_levers(0, 1)
	await Player.return_camera()
	complete_text_event()

const bench_player_dest_x_offset = 50
const wait_before_player_sits := 0.35
const player_y_sit_offset := 30

func play_text_event_make_player_sit(bench: Area2D):
	var player_position = Player.get_global_pos()
	var player_walk_dir = -1
	if player_position.x > bench.global_position.x: player_walk_dir = +1
	var bench_x_position = Overworld.normalize_position(bench.global_position).x
	var sit_destination = bench_x_position + bench_player_dest_x_offset * player_walk_dir
	var player_walk_distance = sit_destination - Overworld.normalize_position(player_position).x
	await MovingNPC.move_player_by(player_walk_distance)
	Player.update_animation("walk_down")
	Player.animNode.stop()
	
	time_since_waiting_to_sit = 0
	sitting_wait_time = randf_range(wait_before_player_sits, wait_before_player_sits * 6)
	await Helper.await_any_movement_or_continue_key_press(false)
	was_any_movement_or_continue_key_pressed = false
	await player_sit
	
	var attempted_to_set_too_early = was_any_movement_or_continue_key_pressed
	TextMethods.update_variable("too_early", was_any_movement_or_continue_key_pressed)
	Player.update_animation("sit", 0)
	Audio.play_sound(UID.SFX_SIT)
	var original_position = Player.node.position.y
	Player.node.position.y -= player_y_sit_offset / Overworld.scaleConst
	time_since_player_sat_on_bench = 0
	
	var bench_interaction_count = NPCData.get_data(NPCData.ID.Antihomeless_Bench_BLEAKLANDS_ENTERANCE, NPCData.Field.InteractionCount)
	if not (attempted_to_set_too_early and bench_interaction_count > 1):
		await Helper.await_any_movement_or_continue_key_press()
	TextMethods.update_variable("time", Helper.convert_time_to_words(time_since_player_sat_on_bench))
	Audio.play_sound(UID.SFX_SIT)
	Player.node.position.y = original_position
	Player.update_animation("walk_down")
	complete_text_event()
