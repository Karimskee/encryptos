extends CharacterBody2D

# --- إعدادات البوس ---
@export var speed: float = 120.0        # سرعة الجري
@export var gravity: float = 1200.0
@export var max_health: int = 15        # 15 ضربة
@export var damage_amount: int = 2      # ينقص قلبين
@export var knockback_force_on_player: float = 800.0 # نوك باك قوي

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

func _ready():
	current_health = max_health
	player_ref = get_tree().get_first_node_in_group("Player")
	
	sprite.animation_finished.connect(_on_animation_finished)
	
	if hitbox:
		# الربط اللي كان بيعمل المشكلة، دلوقتي الدالة بتاعته موجودة تحت
		hitbox.body_entered.connect(_on_hitbox_body_entered)


# --- دي الدالة اللي كانت ناقصة ---
func _on_hitbox_body_entered(body):
	if body == player_ref and not is_dead:
		if can_attack and not is_attacking:
			_start_attack()
# -----------------------------


func _physics_process(delta):
	if is_dead:
		return
	
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
	
	# --- (الحل السحري) تصحيح الاتجاه قبل الضربة ---
	# لو اللاعب لف ورا البوس أثناء التجهيز، البوس هيلفله فجأة ويضربه
	if player_ref and not is_dead:
		var dir_to_player = sign(player_ref.global_position.x - global_position.x)
		if dir_to_player != 0:
			# تحديث اتجاه الصورة
			sprite.flip_h = (dir_to_player < 0)
			# تحديث مكان الهيت بوكس فوراً عشان يلف مع الصورة
			hitbox.position.x = abs(hitbox.position.x) * dir_to_player
	# ---------------------------------------------
	
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
		# الكول داون الطبيعي بعد الهجوم
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true
		
	elif sprite.animation == "Hurt":
		is_hurt = false
		is_attacking = false # تأكيد إن الهجوم وقف
		
		# --- (التصليح السحري) ---
		# بما إنه خلص وجع، خليه يقدر يضرب تاني علطول
		# أو ممكن تعمل تايمر صغير لو عاوزه ياخد وقت عشان يستوعب
		can_attack = true 
		# -----------------------
		
		sprite.play("Idle")
		
	elif sprite.animation == "Dead":
		# لو مات متعملش حاجة
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
		
		# --- ضيف السطر ده ---
		# لو انضرب وهو بيجهز يضرب، الغي الكول داون عشان لما يفوق يهاجمك بشراسة
		# ده هيخلي المعركة حماسية أكتر
		# can_attack = false # (اختياري: لو شلت السطر ده هيعتمد على إنهاء انيميشن Hurt)
		# ------------------

		sprite.play("Hurt")
		
		var knock_dir = sign(global_position.x - attacker_pos.x)
		velocity.x = knock_dir * 200
		velocity.y = -100


func die():
	is_dead = true
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	sprite.play("Dead")
	await sprite.animation_finished
