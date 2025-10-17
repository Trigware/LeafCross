extends Node

enum AgentType {
	Uninitialized,
	PlayerAgent,
	FollowerAgent,
	CutsceneAgent,
	OverworldHazardAgent
}

enum AgentVariation {
	NoVariation,
	rabbitek,
	xdaforge,
	gertofin,
	ess,
	Nixie,
	Hedgehog
}

enum Chapter {
	WeirdForest
}

enum LeverColor {
	Red,
	Blue,
	Green,
	Yellow,
	Purple,
	Orange,
	Gray,
	White,
	Pink,
	ForestGreen
}

enum CaterpillarComponent {
	Head,
	Body,
	Tail
}

func get_component_name(component: CaterpillarComponent) -> String: return CaterpillarComponent.find_key(component)

const lever_colors : Dictionary[LeverColor, Color] = {
	LeverColor.Red: Color("D63636"),
	LeverColor.Blue: Color("24A4BD"),
	LeverColor.Green: Color("9AE861"),
	LeverColor.Yellow: Color("E0CF2F"),
	LeverColor.Purple: Color("6D13A1"),
	LeverColor.Orange: Color("F28E3D"),
	LeverColor.Gray: Color("737373"),
	LeverColor.White: Color("D6D6D6"),
	LeverColor.Pink: Color("C93AC7"),
	LeverColor.ForestGreen: Color("496B2F")
}


func get_lever_color_as_name(color): return LeverColor.find_key(color)
func get_lever_color_from_str(color: String) -> LeverColor:
	match color:
		"R": return LeverColor.Red
		"B": return LeverColor.Blue
		"Y": return LeverColor.Yellow
		"G": return LeverColor.Green
		"P": return LeverColor.Purple
		"O": return LeverColor.Orange
		"Gr": return LeverColor.Gray
		"W": return LeverColor.White
		"Pi": return LeverColor.Pink
		"Fo": return LeverColor.ForestGreen
	if color != "": push_error("Attempted to parse unknown laser/lever color '" + color + "'!")
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	return -1

var lever_colors_shortened = []

func _ready(): get_shortened_lever_colors()

func get_shortened_lever_colors():
	for color in LeverColor.keys():
		var color_str = str(color)
		var color_substr = ""
		for i in range(color_str.length()):
			color_substr += color_str[i]
			if not color_substr in lever_colors_shortened: break
		lever_colors_shortened.append(color_substr)
