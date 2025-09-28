extends CharacterBody2D

const speed = 90

@onready var movement_arrows = $"Leaf/Movement Arrows"
@onready var leaf_summon_root = get_parent().get_parent()
var lock_movement = true
var collectibles_collected = 0
var start_position_x : float

signal obtainted_collectible

func _ready() -> void:
	start_position_x = position.x
	obtainted_collectible.connect(on_obtainted_collectible)

func _physics_process(_delta):
	if lock_movement: return
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed
	if input_vector != Vector2.ZERO: movement_arrows.hide()
	move_and_slide()

func on_obtainted_collectible():
	create_tween().tween_property(leaf_summon_root.light, "scale", leaf_summon_root.light.scale * 1.75, 0.7)
	collectibles_collected += 1
	if collectibles_collected == 2:
		lock_movement = true
		await get_tree().create_timer(0.25).timeout
		var pos_dest = Vector2(start_position_x, leaf_summon_root.leaf_hover_y_anchor)
		var move_tween = create_tween().tween_property(self, "position", pos_dest, 1)
		move_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
