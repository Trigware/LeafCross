extends Area2D

@onready var sprite = $Sprite
var laser_color: Enum.LeverColor
var laser_active := false

func _ready():
	sprite.play()
	sprite.modulate = Enum.lever_colors[laser_color]

func handle_pulling_of_lever(lever_dict):
	var turned_on_laser_v = turned_on_laser(lever_dict)
	sprite.play("on" if turned_on_laser_v else "off")

func turned_on_laser(lever_dict):
	var lever = lever_dict[laser_color]
	laser_active = lever.lever_on
	return laser_active

const electricution_final_y_destination = 50

func _on_body_entered(body):
	if not body.is_in_group("Player"): return
	if not laser_active: return
	Player.set_shader_material(UID.SHD_ELECTICUTION)
	Audio.play_sound(UID.SFX_ELECTRIC_SHOCK)
	CutsceneManager.action_lock = true
	var y_dir = Player.node.basic_direction.y
	var distance = (electricution_final_y_destination - position.y * -y_dir) * -y_dir
	print(distance)
	await MovingNPC.move_player_by(0, distance)
	Player.set_shader_material(UID.SHD_HIDE_SPRITE)
	CutsceneManager.action_lock = false
