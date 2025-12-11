extends CharacterBody2D

# --- Tunables ---
@export var speed: float = 220.0
@export var accel: float = 2000.0
@export var deccel: float = 1800.0
@export var jump_force: float = 450.0
@export var gravity: float = 1200.0
@export var max_jumps: int = 1  # 1 = single jump, 2 = double jump

# grace times (seconds)
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

# hurt / stun
@export var hurt_duration: float = 0.35

# انيميشن الدخول للمنطقة
@export var enter_animation_duration: float = 60  # هيفضل 2.5 ثانية

# nodes
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# state
var facing_right: bool = true
var jumps_left: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var hurt_timer: float = 0.0
var control_enabled: bool = true
var is_attacking: bool = false
var is_playing_enter_animation: bool = false
var enter_animation_timer: float = 0.0


func respown():
	self.global_position = Vector2(49, 223)


func _ready() -> void:
	jumps_left = max_jumps
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		if sprite.animation != "Idle":
			sprite.play("Idle")


func _physics_process(delta: float) -> void:
	# لو انيميشن الدخول شغال، نوقف كل حاجة
	if is_playing_enter_animation:
		enter_animation_timer -= delta
		if enter_animation_timer <= 0.0:
			is_playing_enter_animation = false
			control_enabled = true
		return
	
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0
	
	# timers
	if is_on_floor():
		coyote_timer = coyote_time
		jumps_left = max_jumps
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	
	if hurt_timer > 0.0:
		hurt_timer = max(0.0, hurt_timer - delta)
		if hurt_timer <= 0.0:
			control_enabled = true
	
	# input (guarded by control flag and not attacking)
	var input_dir: float = 0.0
	if control_enabled and not is_attacking:
		input_dir = Input.get_axis("Left", "Right")
	
	# attack input (left mouse button)
	if control_enabled and not is_attacking and Input.is_action_just_pressed("Attack"):
		_start_attack()
	
	# horizontal accel/decel toward target_x
	var target_x := input_dir * speed
	var change_rate := accel if abs(target_x) > abs(velocity.x) else deccel
	velocity.x = move_toward(velocity.x, target_x, change_rate * delta)
	
	# flip sprite if needed (not during attack)
	if not is_attacking:
		if input_dir > 0.0 and not facing_right:
			_flip(true)
		elif input_dir < 0.0 and facing_right:
			_flip(false)
	
	# jump input: buffer the press
	if control_enabled and not is_attacking and Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	
	# perform jump if buffered + allowed
	if jump_buffer_timer > 0.0 and not is_attacking:
		if coyote_timer > 0.0 and jumps_left > 0:
			_do_jump()
			jump_buffer_timer = 0.0
		elif not is_on_floor() and jumps_left > 0 and max_jumps > 1:
			_do_jump()
			jump_buffer_timer = 0.0
	
	# move
	move_and_slide()
	
	# animation state
	_update_animation()


func _do_jump() -> void:
	velocity.y = -jump_force
	jumps_left = max(0, jumps_left - 1)
	coyote_timer = 0.0


func _flip(face_right: bool) -> void:
	facing_right = face_right
	if sprite:
		sprite.flip_h = not facing_right


func _start_attack() -> void:
	is_attacking = true
	if sprite:
		sprite.play("Attack")


func _on_animation_finished() -> void:
	if sprite and sprite.animation == "Attack":
		is_attacking = false


func take_damage(knockback: Vector2 = Vector2.ZERO) -> void:
	control_enabled = false
	hurt_timer = hurt_duration
	is_attacking = false
	velocity = knockback
	if sprite:
		sprite.play("Hurt")


func _update_animation() -> void:
	if sprite == null:
		return
	
	# لو انيميشن الدخول شغال، متعملش حاجة
	if is_playing_enter_animation:
		return
	
	# attack takes priority
	if is_attacking:
		if sprite.animation != "Attack":
			sprite.play("Attack")
		return
	
	# hurt animation
	if not control_enabled and hurt_timer > 0.0:
		if sprite.animation != "Hurt":
			sprite.play("Hurt")
		return
	
	# air animations
	if not is_on_floor():
		if velocity.y < -10.0:
			if sprite.animation != "Jump":
				sprite.play("Jump")
		elif velocity.y > 10.0:
			if sprite.animation != "Fall":
				sprite.play("Fall")
		return
	
	# ground animations
	if abs(velocity.x) > 10.0:
		if sprite.animation != "Run":
			sprite.play("Run")
	else:
		if sprite.animation != "Idle":
			sprite.play("Idle")


# دالة تشغيل انيميشن الدخول
func play_enter_animation():
	print("play_enter_animation called!")
	
	# لو مش على الأرض، استنى لحد ما يوصل
	if not is_on_floor():
		print("Player not on floor, waiting...")
		await get_tree().create_timer(0.1).timeout
		if not is_on_floor():
			print("Still not on floor, canceling animation")
			return
	
	is_playing_enter_animation = true
	enter_animation_timer = enter_animation_duration
	control_enabled = false
	
	# نوقف كل الحركة
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
	# كبّر وخفت الشفافية
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.5)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
	# ارجع للطبيعي
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.5)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	# كرر التأثير مرة تانية
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.4)
	tween.tween_property(sprite, "modulate", Color(1, 1, 0, 1), 0.4)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.4)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.4)
	
	#
