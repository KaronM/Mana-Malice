extends Node

#processing for 
@export var can_look: bool = true
@export var look_speed : float = 0.002
@export var current_focus: int = 8

# Called when the node enters the scene tree for the first time.
@onready var dialogueBalloon : CanvasLayer = $Balloons/DialogueBalloon
@onready var textBalloon : CanvasLayer = $Balloons/TextBalloon
@onready var textEdit = textBalloon.get_node("Balloon/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/TextEdit")

@onready var httpRequestHandler = $HTTPRequestHandler
@onready var suspect = $Suspect
@onready var focusMeter = $PlayerCamera.get_node("FocusMeter/VBoxContainer/ProgressBar")

#menu
@onready var menu = $Menu/MenuSelection/VBoxContainer
@onready var menuButton = menu.get_node("ColorRect/ColorRect/TextureButton")
@onready var evidenceButton = menu.get_node("ColorRect/HBoxContainer/MarginContainer2/EvidenceButton")
@onready var questionsAskedLabel = menu.get_node("ColorRect/QuestionsAsked")
@onready var scrollDestination = $Menu/MenuSelection/ScrollDestination
@onready var scrollStart = $Menu/MenuSelection/ScrollStart
@onready var blurOverlay = $Menu/MenuSelection/BlurOverlay
@onready var camera = $PlayerCamera/CameraPivot/Camera3D
@onready var EndScreen = $Menu/MenuSelection/InterrogationEndRect

#start
@onready var suspectRect = $Menu/MenuSelection.get_node("SuspectRect")

var questionsLeft = 20
var interrogationEnded = false 


var evidenceScroll = preload("res://Scenes/Items/Evidence_Scroll.tscn")
var scrollOffset = Vector2(250,50)

var menuOpened = false
var evidenceOut :bool = false
var currentScroll 
var scrollMoving = false

#dialogue/text variables
var isTalking : bool = false
var isTyping : bool = false
var isPlayerTalking : bool = false

var rng = RandomNumberGenerator.new()

var playerBalloon = null
var suspectBalloon
var suspectPicked : bool = false
var suspectTalkEnded : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	menu.visible = false
	camera.fov = 95
	
	EndScreen.visible = false
	focusMeter.visible = false
	blurOverlay.visible = false
	menuOpened = false
	
	#connections
	menuButton.mouse_entered.connect(toggleMenu)
	evidenceButton.pressed.connect(createScroll)
	var lutherButton = suspectRect.get_node("SuspectSelection/HBoxContainer/LutherBox/Button")
	var seleneButton = suspectRect.get_node("SuspectSelection/HBoxContainer/SeleneBox/Button")
	var zenithButton = suspectRect.get_node("SuspectSelection/HBoxContainer/ZenithBox/Button")
	
	lutherButton.pressed.connect(startInterrogation.bind(lutherButton))
	seleneButton.pressed.connect(startInterrogation.bind(seleneButton))
	zenithButton.pressed.connect(startInterrogation.bind(zenithButton))
	
	toggle_text_balloon_off()
	isTalking = false
	isTyping = false
	
	#toggle_text_balloon_on()
	textBalloon.get_node("Balloon").mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Release focus from TextEdit so menu can receive the click

func startInterrogation(button: Button):
	menu.visible = true
	camera.fov = 75
	suspectRect.visible = false

	focusMeter.visible = true
	toggle_text_balloon_on()
	
	if button.text != null:
		suspect.switch_suspect(button.text)

