extends CharacterBody3D
class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var cam_rotate = $CamRotate
@onready var head = $CamRotate/Head
@onready var camera = $CamRotate/Head/Camera3D
@onready var r_hand = $CamRotate/Head/Camera3D/RightHand
@onready var d_hit = $DebugHit
@onready var clip_cam = $CamRotate/Head/Camera3D/SubViewportContainer/SubViewport/Camera3D
@onready var spear_model = $CamRotate/Head/Camera3D/RightHand/Spear
@onready var raycast = $CamRotate/Head/RayCast3D
@onready var control_text = $PlayerUI/LineEdit
@onready var ship = $".."

#head bob zajebany z tutoriala ale fajnie wyglada
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

@export var spear_gravity_scale = 1.0
@export var spear_mass = 1.0
@export var spear_prediction_v_multiplier = 15.5
var spear_packaged = preload("res://Scenes/Rigidbodies/Spear.tscn")
var thrown_spear_instance : RigidBody3D = null
var active = true

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GlobalVars.show_ship_control_text.connect(show_ship_control_text)
	GlobalVars.hide_ship_control_text.connect(hide_ship_control_text)
	GlobalVars.show_exit_ship_control_text.connect(show_ship_exit_control_text)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	else:
		camera.make_current()
		
	if event is InputEventMouseMotion:
		cam_rotate.rotate_y(-event.relative.x * GlobalVars.sensitivity)
		camera.rotate_x(-event.relative.y * GlobalVars.sensitivity)
		raycast.rotate_x(-event.relative.y * GlobalVars.sensitivity)
		
		raycast.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _process(_delta: float) -> void:
	clip_cam.global_transform = camera.global_transform
	position.x = snapped(position.x, 0.01)
	position.z = snapped(position.z, 0.01)
	
	if Input.is_action_just_pressed("E"):
		print("E")
		handle_ship_control()


func handle_ship_control():
	if active:
		GlobalVars.try_control_ship.emit(self)
	else:
		GlobalVars.try_exit_control_ship.emit(self)


func _physics_process(delta: float) -> void:
	physics_interpolation_mode
	if not active:
		return
	else:
		camera.make_current()
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
	var direction = (cam_rotate.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = (direction.x * SPEED - ship.linear_velocity.x)
		velocity.z = (direction.z * SPEED - ship.linear_velocity.z)
	else:
		velocity.x = -ship.linear_velocity.x
		velocity.z = -ship.linear_velocity.z

	print(velocity)
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	raycast.transform.origin = camera.transform.origin
	
	if raycast.is_colliding():
		pass
	
	move_and_slide()
	
	_fishing_throw()


func _headbob(time):
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func _fishing_throw():
	if Input.is_action_just_pressed("fishing") and is_instance_valid(thrown_spear_instance):
		thrown_spear_instance.queue_free()
		spear_model.visible = true
	if Input.is_action_pressed("fishing") and not is_instance_valid(thrown_spear_instance):
		d_hit.visible = true
		r_hand.translate(Vector3(0.0, 0.0, 0.025))
		r_hand.position.z = clamp(r_hand.position.z, 0.0, 1.0)
		#camera.fov += 1
		#camera.fov = clamp(camera.fov, 90, 100)
		_draw_aim(spear_mass, spear_gravity_scale)
	elif Input.is_action_just_released("fishing"):
		if not is_instance_valid(thrown_spear_instance):
			spear_model.visible = false
			thrown_spear_instance = spear_packaged.instantiate()
			thrown_spear_instance.mass = spear_mass
			thrown_spear_instance.gravity_scale = spear_gravity_scale
			thrown_spear_instance.player_owner = self
			thrown_spear_instance.position = r_hand.global_position
			thrown_spear_instance.transform.basis = r_hand.global_transform.basis
			thrown_spear_instance.throw_speed *= r_hand.position.z
			get_parent().add_child(thrown_spear_instance)
	else:
		d_hit.visible = false
		_smooth_back(0.0)


func _smooth_back(_target_x : float):
	r_hand.position.z = lerp(r_hand.position.z, 0.0, 0.5)
	#camera.fov = lerpf(camera.fov, 90, 0.5)


func _draw_aim(_mass, gravity_scale):
	var d_velocity = -r_hand.global_transform.basis.z as Vector3
	d_velocity *= spear_prediction_v_multiplier * r_hand.position.z # za chuja nie wiem czy ta wartosc jest idealna, nie wiem jak to wyliczyc, dziala to dziala
	
	var t_step := 0.01
	var start_pos = r_hand.global_position
	var d_gravity = -ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	d_gravity *= gravity_scale
	var drag = ProjectSettings.get_setting("physics/3d/default_linear_damp", 0.0)
	
	var line_start = start_pos
	var line_end = start_pos
	
	for i in range(1, 200):
		d_velocity.y += d_gravity * t_step
		line_end = line_start
		line_end += d_velocity * t_step
		
		d_velocity *= clampf(1.0 - drag * t_step, 0, 1)
		
		var ray = _raycast_query(line_start, line_end)
		if not ray.is_empty():
			d_hit.global_position = ray["position"]
		
		line_start = line_end

func _raycast_query(pointA, pointB) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pointA, pointB, 1<<0)
	query.hit_from_inside = false
	var result = space_state.intersect_ray(query)
	return result


func show_ship_control_text():
	control_text.text = "Press E to control the ship"
	control_text.visible = true


func hide_ship_control_text():
	control_text.visible = false


func show_ship_exit_control_text():
	control_text.text = "Press E to exit the control of the ship"
	control_text.visible = true
	
