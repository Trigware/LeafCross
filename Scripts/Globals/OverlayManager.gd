extends Control

@onready var fadeOverlay = $CanvasLayer/Overlay

var activeTween: Tween
var sceneChangingDisabled = false
var while_transition = false
signal finished

func _ready():
	fadeOverlay.color.a = 0

func set_alpha(a):
	fadeOverlay.color.a = a

func hide_overlay():
	fadeOverlay.color.a = 1

func show_overlay():
	fadeOverlay.color.a = 0

func show_scene(duration = 1.0):
	alpha_tween(0, duration)
	await finished

func hide_scene(duration = 1.0):
	alpha_tween(1, duration)
	await finished

func alpha_tween(alpha, duration = 1.0):
	overlay_tween(Color(Color.BLACK, alpha), duration)
	await finished

func overlay_tween(color: Color, duration = 1.0):
	fadeOverlay.modulate = Color(color, fadeOverlay.modulate.a)
	while_transition = true
	kill_tween()
	activeTween = create_tween()
	activeTween.tween_property(fadeOverlay, "color", color, duration)
	await activeTween.finished
	while_transition = false
	emit_signal("finished")

func kill_tween():
	if activeTween != null and is_instance_valid(activeTween):
		activeTween.kill()

func change_scene(scene : PackedScene, hideDuration = 1, showDuration = 1, betweenSceneWait: float = 0):
	if sceneChangingDisabled: return
	sceneChangingDisabled = true
	hide_scene(hideDuration)
	await finished
	if betweenSceneWait > 0:
		await get_tree().create_timer(betweenSceneWait).timeout
	TextMethods.clear_text()
	if SaveData.allow_game_load:
		load_post_legend_scene()
	else:
		get_tree().change_scene_to_packed(scene)
	show_scene(showDuration)
	await finished
	sceneChangingDisabled = false

func load_post_legend_scene():
	var nextScenePath = UID.SCN_CHOOSE_CHARACTER
	if CutsceneManager.is_cutscene_finished(CutsceneManager.Cutscene.ChoosePlayer):
		Overworld.enable()
		nextScenePath = UID.SCN_EMPTY
	if Overworld.saveFileCorrupted: nextScenePath = UID.SCN_ERROR_HANDLELER
	get_tree().change_scene_to_packed(nextScenePath)
