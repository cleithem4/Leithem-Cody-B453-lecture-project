extends StaticBody2D

@onready var Billion = load("res://billions/billion.tscn")
@onready var unit_spawn = $unit_spawn
@onready var body := $body
@onready var spawn_timer = $spawn_timer

@export var team = "none"

var team_textures = {
	"red": preload("res://assets/base-color/ufoRed.png"),
	"blue": preload("res://assets/base-color/ufoBlue.png"),
	"green": preload("res://assets/base-color/ufoGreen.png"),
	"yellow": preload("res://assets/base-color/ufoYellow.png"),
}

func _ready() -> void:
	update()
	spawn_timer.start()
	
	
func _process(delta: float) -> void:
	pass
	
func update():
	self.add_to_group(team)
	if body and not team == "none":
		body.texture = team_textures[team]
	else:
		print("Error: Body is null")
		

func spawn_billion():
	var billion = Billion.instantiate()
	get_tree().root.call_deferred("add_child", billion)
	billion.team = team
	billion.global_position = unit_spawn.global_position

func _on_spawn_timer_timeout() -> void:
	spawn_billion()
