extends CharacterBody2D

@export var nav_points: Array[Marker2D]
var nav_target: Marker2D
var map_ready: bool = false

var speed: int = 150
var test: bool = false

func _ready():
	print(nav_points)
	nav_target = nav_points.pick_random()
	$NavigationAgent2D.target_position = nav_target.global_position
	print(Time.get_datetime_string_from_system() + "Hello!")

func _physics_process(_delta):
	if map_ready:
		var next_path_pos: Vector2 = $NavigationAgent2D.get_next_path_position()
		var direction: Vector2 = (next_path_pos - global_position).normalized()
		velocity = direction * speed
		look_at(next_path_pos)
		move_and_slide()
		
	if test:
		print("ONE")

func _on_navigation_agent_2d_navigation_finished():
	print(Time.get_datetime_string_from_system() + "Arrived at target!")
	$Test.stop()
	$Test.wait_time = 1
	$Test.start()
	while true:
		var next_point = nav_points.pick_random()
		if next_point != nav_target:
			nav_target = next_point
			$NavigationAgent2D.target_position = nav_target.global_position
			break


func _on_test_timeout():
	print(Time.get_datetime_string_from_system() + "Hello!")


func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.is_pressed():
		print("Should cuase one physics frame")
		test = true
		await get_tree().physics_frame
		test = false

