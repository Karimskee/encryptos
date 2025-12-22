extends CharacterBody2D

# --- Tunables ---
@export var speed: float = 220.0
@export var accel: float = 2000.0
@export var deccel: float = 1800.0
@export var jump_force: float = 450.0
@export var gravity: float = 1200.0
@export var max_jumps: int = 1

# 🔥 المتغير الخاص بالدبل جمب (الـ NPC هيغير ده لـ true)
var can_double_jump = false 

@export var knockback_force: float = 400.0
@export var attack_damage: int = 1
@export var attack_area_offset: float = 30.0

# Health System
@export var max_health: int = 5
var current_health: int = 5

var is_knocked_back := false

# Shield System
@export var max_shield_durability: int = 6 
var current_shield_durability: int = 6
var is_blocking: bool = false

# grace times (seconds)
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

# انيميشن الدخول
@export var enter_animation_duration: float = 60

# Dash settings
@export var dash_speed: float = 300.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

# nodes
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

# Audio Nodes
@onready var sfx_attack: AudioStreamPlayer2D = $Audio/Attack
@onready var sfx_hurt: AudioStreamPlayer2D = $Audio/Hurt
@onready var sfx_dash: AudioStreamPlayer2D = $Audio/Dash
@onready var sfx_dead: AudioStreamPlayer2D = $Audio/Dead

# Particles
@onready var dash_particles: GPUParticles2D = $DashParticles

# state
var facing_right: bool = true
var jumps_left: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var control_enabled: bool = true
var is_attacking: bool = false
var is_playing_enter_animation: bool = false
var enter_animation_timer: float = 0.0
var attack_hit_registered: bool = false
var is_dead: bool = false

# Dash state
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

# Signals
signal health_changed(new_health, max_health)
signal player_died


func respown():
	self.global_position = Vector2(106, 213)
	current_health = max_health
	current_shield_durability = max_shield_durability 
	
	is_dead = false
	control_enabled = true
	is_knocked_back = false
	is_blocking = false
	velocity = Vector2.ZERO
	
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
	if attack_area:
		attack_area.set_collision_layer_value(1, true)
		attack_area.set_collision_mask_value(1, true)
		attack_area.monitoring = true
		attack_area.monitorable = true
	
	health_changed.emit(current_health, max_health)
	
	if sprite:
		sprite.play("Idle")


func _ready() -> void:
	# 1. استرجاع القدرات من الجيم مانجر
	can_double_jump = GameManager.unlocked_double_jump
	attack_damage = GameManager.current_damage
	
	# ... (باقي كودك القديم زي ما هو)
	jumps_left = max_jumps
	current_health = max_health
	current_shield_durability = max_shield_durability
	
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		if sprite.animation != "Idle":
			sprite.play("Idle")
	
	_update_attack_area_position()
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	
	if is_dead:
		return
	
	# --- Block Logic ---
	if Input.is_action_pressed("Block") and is_on_floor() and not is_attacking and not is_dashing and current_shield_durability > 0:
		if not is_blocking:
			is_blocking = true
			velocity.x = 0 
	else:
		if is_blocking:
			is_blocking = false
	
	if is_playing_enter_animation:
		enter_animation_timer -= delta
		if enter_animation_timer <= 0.0:
			is_playing_enter_animation = false
			control_enabled = true
		return
	
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			velocity.x = 0.0
		else:
			velocity.x = dash_direction.x * dash_speed
			velocity.y = 0.0
			move_and_slide()
			_update_animation()
			return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0.0 and not is_knocked_back:
			velocity.y = 0.0
	
	# --- 🔥 تعديل منطق القفز هنا 🔥 ---
	if is_on_floor():
		coyote_timer = coyote_time
		
		# لو اللاعب عنده القدرة، بنعطيه نطتين (واحدة من الأرض وواحدة في الهوا)
		# لو معندوش، بياخد القيمة الافتراضية (1)
		if can_double_jump:
			jumps_left = 2
		else:
			jumps_left = max_jumps
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
	# ------------------------------------
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	
	if is_knocked_back:
		velocity.x = move_toward(velocity.x, 0.0, deccel * delta)
		move_and_slide()
		_update_animation()
		return
	
	# --- Input Movement ---
	var input_dir: float = 0.0
	if control_enabled and not is_attacking and not is_blocking:
		input_dir = Input.get_axis("Left", "Right")
	
	# --- Dash Input ---
	if control_enabled and not is_attacking and not is_dashing and not is_blocking and Input.is_action_just_pressed("Dash"):
		if dash_cooldown_timer <= 0.0:
			_start_dash()
	
	# --- Attack Input ---
	if control_enabled and not is_attacking and not is_dashing and not is_blocking and Input.is_action_just_pressed("Attack"):
		_start_attack()
	
	var target_x := input_dir * speed
	var change_rate := accel if abs(target_x) > abs(velocity.x) else deccel
	velocity.x = move_toward(velocity.x, target_x, change_rate * delta)
	
	if not is_attacking and not is_dashing and not is_blocking:
		if input_dir > 0.0 and not facing_right:
			_flip(true)
		elif input_dir < 0.0 and facing_right:
			_flip(false)
	
	# --- Jump Input ---
	if control_enabled and not is_attacking and not is_dashing and not is_blocking and Input.is_action_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	
	if jump_buffer_timer > 0.0 and not is_attacking and not is_dashing and not is_blocking:
		if coyote_timer > 0.0 and jumps_left > 0:
			_do_jump()
			jump_buffer_timer = 0.0
		# 🔥 التعديل هنا: السماح بالنط في الهوا طالما jumps_left > 0
		elif not is_on_floor() and jumps_left > 0:
			_do_jump()
			jump_buffer_timer = 0.0
	
	move_and_slide()
	
	_update_animation()


