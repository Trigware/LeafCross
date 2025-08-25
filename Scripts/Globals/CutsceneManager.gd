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
	Character_Dialog_Tester
}

signal cutscene_completed

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
	add_finished_cutscene_flag(cutscene)
	if cutscene == Cutscene.Nixie_Introductory:
		NPCData.set_data(NPCData.ID.BibleInteractPrompt_SAVEINTROROOM, NPCData.Field.Deactivated, true)

func complete_cutscene():
	await get_tree().process_frame
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
	await Player.move_camera_to(465, -850)
	await wait(1)
	await print_cutscene_sequence({}, PresetSystem.Preset.OverworldTreeTalk)
	await Player.return_camera()
	complete_cutscene()

func play_nixie_introductory_cutscene():
	var nixie = cutscene_nodes["nixie"]
	nixie_introductory_jump(nixie)
	await wait(0.25)
	TextMethods.print_wait_localization("Cutscene_Nixie_Introductory_TreeSaveDialog", {}, PresetSystem.Preset.TreeTextCutoff)
	await nixie_fall_finished
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
