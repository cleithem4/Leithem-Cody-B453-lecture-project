extends RigidBody2D

var inArea: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func check_for_team_domination():
	var team_counts: Dictionary = {
		"green": 0,
		"red": 0,
		"blue": 0,
		"yellow": 0
	}
	
	for unit in inArea:
		var team = unit.team
		if team_counts.has(team):
			team_counts[team] += 1

	var dominating_teams = []

	for team in team_counts.keys():
		if team_counts[team] >= 2:
			dominating_teams.append(team)

	# Only allow powerup if exactly one team dominates the zone
	if dominating_teams.size() == 1:
		var team = dominating_teams[0]
		print("Powerup collected by team:", team)
		Global.bases[team].powerup()
		queue_free()  # Powerup disappears after being collected

func _on_in_area_body_entered(body: Node2D) -> void:
	if body.has_method("damage"):
		inArea.append(body)
		check_for_team_domination()

func _on_in_area_body_exited(body: Node2D) -> void:
	if body.has_method("damage"):
		inArea.erase(body)
