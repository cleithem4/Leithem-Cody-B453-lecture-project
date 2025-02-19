extends CharacterBody2D

@export var repulsionArea : Area2D
@onready var base = $Body/base

var team = "none"
var repulsionForce_array = []

var green_hex = "0dff00"

var team_textures = {
	"red": "f50000",
	"blue": "0054ff",
	"green": "0dff00",
	"yellow": "a2d80c",
}
func _ready() -> void:
	update()
	
func _physics_process(delta: float) -> void:
	if repulsionForce_array.size() != 0:
		var repulsion_force = Vector2.ZERO
		for UNIT in repulsionForce_array:
			repulsion_force += (global_position - UNIT.global_position).normalized() * 2.0
		global_position += repulsion_force

func update():
	self.add_to_group(team)
	base.modulate = team_textures[team]
	
func _on_repulsion_area_body_entered(body: Node2D) -> void:
	if body != self and body.is_in_group("unit"):
		repulsionForce_array.append(body)


func _on_repulsion_area_body_exited(body: Node2D) -> void:
	if body != self and body.is_in_group("unit"):
		repulsionForce_array.erase(body)
