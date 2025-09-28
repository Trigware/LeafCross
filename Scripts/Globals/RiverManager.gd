extends Area2D

@export var shallow_water : Area2D
@export var river_fail_point : Marker2D

const river_fail_return_duration = 0.75
const shallow_water_sink = 0.225
const image_pixel_height = 36.0

func _process(_delta):
	for body in get_overlapping_bodies(): if body.is_in_group("Player"):
		sink_underwater()
		return
	for body in shallow_water.get_overlapping_bodies(): if body.is_in_group("Player"):
		on_entering_shallow_water()
		return
	Player.go_outside_water()

func sink_underwater():
	if Player.is_sinking or Player.on_lilypad: return
	Player.sinked_times += 1
	Player.is_sinking = true
	create_tween().tween_property(Player.leafNode, "modulate:a", 0, 0.7).set_ease(Tween.EASE_IN_OUT)
	TextSystem.lockAction = true
	Audio.play_sound(UID.SFX_DEEP_WATER_SPLASH, 0.2, 5)
	
	player_river_damage()
	await sink_tween(1, 1.5)
	LeafMode.post_river_fail(river_fail_point)

func player_river_damage():
	await get_tree().create_timer(1).timeout
	LeafMode.modify_hp_with_id(LeafMode.HPChangeID.SinkUnderwater)

func sink_tween(final, duration):
	var sink_tween_v = create_tween()
	sink_tween_v.tween_method(
		func(val):
			Player.set_uniform("hide_progression", val + 0.01),
		Player.get_uniform("hide_progression"),
		final,
		duration
	).set_ease(Tween.EASE_IN_OUT)
	await sink_tween_v.finished

func on_entering_shallow_water():
	if Player.in_water or Player.on_lilypad: return
	Effects.effect_end(Effects.ID.Burning)
	Player.in_water = true
	Player.set_uniform("hide_progression", shallow_water_sink)
	Player.leafNode.position.y += shallow_water_sink * image_pixel_height
	Audio.play_sound(UID.SFX_SHALLOW_WATER_SPLASH, 0.2, 5)
