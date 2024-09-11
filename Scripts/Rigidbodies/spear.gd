extends RigidBody3D

@export var throw_speed = 100.0
@export var player_owner = null
@onready var collider = $CollisionShape3D
@onready var area_collider = $Tip/CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_force(transform.basis * Vector3(0, 0, -throw_speed * 10))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	look_at(global_position + linear_velocity)
	pass
	#position += transform.basis * Vector3(0, 0, -throw_speed) * delta


func _on_tip_body_entered(body: Node3D) -> void:
	if body is not Player:
		self.freeze = true


func _on_tip_body_exited(body: Node3D) -> void:
	if body is ItemSupply:
		body.pass_to_player(player_owner)
	pass # chyba useless ale zostawiam jakby ktos potrzebowal
