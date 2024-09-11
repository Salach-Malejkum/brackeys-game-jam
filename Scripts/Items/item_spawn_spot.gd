extends StaticBody3D
class_name ItemSupply

@export var y_axis_force = 100
@export var z_axis_force = 900

var _preloaded_models = [
	preload("res://Scenes/Rigidbodies/BottleBody.tscn"),
	preload("res://Scenes/Rigidbodies/BlunderBussBody.tscn"),
	preload("res://Scenes/Rigidbodies/BarrelBody.tscn"),
	preload("res://Scenes/Rigidbodies/WoodBody.tscn"),
	preload("res://Scenes/Rigidbodies/ChestBody.tscn"),
	preload("res://Scenes/Rigidbodies/BucketBody.tscn"),
	preload("res://Scenes/Rigidbodies/AxeBody.tscn"),
	preload("res://Scenes/Rigidbodies/WoodBody.tscn"),
	preload("res://Scenes/Rigidbodies/WoodBody.tscn")
]

var _spawn_points_references = []

var item_spawned = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_preloaded_models.shuffle()
	
	for child in get_children():
		if child.name.begins_with("SpawnSpot"):
			var curr_instance = _preloaded_models[item_spawned].instantiate()
			child.add_child(curr_instance)
			_spawn_points_references.append(child)
			item_spawned += 1


func pass_to_player(player_node):
	if is_instance_valid(player_node):
		if _spawn_points_references.size() > 0:
			var rb_instance: RigidBody3D = _spawn_points_references.pop_front().get_child(0)
			rb_instance.look_at(player_node.global_position)
			rb_instance.apply_force(rb_instance.transform.basis * Vector3(0, y_axis_force, -z_axis_force))
	else:
		print("zesralo sie")