func _do_jump() -> void:
	velocity.y = -jump_force
	jumps_left = max(0, jumps_left - 1)
	coyote_timer = 0.0


func _flip(face_right: bool) -> void:
	facing_right = face_right
	if sprite:
		sprite.flip_h = not facing_right
	_update_attack_area_position()
	
	if dash_particles:
		if face_right:
			dash_particles.position.x = -abs(dash_particles.position.x)
			dash_particles.scale.x = 1 
		else:
			dash_particles.position.x = abs(dash_particles.position.x)
			dash_particles.scale.x = -1


func _update_attack_area_position():
	if attack_area:
		attack_area.position.x = attack_area_offset * (1 if facing_right else -1)


func _start_attack() -> void:
	is_attacking = true
	attack_hit_registered = false
	if sprite:
		sprite.play("Attack")
	
	if sfx_attack:
		sfx_attack.play()
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(_check_attack_hit)


func _check_attack_hit():
	if attack_hit_registered:
		return
	
	if not attack_area:
		return
	
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage") and body != self:
			body.take_damage(global_position)
			attack_hit_registered = true
			print("Player hit enemy!")
			break


func _start_dash() -> void:
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	var input_dir = Input.get_axis("Left", "Right")
	if input_dir != 0.0:
		dash_direction = Vector2(input_dir, 0.0)
	else:
		dash_direction = Vector2(1.0 if facing_right else -1.0, 0.0)
	
	if sprite:
		sprite.play("Dash")
	
	if sfx_dash:
		sfx_dash.play()
		
	if dash_particles:
		dash_particles.restart()
		dash_particles.emitting = true


func _on_animation_finished() -> void:
	if sprite:
		if sprite.animation == "Attack":
			is_attacking = false
			attack_hit_registered = false
		elif sprite.animation == "Hurt":
			is_knocked_back = false
			control_enabled = true
		elif sprite.animation == "Dash":
			pass
		elif sprite.animation == "Dead":
			pass


func take_damage_no_knockback() -> void:
	if is_dead:
		return
	
	current_health -= 1
	health_changed.emit(current_health, max_health)
	
	if sfx_hurt:
		sfx_hurt.play()
	
	if current_health <= 0:
		die()


