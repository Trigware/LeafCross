extends AnimatedSprite2D

@export var light_color : Color
@export var burning_effect := false
@onready var light = $Light
@onready var effect_trigger = get_parent().get_node("Effect Trigger")

var on_cooldown = false

func _ready():
	play("default")
	modulate = light_color
	light.color = light_color

func _process(_delta):
	if Effects.has_effect(Effects.ID.Burning): return
	if burning_effect and is_player_within_area(): Effects.activate(Effects.ID.Burning, 6)

func is_player_within_area() -> bool:
	for body in effect_trigger.get_overlapping_bodies():
		if body.is_in_group("Player"): return true
	return false
