extends Character

#When the player looks at and clicks on the character

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mat = $MeshInstance3D.get_surface_override_material(0)
	mat.albedo_texture = characterPNG



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
