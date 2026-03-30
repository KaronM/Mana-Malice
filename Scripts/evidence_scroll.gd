extends TextureRect

var is_dragging = false #state management
var draggable = false
var offset = Vector2(0,0)
var mouseDeltaX = 0

func _process(_delta):
	if is_dragging:
		followMouse()
func followMouse():
	position = get_global_mouse_position() + offset
	#rotation = 0

func _on_gui_input(event: InputEvent) -> void:
	if !draggable: return
	
	if is_dragging and event is InputEventMouseMotion:
		# You can access the delta x directly here
		mouseDeltaX = event.relative.x
		print('dragging to delta x: ', mouseDeltaX)
		
		rotation = deg_to_rad(mouseDeltaX/1.5)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			z_index = 50
			print("dragged")
			offset = position - get_global_mouse_position()
			is_dragging = true
			
		else:
			z_index = 5
			rotation = 0
			is_dragging = false
