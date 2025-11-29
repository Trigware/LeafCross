extends Control

@onready var scrollingBackground = $Background
@onready var lightTexture = $Light
@onready var leafTexture = $Leaf
@onready var musicNode = $Music
@onready var nameInput = $"Name Input"
@onready var characterAnimations = $"Character Animations"
@onready var bibleTexture = $Bible

@onready var textReminder = $"Text Reminder"
@onready var moveReminder = $"Move Reminder"

const finalYPosition = -1296
const hoverDuration = 2
const hoverDistance = 100

var leafGoingUp = 1
var continuedToNextText = false
var isLeafStoppingToHover = false
var canSelectCharacter = false
var chosenCharacter := PlayableCharacter.xDaForge
var finalLeafRescalePosition = Vector2(537, 460)

const leafShrinkDuration = 2
const leafCharacterSelectDuration = 0.35

enum PlayableCharacter
{
	Rabbitek = 1,
	xDaForge = 2,
	Gertofin = 3
}

func _ready():
	leafTexture.texture = UID.IMG_LEAF
	nameInput.placeholder_text = Localization.get_text("choosecharacter_name_treeist")
	textReminder.text = Localization.get_text("choosecharacter_notice_pressenter")
	moveReminder.text = Localization.get_text("choosecharacter_notice_moveleaf")
	
	SaveData.selectedCharacter = ""
	PresetSystem.fallback = PresetSystem.Preset.ChooseCharacter
	var empty_style = StyleBoxEmpty.new()
	nameInput.add_theme_stylebox_override("focus", empty_style)
	nameInput.connect("text_submitted", Callable(self, "on_name_submitted"))
	musicNode.finished.connect(loop_audio)
	
	var tween = create_tween()
	tween.tween_property(scrollingBackground, "position:y", finalYPosition, 8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	await get_tree().create_timer(1.5).timeout
	summon_leaf()

func summon_leaf():
	Audio.play_sound(UID.SFX_LIGHT_SWITCH)
	lightTexture.show()
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween()
	tween.tween_property(leafTexture, "position:y", 250, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	TextMethods.print_localization("choosecharacter_prechoose_gift")
	SaveData.seen_leaf = true
	SaveData.save_global_file()
	await TextSystem.text_finished
	
	check_if_not_responding()
	leaf_hover()
	musicNode.play()
	await TextSystem.want_next_text
	create_tween().tween_property(textReminder, "modulate:a", 0, 0.5)
	continuedToNextText = true
	await TextMethods.print_group([
		"choosecharacter_prechoose_changeworld",
		"choosecharacter_prechoose_nochance"
	])
	show_characters()

func leaf_hover():
	while true:
		var tween = create_tween().tween_property(
			leafTexture, "position:y", leafTexture.position.y - hoverDistance * leafGoingUp, hoverDuration).\
			set_trans(Tween.TRANS_SINE)
		await tween.finished
		leafGoingUp *= -1
		if isLeafStoppingToHover:
			break
	create_tween().tween_property(leafTexture, "position", finalLeafRescalePosition, leafShrinkDuration).set_trans(Tween.TRANS_SINE)
	var rescaleTween = create_tween()
	rescaleTween.tween_property(leafTexture, "scale", Vector2(0.5, 0.5), leafShrinkDuration).set_trans(Tween.TRANS_SINE)
	await rescaleTween.finished
	characterAnimations.summon_characters()

func check_if_not_responding():
	await get_tree().create_timer(1.5).timeout
	if not continuedToNextText:
		create_tween().tween_property(textReminder, "modulate:a", 1, 1)

func show_characters():
	create_tween().tween_property(lightTexture, "modulate:a", 0, 2)
	isLeafStoppingToHover = true

func _unhandled_input(_event: InputEvent):
	handle_character_selection()

func handle_character_selection():
	if not canSelectCharacter: return
	var previousChosenCharacter = chosenCharacter
	
	if Input.is_action_just_pressed("move_left") and chosenCharacter != PlayableCharacter.Rabbitek:
		@warning_ignore("int_as_enum_without_cast")
		chosenCharacter -= 1
	if Input.is_action_just_pressed("move_right") and chosenCharacter != PlayableCharacter.Gertofin:
		@warning_ignore("int_as_enum_without_cast")
		chosenCharacter += 1
	if Input.is_action_just_pressed("continue"):
		select_character()
	
	if previousChosenCharacter != chosenCharacter:
		move_leaf_to_chosen_character()

func move_leaf_to_chosen_character():
	if SaveData.selectedCharacter != "": return
	var finalXPosition = 337 * chosenCharacter - 137
	var leafMoveTween = create_tween()
	leafMoveTween.tween_property(leafTexture, "position:x", finalXPosition, leafCharacterSelectDuration).\
	set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	canSelectCharacter = false
	await leafMoveTween.finished
	canSelectCharacter = true

func select_character():
	if SaveData.selectedCharacter != "": return
	create_tween().tween_property(moveReminder, "modulate:a", 0, 1)
	var tween = create_tween()
	tween.tween_property(leafTexture, "position:y", 305, 2).set_trans(Tween.TRANS_SINE).\
	set_ease(Tween.EASE_IN_OUT)
	SaveData.selectedCharacter = Player.playableCharacters[chosenCharacter - 1]
	await tween.finished
	TextMethods.print_localization("choosecharacter_choose_name")
	create_tween().tween_property(nameInput, "modulate:a", 1, 1)
	nameInput.grab_focus()

func on_name_submitted(text):
	nameInput.release_focus()
	var checkedName = text.to_lower()
	var invalidName = false
	TextSystem.overwriteSkippable = true
	
	if checkedName in Player.playableCharacters:
		if SaveData.selectedCharacter.to_lower() == checkedName:
			TextSystem.overwriteSkippable = false
			await TextMethods.print_wait_localization("choosecharacter_namereaction_canonname")
		else:
			TextMethods.print_localization("choosecharacter_namereaction_confusing")
			invalidName = true
	elif checkedName == "angryhonzik" or checkedName == "trigware":
		TextSystem.overwriteSkippable = false
		await TextMethods.print_wait_localization("choosecharacter_namereaction_programmer")
	elif checkedName == "wmt" || checkedName == "wise mystical tree":
		TextMethods.print_localization("choosecharacter_namereaction_god")
		invalidName = true
	elif text.strip_edges() == "":
		TextMethods.print_localization("choosecharacter_namereaction_novisiblesymbols")
		invalidName = true
	elif text.find("{") != -1 or text.find("}") != -1 or text.find("[") != -1 or text.find("]") != -1:
		TextMethods.print_localization("choosecharacter_namereaction_brackets")
		invalidName = true
	
	if invalidName:
		nameInput.text = ""
		nameInput.grab_focus()
		return
	
	TextSystem.overwriteSkippable = false
	SaveData.playerName = text
	on_player_named()

func on_player_named():
	create_tween().tween_property(nameInput, "modulate:a", 0, 1)
	create_tween().tween_property(characterAnimations, "modulate:a", 0, 1)
	var tween = create_tween().tween_property(leafTexture, "position", finalLeafRescalePosition, 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	await TextMethods.print_wait_localization("choosecharacter_postchoose_sayname", {"name": SaveData.playerName})
	show_bible()

func show_bible():
	await TextMethods.print_wait_localization("choosecharacter_postchoose_onemorething")
	music_tween(-80, 0.5)
	Audio.play_sound(UID.SFX_RELIGIOUS_SPAWN)
	create_tween().tween_property(lightTexture, "modulate:a", 1, 1)
	var tween = create_tween().tween_property(bibleTexture, "position:y", 150, 4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	music_tween(0, 0.5)
	finish_scene()

func finish_scene():
	await TextMethods.print_group([
		"choosecharacter_postchoose_givebook",
		"choosecharacter_finish_goodbad",
		"choosecharacter_finish_terror",
		"choosecharacter_finish_destroy",
		"choosecharacter_finish_lies",
		"choosecharacter_finish_prepared",
		"choosecharacter_finish_goodluck"
	])
	CutsceneManager.add_finished_cutscene_flag(CutsceneManager.Cutscene.ChoosePlayer)
	music_tween(-80, 3)
	Overworld.currentRoom = Overworld.Room.Weird_SpawnRoom
	Overlay.change_scene(UID.SCN_OVERWORLD_BRIDGE, 3, 1)

func loop_audio():
	musicNode.play()

func music_tween(final, duration):
	create_tween().tween_property(musicNode, "volume_db", final, duration).set_trans(Tween.TRANS_EXPO)
