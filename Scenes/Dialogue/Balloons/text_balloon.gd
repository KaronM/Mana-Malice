extends CanvasLayer


@onready var player = get_parent()

#for saving text response
var response : String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
#when submitting the text
func submit_response():
	print(response)
	response = %TextEdit.text 
	%TextEdit.clear()

#for actively typing is on
func toggle_typing_on():
	pass

func toggle_typing_off():
	pass
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_text_submit"):
		submit_response()
	
	if !visible:
		%TextEdit.editable = false
	else:
		%TextEdit.editable = true
	
	
