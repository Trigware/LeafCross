extends Node

@export var heroTextureRects: Array[TextureRect]
var transparencyTweenDuration = 1
@onready var mainNode = get_node("/root/Legend/")
@onready var eventTimer = get_node("/root/Legend/EventsTimer")
const firstHeroPanel = 18

func show_hero_panel(textIndex):
	var heroPanel = textIndex - firstHeroPanel
	if heroPanel < 0 || heroPanel > 2: return
	eventTimer.start()
	await eventTimer.timeout
	var heroTexture = heroTextureRects[heroPanel]
	heroTexture.create_tween().tween_property(heroTexture, "modulate:a", 1, transparencyTweenDuration)

func hide_hero_panels():
	for heroPanel in heroTextureRects:
		heroPanel.create_tween().tween_property(heroPanel, "modulate:a", 0, transparencyTweenDuration)
