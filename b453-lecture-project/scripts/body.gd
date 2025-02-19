extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_sprite()
	
func update_sprite():
	var team = get_parent().team
	for child in get_children():
		if child.name == team:
			child.show()
			print("showing " + team)
		else:
			print("hiding " + child.name)
			print("team: " + team)
			child.hide()
