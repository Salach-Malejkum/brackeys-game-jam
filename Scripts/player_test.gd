extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@onready var cam_rotate = $CamRotate
@onready var head = $CamRotate/Head
@onready var camera = $CamRotate/Head/Camera3D
@onready var r_hand = $CamRotate/Head/Camera3D/RightHand

#head bob zajebany z tutoriala ale fajnie wyglada
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0


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
	if Input.is_action_pressed("fishing"):
		r_hand.translate(Vector3(0.0, 0.0, 0.1))
		r_hand.position.z = clamp(r_hand.position.z, 0.0, 1.0)
	elif Input.is_action_just_released("fishing"):
		pass # spawn zylki i splawika
	else:
		_smooth_rotate_r_hand(0.0)


func _smooth_rotate_r_hand(target_x : float):
	r_hand.position.z = lerp(r_hand.position.z, 0.0, 0.5)
