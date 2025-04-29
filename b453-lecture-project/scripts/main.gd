extends Node2D

@onready var Base = load("res://spawners/base.tscn")
@onready var Flag = load("res://flag/flag.tscn")
@onready var PowerUp = load("res://cratePowerUp/power_up.tscn")

var bases = {}  # Dictionary to store base nodes by team

# Dragging flags
var dragged_flag: Node2D = null
var drag_start: Vector2 = Vector2.ZERO
var current_drag: Vector2 = Vector2.ZERO
var drag_threshold: float = 75.0 
var drag_offset: Vector2 = Vector2(-25, 50) 
var offset: Vector2 = Vector2(-17, 55) 

# Procedural generation area
var top_left = Vector2(70,70)
var bottom_right = Vector2(1210,570)
var base_size_x = 100
var base_size_y = 100
var crate_size_x = 30
var crate_size_y = 30
var minimum_base_margin = Vector2(200, 200)
var minimum_crate_margin = Vector2(50, 50)

var existing_positions = []

func _ready() -> void:
	spawn_bases()

func _process(delta: float) -> void:
	pass

func _input(event):
	if event is InputEventMouseMotion and dragged_flag:
		current_drag = event.global_position - drag_offset
		queue_redraw()

	if event is InputEventMouseButton:
		if event.pressed:
			var flag_found = false
			for team in Global.bases.keys():
				var base = Global.bases[team]
				if !base:
					continue
				for flag in base.get_children():
					if flag.is_in_group("flag"):
						if flag.global_position.distance_to(event.global_position) < drag_threshold:
							dragged_flag = flag
							drag_start = flag.global_position
							current_drag = event.global_position - offset
							flag_found = true
							break
				if flag_found:
					break

			if not flag_found:
				if Input.is_key_pressed(KEY_1):
					handle_flag("green", event.global_position)
				elif Input.is_key_pressed(KEY_2):
					handle_flag("red", event.global_position)
		else:
			if dragged_flag:
				var team = dragged_flag.team
				var base = Global.bases.get(team)
				if base:
					var local_target = base.to_local(event.global_position) - offset
					dragged_flag.position = local_target
				dragged_flag = null
				queue_redraw()

func _draw():
	if dragged_flag:
		var drag_distance = drag_start.distance_to(current_drag)
		var line_thickness = clamp(2 + drag_distance / 100.0, 2, 6)
		draw_line(drag_start, current_drag - Vector2(20, -10), Color(1, 1, 1), line_thickness)

func find_rand_base_location(existing_positions: Array) -> Vector2:
	var max_attempts = 100
	for i in range(max_attempts):
		var pos = Vector2(
			randf_range(top_left.x + base_size_x, bottom_right.x - base_size_x),
			randf_range(top_left.y + base_size_y, bottom_right.y - base_size_y)
		)

		var valid = true
		for existing_pos in existing_positions:
			if pos.distance_to(existing_pos) < minimum_base_margin.length():
				valid = false
				break

		if valid:
			return pos
	
	print("Warning: Couldn't find valid base position after many attempts.")
	return top_left  # fallback

func find_rand_powerup_spawn_location(existing_positions: Array) -> Vector2:
	var max_attempts = 100
	for i in range(max_attempts):
		var pos = Vector2(
			randf_range(top_left.x + crate_size_x, bottom_right.x - crate_size_x),
			randf_range(top_left.y + crate_size_y, bottom_right.y - crate_size_y)
		)

		var valid = true
		for existing_pos in existing_positions:
			if pos.distance_to(existing_pos) < minimum_crate_margin.length():
				valid = false
				break

		if valid:
			return pos
	
	print("Warning: Couldn't find valid powerup position after many attempts.")
	return top_left  # fallback

func spawn_bases():
	var teams = ["green", "red", "yellow", "blue"]

	for team in teams:
		var base = Base.instantiate()
		base.team = team
		call_deferred("add_child", base)
		var pos = find_rand_base_location(existing_positions)
		base.global_position = pos
		existing_positions.append(pos)

		Global.bases[team] = base

func spawn_powerup():
	var crate = PowerUp.instantiate()
	var pos = find_rand_powerup_spawn_location(existing_positions)
	crate.global_position = pos
	add_child(crate)

func handle_flag(team: String, click_position: Vector2) -> void:
	var base = Global.bases.get(team)
	if base == null:
		print("Base for team ", team, " not found!")
		return
	
	var flag_nodes = []
	for child in base.get_children():
		if child.is_in_group("flag"):
			flag_nodes.append(child)
	
	var local_click = base.to_local(click_position) - offset
	
	if flag_nodes.size() < 2:
		var new_flag = Flag.instantiate()
		new_flag.team = team
		new_flag.position = local_click
		new_flag.add_to_group("flag")
		base.add_child(new_flag)
	else:
		var nearest_flag: Node2D = null
		var nearest_distance = INF
		for flag in flag_nodes:
			var dist = flag.global_position.distance_to(click_position)
			if dist < nearest_distance:
				nearest_distance = dist
				nearest_flag = flag
		if nearest_flag:
			nearest_flag.global_position = click_position - offset

func _on_powerup_spawn_timeout() -> void:
	spawn_powerup()
