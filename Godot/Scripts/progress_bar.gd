extends ProgressBar

var style: StyleBoxFlat
var time = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	style = get_theme_stylebox("fill", "ProgressBar") as StyleBoxFlat

func _process(delta: float) -> void:
	time += delta
	var glow = (sin(time * 3.0) + 1.0) / 2.0  # oscillates 0 to 1
	style.bg_color.a = lerp(0.5, 1.0, glow) 
