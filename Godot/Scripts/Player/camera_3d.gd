extends Camera3D

@export var max_lean : Vector2 = Vector2(10, 10) # Max degrees
@export var smoothness : float = 10.0

var target_rotation : Vector3 = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var view_size = get_viewport().size
		
		# Normalize mouse to -1.0 to 1.0
		var mouse_n = Vector2(
			(event.position.x / view_size.x) * 2 - 1,
			(event.position.y / view_size.y) * 2 - 1
		)
		
		# Calculate the local offset
		# Mouse X (horizontal) rotates the Y axis (yaw)
		# Mouse Y (vertical) rotates the X axis (pitch)
		target_rotation.y = -mouse_n.x * deg_to_rad(max_lean.x)
		target_rotation.x = -mouse_n.y * deg_to_rad(max_lean.y)

func _process(delta: float) -> void:
	# Use a clean Basis for the "lean"
	var lean_basis = Basis()
	lean_basis = lean_basis.rotated(Vector3.UP, target_rotation.y)
	lean_basis = lean_basis.rotated(Vector3.RIGHT, target_rotation.x)
	
	# Smoothly interpolate the current basis to the lean basis
	# This keeps the lean relative to the parent's forward direction
	transform.basis = transform.basis.slerp(lean_basis, delta * smoothness)
