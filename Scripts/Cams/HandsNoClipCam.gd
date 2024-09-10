extends SubViewportContainer

@onready var clip_viewport = $SubViewport
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().size_changed.connect(_resize_viewport)


func _resize_viewport():
	clip_viewport.size = get_window().size
