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
@onready var raycast = $CamRotate/Head/RayCast3D
@onready var control_text = $PlayerUI/LineEdit
@onready var fixing_bar = $"PlayerUI/Fixing Progress"
@onready var ship = $"../Ship"
@onready var pickup_hint = $PlayerUI/PickupLabel

#eq slots
@onready var spear_model = $CamRotate/Head/Camera3D/RightHand/Spear
@onready var axe_model = $CamRotate/Head/Camera3D/RightHand/Axe
@onready var blunderbuss_model = $CamRotate/Head/Camera3D/RightHand/Blunderbussy

@onready var left_hand = $CamRotate/Head/Camera3D/LeftHand
var holding_item : String = ""

var throwable = {
	"Bottle": preload("res://Scenes/Rigidbodies/BottleBody.tscn"),
	"Bucket": preload("res://Scenes/Rigidbodies/BucketBody.tscn"),
	"Axe": preload("res://Scenes/Rigidbodies/AxeBody.tscn"),
	"Barrel": preload("res://Scenes/Rigidbodies/BarrelBody.tscn"),
	"Chest": preload("res://Scenes/Rigidbodies/ChestBody.tscn"),
	"Wood": preload("res://Scenes/Rigidbodies/WoodBody.tscn"),
}

#eq animations
@onready var axe_anim = $CamRotate/Head/Camera3D/RightHand/Axe/AnimationPlayer
@onready var blunderbuss_anim = $CamRotate/Head/Camera3D/RightHand/Blunderbussy/AnimationPlayer

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
var eq_item_selected = 1
var last_ray_cast_collider: Hole = null

var has_axe = false
var has_weapon = false


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GlobalVars.show_ship_control_text.connect(show_ship_control_text)
	GlobalVars.hide_ship_control_text.connect(hide_ship_control_text)
	GlobalVars.show_exit_ship_control_text.connect(show_ship_exit_control_text)
	GlobalVars.show_fix_the_hole_text.connect(show_fix_the_hole_text)
	GlobalVars.hole_fixed_signal_back.connect(hole_fixed_message_back)
	
	fixing_bar.max_value = GlobalVars.time_to_fix_hole


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
	elif Input.is_action_just_pressed("EqSlot1"):
		_models_turn_visibility(1)
	elif Input.is_action_just_pressed("EqSlot2") and has_axe:
		_models_turn_visibility(2)
	elif Input.is_action_just_pressed("EqSlot3") and has_weapon:
		_models_turn_visibility(3)
	elif Input.is_action_just_pressed("E"):
		_item_pickup(raycast.get_collider())
	elif Input.is_action_just_pressed("drop"):
		_throw_item()


func _models_turn_visibility(toggle_id):
	spear_model.visible = false if toggle_id != 1 else true
	axe_model.visible = false if toggle_id != 2 else true
	blunderbuss_model.visible = false if toggle_id != 3 else true
	
	eq_item_selected = toggle_id


func _process(_delta: float) -> void:
	clip_cam.global_transform = camera.global_transform
	
	if Input.is_action_just_pressed("E"):
		print("E")
		handle_ship_control()
		
	handle_fixing_signals()


func handle_fixing_signals():
	if last_ray_cast_collider != null && Input.is_action_just_pressed("Fix"):
		print("F")
		GlobalVars.start_repair.emit(last_ray_cast_collider, self)
		fixing_bar.show()
	elif last_ray_cast_collider != null && Input.is_action_just_released("Fix"):
		print("F gone")
		GlobalVars.repair_interrupted.emit(last_ray_cast_collider)
		fixing_bar.hide()
		fixing_bar.value = 0


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
		velocity.x = (direction.x * SPEED)
		velocity.z = (direction.z * SPEED)
	else:
		velocity.x = 0
		velocity.z = 0
	
	
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	raycast.transform.origin = camera.transform.origin
	
	if raycast.get_collider() is Item:
		pickup_hint.visible = true
	else:
		pickup_hint.visible = false
	
	handle_holes(raycast.get_collider())
	
	move_and_slide()
	
	if eq_item_selected == 1: #spear
		_fishing_throw()
	elif eq_item_selected == 2: #spear
		_handle_axe()
	elif eq_item_selected == 3: #spear
		_handle_shoot()


