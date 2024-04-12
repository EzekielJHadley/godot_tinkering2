extends CharacterBody2D


func _process(delta):
	var mouse_vec: Vector2 = get_global_mouse_position()
	look_at(mouse_vec)
	var collider: KinematicCollision2D = move_and_collide(( mouse_vec - global_position))
	if collider:
		print(collider.get_collider().my_name)
