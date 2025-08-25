extends Node

@onready var panel = get_node("/root/Legend/Panels")
@onready var panelTimer = get_node("/root/Legend/PanelTimer")
@onready var panelBlock = get_node("/root/Legend/Panel Block")
@onready var protagonists = get_node("/root/Legend/Protagonists")
@onready var rootNode = get_node("/root/Legend")
@onready var eventTimer = get_node("/root/Legend/EventsTimer")
@onready var skipPrompt = get_node("/root/Legend/Skip Prompt")
@onready var musicNode = get_node("/root/Legend/Music")

@export var panelTextures: Array[Texture2D]
const slidingDuration = 18.0
var startPosition := Vector2(350, 320)
var currentPanelTextureIndex = 0

var scrollTween = create_tween()
const bigPanelStart = 3

func _ready():
	panel.position = startPosition
	panel.modulate.a = 0
	panel.texture = panelTextures[0]
	var endPosition = Vector2(startPosition.x, -530)
	scrollTween.tween_property(panel, "position", endPosition, slidingDuration)
	transparency_tween(1, 5, false)

func transparency_tween(final, duration, transition):
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", final, duration)
	if !transition:
		return
	await tween.finished
	panelTimer.start()
	await panelTimer.timeout
	show_next_panel()
	
func show_next_panel():
	scrollTween.kill()
	currentPanelTextureIndex += 1
	protagonists.show_hero_panel(rootNode.currentPrintedTextIndex - 1)
	
	if currentPanelTextureIndex == 5:
		panel.visible = false
		return
	if currentPanelTextureIndex == 6:
		show_big_panel_after_hero_scene()
	else:
		transparency_tween(1, 1, false)
	
	var actualUsedTextureIndex = currentPanelTextureIndex
	if currentPanelTextureIndex > 5: actualUsedTextureIndex -= 1
	panel.texture = panelTextures[actualUsedTextureIndex]
	if currentPanelTextureIndex >= bigPanelStart:
		fill_entire_screen()
		return
	panel.position = Vector2(startPosition.x, 65)

func fill_entire_screen():
	panel.scale = Vector2(1, 1)
	panel.anchors_preset = Control.PRESET_FULL_RECT
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.expand = true
	panelBlock.color.a = 0
	
func exit_hero_panel():
	protagonists.hide_hero_panels()
	eventTimer.start()
	await eventTimer.timeout
	panel.visible = true

func show_big_panel_after_hero_scene():
	exit_hero_panel()
	eventTimer.start()
	await eventTimer.timeout
	transparency_tween(1, 1, false)