func _headbob(time):
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func _handle_axe():
	if Input.is_action_just_pressed("fishing") and not axe_anim.is_playing():
		axe_anim.play("Chop")


func _handle_shoot():
	if Input.is_action_just_pressed("fishing") and not blunderbuss_anim.is_playing():
		blunderbuss_anim.play("Shoot")


func _fishing_throw():
	if Input.is_action_just_pressed("fishing") and is_instance_valid(thrown_spear_instance):
		thrown_spear_instance.queue_free()
		spear_model.visible = true
	if Input.is_action_pressed("fishing") and not is_instance_valid(thrown_spear_instance):
		r_hand.translate(Vector3(0.0, 0.0, 0.025))
		r_hand.position.z = clamp(r_hand.position.z, 0.0, 1.0)
		#camera.fov += 1
		#camera.fov = clamp(camera.fov, 90, 100)
		if r_hand.position.z > 0.3:
			d_hit.visible = true
			_draw_aim(spear_mass, spear_gravity_scale)
	elif Input.is_action_just_released("fishing") and r_hand.position.z > 0.3:
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


func _item_pickup(raycast_collider: Object):
	if raycast_collider is Item and left_hand.get_child_count() == 0:
		if raycast_collider.name.begins_with("Axe") and not has_axe:
			has_axe = true
		elif raycast_collider.name.begins_with("Blunderbuss") and not has_weapon:
			has_weapon = true
		else:
			var item_prefab = raycast_collider.hand_appearence.instantiate()
			print(raycast_collider.item_name)
			holding_item = raycast_collider.item_name
			left_hand.add_child(item_prefab)
			item_prefab.transform = left_hand.transform
			item_prefab.get_child(0).set_layer_mask_value(2, true)
			item_prefab.get_child(0).set_layer_mask_value(1, false)
		
		raycast_collider.queue_free()


func _throw_item():
	if holding_item != "" and throwable.has(holding_item):
		var to_throw_instance: RigidBody3D = throwable[holding_item].instantiate()
		get_parent().add_child(to_throw_instance)
		to_throw_instance.global_transform = left_hand.global_transform
		to_throw_instance.apply_force(left_hand.transform.basis * Vector3(0, 0, -50 * 10))
		left_hand.get_child(0).queue_free()
		holding_item = ""
		



func _raycast_query(pointA, pointB) -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pointA, pointB, 1<<0)
	query.hit_from_inside = false
	var result = space_state.intersect_ray(query)
	return result
	

func handle_holes(collider: Object) -> void:
	## If we don't have last collider we get the hole and set it to the last collider and show text
	if last_ray_cast_collider == null && collider != null && collider.get_parent().name.contains("Hole"):
		last_ray_cast_collider = collider.get_parent()
		GlobalVars.show_fix_the_hole_text.emit()
	## Here if we already have last collider we check if it changed to something else than hole
	elif last_ray_cast_collider != null && (collider == null || !collider.get_parent().name.contains("Hole")):
		last_ray_cast_collider = null
		GlobalVars.hide_ship_control_text.emit()

func show_ship_control_text():
	control_text.text = "Press E to control the ship"
	control_text.visible = true


func hide_ship_control_text():
	control_text.visible = false


func show_ship_exit_control_text():
	control_text.text = "Press E to exit the control of the ship"
	control_text.visible = true
	

func show_fix_the_hole_text():
	control_text.text = "Hold F to fix the hole!"
	control_text.visible = true

func hole_fixed_message_back(player: Player):
	if player != self:
		return
	
	fixing_bar.value = 0
	fixing_bar.hide()
	GlobalVars.hide_ship_control_text.emit()
