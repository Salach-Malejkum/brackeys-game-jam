extends RigidBody3D

@export var throw_speed = 100.0
@onready var collider = $CollisionShape3D
@onready var area_collider = $Tip/CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collider.disabled = true
	area_collider.disabled = true
	apply_force(transform.basis * Vector3(0, 0, -throw_speed * 10))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	look_at(global_position + linear_velocity)
	pass
	#position += transform.basis * Vector3(0, 0, -throw_speed) * delta


func _on_tip_body_entered(body: Node3D) -> void:
	self.freeze = true
	print(body)


func _on_tip_body_exited(body: Node3D) -> void:
	print(body)


func _on_compensate_throw_timeout() -> void:
	collider.disabled = false
	area_collider.disabled = false
