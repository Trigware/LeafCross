extends Area2D

func _on_body_entered(body: Node2D):
	if not body.is_in_group("Player"): return
	Player.time_spend_not_walking = 0.0
	Player.tween_value(0.7)
	LeafMode.tween_light(0.65)
	Player.tween_color(Color.LIGHT_GREEN)
	Player.tween_light_energy(1.5)
	Player.tween_leaf_alpha(1)
	LeafMode.tween_ui(LeafMode.stamina_ui_show_x)
	await get_tree().create_timer(0.1).timeout
	Audio.play_sound(UID.SFX_LEAF_MODE_ENTER, 0.2)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"): return
	LeafMode.hide_health_ui()
	Player.tween_value(1)
	Player.tween_color(Color.WHITE)
	LeafMode.tween_light(0)
	LeafMode.tween_ui(LeafMode.stamina_ui_hide_x)
	Player.tween_light_energy(0)
	if not LeafMode.game_over: Player.tween_leaf_alpha(0)
