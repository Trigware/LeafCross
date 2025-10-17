extends AnimatedSprite2D

@export var light_color : Color
@export var burning_effect := false
@onready var light = $Light
@onready var layer_manager = $"Layered Manager"

var on_cooldown = false

func _ready():
	play("default")
	modulate = light_color
	light.color = light_color
	if not burning_effect:
		layer_manager.queue_free()

func on_body_entering_fire(body: Node2D) -> void:
	if not body.is_in_group("Player") or not burning_effect: return
	Effects.activate(Effects.ID.Burning, 6)
