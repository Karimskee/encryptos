extends CharacterBody2D

# إشارة عشان لما البوس يموت اللعبة تعرف
signal boss_died

# --- إعدادات البوس ---
@export var speed: float = 120.0        # سرعة الجري
@export var gravity: float = 1200.0
@export var max_health: int = 15        # 15 ضربة
@export var damage_amount: int = 2      # ينقص قلبين
@export var knockback_force_on_player: float = 800.0 # نوك باك قوي

# --- إعدادات الرسوبن (Spawn) ---
@export var reward_scene: PackedScene  # هنا هنحط ملف الـ .tscn
@export var spawn_marker: Marker2D     # هنا هنحط الـ Marker2D اللي في المرحلة

# --- إعدادات الهجوم ---
@export var attack_range: float = 30.0  
@export var attack_cooldown: float = 1.5
@export var damage_timing: float = 0.4  

# --- النودز ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $HitBox   

# --- متغيرات الحالة ---
var current_health: int = 15
var player_ref: CharacterBody2D = null
var can_attack: bool = true
var is_attacking: bool = false
var is_dead: bool = false
var is_hurt: bool = false

# (جديد) متغير التحكم في نشاط البوس
var is_active: bool = false 

func _ready():
	current_health = max_health
	player_ref = get_tree().get_first_node_in_group("Player")
	
	sprite.animation_finished.connect(_on_animation_finished)
	
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)


# (جديد) دالة لتشغيل البوس بعد الحوار
func start_battle():
	is_active = true
	print("BOSS FIGHT STARTED!")


func _on_hitbox_body_entered(body):
	if body == player_ref and not is_dead:
		if can_attack and not is_attacking:
			_start_attack()


func _physics_process(delta):
	if is_dead:
		return
	
	# (جديد) لو البوس مش نشط (لسه في الحوار)، وقف حركته تماماً
	if not is_active:
		velocity.x = 0
		_apply_gravity(delta) # عشان يثبت على الأرض
		move_and_slide()
		if sprite.animation != "Idle":
			sprite.play("Idle")
		return
	# -------------------------------------------------------
	
	_apply_gravity(delta)
	
	if is_hurt:
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		move_and_slide()
		return

	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return
	
	# --- المطاردة ---
	if player_ref:
		var distance = global_position.distance_to(player_ref.global_position)
		var dir_to_player = sign(player_ref.global_position.x - global_position.x)
		
		if dir_to_player != 0:
			sprite.flip_h = (dir_to_player < 0)
			hitbox.position.x = abs(hitbox.position.x) * dir_to_player
		
		if distance <= attack_range:
			if can_attack:
				_start_attack()
			else:
				velocity.x = 0
				sprite.play("Idle")
		
		elif player_ref.is_on_floor(): 
			velocity.x = dir_to_player * speed
			sprite.play("Run")
		
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed * delta)
			sprite.play("Idle")
	else:
		velocity.x = 0
		sprite.play("Idle")
	
	move_and_slide()


func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0


func _start_attack():
	is_attacking = true
	can_attack = false
	sprite.play("Attack")
	
	# استنى وقت التجهيز (Windup)
	await get_tree().create_timer(damage_timing).timeout
	
	# تصحيح الاتجاه قبل الضربة (عشان ميتضربش من ضهره)
	if player_ref and not is_dead:
		var dir_to_player = sign(player_ref.global_position.x - global_position.x)
		if dir_to_player != 0:
			sprite.flip_h = (dir_to_player < 0)
			hitbox.position.x = abs(hitbox.position.x) * dir_to_player
	
	# كمل باقي كود الضرر عادي
	if is_attacking and not is_dead and player_ref:
		var bodies = hitbox.get_overlapping_bodies()
		for body in bodies:
			if body == player_ref:
				_deal_damage_to_player(player_ref)
				break


func _deal_damage_to_player(player):
	print("Boss hit player!")
	if player.has_method("take_boss_damage"):
		player.take_boss_damage(damage_amount, global_position, knockback_force_on_player)
	elif player.has_method("apply_knockback"):
		player.apply_knockback(global_position)
		if player.get("current_health"):
			player.current_health -= (damage_amount - 1)


func _on_animation_finished():
	if sprite.animation == "Attack":
		is_attacking = false
		sprite.play("Idle")
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
		
	elif sprite.animation == "Hurt":
		is_hurt = false
		is_attacking = false 
		can_attack = true # يقدر يضرب تاني علطول بعد الوجع
		sprite.play("Idle")
		
	elif sprite.animation == "Dead":
		pass


func take_damage(attacker_pos: Vector2):
	if is_dead: return
	
	current_health -= 1
	print("Boss HP: ", current_health)
	
	if current_health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false 
		sprite.play("Hurt")
		
		var knock_dir = sign(global_position.x - attacker_pos.x)
		velocity.x = knock_dir * 200
		velocity.y = -100


func die():
	is_dead = true
	velocity = Vector2.ZERO
	
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	
	if hitbox:
		hitbox.set_collision_mask_value(2, false)
	
	sprite.play("Dead")
	
	# ظهور السبيريت/المكافأة
	if reward_scene and spawn_marker:
		var reward_instance = reward_scene.instantiate()
		reward_instance.global_position = spawn_marker.global_position
		get_parent().add_child(reward_instance)
	
	# إرسال إشارة موت البوس
	boss_died.emit()
	print("Boss died!")
	
	await sprite.animation_finished
