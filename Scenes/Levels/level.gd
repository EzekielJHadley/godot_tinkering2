extends Node2D


func _on_tile_map_changed():
	print("map changed?")
	$Godot.map_ready = true
