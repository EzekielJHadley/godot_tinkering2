class_name comp_ai
extends Object

var all_stations: Array = [Station]
var graph: Array = [] 
#var player_start: int
var start_indecies: Dictionary = {}
var COMP1
var COMP2

func _init(stations: Array):
	all_stations = stations
	for i in range(all_stations.size()):
		graph.append(Array())
	
	COMP1 = COMPUTER.new(Globals.team_choices.COMP1, all_stations, graph)
	COMP2 = COMPUTER.new(Globals.team_choices.COMP2, all_stations, graph)
	print("Building graph")
	print(all_stations)
	#var start_indecies = build_graph()

func set_starting_points(team: Globals.team_choices, start_index: int):
	match team:
		Globals.team_choices.PLAYER:
			#player_start = start_index
			COMP1.target_indx = start_index
			COMP2.target_indx = start_index
		Globals.team_choices.COMP1:
			COMP1.start_indx = start_index
			COMP1.set_paths()
		Globals.team_choices.COMP2:
			COMP2.start_indx = start_index
			COMP2.set_paths()

func get_highest_level_player_station() -> Station:
	var best_station: Station = null
	for station in all_stations:
		if station.team == Globals.team_choices.PLAYER:
			if best_station == null:
				best_station = station
			elif station.level > best_station.level:
				best_station = station
	
	return best_station		
			
func update_AI_starting_points(team: Globals.team_choices):
	var best_station:Station
	match team:
		Globals.team_choices.COMP1:
			print("Updateing COMP1 starting node")
			best_station = COMP1.get_highest_level_station()
			print("COMP1's best station is: ", best_station)
			if best_station == null:
				print("No more stations!")
				COMP1.active = false
				return
		Globals.team_choices.COMP2:
			best_station = COMP2.get_highest_level_station()
			if best_station == null:
				COMP2.active = false
				return
		Globals.team_choices.PLAYER:
			#the player's main base was defeated
			#TODO: pick a new taerget for AI
			best_station = get_highest_level_player_station()
			if best_station == null:
				#should never get here, lol
				print("ERROR! Lose condition should have triggered.")
				return
	best_station.start = true
	set_starting_points(team, all_stations.find(best_station))

func build_graph():
	#var ret = {}
	for station: Station in all_stations:
		print("Station: ", station, ", can see the following:")
		var station_index = all_stations.find(station)
		if station.start:
			start_indecies[station.team] = station_index
		for target: Station in all_stations:
			if station != target:
				await station.setup_vision(target.global_position)
				var next_node = station.test_vision()
				print(next_node)
				if next_node is Station and next_node == target:
					var next_node_indx = all_stations.find(next_node)
					graph[station_index].append(next_node_indx)
	#return ret
	print("Graph set")
	print(graph)
	#need to set player index first
	set_starting_points(Globals.team_choices.PLAYER, start_indecies[Globals.team_choices.PLAYER])
	for key in start_indecies:
		set_starting_points(key, start_indecies[key])
					
func connect_computer_signals(call_back):
	if COMP1.active: COMP1.create_ai_connection.connect(call_back)
	if COMP2.active: COMP2.create_ai_connection.connect(call_back)

enum {RETALIATE, ADVANCE, ATTACK_PLAYER, ATTACK_FREE, UPGRADE, ACTION_MAX}

class COMPUTER:
#region Class Varaibles
	signal create_ai_connection(from_station, to_station)
	var all_stations : Array = []
	var graph: Array = []
	var path: Array = []
	var distances: Array = []
	var action = ADVANCE:
		set(val):
			if val >= ACTION_MAX:
				action = ADVANCE
			else:
				action = val
	var team
	var target_indx:int:
		set(val):
			target_indx = val
			#if start_indx != null:
				#self.bfs_shortest_path()
				#print("distances from starting point to this point")
				#print(self.distances)
				#print("paths to each point from start")
				#print(self.path)
	var active:bool = false
	var start_indx: int = -1:
		set(val):
			if(val >= 0):
				start_indx = val
				self.active = true
