extends StaticBody2D

@onready var flag_color = $"flag-color"

var team = "none"
@onready var pos = $pos

var team_textures = {
	"red": preload("res://assets/flag-color/flagred.png"),
	"blue": preload("res://assets/flag-color/flagblue.png"),
	"green": preload("res://assets/flag-color/flaggreen.png"),
	"yellow": preload("res://assets/flag-color/flagyellow.png"),
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update():
	self.add_to_group(team)
	if flag_color and not team == "none":
		flag_color.texture = team_textures[team]
	else:
		print("Error: Body is null")
