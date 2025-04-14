extends StaticBody2D

@onready var Billion = load("res://billions/billion.tscn")
@onready var Bullet = load("res://spawners/baseBullet.tscn")
@onready var unit_spawn = $unit_spawn
@onready var body := $body
@onready var spawn_timer = $spawn_timer
@export var range_area: Area2D
@export var bullet_speed: float = 300.0
@export var attack_cooldown: float = 2.0
@export var turret_rotation_speed: float = 1.0
@export var team = "none"
@export var max_aim_angle_deg: float = 10.0  # Degrees within which turret must aim to fire
@export var health = 15


@onready var turret = $barrel
@onready var muzzle = $barrel/muzzle
@onready var attack_timer = $AttackCooldown
@onready var turret_pivot = $Body/turret_pivot
@onready var health_progress_bar = $health_progress_bar

var inRange = []
var isInRange = false
var able_to_attack = true
var current_target = null
var MAX_HEALTH = 15

var team_textures = {
	"red": preload("res://assets/base-color/ufoRed.png"),
	"blue": preload("res://assets/base-color/ufoBlue.png"),
	"green": preload("res://assets/base-color/ufoGreen.png"),
	"yellow": preload("res://assets/base-color/ufoYellow.png"),
}

func _ready() -> void:
	update()
	spawn_timer.start()
	
	
func _process(delta: float) -> void:
	if inRange.size() > 0:
		update_current_target()
		aim_to_attack(delta)
		
		if able_to_attack and current_target:
			var turret_direction = Vector2.RIGHT.rotated(turret.global_rotation)
			var to_target = (current_target.global_position - muzzle.global_position).normalized()
			var angle_diff = abs(turret_direction.angle_to(to_target))
			
			if rad_to_deg(angle_diff) <= max_aim_angle_deg:
				attack()
	
func update():
	self.add_to_group(team)
	if body and not team == "none":
		body.texture = team_textures[team]
	else:
		print("Error: Body is null")
		
func damage(dmg):
	health -= dmg
	var progress_value = float(health) / float(MAX_HEALTH) * 100.0
	animate_progress_bar(progress_value,0.2)
	if health < 1:
		queue_free()

func animate_progress_bar(target_value: float, duration: float):
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(health_progress_bar, "value", target_value,duration)

func spawn_billion():
	var billion = Billion.instantiate()
	get_tree().root.call_deferred("add_child", billion)
	billion.team = team
	billion.global_position = unit_spawn.global_position

func _on_spawn_timer_timeout() -> void:
	spawn_billion()

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
		var current_angle = turret.rotation
		var new_angle = lerp_angle(current_angle, target_angle, turret_rotation_speed * delta)
		turret.rotation = new_angle

func attack() -> void:
	if !current_target:
		return
	
	# Create bullet
	var bullet = Bullet.instantiate()
	
	# Set bullet properties
	bullet.team = team
	bullet.global_position = muzzle.global_position
	
	# Calculate direction to target
	var direction = Vector2.RIGHT.rotated(turret.global_rotation)
	
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
	if body.is_in_group("unit") and !body.is_in_group(team):
		inRange.append(body)
		update_current_target()


func _on_range_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("unit") and !body.is_in_group(team):
		inRange.erase(body)
		update_current_target()
		

func _on_attack_cooldown_timeout() -> void:
	able_to_attack = true
