extends Character


@onready var mat = $MeshInstance3D.get_surface_override_material(0)
#When the player looks at and clicks on the character
enum suspects {
	Luther, Zenith, Selene
}

var turns #for tracking how many rounds of responses are generated
var currentEpisode: int  = 1 
var current_suspect_name : String

signal suspect_switched(suspect_id)

var aggression: int = 0 
var compliance: int = 0 
var currentMood


func _ready() -> void:
	mat.albedo_texture = characterPNG
	
func switch_suspect(new_suspect_name: String):
	if current_suspect_name != new_suspect_name:
		current_suspect_name = new_suspect_name
		var characterImagePath = load("res://Assets/Characters/E" + str(currentEpisode) + "/" + current_suspect_name + "/" + current_suspect_name + ".png")
		mat.albedo_texture = characterImagePath
		 
		suspect_switched.emit(suspects[new_suspect_name]) #emit suspect id
		

func switch_mood(new_mood: String):
	currentMood = new_mood
	var emoji = load("res://Assets/Icons/Emojis/" + currentMood + ".png")
	$Mood/Sprite3D.texture = emoji
	
func create_dialogue_resource(response:String, char_name: String) -> Resource:
	var dialogue = "~ start\n" + char_name + ": " + response
	var resource = DialogueManager.create_resource_from_text(dialogue)
	return resource
	
