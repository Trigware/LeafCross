extends Area2D

const head_dir_list = [Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN, Vector2.UP]

@export var component_type := Enum.CaterpillarComponent.Head
@export var caterpillar_direction: Vector2
@onready var sprite = $Sprite

var progress: float
var component_index: int
var caterpillar_index: int

func update_sprite():
	sprite.frame_coords = get_frame_coords()

const caterpillar_body_coords = Vector2(1, 0)
const caterpillar_left_tail_dir_coords = Vector2(1, 1)
const caterpillar_right_tail_dir_coords = Vector2(1, 2)
const caterpillar_vertical_tail_dir_coords = Vector2(1, 3)

func get_frame_coords():
	if component_type == Enum.CaterpillarComponent.Body: return caterpillar_body_coords
	if component_type == Enum.CaterpillarComponent.Head: return Vector2(0, head_dir_list.find(caterpillar_direction))
	if caterpillar_direction in [Vector2.UP, Vector2.DOWN]: return caterpillar_vertical_tail_dir_coords
	if caterpillar_direction == Vector2.LEFT: return caterpillar_left_tail_dir_coords
	else: return caterpillar_right_tail_dir_coords

func _on_body_entered(body):
	if not body.is_in_group("Player"): return
	if Player.sitting_on_caterpillar_component_index == -1 and not caterpillar_index in Player.disallowed_caterpillars:
		Player.sitting_on_caterpillar_component_index = component_index
		Player.sitting_on_caterpillar_index = caterpillar_index
