extends Node2D

@onready var triggerArea = $"Trigger Area"
@export var treeSprite : Node2D

var sprite_zindex = 40
const area_entered_zindex = 30
const area_exited_zindex = 50

func _ready():
	triggerArea.body_entered.connect(_on_trigger_area_body_entered)
	triggerArea.body_exited.connect(_on_trigger_area_body_exited)
	if treeSprite != null: treeSprite.z_index = sprite_zindex
	if treeSprite is AnimatedSprite2D:
		var anim_name = "Tree"
		if anim_name in treeSprite.sprite_frames.get_animation_names():
			treeSprite.play("Tree")

func body_invalid(body: Node2D):
	return not (body.is_in_group("Player") or body.is_in_group("Moving NPC"))

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body_invalid(body): return
	body.base_follower_zindex = area_entered_zindex
	body.layer_npc_areas += 1

func _on_trigger_area_body_exited(body: Node2D) -> void:
	if body_invalid(body): return
	body.layer_npc_areas -= 1
	if body.layer_npc_areas == 0:
		body.base_follower_zindex = area_exited_zindex
