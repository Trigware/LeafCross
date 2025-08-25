extends Node2D

@export var lilypad_flower_dir := UID.LILYPAD_FLOWER_DIRECTION.DOWN
@onready var sprite = $"NPC Root/Sprite"

func _ready():
	sprite.texture = UID.IMG_LILYPAD_FLOWER[lilypad_flower_dir]
