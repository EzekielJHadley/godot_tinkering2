extends CharacterBody2D


enum movement_enum {CRAWL, DANCE}
@export var move_style: movement_enum


func _ready():
	match move_style:
		movement_enum.CRAWL:
			$AnimationPlayer.play("crawl")
		movement_enum.DANCE:
			$AnimationPlayer.play("dance")
		_:
			print("Error: no enum selected")
