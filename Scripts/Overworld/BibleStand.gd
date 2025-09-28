extends Node2D

@export var npcID: NPCData.ID

func _ready():
	if not NPCData.is_identifier_save_point(npcID):
		push_error("This npc's ID must be a 'SavePoint' identifier!")