func createScroll():
	if evidenceOut: return 
	scrollMoving = true
	evidenceOut = true
	
	var scroll = evidenceScroll.instantiate()
	$Menu/MenuSelection.add_child(scroll)
	scroll.position = scrollStart.position - scrollOffset
	currentScroll = scroll
	
	var tween = get_tree().create_tween().set_parallel(true)

	tween.tween_property(scroll, "position", scrollDestination.position - scrollOffset, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(scroll, "rotation", deg_to_rad(rng.randi_range(-20, 20)), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(finishScrollMoving.bind(scroll)).set_delay(1)
	
func toggle_player_talking_off():
	isPlayerTalking = false
	
func finishScrollMoving(scroll):
	scrollMoving = false
	scroll.draggable = true
	
func toggleMenu():
	if isTalking or scrollMoving: return
	
	var tween = get_tree().create_tween().set_parallel(false)
	if menuOpened:
		menuOpened = false
		menuButton.flip_h = false
		textEdit.editable = true

		evidenceOut = false
		tween.tween_property(menu, "position", Vector2(0,-60), 0.1)
		tween.tween_method(
			func(val): blurOverlay.material.set_shader_parameter("alpha", val),
			0.7, 0.0, 0.2
		)
		blurOverlay.visible = false
		
		if currentScroll:
			currentScroll.queue_free()
	else:
		menuOpened = true
		menuButton.flip_h = true
		blurOverlay.visible = true
		textEdit.editable = false

		tween.tween_property(menu, "position", Vector2(0,0), 0.1)
		tween.tween_method(
			func(val): blurOverlay.material.set_shader_parameter("alpha", val),
			0.0, 0.7, 1
		)
		
func toggle_dialogue_on(dialogueResource: Resource, isPlayerBalloon : bool):
	var tween = get_tree().create_tween().set_parallel(false)
	tween.tween_property(menu, "position", Vector2(0,-100), 0.05)
	
	toggle_text_balloon_off()
	print("Dialogue on")
	isTalking = true
	isTyping = false
	
	if isPlayerTalking and !isPlayerBalloon: #waitfor player to finish before suspect responds
		await playerBalloon.dialogue_label.finished_typing 
		await get_tree().create_timer(1.75).timeout
	
	var balloon = DialogueManager.show_dialogue_balloon(dialogueResource, "start")
	await balloon.ready
	balloon.get_node("Balloon").mouse_filter = Control.MOUSE_FILTER_IGNORE
	balloon.dialogue_label.seconds_per_step = 0.08
	
	if isPlayerBalloon:
		
		playerBalloon = balloon
		isPlayerTalking = true
		toggle_fov_close()
		
		questionsLeft += 1
		change_questions_asked_label(questionsLeft)
		balloon.dialogue_label.finished_typing.connect(toggle_suspect_comment_bubble_on)
		balloon.dialogue_label.finished_typing.connect(toggle_player_talking_off)
		suspectTalkEnded = false
	else:
		suspectBalloon = balloon
		isPlayerTalking = false
		balloon.dialogue_label.started_typing.connect(toggle_suspect_comment_bubble_off)
		balloon.dialogue_label.finished_typing.connect(toggle_suspect_balloon)

func change_questions_asked_label(questionsAsked: int):
	questionsLeft = questionsAsked
	questionsAskedLabel.text = str(questionsLeft) + "/20 responses left"

#ending suspect dialogue
func toggle_suspect_balloon():
	await get_tree().create_timer(1).timeout
	suspectTalkEnded = true

	
func toggle_suspect_comment_bubble_off():
	print("Turning Off Bubble")
	var tween = get_tree().create_tween()
	var comment = suspect.get_node("Node3D")
	tween.tween_property(comment,"scale",Vector3(0,0,0),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func toggle_fov_close():
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "fov", 49, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
func toggle_fov_far():
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "fov", 75, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
func toggle_suspect_comment_bubble_on():
	if !isPlayerTalking: return #don't turn on if suspect is talking immediately
	
	print("Turning On Bubble")
	
	await get_tree().create_timer(0.5).timeout
	
	var tween = get_tree().create_tween()
	var comment = suspect.get_node("Node3D")
	tween.tween_property(comment,"scale",Vector3(0.1,0.1,0.1),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var sprite = comment.get_node("Sprite3D")
	sprite.play("TurningOn")

func toggle_dialogue_off(dialogueResource: Resource):
	print("Dialogue off")
	isTalking = false
	isPlayerTalking = false
	
func toggle_text_balloon_on():
	print("Typing on")
	if playerBalloon:
		playerBalloon.queue_free()
		
	if suspectBalloon:
		suspectBalloon.queue_free()

	var tween = get_tree().create_tween()
	tween.tween_property(menu, "position", Vector2(0,-60), 0.5)
	
	toggle_fov_far()
	
	toggle_suspect_comment_bubble_off()
	
	textBalloon.visible = true
	isTalking = false
	isTyping = true
	isPlayerTalking = false
	
func toggle_text_balloon_off():
	print("Typing off")
	
	textBalloon.visible = false

func change_focus(new_focus: int):
	current_focus = new_focus
	
	var tween = create_tween()
	tween.tween_property(focusMeter,"value",float(new_focus),1)
	#focusMeter.value = float(new_focus)
	
func _input(event: InputEvent) -> void:
	#when suspect is finished talking
	if suspectTalkEnded and Input.is_action_just_pressed("ui_accept"):
		if !interrogationEnded:
			suspectTalkEnded = false
			toggle_text_balloon_on()
		if interrogationEnded:
			endInterrogation()

func endInterrogation():
	EndScreen.visible = true
	textBalloon.visible = false
	if playerBalloon:
		playerBalloon.queue_free()
	
