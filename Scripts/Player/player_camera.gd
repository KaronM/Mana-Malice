extends Node3D

@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var textBalloon : CanvasLayer = $TextBalloon 

#dialogue/text variables
var isTalking : bool = false
var isTyping : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	toggle_text_balloon_off()
	isTalking = false
	isTyping = false


func toggle_dialogue_on(dialogueResource: Resource):
	print("Dialogue on")
	
	isTalking = true
	isTyping = false

	
func toggle_dialogue_off(dialogueResource: Resource):
	print("Dialogue off")
	
	isTalking = false


func toggle_text_balloon_on():
	print("Typing on")
	
	textBalloon.visible = true
	isTalking = false
	isTyping = true
	

func toggle_text_balloon_off():
	print("Typing off")
	
	textBalloon.visible = false

func _input(event: InputEvent) -> void:
	pass
