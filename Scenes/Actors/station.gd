extends StaticBody2D
class_name Station

@export var team: Globals.team_choices
@export var start: bool = false
var team_color: Color
@export var my_name: String
const MAX_LEVEL:int = 4
@export_range(0, MAX_LEVEL) var level: int = 0:
	set(value):
		level = min(value, MAX_LEVEL)
var level_cost:float = 5

#define the state of units and generation
var max_units: int = 10
@export var starting_units: int = 0
var units: float = 0:
	set(value):
		units = min(value, max_units)
		$StationTop/UnitsLabel.text = str(round((units*100)/max_units))
var units_acrual: float = 1
var acrue_time: float = 1:
	set(value):
		#maybe send the accrue timeout signal on update
		acrue_time = value
		$Timers/AccrueUnitsTimer.wait_time = acrue_time
var transfer_strength: float = 2
var transfer_time: float = 1:
	set(value):
		#maybe send the transfer timeout signal on update
		transfer_time = value
		for timer in $Timers/Atk_timers.get_children():
			timer.wait_time = transfer_time
		$Timers/TransferTimer.wait_time = transfer_time
var transfer_stack: Array[Connector] = []

signal start_connector(station)
signal transfer_units(station)
signal owner_changed(station, from)

func _ready():
	update_team(team)
	set_level()
	units = starting_units
	#$Timers/TransferTimer.start()
	$Timers/AccrueUnitsTimer.start()

func _process(_delta):
	if transfer_stack.has(null):
		pass
	while transfer_stack.size() > 0 and units > transfer_strength:
		var conn: Connector = transfer_stack.pop_front()
		conn.recieve_units(self)
		print("Timers/Atk_timers/" + conn.name.validate_node_name() + "_timer")
		get_node("Timers/Atk_timers/" + conn.name.validate_node_name() + "_timer").start()
		

func set_level():
	#level the following values
	#how frequenty packets are transfered
	transfer_time = 0.5
	#generated units
	acrue_time = 0.5
	
	match level:
		0:
			#how much to transfer each tic (0.5 sec)
			transfer_strength = 2 * transfer_time
			#how much to accrue each tic (0.5 sec)
			units_acrual = 1 * acrue_time
			$upgrade/Upgrade_lvl1.modulate.a = 0.5
			$upgrade/Upgrade_lvl1.visible = true
		1:
			#how much to transfer each tic (0.5 sec)
			transfer_strength = 2 * transfer_time
			#how much to accrue each tic (0.5 sec)
			units_acrual = 1.5 * acrue_time
			$upgrade/Upgrade_lvl1.modulate.a = 1
			$upgrade/Upgrade_lvl1.disabled = true
			$upgrade/Upgrade_lvl2.modulate.a = 0.5
			$upgrade/Upgrade_lvl2.visible = true
		2:
			#how much to transfer each tic (0.5 sec)
			transfer_strength = 2.5 * transfer_time
			#how much to accrue each tic (0.5 sec)
			units_acrual = 2.5 * acrue_time
			$upgrade/Upgrade_lvl2.modulate.a = 1
			$upgrade/Upgrade_lvl2.disabled = true
			$upgrade/Upgrade_lvl3.modulate.a = 0.5
			$upgrade/Upgrade_lvl3.visible = true
		3:
			#how much to transfer each tic (0.5 sec)
			transfer_strength = 3.5 * transfer_time
			#how much to accrue each tic (0.5 sec)
			units_acrual = 4.375 * acrue_time
			$upgrade/Upgrade_lvl3.modulate.a = 1
			$upgrade/Upgrade_lvl3.disabled = true
			$upgrade/Upgrade_lvl4.modulate.a = 0.5
			$upgrade/Upgrade_lvl4.visible = true
		4:
			#how much to transfer each tic (0.5 sec)
			transfer_strength = 5.5 * transfer_time
			#how much to accrue each tic (0.5 sec)
			units_acrual = 8.25 * acrue_time
			$upgrade/Upgrade_lvl4.modulate.a = 1
			$upgrade/Upgrade_lvl4.disabled = true
		_:
			print("ERROR!: Some how got to level 5+")
	
	#Set max accrual (takes 6 seconds)
	max_units = units_acrual * 30.0/acrue_time
	#how much the next level costs (half max)
	level_cost = max_units * .75
	#update display
	$StationTop/UnitsLabel.text = str((units*100)/max_units)
	

func update_team(new_team):
	var old_team = team
	team = new_team
	match team:
		Globals.team_choices.NONE:
			team_color = Color.GRAY
		Globals.team_choices.PLAYER:
			team_color = Color.BLUE
		Globals.team_choices.COMP1:
			team_color = Color.RED
		Globals.team_choices.COMP2:
			team_color = Color.GREEN
		_:
			team_color = Color.MAGENTA
	
	$TeamColor.modulate = team_color
	owner_changed.emit(self, old_team)

#this function will be used by the connector
func units_from_station() -> float:
	if units >= transfer_strength:
		units -= transfer_strength
		return transfer_strength
	else:
		return 0

#this function will be used by the connector
func units_to_station(original_station_team: Globals.team_choices, units_transfered) -> float:
	var remainder: float = 0
	if original_station_team == team:
		#first see if this will max out units
		if (units + units_transfered) > max_units:
			remainder = (units + units_transfered) - max_units
		units += units_transfered
	else:
		units -= units_transfered
		
	#now check the state
	if units <= 0:
		units = abs(units)
		update_team(original_station_team)
		
	return remainder

func setup_vision(target_position: Vector2):
	await $connection_tester.set_test(target_position)

func test_vision():
	return $connection_tester.test_collision()

func _on_team_color_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if team == Globals.team_choices.PLAYER:
			#print("Hello my name is " + my_name)
			start_connector.emit(self)
			#event.canceled = true

func start_transfer_timer():
	$Timers/TransferTimer.start()
	
func attach_new_timer(new_connector: Connector):
	var new_timer = Timer.new()
	new_timer.wait_time = transfer_time
	new_timer.autostart = true
	new_timer.one_shot = true
	new_timer.name = new_connector.name.validate_node_name() + "_timer"
	new_timer.connect("timeout", func(): transfer_stack.append(new_connector))
	$Timers/Atk_timers.add_child(new_timer)
	
	
func detach_timer(dead_conn: Connector):
	transfer_stack.erase(dead_conn)
	get_node("Timers/Atk_timers/"+dead_conn.name.validate_node_name()+"_timer").queue_free()
	


func _on_transfer_timer_timeout():
	#await a function that, when units are available, send signal
	#then start timer again
	#transfer_units.emit(self)
	pass

func _on_accrue_units_timer_timeout():
	if team != Globals.team_choices.NONE:
		units += units_acrual

func upgrade_station():
	if units > level_cost and level < MAX_LEVEL:
		units -= level_cost
		level += 1
		print("upgrade to: ", level)
		set_level()
		return true
	else:
		return false
			
func _upgrade_event():
	if team == Globals.team_choices.PLAYER:
		upgrade_station()


