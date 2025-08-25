extends Node

#region GameData
var selectedCharacter = "xdaforge"
var playerName = ""
var PlayerInventory := {}
var PlayTime := 0.0
var language_chosen = false
var watched_intro_cutscene = false
var seen_leaf = false
var death_counter := 0
var save_choice_seen := false
var game_saved_times := 0
var load_at_room_center := false
#endregion

var allow_game_load = false
var loaded_save_file = 1
const global_path = "user://global.json"
const autosave_path = "user://autosave"

func _ready():
	load_global_file()
	Localization.load_language(Localization.current_language)

func _process(delta):
	PlayTime += delta

func load_global_file():
	var loadedDictionary = load_dictionary(global_path)
	Localization.current_language = loadedDictionary.get("lang", Localization.current_language)
	language_chosen = loadedDictionary.get("lang_chosen", language_chosen)
	watched_intro_cutscene = loadedDictionary.get("watched_intro", watched_intro_cutscene)
	seen_leaf = loadedDictionary.get("seen_leaf", seen_leaf)

func save_global_file():
	var saveData = {
		"lang": Localization.current_language,
		"lang_chosen": language_chosen,
		"watched_intro": watched_intro_cutscene,
		"seen_leaf": seen_leaf
	}
	write_to_savedata(global_path, saveData)

func load_autosave_file():
	var file_path = get_autosave_file_path(loaded_save_file)
	var loadedDictionary = load_dictionary(file_path)
	death_counter = loadedDictionary.get("death_counter", 0)
	PlayTime = floor(loadedDictionary.get("PlayTime", 0))

func save_autosave_file():
	var file_path = get_autosave_file_path(loaded_save_file)
	var saveData = {
		"death_counter": death_counter,
		"PlayTime": floor(PlayTime)
	}
	write_to_savedata(file_path, saveData)

func get_autosave_file_path(file):
	return autosave_path + str(file) + ".json"

func load_game(file):
	allow_game_load = false
	var loadedDictionary = load_dictionary(get_save_file_path(file))
	var positionDictionary: Dictionary[String, float] = {"X": 0.0, "Y": 0.0}
	#region LoadData
	selectedCharacter = loadedDictionary.get("selectedCharacter", selectedCharacter)
	playerName = loadedDictionary.get("playerName", playerName)
	PlayerInventory = loadedDictionary.get("playerInventory", PlayerInventory)
	Overworld.currentRoom = loadedDictionary.get("currentRoom", Overworld.currentRoom)
	NPCData.data = loadedDictionary.get("NPCData", NPCData.data)
	positionDictionary["X"] = loadedDictionary.get("playerPosition", positionDictionary)["X"]
	positionDictionary["Y"] = loadedDictionary.get("playerPosition", positionDictionary)["Y"]
	CutsceneManager.FinishedCutscenes = loadedDictionary.get("FinishedCutscenes", CutsceneManager.FinishedCutscenes)
	Player.node.stringAnimation = loadedDictionary.get("playerDirection", Player.node.stringAnimation)
	Overworld.party_members = loadedDictionary.get("PartyMembers", Overworld.party_members)
	save_choice_seen = loadedDictionary.get("save_choice_seen", save_choice_seen)
	game_saved_times = loadedDictionary.get("game_saved_times", game_saved_times)
	load_at_room_center = loadedDictionary.get("load_at_room_center", load_at_room_center)
	#endregion
	Overworld.initialPosition = Vector2(positionDictionary["X"], positionDictionary["Y"]) / Overworld.scaleConst
	LeafMode.update_head_texture()
	loaded_save_file = file
	load_autosave_file()

func load_dictionary(save_path) -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file != null:
		var content = file.get_as_text()
		file.close()
		return parse_json(content)
	
	Overworld.saveFileCorrupted = true
	return {}

func save_game():
	await get_tree().process_frame
	var playerPosition := {
		"X": Player.node.global_position.x,
		"Y": Player.node.global_position.y
	}
	#region SaveData
	var saveData = {
		"selectedCharacter": selectedCharacter,
		"playerName": playerName,
		"playerInventory": PlayerInventory,
		"currentRoom": Overworld.currentRoom,
		"NPCData": NPCData.data,
		"playerPosition": playerPosition,
		"playerDirection": Player.node.stringAnimation,
		"FinishedCutscenes": CutsceneManager.FinishedCutscenes,
		"PartyMembers": Overworld.party_members,
		"save_choice_seen": save_choice_seen,
		"game_saved_times": game_saved_times,
		"load_at_room_center": load_at_room_center
	}
	#endregion
	write_to_savedata(get_save_file_path(loaded_save_file), saveData)
	save_autosave_file()

func write_to_savedata(path, writtenData):
	var file := FileAccess.open(path, FileAccess.WRITE)
	var json := JSON.stringify(writtenData, '\t')
	file.store_string(json)
	file.close()

func parse_json(contents):
	var json = JSON.new()
	var error = json.parse(contents)
	if error != OK:
		Overworld.saveFileCorrupted = true
		return {}
	var result = JSON.parse_string(contents)
	return result

func get_save_file_path(file_num):
	return "user://savefile" + str(file_num) + ".json"

func access_other_file_data(file_num, data):
	return load_dictionary(get_save_file_path(file_num)).get(data, "")

func access_loaded_file_data(data):
	return access_other_file_data(loaded_save_file, data)

func access_other_autosave_data(file_num, data):
	return load_dictionary(get_autosave_file_path(file_num)).get(data, "")

func access_loaded_autosave_data(data):
	return access_other_autosave_data(loaded_save_file, data)

func save_file_exists(file_num):
	var file_path = get_save_file_path(file_num)
	return FileAccess.file_exists(file_path)

func get_next_load_scene() -> PackedScene:
	if not SaveData.language_chosen:
		return UID.SCN_CHOOSE_LANGUAGE
	if not does_any_save_file_exist():
		SaveData.load_game(1)
		return UID.SCN_LEGEND
	return UID.SCN_FILE_SELECT

func does_any_save_file_exist():
	var dir_path = "user://"
	var dir = DirAccess.open(dir_path)
	if dir == null:
		push_error("Directory cannot be opened!")
		return
	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if not dir.current_is_dir():
			var basename = filename.get_basename()
			if basename.substr(0, 8) == "savefile":
				var filenum = basename.substr(8)
				if filenum.is_valid_int() and int(filenum) >= 1 and int(filenum) <= 3: return true
		filename = dir.get_next()
	dir.list_dir_end()
	return false
