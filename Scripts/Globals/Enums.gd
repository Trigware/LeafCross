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
	Orange
}

const lever_colors : Dictionary[Enum.LeverColor, Color] = {
	LeverColor.Red: Color("D63636"),
	LeverColor.Blue: Color("24A4BD"),
	LeverColor.Green: Color("24BD2E"),
	LeverColor.Yellow: Color("E0CF2F"),
	LeverColor.Purple: Color("A103FC"),
	LeverColor.Orange: Color("F28E3D")
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
	if color != "": push_error("Attempted to parse unknown laser/lever color '" + color + "'!")
	@warning_ignore("int_as_enum_without_cast", "int_as_enum_without_match")
	return -1
