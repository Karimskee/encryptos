extends CharacterBody2D

@export var speed: float = 60.0
@export var gravity: float = 1200.0
@export var edge_offset: float = 20.0
@export var attack_duration: float = 0.6
@export var attack_cooldown: float = 1.2
@export var attack_range: float = 50.0
@export var hitbox_offset: float = 30.0
@export var damage_timing: float = 1.0

# Health & Knockback
@export var max_health: int = 3
@export var knockback_force_from_player: float = 125.0
@export var knockback_duration: float = 0.3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ray: RayCast2D = $GroundRay
@onready var hitbox: Area2D = $HitBox

var direction: int = -1
var dead := false
var attacking := false
var can_attack := true
var target_player: Node = null
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var damage_dealt: bool = false

# Knockback state
var current_health: int = 3
var is_knocked_back: bool = false
var knockback_timer: float = 0.0

func _ready():
	current_health = max_health
	sprite.play("Run")
	_update_ground_ray()
	_update_hitbox_position()
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.body_exited.connect(_on_hitbox_body_exited)
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	if dead:
		return
	
	# Knockback timer
	if is_knocked_back:
		knockback_timer += delta
		if knockback_timer >= knockback_duration:
			is_knocked_back = false
			knockback_timer = 0.0
	
	# Cooldown timer
	if not can_attack:
		cooldown_timer += delta
		if cooldown_timer >= attack_cooldown:
			can_attack = true
			cooldown_timer = 0.0
	
	_apply_gravity(delta)
	
	# لو في knockback، متحركش العدو
	if is_knocked_back:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		move_and_slide()
		_update_animation()
		return
	
	if attacking:
		_handle_attack(delta)
	else:
		_move_enemy()
		_check_platform_edge()
		_check_wall()
		_update_animation()
	
	move_and_slide()

# ---------------- MOVEMENT ----------------
func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if not is_knocked_back:
			velocity.y = 0

func _move_enemy():
	velocity.x = speed * direction

func _check_platform_edge():
	if is_on_floor() and not ground_ray.is_colliding():
		_flip()

func _check_wall():
	if is_on_wall():
		_flip()

func _flip():
	direction *= -1
	sprite.flip_h = direction < 0
	_update_ground_ray()
	_update_hitbox_position()

func _update_ground_ray():
	ground_ray.target_position.x = edge_offset * direction

func _update_hitbox_position():
	if hitbox:
		hitbox.position.x = hitbox_offset * direction

# ---------------- ANIMATION ----------------
func _update_animation():
	# Knockback/Hurt has priority
	if is_knocked_back:
		if sprite.animation != "Hurt":
			sprite.play("Hurt")
		return
	
	if attacking:
		if sprite.animation != "Attack":
			sprite.play("Attack")
		return
	
	if sprite.animation != "Run":
		sprite.play("Run")

func _on_animation_finished():
	if sprite.animation == "Attack":
		attacking = false
		damage_dealt = false
		target_player = null
	elif sprite.animation == "Hurt":
		# لما أنيميشن الـ Hurt يخلص
		if not dead and not is_knocked_back:
			sprite.play("Run")

# ---------------- ATTACK ----------------
func _on_hitbox_body_entered(body):
	if dead or attacking or not can_attack or is_knocked_back:
		return
	
	if body.name == "Player":
		# شيك لو اللاعب مات
		if body.has_method("is_player_dead") and body.is_player_dead():
			return
		
		target_player = body
		_start_attack()

func _on_hitbox_body_exited(body):
	if body == target_player and attacking and not damage_dealt:
		target_player = null

func _start_attack():
	attacking = true
	can_attack = false
	attack_timer = 0.0
	damage_dealt = false
	velocity.x = 0
	sprite.play("Attack")

func _handle_attack(delta):
	attack_timer += delta
	velocity.x = 0
	
	if not damage_dealt and attack_timer >= (attack_duration * damage_timing):
		_deal_damage()

func _deal_damage():
	if target_player == null:
		return
	
	var distance = abs(global_position.x - target_player.global_position.x)
	if distance > attack_range:
		target_player = null
		return
	
	if target_player.has_method("apply_knockback"):
		target_player.apply_knockback(global_position)
		damage_dealt = true

# ---------------- DAMAGE & KNOCKBACK ----------------
func take_damage(attacker_position: Vector2):
	if dead:
		return
	
	# خصم صحة
	current_health -= 1
	print("Enemy health: ", current_health)
	
	# حساب اتجاه الـ knockback
	var knockback_direction = sign(global_position.x - attacker_position.x)
	if knockback_direction == 0:
		knockback_direction = -direction
	
	# تطبيق الـ knockback
	is_knocked_back = true
	knockback_timer = 0.0
	velocity.x = knockback_direction * knockback_force_from_player
	velocity.y = -knockback_force_from_player * 0.4
	
	# إيقاف الهجوم لو كان بيهاجم
	if attacking:
		attacking = false
		damage_dealt = false
		target_player = null
		can_attack = false
		cooldown_timer = 0.0
	
	# شيك لو مات
	if current_health <= 0:
		die()
	else:
		sprite.play("Hurt")

# ---------------- DEATH ----------------
func die():
	dead = true
	is_knocked_back = false
	velocity = Vector2.ZERO
	
	# عطّل الـ collision فوراً
	collision_layer = 0
	collision_mask = 0
	
	# عطّل الـ HitBox
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
	
	sprite.play("Dead")
	
	await sprite.animation_finished
	
	# وقف على آخر فريم
	sprite.stop()
	sprite.frame = sprite.sprite_frames.get_frame_count("Dead") - 1
	
	# Optional: fade out بعد شوية
	await get_tree().create_timer(3.0).timeout
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	await tween.finished
	queue_free()
