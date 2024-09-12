extends RigidBody3D

class_name Ship

@export var speed: float = 300
@export var rotation_speed: float = 10
@export var camera_rotation_speed: float = 0.001
@export var force_limits: float = 150

var current_force_speed: float = 0
var target_rotation: Vector3
var active: bool = false
var is_taken: bool = false
var players_in_range: Array = []
var player_in_control: Player = null
@onready var rotation_point: Node3D = $"Rotation point"
@onready var speed_effect: ColorRect = $"Rotation point/Camera3D/CanvasLayer/ColorRect"
@onready var camera: Camera3D = $"Rotation point/Camera3D"
@onready var capitan_pos: Marker3D = $Galleon/ShipControl/CapitanPos

func _ready():
	can_sleep = false
	angular_damp = 0.8
	axis_lock_angular_x = true
	axis_lock_angular_z = true

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GlobalVars.try_control_ship.connect(player_try_control_ship)
	GlobalVars.try_exit_control_ship.connect(player_try_exit_control_ship)


func add_to_current_force(force_to_add: float) -> void:
	current_force_speed += force_to_add
	current_force_speed = clamp(current_force_speed, -force_limits, force_limits / 2)


func apply_ship_rotation(side_movement: float) -> void:
	var rotation_dir = -side_movement
	apply_torque_impulse(global_transform.basis.y * rotation_speed * rotation_dir)


func camera_movement(rotation_dir: float) -> void:
	rotation_point.rotate(Vector3.DOWN, camera_rotation_speed * rotation_dir)


func _input(event):
	if not active:
		return
	else:
		camera.make_current()

	if event is InputEventMouseMotion:
		camera_movement(event.relative.x)


func _integrate_forces(state):
	var input_vect: Vector2 = Input.get_vector("Left", "Right", "Up", "Down").normalized()
	if not active:
		input_vect = Vector2.ZERO
		pass
	else:
		camera.make_current()
		
	var desired_velocity: Vector3 = -global_transform.basis.z * current_force_speed * speed
	
	add_to_current_force(input_vect.y)
	state.set_linear_velocity(desired_velocity)
	apply_ship_rotation(input_vect.x)
	


func _process(_delta):
	if not active:
		return
	else:
		camera.make_current()

	if abs(current_force_speed) > force_limits * 0.9:
		speed_effect.visible = true
	else:
		speed_effect.visible = false


func _on_area_3d_body_entered(body):
	if body is Player:
		GlobalVars.show_ship_control_text.emit()
		players_in_range.append(body)


func _on_area_3d_body_exited(body):
	if body is Player:
		GlobalVars.hide_ship_control_text.emit()
		players_in_range.erase(body)

func player_try_control_ship(player: Player):
	if player in players_in_range && !is_taken:
		player.global_position = capitan_pos.global_position
		active = true
		player.active = false
		is_taken = true
		player_in_control = player
		player.reparent(self)
		GlobalVars.show_exit_ship_control_text.emit()


func player_try_exit_control_ship(player: Player):
	if player == player_in_control:
		active = false
		player.active = true
		is_taken = false
		player_in_control = null
		player.reparent(get_parent())
