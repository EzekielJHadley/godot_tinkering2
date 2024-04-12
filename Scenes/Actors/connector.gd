extends Polygon2D



func _ready():
	print($".".uv[1])
	print($".".uv[2])


func _process(_delta):
	#look_at(get_global_mouse_position())
	$".".uv[1].x += 1
	$".".uv[2].x += 1
	$".".polygon[1].x += 1
	$".".polygon[2].x += 1
