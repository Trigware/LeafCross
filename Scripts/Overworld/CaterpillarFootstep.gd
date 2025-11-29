extends Sprite2D

@export var direction: Vector3
@export var direction_changed := false
const vector_directions : Dictionary[Vector2, Vector2] = {Vector2.LEFT: Vector2(0, 1), Vector2.RIGHT: Vector2(0, 1), Vector2.DOWN: Vector2(1, 0), Vector2.UP: Vector2(1, 0)}
const changing_direction_rotation : Dictionary[Vector3, float] = {Vector3(1, -1, -1): 0, Vector3(1, 1, 1): 90, Vector3(1, 1, -1): 270, Vector3(1, -1, 1): 180}

func _ready():
	var footstep_coords: Vector2 
	var pure_direction = Vector2(direction.x, direction.y)
	if pure_direction in vector_directions: footstep_coords = vector_directions[pure_direction]
	else:
		footstep_coords = Vector2.ONE
		if not direction in changing_direction_rotation: direction = -direction
		var direction_in_degrees = changing_direction_rotation[direction]
		rotation = deg_to_rad(direction_in_degrees)
	frame_coords = footstep_coords
