extends Area2D

@export var audioStream : AudioStream
@export var maxDistance := 1000
@export var volume_multiplier := 1.0

var multiplier_before_disable : float

@onready var audioNode = $Audio

var collisionShapes : Array[CollisionShape2D] = []
var closest_shape = null

func _ready():
	get_collision_shapes()
	await get_tree().process_frame
	audioNode.stream = audioStream
	audioNode.play()
	LeafMode.game_over_triggered.connect(stop_audio)

func stop_audio():
	audioNode.stop()

func disable():
	multiplier_before_disable = volume_multiplier
	volume_multiplier = 0

func enable():
	volume_multiplier = multiplier_before_disable

func _process(_delta):
	var distance = get_audio_area_distance()
	var volume = clamp(1.0 - (distance / maxDistance), 0, 1) * volume_multiplier
	var used_volume = linear_to_db(volume)
	audioNode.volume_db = used_volume

func get_audio_area_distance():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Player"): return 0
	
	var closestDistance = INF
	for shape_node in collisionShapes:
		var shape = shape_node.shape
		if shape is not RectangleShape2D: continue
		var closest_point_dist = get_distance_between_player_and_closest_point(shape, shape_node.global_position, shape_node.global_scale)
		if closest_point_dist < closestDistance: closestDistance = closest_point_dist
	
	return closestDistance

func get_distance_between_player_and_closest_point(shape: RectangleShape2D, shapePos, shape_global_scale):
	var scaled_extents = shape.extents * shape_global_scale
	var top_left = shapePos - scaled_extents
	var down_right = shapePos + scaled_extents
	
	var playerPos = Player.get_global_pos()
	var closest_point = playerPos
	if closest_point.x < top_left.x: closest_point.x = top_left.x
	if closest_point.x > down_right.x: closest_point.x = down_right.x
	if closest_point.y < top_left.y: closest_point.y = top_left.y
	if closest_point.y > down_right.y: closest_point.y = down_right.y
	
	return playerPos.distance_to(closest_point)

func get_collision_shapes():
	collisionShapes = []
	for node in get_children():
		if node is CollisionShape2D:
			collisionShapes.append(node)

func _on_audio_finished():
	audioNode.play()
