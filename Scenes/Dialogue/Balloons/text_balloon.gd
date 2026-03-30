extends CanvasLayer


@onready var suspect = get_parent().get_parent().get_node("Suspect")
@onready var interrogation = get_parent().get_parent()
#for saving text response
var response : String

signal response_submitted(suspect_name,response,aggression,compliance,focus)
#for character numbers
var char_num : int
var char_limit : int = 100
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Label.text = "0/" + str(char_limit) + " Characters Left"
	%TextEdit.text_changed.connect(_on_text_changed)
	pass # Replace with function body.
	
func _on_text_changed():
	char_num = %TextEdit.text.length()
	%Label.text = str(char_num) + "/" + str(char_limit) + " Characters Left"
	
	if char_num > char_limit :
		%Label.add_theme_color_override("font_color", Color.RED)
	else:
		%Label.add_theme_color_override("font_color", Color.WHITE)

#when submitting the text
func submit_response():
	%TextEdit.editable = false
	var text = %TextEdit.text
	
	var trimmed_text = text.strip_edges()
	
	if trimmed_text.is_empty():
		print("Cannot send an empty string")
		%TextEdit.clear()
		return
	
	response = trimmed_text
	response_submitted.emit(suspect.suspects[suspect.current_suspect_name],response,suspect.aggression,suspect.compliance, interrogation.current_focus, interrogation.questionsLeft)
	
	print(response)
	%TextEdit.clear()

#for actively typing is on
func toggle_typing_on():
	pass

func toggle_typing_off():
	pass
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_text_submit") and %TextEdit.editable and char_num <= char_limit:
		submit_response()
func _on_visibility_changed() -> void:
	if visible == false:
		print("visibility changes")
		%TextEdit.editable = true
	else:
		%TextEdit.editable = true
	
	pass # Replace with function body.
