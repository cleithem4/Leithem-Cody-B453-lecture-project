extends Node2D

@onready var Base = load("res://spawners/base.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_base()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func spawn_base():
	var base = Base.instantiate()
	call_deferred("add_child", base)
	base.team = "green"
	base.global_position = Vector2(200,200)
	var base2 = Base.instantiate()
	call_deferred("add_child", base2)
	base2.team = "red"
	base2.global_position = Vector2(1000,200)