#endregion

	func _init(team_enum: Globals.team_choices, stations: Array, master_graph: Array):
		self.all_stations = stations
		self.graph = master_graph
		self.action = ATTACK_PLAYER
		self.team = team_enum
	
	#wrapper for the bfs_shortest_path
	#checks that everything is in place first
	func set_paths():
		if self.target_indx != null and self.start_indx != null:
			bfs_shortest_path()
		else:
			print("ERROR! Target index or Start index not defined")
	
	func bfs_shortest_path():
		#set up the queue
		var queue = [self.start_indx]
		
		#this array will hold the value of the distance to each node from the start
		for i in range(self.graph.size()):
			self.distances.append(INF)
		self.distances[self.start_indx] = 0
		
		#this array will hold the paths from the start to each node
		self.path.resize(self.graph.size())
		self.path[self.start_indx] = []
		
		var visited = [self.start_indx]
		
		while queue.size() != 0:
			var vertex = queue.pop_front()
			
			for neighbor in self.graph[vertex]:
				if neighbor not in visited:
					self.distances[neighbor] = self.distances[vertex] + 1
					visited.append(neighbor)
					queue.append(neighbor)
					
					var temp = self.path[vertex].duplicate(true)
					temp.append(neighbor)
					self.path[neighbor] = temp.duplicate(true)

	#from the first COMP node, find the nearest unallinged node
	#return an array defining what station from ai and to unallinged
	func get_nearest_unallinged_node():
		#from start nodes, add the connected nodes to a queue
		var queue: Array = []
		queue.append_array(self.graph[self.start_indx])
		#set a timout for the loop, i shouldn't travel a distance farther than the maximum distance
		#(naive implementation, does not prevent loops)
		var max_loops: int = self.distances.max()
		for i in range(max_loops):
			#check each node in queue for the first player node
			var temp_queue = []
			for index in queue:
				if self.all_stations[index].team == Globals.team_choices.NONE:
					#check that this path is valid, if not continue
					var path_to_node = self.path[index]
					var next_node = self.get_next_node_in_path(path_to_node, index)
					if next_node["valid"]:
						self.create_ai_connection.emit(next_node["from_station"], next_node["to_station"])
						break
				#if not, add all nodes connect to each to the queue
				temp_queue.append_array(self.graph[index])
			#when one is found, check if it can be reached, if not continue on (based off of path array)
		#print("Manifest Destiney")

	#from the first COMP node, find the nearest player node
	#return an array defining what station from ai and to player 
	func get_nearest_player_node():
		#from start nodes, add the connected nodes to a queue
		var queue: Array = []
		queue.append_array(self.graph[self.start_indx])
		#set a timout for the loop, i shouldn't travel a distance farther than the maximum distance
		#(naive implementation, does not prevent loops)
		var max_loops: int = self.distances.max()
		for i in range(max_loops):
			#check each node in queue for the first player node
			var temp_queue = []
			for index in queue:
				if self.all_stations[index].team == Globals.team_choices.PLAYER:
					#check that this path is valid, if not continue
					var path_to_node = self.path[index]
					var next_node = self.get_next_node_in_path(path_to_node, index)
					if next_node["valid"]:
						self.create_ai_connection.emit(next_node["from_station"], next_node["to_station"])
						break
				#if not, add all nodes connect to each to the queue
				temp_queue.append_array(self.graph[index])
			#when one is found, check if it can be reached, if not continue on (based off of path array)
		#print("Crush, Kill, and Destroy!")
		
	#from first COMP node, follow the shortes path to first player node
	#this will return the next node in that path
	func get_next_path_node():
		#print("Going to connect to next node in path")
		var path_to_player: Array = self.path[self.target_indx]
		#print("Player index: ", self.target_indx, " with path: ", path_to_player)
		#print("From this array: ", self.all_stations)
		var from_station: Station = self.all_stations[self.start_indx]
		var to_station: Station
		for station_indx in path_to_player:
			to_station = self.all_stations[station_indx]
			if to_station.team == Globals.team_choices.PLAYER or to_station.team == Globals.team_choices.NONE:
				self.create_ai_connection.emit(from_station, to_station)
				break
			elif to_station.team != self.team:
				#this means the nodes in the path is another computer node
				#exit without doing anything (computers don't compete)
				break
			else:
				#if that station is already conquered, then we will connect from that one
				#TODO: if the node is in the path, maybe it needs to be reinforced
				from_station = to_station
		#print("Sally Forth!")
	
	func get_next_node_in_path(node_path:Array, _end:int)->Dictionary:
		var ret = {"from_station":0, "to_station":0, "valid":false}
		ret["from_station"] = self.all_stations[self.start_indx]
		for station_indx in node_path:
			ret["to_station"] = self.all_stations[station_indx]
			if ret["to_station"].team == Globals.team_choices.PLAYER or ret["to_station"].team == Globals.team_choices.NONE:
				ret["valid"] = true
				break
			elif ret["to_station"].team != self.team:
				#this means the nodes in the path is another computer node
				#exit without doing anything (computers don't compete)
				break
			else:
				#if that station is already conquered, then weill connect from that one
				ret["from_station"] = ret["to_station"]
		return ret
	#from all nodes controlled by ai
	#call upgrade on node
	#returns nothing
	func get_node_to_upgrade():
		#from the starting station
		#try to upgrade, if fail
		#try the next closest station (may be on the path, may not)
		#keep trying until one upgrades or we run out of stations
		var max_loops: int = self.distances.max()
		for i in range(max_loops):
			var station_index = self.distances.find(i)
			var station_node:Station = all_stations[station_index]
			if station_node.team == self.team and station_node.upgrade_station():
				print("upgraded AI station")
				break
			else:
				continue
		#print("You must construct additional pylons!")
	
	#this is how i will determine new start if start is defeated
	func get_highest_level_station() -> Station:
		var best_station: Station = null
		for station in self.all_stations:
			if station.team == self.team:
				if best_station == null:
					best_station = station
				elif station.level > best_station.level:
					best_station = station
		
		return best_station

	#determine what the next action an ai will take
	#return success/fail for the action
	func do_action():
		match self.action:
			RETALIATE:
				#TODO set up retaliation when node is taken by player
				pass
				#print("THIS MEANS WAR!!!!")
			ADVANCE:
				self.get_next_path_node()
			ATTACK_PLAYER:
				self.get_nearest_player_node()
			ATTACK_FREE:
				self.get_nearest_unallinged_node()
			UPGRADE:
				self.get_node_to_upgrade()
		
		self.action += 1
