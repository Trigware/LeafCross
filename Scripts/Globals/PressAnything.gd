extends Control

@onready var pressAnythingLabel = $"Moving Nodes/PressButton"
@onready var versionNumber = $Version
@onready var movingNodes = $"Moving Nodes"

const transparency_duration = 2
const hide_scene_duration = 2.5
var allowStartGame = false
var startingGame = false

func _ready():
	pressAnythingLabel.text = Localization.get_text("logo_press_anything")
	versionNumber.text = Localization.get_text("logo_version_number")
	create_tween().tween_property(self, "modulate:a", 1, transparency_duration)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1).timeout
	allowStartGame = true
	tween_transparency(0)

func _process(_delta):
	if Input.is_action_pressed("continue") and allowStartGame:
		allowStartGame = false
		startingGame = true
		create_tween().tween_property(movingNodes, "position:y", -350, hide_scene_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		Audio.play_sound(UID.SFX_START_GAME)
		Overlay.change_scene(SaveData.get_next_load_scene(), hide_scene_duration)

func tween_transparency(final):
	var tween = create_tween().tween_property(pressAnythingLabel, "modulate:a", final, transparency_duration)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_SINE)
	await tween.finished
	var nextFinal = 0
	if final == 0: nextFinal = 1
	else: await get_tree().create_timer(1).timeout
	if startingGame: return
	tween_transparency(nextFinal)
