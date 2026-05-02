extends TextureButton

var interrogation
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("owner: ", owner)
	interrogation = owner
	self.mouse_entered.connect(hovered)
	self.mouse_exited.connect(exited)
	pass # Replace with function body.

func hovered():
	if interrogation.menuOpened:
		$Label.add_theme_color_override("font_color", Color.WHITE)

func exited():
	if interrogation.menuOpened:
		$Label.add_theme_color_override("font_color", Color.BLACK)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
