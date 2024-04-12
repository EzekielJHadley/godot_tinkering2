extends CanvasLayer


func _ready():
	$Menu/VBoxContainer2/VBoxContainer/NextLevel.disabled = true
	$Menu.visible = false
	$Menu/VBoxContainer2/Label.text = get_tree().current_scene.name


func _input(event):
	if event.is_action_pressed("Menu"):
		_on_menu_button_pressed()

func you_win():
	$Menu/VBoxContainer2/VBoxContainer/NextLevel.disabled = false
	$Menu/VBoxContainer2/Label.text = "YOU WIN!"
	_on_menu_button_pressed()

func you_lose():
	$Menu/VBoxContainer2/Label.text = "YOU LOSE!"
	_on_menu_button_pressed()

func _on_menu_button_pressed():
	get_tree().paused = not get_tree().paused
	$Menu.visible = not $Menu.visible


func _on_restart_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Levels/station_level.tscn")


func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Levels/level_select.tscn")
