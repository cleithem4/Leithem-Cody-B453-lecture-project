extends CharacterBody2D

@export var repulsionArea: Area2D
@onready var base = $Body/base

# Movement parameters
@export var max_speed: float = 100.0
@export var acceleration: float = 200.0
@export var deceleration: float = 150.0
@export var rotation_speed: float = 5.0

# Flag approach parameters
@export var approach_distance: float = 50.0
@export var stop_distance: float = 5.0

# Collision parameters
@export var mass: float = 1.0
@export var elasticity: float = 0.5
@export var repulsion_strength: float = 20.0

var team: String = "none"
var nearby_units: Array = []

var team_textures = {
	"red": Color("f50000"),
	"blue": Color("0054ff"),
	"green": Color("0dff00"),
	"yellow": Color("a2d80c"),
}

func _ready() -> void:
	update_visuals()
	add_to_group("unit")

func _physics_process(delta: float) -> void:
	var target_flag = get_closest_flag()
	var movement = Vector2.ZERO
	
	# Calculate distance to flag
	if target_flag:
		var to_flag = target_flag.global_position - global_position
		var distance = to_flag.length()
		
		if distance > stop_distance:
			var target_speed = max_speed * smoothstep(stop_distance, approach_distance, distance)
			movement = to_flag.normalized() * target_speed
			
	
	# Apply acceleration or deceleration
	if movement.length() > 0:
		velocity = velocity.move_toward(movement, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
	# Apply repulsion from nearby units
	for unit in nearby_units:
		if is_instance_valid(unit):
			var away = global_position - unit.global_position
			velocity += away.normalized() * repulsion_strength * delta / away.length()
	
	# Move and handle collisions
	var collision = move_and_collide(velocity * delta)
	if collision:
		handle_collision(collision)
	
	# Keep within screen bounds
	global_position.x = clamp(global_position.x, 0, Global.screen_size.x)
	global_position.y = clamp(global_position.y, 0, Global.screen_size.y)

func handle_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	if collider.is_in_group("unit"):
		var normal = collision.get_normal()
		var relative_velocity = velocity - collider.velocity
		var impulse = -(1 + elasticity) * relative_velocity.dot(normal) / (1/mass + 1/collider.mass)
		
		velocity += (impulse / mass) * normal
		collider.velocity -= (impulse / collider.mass) * normal

func update_visuals() -> void:
	add_to_group(team)
	base.modulate = team_textures[team]

func _on_repulsion_area_body_entered(body: Node2D) -> void:
	if body != self and body.is_in_group("unit"):
		nearby_units.append(body)

func _on_repulsion_area_body_exited(body: Node2D) -> void:
	nearby_units.erase(body)

func get_closest_flag() -> Node2D:
	var base = Global.bases.get(team)
	if not base:
		return null
	
	var closest_flag = null
	var closest_distance = INF
	
	for child in base.get_children():
		if child.is_in_group("flag"):
			var distance = global_position.distance_to(child.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_flag = child
	
	return closest_flag
