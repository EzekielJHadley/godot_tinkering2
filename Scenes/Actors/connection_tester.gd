extends Node2D

var test: bool = false
var target_distance: float = 100

func set_test(target_position: Vector2):
	#point the rays at the target station
	look_at(target_position)
	#calculate the distance to stretch the rays to target
	target_distance = global_position.distance_to(target_position)
	$RayCast2D.target_position = Vector2(target_distance, 0)
	$RayCast2D2.target_position = Vector2(target_distance, 0)
	#forst an update, so i can read their collisions
	await Engine.get_main_loop().physics_frame
	$RayCast2D.force_update_transform()
	$RayCast2D.force_raycast_update()
	$RayCast2D2.force_update_transform()
	$RayCast2D2.force_raycast_update()

func test_collision():
	#check what they collide with first
	var collision1 = $RayCast2D.get_collider()
	var collision2 = $RayCast2D2.get_collider()
	print("Ray test1: ", collision1, " Distance: ", global_position.distance_to($RayCast2D.get_collision_point()))
	#print("Ray test2: ", collision2, " Distance: ", global_position.distance_to($RayCast2D2.get_collision_point()))
	#determine what the first thing they collide with, between the two
	print(collision1)
	print(collision2)
	if collision1 != collision2:
		#if one clips a wall, this will count as hitting the wall first
		if global_position.distance_to($RayCast2D.get_collision_point()) < global_position.distance_to($RayCast2D2.get_collision_point()):
			return collision1
		else:
			return collision2
	else:
		return collision1
