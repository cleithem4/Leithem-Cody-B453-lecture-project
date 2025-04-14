extends Node2D

@onready var Base = load("res://spawners/base.tscn")
@onready var Flag = load("res://flag/flag.tscn")
var bases = {}  # Dictionary to store base nodes by team

# Variables for dragging flags
var dragged_flag: Node2D = null
var drag_start: Vector2 = Vector2.ZERO
var current_drag: Vector2 = Vector2.ZERO
var drag_threshold: float = 75.0 
var drag_offset: Vector2 = Vector2(-25, 50) 
var offset: Vector2 = Vector2(-17, 55) 

func _ready() -> void:
	spawn_base()

func _process(delta: float) -> void:
	pass

func _input(event):
	# Handle mouse motion while dragging a flag
	if event is InputEventMouseMotion and dragged_flag:
		current_drag = event.global_position - drag_offset
		queue_redraw()

	# Handle mouse button events
	if event is InputEventMouseButton:
		# Mouse button pressed
		if event.pressed:
			# Check if the mouse is over any flag (for either team)
			var flag_found = false
			for team in Global.bases.keys():
				var base = Global.bases[team]
				if !base:
					return
				for flag in base.get_children():
					if flag.is_in_group("flag"):
						# Use distance check
						if flag.global_position.distance_to(event.global_position) < drag_threshold:
							dragged_flag = flag
							drag_start = flag.pos.global_position
							current_drag = event.global_position - offset
							flag_found = true
							break
				if flag_found:
					break
			# If no flag was clicked, then handle spawning/moving
			if not flag_found:
				if Input.is_key_pressed(KEY_1):
					handle_flag("green", event.global_position)
				elif Input.is_key_pressed(KEY_2):
					handle_flag("red", event.global_position)
		# Mouse button released: finish dragging if a flag was dragged
		else:
			if dragged_flag:
				# Set the flag's new position. Convert the global position to the base's local space.
				var team = dragged_flag.team
				var base = Global.bases.get(team)
				if base:
					# Convert global drag position to base local and subtract offset.
					var local_target = base.to_local(event.global_position) - offset
					dragged_flag.position = local_target
				dragged_flag = null
				queue_redraw()

func _draw():
	# While dragging, draw a line from the original flag position to the current mouse position.
	if dragged_flag:
		# Calculate distance to adjust line thickness (min 2, max 6 pixels)
		var drag_distance = drag_start.distance_to(current_drag)
		var line_thickness = clamp(2 + drag_distance / 100.0, 2, 6)
		draw_line(drag_start, current_drag - Vector2(20,-10), Color(1, 1, 1), line_thickness)

func spawn_base():
	# Spawn and store the green base
	var green_base = Base.instantiate()
	call_deferred("add_child", green_base)
	green_base.team = "green"
	green_base.global_position = Vector2(200, 200)
	Global.bases["green"] = green_base

	# Spawn and store the red base
	var red_base = Base.instantiate()
	call_deferred("add_child", red_base)
	red_base.team = "red"
	red_base.global_position = Vector2(1000, 200)
	Global.bases["red"] = red_base
	
	# Spawn and store the yellow base
	var yellow_base = Base.instantiate()
	call_deferred("add_child", yellow_base)
	yellow_base.team = "yellow"
	yellow_base.global_position = Vector2(1000, 400)
	Global.bases["yellow"] = yellow_base
	
	# Spawn and store the blue base
	var blue_base = Base.instantiate()
	call_deferred("add_child", blue_base)
	blue_base.team = "blue"
	blue_base.global_position = Vector2(200, 400)
	Global.bases["blue"] = blue_base

func handle_flag(team: String, click_position: Vector2) -> void:
	var base = Global.bases.get(team)
	if base == null:
		print("Base for team ", team, " not found!")
		return
	
	var flag_nodes = []
	for child in base.get_children():
		if child.is_in_group("flag"):
			flag_nodes.append(child)
	
	# Convert the global click position to base's local coordinates and subtract the offset.
	var local_click = base.to_local(click_position) - offset
	
	if flag_nodes.size() < 2:
		# Spawn a new flag if fewer than 2 exist.
		var new_flag = Flag.instantiate()
		new_flag.team = team
		new_flag.position = local_click
		new_flag.add_to_group("flag")
		base.add_child(new_flag)
	else:
		# If there are already 2 flags, move the nearest flag.
		var nearest_flag: Node2D = null
		var nearest_distance = INF
		for flag in flag_nodes:
			var dist = flag.global_position.distance_to(click_position)
			if dist < nearest_distance:
				nearest_distance = dist
				nearest_flag = flag
		if nearest_flag:
			nearest_flag.global_position = click_position - offset
