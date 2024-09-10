extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var cam_rotate = $CamRotate
@onready var head = $CamRotate/Head
@onready var camera = $CamRotate/Head/Camera3D
@onready var r_hand = $CamRotate/Head/Camera3D/RightHand

@onready var spear_model = $CamRotate/Head/Camera3D/RightHand/Spear

#head bob zajebany z tutoriala ale fajnie wyglada
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0

var spear_packaged = preload("res://Scenes/Rigidbodies/Spear.tscn")
var thrown_spear_instance : RigidBody3D = null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cam_rotate.rotate_y(-event.relative.x * GlobalVars.sensitivity)
		camera.rotate_x(-event.relative.y * GlobalVars.sensitivity)
		
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction = (cam_rotate.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
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
		r_hand.translate(Vector3(0.0, 0.0, 0.1))
		r_hand.position.z = clamp(r_hand.position.z, 0.0, 1.0)
		camera.fov += 1
		camera.fov = clamp(camera.fov, 90, 100)
	elif Input.is_action_just_released("fishing"):
		if not is_instance_valid(thrown_spear_instance):
			spear_model.visible = false
			thrown_spear_instance = spear_packaged.instantiate()
			thrown_spear_instance.position = r_hand.global_position
			thrown_spear_instance.transform.basis = r_hand.global_transform.basis
			thrown_spear_instance.throw_speed *= r_hand.position.z
			get_parent().add_child(thrown_spear_instance)
	else:
		_smooth_back(0.0)


func _smooth_back(target_x : float):
	r_hand.position.z = lerp(r_hand.position.z, 0.0, 0.5)
	camera.fov = lerpf(camera.fov, 90, 0.5)
