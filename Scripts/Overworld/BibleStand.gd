extends Node2D

@export var npcID: NPCData.ID

func _ready():
	if not NPCData.is_identifier_save_point(npcID): push_error("This npc's ID must be a 'SavePoint' identifier!")
	var has_bible_appearence_trigger = false
	for node in get_parent().get_children():
		if not node.has_meta("bible_appearence_trigger"): continue
		has_bible_appearence_trigger = true
		break
	if not has_bible_appearence_trigger: push_error("The save point doesn't have an appearence trigger!")