func apply_knockback(enemy_position: Vector2, force_override: float = -1) -> void:
	if is_dead: return
	
	var direction_to_enemy = sign(enemy_position.x - global_position.x)
	var my_facing = 1 if facing_right else -1
	
	if is_blocking and direction_to_enemy == my_facing and current_shield_durability > 0:
		current_shield_durability -= 1
		print("Blocked! Shield left: ", current_shield_durability)
		
		velocity.x = -my_facing * 100 
		
		if current_shield_durability <= 0:
			is_blocking = false
			print("Shield Broken!")
		return 
	
	current_health -= 1
	health_changed.emit(current_health, max_health)
	
	if sfx_hurt: sfx_hurt.play()
	
	if current_health <= 0:
		die()
		return
	
	var knockback_force_val = knockback_force
	if force_override > 0: knockback_force_val = force_override
	
	var knockback_direction = -direction_to_enemy
	if knockback_direction == 0: knockback_direction = -my_facing
	
	is_knocked_back = true
	velocity.x = knockback_direction * knockback_force_val
	velocity.y = -knockback_force_val * 0.4
	
	control_enabled = false
	is_attacking = false
	is_dashing = false
	is_blocking = false
	
	if sprite: sprite.play("Hurt")


func take_damage(enemy_position: Vector2 = Vector2.ZERO) -> void:
	apply_knockback(enemy_position)


func take_boss_damage(dmg_amount: int, boss_pos: Vector2, force: float):
	if is_dead: return
	
	var direction_to_enemy = sign(boss_pos.x - global_position.x)
	var my_facing = 1 if facing_right else -1
	
	if is_blocking and direction_to_enemy == my_facing and current_shield_durability > 0:
		current_shield_durability -= 1
		print("Boss Blocked! Shield left: ", current_shield_durability)
		velocity.x = -my_facing * 300 
		return
	
	current_health -= dmg_amount
	health_changed.emit(current_health, max_health)
	
	var dir = sign(global_position.x - boss_pos.x)
	if dir == 0: dir = 1
	
	is_knocked_back = true
	velocity.x = dir * force
	velocity.y = -force * 0.5
	
	is_blocking = false
	if sprite: sprite.play("Hurt")
	
	if current_health <= 0:
		die()


func heal(amount: int) -> void:
	if is_dead:
		return
	
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	print("Player healed! Health: ", current_health)


func die():
	if is_dead:
		return
	
	is_dead = true
	control_enabled = false
	is_knocked_back = false
	is_attacking = false
	is_dashing = false
	is_blocking = false
	velocity = Vector2.ZERO
	
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	if attack_area:
		attack_area.set_collision_layer_value(1, false)
		attack_area.set_collision_mask_value(1, false)
		attack_area.monitoring = false
		attack_area.monitorable = false
	
	if sprite:
		sprite.play("Dead")
	
	if sfx_dead:
		sfx_dead.play()
	
	player_died.emit()
	
	print("Player died!")
	
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()


func _update_animation() -> void:
	if sprite == null:
		return
	
	if is_playing_enter_animation:
		return
	
	if is_dead:
		if sprite.animation != "Dead":
			sprite.play("Dead")
		return
	
	if is_knocked_back:
		if sprite.animation != "Hurt":
			sprite.play("Hurt")
		return
		
	if is_blocking:
		if sprite.animation != "Block":
			sprite.play("Block")
		return 
	
	if is_dashing:
		if sprite.animation != "Dash":
			sprite.play("Dash")
		return
	
	if is_attacking:
		if sprite.animation != "Attack":
			sprite.play("Attack")
		return
	
	if not is_on_floor():
		if velocity.y < -10.0:
			if sprite.animation != "Jump":
				sprite.play("Jump")
		elif velocity.y > 10.0:
			if sprite.animation != "Fall":
				sprite.play("Fall")
		return
	
	if abs(velocity.x) > 10.0:
		if sprite.animation != "Run":
			sprite.play("Run")
	else:
		if sprite.animation != "Idle":
			sprite.play("Idle")


func play_enter_animation():
	print("play_enter_animation called!")
	
	if not is_on_floor():
		print("Player not on floor, waiting...")
		await get_tree().create_timer(0.1).timeout
		if not is_on_floor():
			print("Still not on floor, canceling animation")
			return
	
	is_playing_enter_animation = true
	enter_animation_timer = enter_animation_duration
	control_enabled = false
	
	velocity = Vector2.ZERO
	
	if sprite.sprite_frames.has_animation("Enter"):
		sprite.play("Enter")
		print("Playing 'Enter' animation for ", enter_animation_duration, " seconds")
	else:
		print("'Enter' animation not found, playing visual effect")
		sprite.play("Idle")
		_do_scale_effect()


func _do_scale_effect():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.5)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.4)
	tween.tween_property(sprite, "modulate", Color(1, 1, 0, 1), 0.4)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.4)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.4)
