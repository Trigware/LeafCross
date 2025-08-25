extends Node2D

const scaleConst := 1.7

var activeRoom = null
var currentRoom := Room.ErrorHandlerer
var latestExitRoom := Room.ErrorHandlerer
var initialPosition := Vector2.ZERO
var saveFileCorrupted = false
var triggerLocked = false
var time_since_room_load : float
var delayRoomRequest = {}

var party_members := []

@onready var music = $Music
@onready var baseLight = $"Base Light"

var base_light_color = Color("d9d9d9")
const debug_mode_active := false

func _process(delta):
	time_since_room_load += delta
	if activeRoom == null or not debug_mode_active: return
	if Input.is_action_just_pressed("debug_previous_room"): debug_room_load(currentRoom - 1)
	if Input.is_action_just_pressed("debug_next_room"): debug_room_load(currentRoom + 1)

func enable():
	scale = Vector2(scaleConst, scaleConst)
	Player.enable()
	load_room(currentRoom, initialPosition * scaleConst, true)
	baseLight.show()
	baseLight.color = base_light_color

func disable():
	Player.disable()
	baseLight.hide()
	if activeRoom != null:
		activeRoom.queue_free()

func debug_room_load(room):
	load_room(room, Vector2.ZERO, false, true)

func load_room(room: Room, newPlayerPosition := Vector2.ZERO, autoload := false, debug_load := false):
	var strRoom = get_room_enum(room)
	var roomPath = "res://Rooms/" + strRoom + ".tscn"
	if not ResourceLoader.exists(roomPath) or saveFileCorrupted:
		if debug_load: return
		Player.disable()
		await get_tree().process_frame
		add_child(UID.SCN_ERROR_HANDLELER.instantiate())
		return
	
	if activeRoom != null:
		activeRoom.queue_free()
		await activeRoom.tree_exited
	currentRoom = room
	
	setup_loaded_room(roomPath, strRoom, room, newPlayerPosition, autoload)

func setup_loaded_room(roomPath, strRoom, room: Room, newPlayerPosition, autoload):
	var sceneRoom = load(roomPath)
	activeRoom = sceneRoom.instantiate()
	activeRoom.name = strRoom
	LeafMode.restore_all_stamina()
	if BibleOverworld.activated:
		BibleOverworld.reset()
	
	var roomCutscene = activeRoom.cutscene
	if roomCutscene != CutsceneManager.Cutscene.None and not CutsceneManager.is_cutscene_finished(roomCutscene):
		newPlayerPosition = Vector2(activeRoom.cutscenePosition) * scaleConst
		CutsceneManager.let_cutscene_play_out(roomCutscene)
	
	SaveData.save_autosave_file()
	latestExitRoom = room
	if autoload and SaveData.load_at_room_center: newPlayerPosition = Vector2.ZERO
	Player.set_pos(newPlayerPosition)
	Player.reset_camera_smoothing()
	if autoload: BibleOverworld.attempt_to_load_bible()
	await check_if_no_rooms_loaded()
	MovingNPC.create_follower_agents()
	add_child(activeRoom)
	time_since_room_load = 0
	var roomMusic = activeRoom.roomMusic
	Audio.play_music(roomMusic, activeRoom.roomMusicPitchRange, activeRoom.playNoMusic)

func check_if_no_rooms_loaded():
	for child in get_children():
		var script = child.get_script()
		var is_room = script != null and script.resource_path.ends_with("BaseRoom.gd")
		if is_room:
			child.queue_free()
			await child.tree_exited

enum Room
{
	ErrorHandlerer = -1,
	Weird_SpawnRoom,
	Weird_SpawnRoomEnterance,
	Weird_TeleportRoom,
	Weird_LilypadRoom,
	Weird_CemetaryGate,
	Weird_SaveIntroRoom,
	Weird_MushroomTester,
	Weird_LayeredNPCTester,
	Weird_CharacterDialogTester
}

func get_room_enum(room: Room) -> String:
	var roomName = Room.find_key(room)
	if roomName == null:
		return ""
	return roomName.replace("_", "/")

func get_room_ingame_name(room):
	return Localization.get_text("room_name_" + get_room_enum(int(room)))

func trigger_blocked():
	return time_since_room_load < 0.05
