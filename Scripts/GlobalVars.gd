extends Node

@export var sensitivity = 0.005

signal show_ship_control_text
signal hide_ship_control_text
signal show_exit_ship_control_text
signal show_fix_the_hole_text
signal try_control_ship(player: Player)
signal try_exit_control_ship(player: Player)
signal start_repair(hole: Hole)
signal repair_interrupted(hole: Hole)
signal hole_fixed_signal_back(player: Player)
