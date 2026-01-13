extends Area2D

@export var layer_trigger_area: Area2D
@export var is_bottom: bool

func _on_body_entered(body):
	if not body.is_in_group("Player") or Player.node.latest_basic_dir_y == 1: return
	Player.handle_ladder_trigger_behaviour(false, is_bottom, layer_trigger_area, false, self)

func _on_body_exited(body):
	if not body.is_in_group("Player") or Player.node.latest_basic_dir_y == -1: return
	Player.handle_ladder_trigger_behaviour(true, is_bottom, layer_trigger_area, false, self)
