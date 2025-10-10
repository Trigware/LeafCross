extends Area2D

@export var layer_trigger_area: Area2D
@export var is_bottom: bool

func _on_body_entered(body):
	if not body.is_in_group("Player") or Player.node.latest_basic_dir_y == 1: return
	handle_ladder_trigger_behaviour(false)

func _on_body_exited(body):
	if not body.is_in_group("Player") or Player.node.latest_basic_dir_y == -1: return
	handle_ladder_trigger_behaviour(true)

func handle_ladder_trigger_behaviour(exiting):
	Player.climbing_ladder = not exiting
	if not is_bottom:
		handle_top_behaviour()
		return
	var ladder_index = get_parent().get_meta("ladder_index")
	Player.climbing_ladder_index = get_parent().get_meta("ladder_parent_index") if exiting else ladder_index
	
	Player.update_animation("walk_down" if exiting else "climb")
	if not exiting or Player.climbing_ladder_index == -1:
		Player.body.set_collision_mask_value(4, exiting)
		Player.body.set_collision_mask_value(5, not exiting)
	layer_trigger_area.monitoring = exiting

func handle_top_behaviour():
	Player.climbing_ladder = not Player.climbing_ladder
	Player.update_animation(Player.node.get_animation_name())
