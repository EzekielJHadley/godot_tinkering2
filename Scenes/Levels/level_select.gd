extends Control

var test: bool = false

func _on_texture_button_pressed():
	print("Button pressed")
	get_tree().change_scene_to_file("res://Scenes/Levels/station_level.tscn")

