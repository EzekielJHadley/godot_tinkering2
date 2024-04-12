extends Node2D

var connector_scene: PackedScene = preload("res://Scenes/Actors/connector_body.tscn")
var all_stations: Array = []
var AI: comp_ai

func _ready():
	print("setting up station listeners.")
	all_stations = $Stations.get_children()
	#graph will map index to index to all_stations: 
	#i.e. graph[0] will be all the edges coming from all_stations[0]
	
	
	for station: Station in all_stations:
		print(station.my_name)
		station.start_connector.connect(create_connector)
		station.owner_changed.connect(station_conquered)
	print("all station listeners set.")

	AI = comp_ai.new(all_stations)
	AI.connect_computer_signals(ai_connection)
	
func station_conquered(station, former_team):
	#always check win condition
	check_win_condition()
	#need to check connectors, and destroy any owned by that node
	for connector: Connector in $Connectors.get_children():
		if connector.from_station == station or connector.to_station == station:
			if connector.contested:
				#contested will only be between PLAYER and COMP#
				#when conquering a node with contested connectors
				#only the player can be attacking it, so all connectors need to become player owned connectors
				if connector.base_team == former_team:
					connector.reverse_connection()
				connector.set_uncontested()
			elif connector.from_station == station:
				#all outgoing connectors vanish
				connector.queue_free()
		#if this was an unaligned node any attacks will persist
	#if this station was a starting point for a COMP, i will need to adjust the AI
	if station.start:
		station.start = false
		AI.update_AI_starting_points(former_team)

#each time a station changes owner, check to see if player wins or loses
func check_win_condition():
	var num_stations = $Stations.get_child_count()
	var num_player_stations: int = 0
	for station: Station in $Stations.get_children():
		if station.team == Globals.team_choices.PLAYER:
			num_player_stations += 1
			
	if num_player_stations == 0:
		print("YOU LOSE!")
		$HUD.you_lose()
	elif num_player_stations >= num_stations:
		print("YOU WIN!")
		$HUD.you_win()

func create_connector(station):
	var connector = connector_scene.instantiate()
	connector.position = station.position
	connector.from_station = station
	connector.connection_made.connect(validate_connection)
	$Connectors.add_child(connector)
	return connector

func validate_connection(new_connector):
	#check that this connection is unique
	for connector in $Connectors.get_children():
		if connector != new_connector:
			if connector.from_station == new_connector.from_station \
			and connector.to_station == new_connector.to_station:
				print("Repeat connection, removing")
				new_connector.queue_free()
		
			#if the order is revered then need to change the state of the existing connector
			if connector.from_station == new_connector.to_station \
			and connector.to_station == new_connector.from_station:
				print("Contested connection")
				new_connector.queue_free()
				connector.set_contested()

func ai_connection(from_station, to_station):
	#check if teh connection already exists
	if does_connector_exist(from_station, to_station):
		#just call the action command again
		#print("Connector already exists!!")
		#skip action
		pass
	else:
		#print("Creating connection!")
		#set up the connector
		var connector = create_connector(from_station)
		#for ai set the length to be small
		connector.change_length(0.5)
		#then connect it
		connector.connect_stations(to_station)
		#there is already architeture in place to determine if this becomes
		#a contested connection

func does_connector_exist(from_station, to_station) -> bool:
	var ret = false
	for connector in $Connectors.get_children():
		if connector.from_station == from_station and connector.to_station == to_station:
			ret = true
			break
			
	return ret

func _on_comp_1_attack_timeout():
	if AI.COMP1.active:
		AI.COMP1.do_action()

func _on_comp_2_attack_timeout():
	if AI.COMP2.active:
		AI.COMP2.do_action()
