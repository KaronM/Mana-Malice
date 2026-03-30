extends Node

@onready var http_request = $HTTPRequest
@onready var textBalloon = get_parent().get_node("Balloons/TextBalloon")
@onready var dialogueBalloon = get_parent().get_node("Balloons/DialogueBalloon")
@onready var suspect = get_parent().get_node("Suspect")
@onready var interrogation = get_parent()

var getting_ac_stats = false
var requestReady : bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	textBalloon.response_submitted.connect(send_request)
	http_request.request_completed.connect(_on_request_completed)
	suspect.suspect_switched.connect(get_aggression_compliance_stats)
	suspect.switch_suspect("Selene")

func get_aggression_compliance_stats(suspect_id):
	print("getting Suspect's aggression and compliance stats")
	if !requestReady: return
	requestReady = false
	getting_ac_stats = true
	
	var err = http_request.request('http://127.0.0.1:8000/Interrogation/' + str(suspect_id) + '/stats')
	
func send_request(suspect_id: int, resp: String, aggression: int, compliance: int, focus:int, questionsAsked: int):
	print("Sending Request")
	if !requestReady: return
	requestReady = false
	
	var resource = suspect.create_dialogue_resource(resp, 'You')
	interrogation.toggle_dialogue_on(resource, true)
	
	getting_ac_stats = false
	
	var player_request = {
		'player_text' : resp,
		'suspect_id' : suspect_id,
		'aggression' : aggression,
		'compliance' : compliance,
		'current_focus' : focus,
		'questionsAsked' : questionsAsked,
	}
	
	var request = JSON.stringify(player_request)
	
	var err = http_request.request('http://127.0.0.1:8000/Interrogation/' + str(suspect_id), ["Accept: application/json", "Content-Type: application/json"],HTTPClient.METHOD_POST, request)
	if err != OK:
		push_error("An error occurred in the HTTP request.")

func _on_request_completed(result, response_code, headers, body):
	
	if result != 0 or response_code != 200:
		push_error("HTTP request Unsuccessful")
		
	if getting_ac_stats: # for ac_stats
		var json = JSON.parse_string(body.get_string_from_utf8())
		print(json)
		suspect.aggression = json["base_aggression"]
		suspect.compliance = json["base_compliance"]
	else: #for resposnes
		print("Response code: ", response_code)
		print("Result: ", result)
		
		print("body: ", body.get_string_from_utf8())
		var json = JSON.parse_string(body.get_string_from_utf8())
		print(json)
		var response = json["output"]
		suspect.aggression = json["updated aggression"]
		suspect.compliance = json["updated compliance"]
		interrogation.interrogationEnded = json["left interrogation"]
		interrogation.change_focus(json["updated focus"])
		
		
		
		var resource = suspect.create_dialogue_resource(response, suspect.current_suspect_name)
		interrogation.toggle_dialogue_on(resource, false)
		
	getting_ac_stats = false
	requestReady = true	
	print("Request received!")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
