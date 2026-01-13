extends Area2D

@export var shallow_water : Area2D
@export var river_fail_point : Marker2D

const river_fail_return_duration = 0.75

func _process(_delta):
	for body in get_overlapping_bodies(): if body.is_in_group("Player"):
		sink_underwater()
		return
	for body in shallow_water.get_overlapping_bodies(): if body.is_in_group("Player"):
		Player.on_entering_shallow_water()
		return
	Player.go_outside_water()

func sink_underwater():
	if Player.is_sinking or Player.on_lilypad or not Player.in_water: return
	Player.start_to_sink(river_fail_point)
