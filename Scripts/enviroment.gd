extends Node3D

@onready var env : Environment = $WorldEnvironment.environment;
@onready var rain : GPUParticles3D = $Camera3D/Rain;
@onready var timer : Timer = $Timer;
@onready var waves : MeshInstance3D = $Camera3D/Waves;

var rain_ratio : float = 0.0;
var timer_time : float = 0.1;
var wavey : float = 0.1;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("test")
	timer.start(timer_time);

func _on_every_timer():
	rain.amount_ratio = rain_ratio;
	rain_ratio += 0.0001;
	
	env.volumetric_fog_density += 0.0001;
	
	wavey += 0.002;
	#print(waves.mesh.surface_get_material(0).resource_path);
	#"res://Materials/water.tres::ShaderMaterial_fwi4a"
	var material = waves.mesh.surface_get_material(0);
	material.set_shader_parameter("amount", wavey);
	#print(waves.material_overlay.resource_name);
	#print(waves.material_override.resource_name);
	#print(rain_ratio);
	timer.start(timer_time);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#env.sky.sky_material.Clou
	pass

func _on_timer_timeout() -> void:
	pass # Replace with function body.
