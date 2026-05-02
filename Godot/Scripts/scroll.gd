extends TextureRect

@onready var textEdit = %TextEdit

var is_dragging = false #state management
var draggable = false
var offset = Vector2(0,0)
var mouseDeltaX = 0
var notes = ""

func _process(_delta):
	if is_dragging:
		followMouse()
func followMouse():
	position = get_global_mouse_position() + offset
	#rotation = 0

func _on_gui_input(event: InputEvent) -> void:
	if !draggable: return
	
	if is_dragging and event is InputEventMouseMotion:

		mouseDeltaX = event.relative.x
		print('dragging to delta x: ', mouseDeltaX)
		
		rotation = deg_to_rad(mouseDeltaX/2)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			ZIndexManager.highest_z += 1
			z_index = ZIndexManager.highest_z
			offset = position - get_global_mouse_position()
			is_dragging = true
			
		else:
			rotation = 0
			is_dragging = false

func loadNotes():
	textEdit.text = notes
	
func saveNotes():
	notes = textEdit.text 

func clearText():
	textEdit.clear()
