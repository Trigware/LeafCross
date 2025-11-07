extends Node

var fallback := Preset.Fallback

enum Preset
{
	Fallback,
	LegendSmallPanel,
	LegendBigPanel,
	ChooseCharacter,
	RegularDialog,
	OverworldTreeTalk,
	GameOver,
	FirstGameOver,
	TreeTextCutoff
}

enum Property
{
	VectorPosition,
	PositionX,
	PositionY,
	LineLength,
	Speed,
	AllowTextSkip,
	CenterAlign,
	TalkAudio,
	PitchRange,
	OverlapAudio,
	FontSize,
	Textbox,
	Outline,
	InitialColor,
	EndAutomatically,
	EndExternally
}

@onready var TextConfigurations = {
	Preset.LegendSmallPanel: {
		Property.PositionX: 255,
		Property.PositionY: 350,
		Property.LineLength: 650,
		Property.Speed: 0.08,
		Property.AllowTextSkip: false
	},
	Preset.ChooseCharacter: {
		Property.PositionX: 255,
		Property.PositionY: 590,
		Property.CenterAlign: true,
		Property.TalkAudio: UID.TALK_WMT,
		Property.PitchRange: 0.2,
		Property.Speed: 0.05,
		Property.OverlapAudio: true
	},
	Preset.RegularDialog: {
		Property.TalkAudio: UID.TALK_DEFAULT,
		Property.PitchRange: 0.15,
		Property.FontSize: 44,
		Property.Textbox: true,
		Property.PositionX: 105,
		Property.PositionY: 465,
		Property.LineLength: 950
	}
}

func preset_variations():
	add_variation(Preset.OverworldTreeTalk, Preset.ChooseCharacter, {
		Property.PositionY: 525
	})
	add_variation(Preset.LegendBigPanel, Preset.LegendSmallPanel, {
		Property.PositionY: 540
	})
	add_variation(Preset.GameOver, Preset.ChooseCharacter, {
		Property.VectorPosition: Vector2(150, 350),
		Property.Outline: true,
		Property.InitialColor: Color.WEB_GRAY,
		Property.FontSize: 54,
		Property.LineLength: 850
	})
	add_variation(Preset.FirstGameOver, Preset.GameOver, {
		Property.LineLength: 0
	})
	add_variation(Preset.TreeTextCutoff, Preset.OverworldTreeTalk, {
		Property.EndExternally: true
	})

func add_variation(stored_as: Preset, from: Preset, deltas: Dictionary):
	if stored_as in TextConfigurations:
		push_error("Preset already in the configurations dictionary!")
		return
	if not from in TextConfigurations:
		push_error("There is not a preset currently loaded to variate!")
		return
	var preset_dict = TextConfigurations[from].duplicate(true) # prevents it from storing a reference
	for property in deltas.keys():
		var value = deltas[property]
		preset_dict[property] = value
	TextConfigurations[stored_as] = preset_dict

func get_preset_name(preset_member: Preset):
	return Preset.find_key(preset_member)

func get_preset_property(preset: Preset, property: Property):
	if not preset in TextConfigurations:
		var preset_name = get_preset_name(preset)
		push_error("Given preset '" + preset_name + "' was not properly configured!")
		return
	var preset_data = TextConfigurations[preset]
	
	match property:
		Property.Speed: return preset_data.get(Property.Speed, 1.0/25)
		Property.FontSize: return preset_data.get(Property.FontSize, 48)
		Property.VectorPosition: return get_text_position(preset, preset_data)
		Property.PositionX: return preset_data.get(Property.PositionX, 0)
		Property.PositionY: return preset_data.get(Property.PositionY, 0)
		Property.LineLength: return preset_data.get(Property.LineLength, 0)
		Property.CenterAlign: return preset_data.get(Property.CenterAlign, false)
		Property.AllowTextSkip: return preset_data.get(Property.AllowTextSkip, true)
		Property.TalkAudio: return preset_data.get(Property.TalkAudio, null)
		Property.PitchRange: return preset_data.get(Property.PitchRange, 0)
		Property.Textbox: return preset_data.get(Property.Textbox, false)
		Property.OverlapAudio: return preset_data.get(Property.OverlapAudio, false)
		Property.Outline: return preset_data.get(Property.Outline, false)
		Property.InitialColor: return preset_data.get(Property.InitialColor, "#FFFFFF")
		Property.EndAutomatically: return preset_data.get(Property.EndAutomatically, false)
		Property.EndExternally: return preset_data.get(Property.EndExternally, false)

func get_text_position(preset: Preset, preset_data):
	if Property.VectorPosition in preset_data: return preset_data.get(Property.VectorPosition)
	return Vector2(get_preset_property(preset, Property.PositionX), get_preset_property(preset, Property.PositionY))

func print_preset(text, preset := Preset.Fallback, variables := {}):
	if preset == Preset.Fallback:
		preset = fallback
	
	TextSystem.print_text(
		text,
		get_preset_property(preset, Property.Speed),
		get_preset_property(preset, Property.FontSize),
		get_preset_property(preset, Property.VectorPosition),
		get_preset_property(preset, Property.LineLength),
		get_preset_property(preset, Property.CenterAlign),
		get_preset_property(preset, Property.AllowTextSkip),
		get_preset_property(preset, Property.TalkAudio),
		get_preset_property(preset, Property.PitchRange),
		get_preset_property(preset, Property.Textbox),
		get_preset_property(preset, Property.OverlapAudio),
		get_preset_property(preset, Property.Outline),
		get_preset_property(preset, Property.InitialColor),
		get_preset_property(preset, Property.EndAutomatically),
		get_preset_property(preset, Property.EndExternally),
		variables
	)
