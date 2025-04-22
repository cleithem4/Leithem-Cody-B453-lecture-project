extends CharacterBody2D

@export var repulsionArea: Area2D
@export var range_area: Area2D
@export var bullet_speed: float = 300.0
@export var attack_cooldown: float = 1.0
@export var turret_rotation_speed: float = 10.0

@onready var base = $Body/base
@onready var turret = $Body/turret_pivot/turret
@onready var muzzle = $Body/turret_pivot/turret/muzzle
@onready var attack_timer = $AttackCooldown
@onready var turret_pivot = $Body/turret_pivot
@onready var Bullet = load("res://billions/bullet.tscn")
@onready var level_label = $level

var inRange = []
var isInRange = false
var able_to_attack = true
@export var health = 5
@export var hit_dmg = 1

# Movement parameters
@export var max_speed: float = 100.0
@export var acceleration: float = 200.0
var deceleration: float = 150.0
@export var rotation_speed: float = 5.0

# Flag approach parameters
var approach_distance: float = 50.0
var stop_distance: float = 5.0

# Collision parameters
var mass: float = 1.0
var elasticity: float = 0.5
@export var repulsion_strength: float = 20.0

var team: String = "none"
var level = 1
var Base : StaticBody2D
var nearby_units: Array = []
var current_target = null

var team_textures = {
	"red": Color("a70000"),
	"blue": Color("0054ff"),
	"green": Color("00a600"),
	"yellow": Color("d4d400"),
}

func _ready() -> void:
	update_visuals()
	add_to_group("unit")
	if !has_node("AttackCooldown"):
		attack_timer = Timer.new()
		attack_timer.name = "AttackCooldown"
		attack_timer.wait_time = attack_cooldown
		attack_timer.one_shot = true
		attack_timer.connect("timeout", Callable(self, "_on_attack_cooldown_timeout"))
		add_child(attack_timer)
	

func damage(attack : Attack):
	var dmg = attack.hit_dmg
	health -= dmg
	if health < 1:
		if is_instance_valid(attack.attacker_base):
			attack.attacker_base._add_experience(5)
		queue_free()
	var DI_scale = Vector2(health/5.0,health/5.0)
	base.scale = DI_scale


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
	
	# Handle targeting and attacking
	if inRange.size() > 0:
		# Find closest target
		update_current_target()
		aim_to_attack(delta)
		
		# Attack if able
		if able_to_attack and current_target:
			attack()
	
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
	if collider.is_in_group("bullet"):
		return
	if collider.is_in_group("unit"):
		var normal = collision.get_normal()
		var relative_velocity = velocity - collider.velocity
		var impulse = -(1 + elasticity) * relative_velocity.dot(normal) / (1/mass + 1/collider.mass)
		
		velocity += (impulse / mass) * normal
		collider.velocity -= (impulse / collider.mass) * normal

func update_visuals() -> void:
	add_to_group(team)
	base.modulate = team_textures[team]
	level_label.text = str(level)

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

func update_current_target() -> void:
	# Clean up invalid targets
	inRange = inRange.filter(func(target): return is_instance_valid(target))
	
	if inRange.size() == 0:
		current_target = null
		return
	
	# Find closest target
	var closest_distance = INF
	var closest_target = null
	
	for target in inRange:
		var distance = global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	current_target = closest_target

func aim_to_attack(delta: float) -> void:
	if current_target and is_instance_valid(current_target):
		# Calculate direction to target
		var direction = (current_target.global_position - global_position).normalized()
		
		# Calculate target angle
		var target_angle = direction.angle()
		
		# Smoothly rotate turret towards target
		var current_angle = turret_pivot.rotation
		var new_angle = lerp_angle(current_angle, target_angle, turret_rotation_speed * delta)
		turret_pivot.rotation = new_angle

func attack() -> void:
	if !current_target:
		return
	
	# Create bullet
	var bullet = Bullet.instantiate()
	
	# Set bullet properties
	bullet.team = team
	bullet.global_position = muzzle.global_position
	bullet.hit_dmg = hit_dmg
	bullet.base = Base
	
	# Calculate direction to target
	var direction = (current_target.global_position - global_position).normalized()
	
	# Set bullet rotation
	bullet.rotation = direction.angle()
	
	# Add bullet to scene first so it can interact with physics
	get_parent().add_child(bullet)
	
	# Since it's a RigidBody2D, apply impulse/force to it
	bullet.apply_central_impulse(direction * bullet_speed)
  
	
	# Start cooldown
	able_to_attack = false
	attack_timer.start()

func _on_range_area_body_entered(body: Node2D) -> void:
	if (body.is_in_group("unit") or body.is_in_group("base")) and !body.is_in_group(team):
		inRange.append(body)
		update_current_target()

func _on_range_area_body_exited(body: Node2D) -> void:
	if (body.is_in_group("unit") or body.is_in_group("base")) and !body.is_in_group(team):
		inRange.erase(body)
		update_current_target()

func _on_attack_cooldown_timeout() -> void:
	able_to_attack = true
