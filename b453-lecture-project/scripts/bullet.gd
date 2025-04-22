extends RigidBody2D

var team = "none"

var hit_dmg = 1
var base : StaticBody2D

const Attack = preload("res://scripts/Attack.gd")


var team_textures = {
	"red": Color("a70000"),
	"blue": Color("0054ff"),
	"green": Color("00a600"),
	"yellow": Color("d4d400"),
	"none": Color("000000"),
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$despawn.start()
	update_visuals()


func update_visuals() -> void:
	add_to_group(team)
	$Sprite2D.modulate = team_textures[team]
	

func _on_despawn_timeout() -> void:
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if !body.is_in_group(team):
		if body.has_method("damage"):
			var attack = Attack.new()
			attack.attacker_base = base
			attack.hit_dmg = hit_dmg
			body.damage(attack)
			queue_free()
