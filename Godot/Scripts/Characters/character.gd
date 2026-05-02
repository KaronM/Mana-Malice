class_name Character
extends Node3D


@export var characterPNG: Texture2D
@export var characterName:String
@export var dialogueResource: Resource
var talkable = true
var currentTitle = "start" #title of dialogue resource to start from

func interact():
	pass
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set textures to mesh
	var mat = $MeshInstance3D.get_surface_override_material(0)
	mat.albedo_texture = characterPNG

	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
