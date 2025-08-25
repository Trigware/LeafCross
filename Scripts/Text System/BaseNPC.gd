extends Area2D

@export var npcID := NPCData.ID.Uninitialized
@export var item := Inventory.Item.NONE
@export var itemCount := 1
@export var itemColor := Color.YELLOW
@export var removeStaticBody := false
@export var autoTrigger := false
@export var deleteAfterTalk := false
@export var ignoreDirections := false
@export var disable_placeholder_interactions := false
@export var deactivated_at_start := false
@export var save_menu := false
@export var override_id_from_parent := false
@export var set_only_at_start := false

@onready var triggerZone = $"Trigger Zone"

var interactionCount := 0
var textID := ""

var padestalTexts := [NPCData.ID.Pedestal_SPAWN_ENTERANCE]

func _ready():
	await get_tree().process_frame
	if override_id_from_parent:
		override_id_from_parent_fn()
	
	if npcID == NPCData.ID.Uninitialized:
		push_error("NPC ID is not initiliazed!")
		return
	if deactivated_at_start:
		NPCData.set_data(npcID, NPCData.Field.Deactivated, true)
	textID = NPCData.get_id_name(npcID)
	var isNPCDeleted = NPCData.get_data(npcID, NPCData.Field.Deleted)
	if isNPCDeleted: queue_free()
	if set_only_at_start:
		NPCData.set_data(npcID, NPCData.Field.OnlyInteraction, true)
	
	remove_static_body()
	get_suffix(1)

func override_id_from_parent_fn():
	var parent = get_parent()
	if parent == null: return
	if parent.has_meta("npc_id"):
		var strID = parent.get_meta("npc_id")
		npcID = NPCData.convert_string_to_id(strID)
		return
	
	var parent_properties = get_property_list()
	for property in parent_properties:
		var prop_name = property.name
		if prop_name == "npcID":
			npcID = parent.npcID
			return
	push_error("Parent has no NPC ID metadata or property!")

func remove_static_body():
	if not removeStaticBody: return
	var possible_static_bodies = ["Static Body", "Layered Manager/Static Body"]
	for static_body_name in possible_static_bodies:
		if has_node(static_body_name):
			get_node(static_body_name).queue_free()

func _process(_delta):
	if (not Input.is_action_just_pressed("continue") and not autoTrigger) or not TextSystem.canInteract: return
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Player"):
			interact_with_npc()
			return

func interact_with_npc():
	var deactivated = NPCData.get_data(npcID, NPCData.Field.Deactivated)
	if deactivated: return
	if TextSystem.lockAction or SaveMenu.menu_openned or Player.inputless_movement or CutsceneManager.action_lock: return
	if not is_player_looking_towards_npc(): return
	
	if autoTrigger:
		NPCData.set_data(npcID, NPCData.Field.Deactivated, true)
	
	interactionCount = NPCData.get_incremented_data(npcID, NPCData.Field.InteractionCount)
	TextSystem.canInteract = false
	
	var base_key = textID
	var suffix = get_suffix(interactionCount)
	
	if suffix != null: await TextMethods.print_sequence(base_key, {}, PresetSystem.Preset.Fallback, suffix)
	else: await TextMethods.print_wait_localization("npc_outofinteract", {}, PresetSystem.Preset.Fallback)
	
	if item != Inventory.Item.NONE:
		await Inventory.ask_to_get_item(Inventory.Item.GLOWING_MUSHROOM, itemCount, self, npcID, itemColor)
	
	await after_base_dialog_complete()
	NPCData.end_npc_dialog(npcID, self, deleteAfterTalk)
	if save_menu:
		SaveMenu.on_menu_open()

func get_suffix(interaction_count):
	var base_key = textID
	var suffix = str(interaction_count)
	var npc_only_property = NPCData.get_data(npcID, NPCData.Field.OnlyInteraction)
	var npc_suffix_property = NPCData.get_data(npcID, NPCData.Field.Suffix)
	if npc_only_property or npc_suffix_property != null:
		suffix = npc_suffix_property if npc_suffix_property != null else "only"
		var suffixed_text_key = TextMethods.add_suffix_to_key(base_key, suffix)
		if not Localization.does_suffixed_key_exist(suffixed_text_key): push_error("NPC with id " + textID + " requests a missing the '" + suffix + "' suffix!")
		return suffix
	
	var first_text = TextMethods.get_indexed_key(base_key, suffix)
	var first_text_exists = Localization.text_exists(first_text)
	if first_text_exists: return suffix
	suffix = "outofinteract"
	
	var placeholder_text = TextMethods.add_suffix_to_key(base_key, suffix)
	if suffixed_key_exists(placeholder_text): return suffix
	if interactionCount == 1:
		push_error("An associated start text key on npc with id " + textID + " doesn't exist! (first_text: " + first_text + ", placeholder_text: " + placeholder_text + ")")

func suffixed_key_exists(suffixed_key):
	return Localization.text_exists(suffixed_key) or Localization.text_exists(suffixed_key + TextMethods.suffix_seperator_character + "1")

func is_player_looking_towards_npc() -> bool:
	if autoTrigger or removeStaticBody or ignoreDirections: return true
	var playerPos : Vector2 = Player.get_body_pos()
	var npcPos : Vector2 = triggerZone.global_position
	var playerDir = Player.node.stringAnimation
	
	match playerDir:
		"Left": return playerPos.x > npcPos.x
		"Right": return playerPos.x < npcPos.x
		"Up": return playerPos.y > npcPos.y
		_: return playerPos.y < npcPos.y

func after_base_dialog_complete():
	if npcID in padestalTexts:
		await ChoicerSystem.give_basic_choice()
		if ChoicerSystem.is_player_choice("decline"): return
		await TextMethods.print_wait_localization("PedestalText_intro", [SaveData.playerName])
		var text_template_part = "PedestalText__" + SaveData.selectedCharacter + "#"
		await TextMethods.print_group(
			[text_template_part + "1",
			text_template_part + "2",
			"PedestalText_end"]
		)
		return
	if NPCData.is_identifier_save_point(npcID):
		var final_text_key = "SavePoint_end"
		if not SaveData.save_choice_seen:
			final_text_key = "SavePoint_end_first_time"
		await TextMethods.print_wait_localization(final_text_key)
		return
	if npcID == NPCData.ID.BibleInteractPrompt_SAVEINTROROOM:
		await MovingNPC.move_player_by(-100)
		NPCData.set_data(npcID, NPCData.Field.Deactivated, false)
		return
