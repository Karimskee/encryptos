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

# nodes (Godot 4.x uses @onready)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# state
var facing_right: bool = true
var jumps_left: int = 1
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var hurt_timer: float = 0.0
var control_enabled: bool = true
var is_attacking: bool = false

func _ready() -> void:
	jumps_left = max_jumps
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		if sprite.animation != "Idle":
			sprite.play("Idle")

func _physics_process(delta: float) -> void:
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
		input_dir = Input.get_axis("Left", "Right") # -1..1
	
	# attack input (left mouse button)
	if control_enabled and not is_attacking and Input.is_action_just_pressed("Attack"):
		_start_attack()
	
	# horizontal accel/decel toward target_x
	var target_x := input_dir * speed
	# Fixed: proper ternary syntax in GDScript
	var change_rate := accel if abs(target_x) > abs(velocity.x) else deccel
	velocity.x = move_toward(velocity.x, target_x, change_rate * delta)
	
	# flip sprite if needed (not during attack)
	if not is_attacking:
		if input_dir > 0.0 and not facing_right:
			_flip(true)
		elif input_dir < 0.0 and facing_right:
			_flip(false)
	
	# jump input: buffer the press (can't jump while attacking)
	if control_enabled and not is_attacking and Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_time
	
	# perform jump if buffered + allowed (coyote or extra jumps)
	if jump_buffer_timer > 0.0 and not is_attacking:
		if coyote_timer > 0.0 and jumps_left > 0:
			_do_jump()
			jump_buffer_timer = 0.0
		elif not is_on_floor() and jumps_left > 0 and max_jumps > 1:
			_do_jump()
			jump_buffer_timer = 0.0
	
	# move (CharacterBody2D will update its velocity property)
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
	# End attack when the Attack animation finishes
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
	
	# attack takes priority
	if is_attacking:
		if sprite.animation != "Attack":
			sprite.play("Attack")
		return
	
	if not control_enabled and hurt_timer > 0.0:
		if sprite.animation != "Hurt":
			sprite.play("Hurt")
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
