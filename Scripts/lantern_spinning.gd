extends Node3D

@onready var spin_me : MeshInstance3D = $Lantern;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass # Replace with function body.
	
func _on_timer_timeout() -> void:
	#spin_me.transform.rotated(Vector3(0, 1, 0), 20.0);
	spin_me.rotate_y(0.03);
	#print(spin_me.rotation_degrees);
