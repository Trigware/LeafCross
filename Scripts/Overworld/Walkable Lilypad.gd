extends Area2D

const fade_speed = 5
const respawn_duration = 3
const shake = 1.5
const shake_tween_duration = 0.1

@onready var scale_avg = (scale.x+scale.y) / 2
@onready var tween_duration = scale_avg / fade_speed
@onready var light = $Light

var sinking = false
var disabled = true

signal lilypad_exited

func _ready():
	await get_tree().create_timer(0.1).timeout
	disabled = false

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player") or disabled: return
	emit_signal("lilypad_exited")
	Player.lilypad_overlaps -= 1
	if Player.lilypad_overlaps >= 1: return
	Player.on_lilypad = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player") or disabled: return
	Player.lilypad_overlaps += 1
	if sinking: return
	Player.on_lilypad = true
	Player.go_outside_water(true)
	sinking = true
	Audio.play_sound(UID.SFX_LILYPAD_DISAPPEAR, 0.4, scale_avg / 2)
	await move_cyclic()
	await tween_lilypad(0)
	sinking = false
	monitoring = false
	await get_tree().create_timer(respawn_duration).timeout
	regenerate_lilypad()

func tween_lilypad(final):
	create_tween().tween_property(light, "energy", final, tween_duration).set_ease(Tween.EASE_IN_OUT)
	var tween_alpha = create_tween().tween_property(self, "modulate:a", final, tween_duration).set_ease(Tween.EASE_IN_OUT)
	await tween_alpha.finished

func regenerate_lilypad():
	tween_lilypad(1)
	monitoring = true

func move_cyclic():
	var original_pos = position
	for i in range(6):
		var tween_move = create_tween()
		var multiplier = 1
		var used_duration = max(shake_tween_duration - i * 0.02, 0.06)
		if i % 2 == 0: multiplier = -1
		tween_move.tween_property(self, "position", original_pos + Vector2(shake, shake) * multiplier * (i + 1), used_duration)
		await tween_move.finished
		var tween_back_to_orig = create_tween()
		tween_back_to_orig.tween_property(self, "position", original_pos, used_duration)
		await tween_back_to_orig.finished
