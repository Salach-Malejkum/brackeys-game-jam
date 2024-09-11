extends RigidBody3D

@export var speed: float = 300
@export var rotation_speed: float = 10
@export var camera_rotation_speed: float = 0.001
@export var force_limits: float = 150

var current_force_speed: float = 0
var target_rotation: Vector3
@onready var rotation_point: Node3D = $"Rotation point"
@onready var speed_effect: ColorRect = $"Rotation point/Camera3D/CanvasLayer/ColorRect"

func _ready():
	angular_damp = 0.8
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func add_to_current_force(force_to_add: float) -> void:
	current_force_speed += force_to_add
	current_force_speed = clamp(current_force_speed, -force_limits, force_limits / 2)


func apply_ship_rotation(side_movement: float) -> void:
	var rotation_dir = -side_movement
	apply_torque_impulse(global_transform.basis.y * rotation_speed * rotation_dir)


func camera_movement(rotation_dir: float) -> void:
	#if camera == null:
		#return
	
	rotation_point.rotate(Vector3.DOWN, camera_rotation_speed * rotation_dir)


func _input(event):
	if event is InputEventMouseMotion:
		camera_movement(event.relative.x)


func _integrate_forces(state):
	var input_vect: Vector2 = Input.get_vector("Left", "Right", "Up", "Down").normalized()
	
	var desired_move_direction = -global_transform.basis.z * input_vect.y
	add_to_current_force(input_vect.y)
	set_linear_velocity(-global_transform.basis.z * current_force_speed * speed)
	apply_ship_rotation(input_vect.x)


func _process(delta):
	print(current_force_speed)
	if abs(current_force_speed) > force_limits * 0.9:
		speed_effect.visible = true
	else:
		speed_effect.visible = false
