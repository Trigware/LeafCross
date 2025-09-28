extends Area2D

var starting_position : Vector2
const x_final_offset = 22
var obtaining_collectable_disabled = false

@onready var leafNode = get_parent().get_parent().get_node("CanvasLayer/Leaf Body")

func _ready():
	starting_position = position
	var direction = 1
	while true:
		var final_x_dest = starting_position.x + x_final_offset * direction
		var move_tween = create_tween().tween_property(self, "position:x", final_x_dest, 0.8)
		move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
		await move_tween.finished
		direction *= -1

func _on_body_entered(body: Node2D):
	if not body.is_in_group("Player"): return
	if leafNode.lock_movement or obtaining_collectable_disabled: return
	Audio.play_sound(UID.SFX_PLAYER_HEAL, 0.2)
	var alpha_tween = create_tween().tween_property(self, "modulate:a", 0, 0.35)
	obtaining_collectable_disabled = true
	await alpha_tween.finished
	queue_free()
	leafNode.emit_signal("obtainted_collectible")
