extends Node

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"): return
	Player.in_leaves = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"): return
	Player.in_leaves = false
