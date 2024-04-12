extends CharacterBody2D
class_name Connector

var connected: bool = false
var is_connecting: bool = false
var from_station: Station
var to_station: Station

var base_team: Globals.team_choices
var contested: bool = false
var contested_storage = {"rec_station":null, "units":0}

signal connection_made(connector)

func set_team(team: Globals.team_choices, team_color: Color):
	base_team = team
	$Polygon2D.material.set_shader_parameter("team_color", team_color)
	$Polygon2D.material.set_shader_parameter("percent_fill", 1.0)

func _ready():
	set_team(from_station.team, from_station.team_color)
	from_station.transfer_units.connect(recieve_units)
	add_collision_exception_with(from_station)

func _process(_delta):
	if not connected:
		#if not connected yet, esc to cancel
		if Input.is_action_pressed("Cancel"):
			queue_free()
		
		if not is_connecting and base_team == Globals.team_choices.PLAYER:
			var collision = rotate_and_colide(get_global_mouse_position())
			if collision is Station:
				print(collision)
				connect_stations(collision)
		
	

func connect_stations(target: Station):
	#print("connecting to station!")
	var target_pos:Vector2 = target.position
	var distance = position.distance_to(target_pos)
	#print(target_pos)
	#notify game that the connection made, ensure no repeat connections
	add_collision_exception_with(target)
	#var collision = rotate_and_colide(target_pos)
	var start_pos = get_endpoint()
	var collision_container: Array = []
	#start the connection process
	is_connecting = true
	var tween = get_tree().create_tween()
	tween.tween_method(tween_test.bind(collision_container), start_pos, target_pos, 1)
	await tween.finished
	var collision = collision_container.pop_back()
	#print(collision)
	if collision:
		remove_collision_exception_with(target)
		#print("Colliding with:")
		#print(collision)
	else:
		#set the target station
		to_station = target
		connected = true
		set_light_path_endpoint(distance)
		connection_made.emit(self)
		#emit smoke to show connection
		$ParticleOffset/GPUParticles2D.emitting = true
	#either way we aren't in the process of connecting
	is_connecting = false

#this funtions only purpose is to allow me to tween the rotate_and_slide
#for when it does the final move
#BUT i need the collision response to know if there was a problem with that final move
func tween_test(target_pos: Vector2, collision_container: Array):
	collision_container.append(rotate_and_colide(target_pos))
	
func reverse_connection():
	if from_station.transfer_units.is_connected(recieve_units):
			from_station.transfer_units.disconnect(recieve_units)
	var station_swap = from_station
	from_station = to_station
	to_station = station_swap
	#flip this connector around
	position = from_station.global_position
	rotate(PI)
	#change the signal listener
	from_station.transfer_units.connect(recieve_units)
	
func set_contested():
	print("This connection is now contested")
	#though if the same team, just switch directions
	if from_station.team == to_station.team:
		#player must want to swap the connector around
		reverse_connection()
	else:
		contested = true
		$Polygon2D.material.set_shader_parameter("percent_fill", 0.5)
		$Polygon2D.material.set_shader_parameter("contested_color", to_station.team_color)
		to_station.transfer_units.connect(recieve_units)

func set_uncontested():
	contested = false
	if to_station.transfer_units.is_connected(recieve_units):
		to_station.transfer_units.disconnect(recieve_units)
	set_team(from_station.team, from_station.team_color)
	

func recieve_units(rec_station: Station):
	if connected and not contested:
		var units_in_transit = from_station.units_from_station()
		var ret = to_station.units_to_station(from_station.team, units_in_transit)
		if ret > 0:
			#send it back
			from_station.units_to_station(from_station.team, ret)
		move_light()
	elif connected and contested:
		if contested_storage["units"] > 0:
			if contested_storage["rec_station"] == rec_station:
				contested_storage["units"] += rec_station.units_from_station()
			else:
				var diff = contested_storage["units"] - rec_station.units_from_station()
				if diff > 0:
					#then rec_station has lost this contest
					print("Contest winner is: ", contested_storage["rec_station"])
					rec_station.units_to_station(contested_storage["rec_station"].team, abs(diff))
					move_light(rec_station.team == base_team)
				else:
					#then the stored station lost this contest
					print("Contest winner is: ", rec_station)
					contested_storage["rec_station"].units_to_station(rec_station.team, abs(diff))
					move_light(contested_storage["rec_station"].team == base_team)
					pass
				contested_storage["rec_station"] = null
				contested_storage["units"] = 0
		else:
			#if the from station sends first store it
			contested_storage["rec_station"] = rec_station
			contested_storage["units"] = rec_station.units_from_station()

#store it as {is_team: true/false, units: 0}
#rec
#if units > 0
#this is second message
#if is_team and rec_station == team
#add
#else
#subract, and 

	
func move_light(reverse: bool = false):
	#print("Moving the light")
	var start:float = 0
	var end:float = 1.0
	if reverse:
		start = 1.0
		end = 0
	$Path2D/PathFollow2D/PointLight2D.visible = true
	$Path2D/PathFollow2D.progress_ratio = start
	var tween = create_tween()
	tween.tween_property($Path2D/PathFollow2D, "progress_ratio", end, from_station.transfer_time - 0.2)
	tween.finished.connect($Path2D/PathFollow2D/PointLight2D.hide)
	

func rotate_and_colide(radial: Vector2):
	#create a fake transformation to mimic the movement
	#use that to test if that transformation will collide with anything
	var new_rotation: float = radial.angle_to_point(position) + PI
	var distance: float = position.distance_to(radial)
	var x_scale: float = distance / $CollisionPolygon2D.polygon[1].x
	var new_transform = Transform2D(new_rotation, Vector2(x_scale, 1), 0, position)
	#By pass by reference this will collect the collision info
	var collider: KinematicCollision2D = KinematicCollision2D.new()
	#test the collision
	var collision: bool = test_move(new_transform, Vector2.ZERO, collider, 0.0)
	if not collision:
		change_length(distance)
		look_at(radial)
	
	return collider.get_collider()

func change_length(rect_len: float):
	#distance from origin to mouse
	#change the end point of the polygon image
	$Polygon2D.uv[1].x = rect_len
	$Polygon2D.uv[2].x = rect_len
	$Polygon2D.polygon[1].x = rect_len
	$Polygon2D.polygon[2].x = rect_len
	#the the end popint of the collision shape
	$CollisionPolygon2D.polygon[1].x = rect_len
	$CollisionPolygon2D.polygon[2].x = rect_len
	#update the shader so it knows where the halfway point is
	$Polygon2D.material.set_shader_parameter("conn_length", rect_len)
	#the particl offset needs to be moved as well
	$ParticleOffset.position.x = rect_len
	
func get_endpoint() -> Vector2:
	#the point between the end corners
	var endpoint: Vector2 = ($Polygon2D.polygon[1] + $Polygon2D.polygon[2])/2
	endpoint = endpoint.rotated(rotation)
	print("Endpoing is: ", endpoint)
	return global_position + endpoint

func set_light_path_endpoint(distance: float):
	#need to first get the existing temp point
	var curve_end: Vector2 = $Path2D.curve.get_point_position(1) 
	#append with new distance (like in change_length)
	curve_end.x = distance
	$Path2D.curve.set_point_position(1, curve_end)
	#this is because it sets a Curve2D which is more complicated than a normal line
	#and the interface is messier


func _on_input_event(_viewport, event, _shape_idx):
		if event is InputEventMouseButton and event.is_pressed():
			if base_team == Globals.team_choices.PLAYER:
				queue_free()
