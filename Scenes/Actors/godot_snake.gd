extends CharacterBody2D

func _ready():
	$Path2D/PathFollow2D.progress_ratio = randf()

func _process(delta):
	$Path2D/PathFollow2D.progress_ratio += 0.1 * delta
