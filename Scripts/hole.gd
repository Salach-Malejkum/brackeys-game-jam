extends Node3D

class_name Hole

@export var time_to_fix: float = 3.0

var fixing_time: float = 0.0
var is_fixing: bool = false
var is_locked_by_player: bool = false
var curr_player: Player = null

func _ready():
	GlobalVars.start_repair.connect(repairing)
	GlobalVars.repair_interrupted.connect(repairing_interrupted)


func repairing(hole: Hole, player: Player):
	if hole != self:
		return
	
	curr_player = player
	is_fixing = true
	print("Working...", name)
	

func repairing_interrupted(hole: Hole):
	if hole != self:
		return
	
	curr_player = null
	is_fixing = false
	print("Interrupted...", name)


func _process(delta):
	if is_fixing && fixing_time > time_to_fix:
		GlobalVars.hole_fixed_signal_back.emit(curr_player)
		self.queue_free()
	elif is_fixing:
		fixing_time += delta
	else:
		fixing_time = 0.0
