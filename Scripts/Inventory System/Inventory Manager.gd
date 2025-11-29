extends Node

enum Item
{
	NONE,
	GLOWING_MUSHROOM
}

enum ItemTier
{
	KEY
}

var ItemClassifications : Dictionary[Item, ItemTier] = {
	Item.GLOWING_MUSHROOM: ItemTier.KEY
}

func get_item_tier(item: Item) -> String:
	return ItemTier.find_key(ItemClassifications[item])

func get_item_name(item: Item) -> String:
	return Localization.get_text("itemname_" + get_item_enum(item))

func get_item_enum(item: Item) -> String:
	return Item.find_key(item)

func add_item(item: Item, count: int):
	var enumName = get_item_enum(item)
	if not SaveData.PlayerInventory.has(enumName): SaveData.PlayerInventory[enumName] = 0
	SaveData.PlayerInventory[enumName] += count

func has_item(item: Item, count_over = 0):
	var item_name = get_item_enum(item)
	if not item_name in SaveData.PlayerInventory: return false
	return SaveData.PlayerInventory[item_name] > count_over

func ask_to_get_item(
		item: Item,
		count := 1,
		npcNode: Node = null,
		npcID: NPCData.ID = NPCData.ID.Uninitialized,
		color: Color = Color.YELLOW):

	var item_name = get_item_name(item)
	var color_control = "{#" + color.to_html() + "}"
	var colored_item_text = color_control + item_name + "{#/}"
	await TextMethods.print_wait_localization("item_choice_pickup", {"item": colored_item_text})
	
	await ChoicerSystem.give_basic_choice()
	if ChoicerSystem.is_player_choice("decline"):
		var text_key = "item_decline_" + get_item_enum(item)
		await TextMethods.print_sequence(text_key)
		return
	
	var item_tier = get_item_tier(item)
	var item_count_str = ""
	if count > 1: item_count_str = " (" + str(count) + "x)"
	await TextMethods.print_wait_localization("item_confirm_pickup_" + item_tier, {"item": colored_item_text, "count": item_count_str})
	add_item(item, count)
	Audio.play_sound(UID.SFX_ITEM_OBTAINED)
	
	if npcNode != null:
		npcNode.queue_free()
		NPCData.set_data(npcID, NPCData.Field.Deleted, true)
	after_obtainted_item(item)

func after_obtainted_item(item):
	match item:
		Inventory.Item.GLOWING_MUSHROOM:
			NPCData.set_data(NPCData.ID.BlockTree_SPAWNROOM, NPCData.Field.Suffix, "NoLight")
			NPCData.set_data(NPCData.ID.BlockTree_SPAWNROOM, NPCData.Field.InteractionCount, 0)
