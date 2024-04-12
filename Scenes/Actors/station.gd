extends StaticBody2D
class_name Station

@export var team: Globals.team_choices
@export var start: bool = false
var team_color: Color
@export var my_name: String
@export var level: int = 0

#define the state of units and generation
var max_units: int = 10
@export var starting_units: int = 0
var units: int = 0:
	set(value):
		units = min(value, max_units)
		$StationTop/UnitsLabel.text = str(units)
var units_acrual: int = 1
var acrue_time: float = 1:
	set(value):
		#maybe send the accrue timeout signal on update
		acrue_time = value
		$Timers/AccrueUnitsTimer.wait_time = acrue_time
var transfer_strength: int = 2
var transfer_time: float = 1:
	set(value):
		#maybe send the transfer timeout signal on update
		transfer_time = value
		$Timers/TransferTimer.wait_time = transfer_time

signal start_connector(station)
signal transfer_units(station)
signal owner_changed(station, from)

func _ready():
	update_team(team)
	units = starting_units
	
	transfer_time = 1 - level/5.0
	$Timers/TransferTimer.start()
	acrue_time = 1 - level/2.5
	$Timers/AccrueUnitsTimer.start()
	transfer_strength += floor(level/2)

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
func units_from_station() -> int:
	if units >= transfer_strength:
		units -= transfer_strength
		return transfer_strength
	else:
		return 0

#this function will be used by the connector
func units_to_station(original_station_team: Globals.team_choices, units_transfered) -> int:
	var remainder: int = 0
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

func test_vision(target_position: Vector2):
	return $connection_tester.test_collision(target_position)

func _on_team_color_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if team == Globals.team_choices.PLAYER:
			#print("Hello my name is " + my_name)
			start_connector.emit(self)
			#event.canceled = true

func _on_transfer_timer_timeout():
	transfer_units.emit(self)

func _on_accrue_units_timer_timeout():
	if team != Globals.team_choices.NONE:
		units += units_acrual
