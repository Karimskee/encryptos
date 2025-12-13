extends CharacterBody2D

@export var speed: float = 60.0
@export var gravity: float = 1200.0
@export var edge_offset: float = 20.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_ray: RayCast2D = $GroundRay

var direction: int = -1   # -1 = شمال | 1 = يمين
var dead := false


func _ready():
	sprite.play("Run")
	_update_ground_ray()


func _physics_process(delta):
	if dead:
		return

	_apply_gravity(delta)
	_move_enemy()
	_check_platform_edge()
	_check_wall()
	_update_animation()


func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0


func _move_enemy():
	velocity.x = speed * direction
	move_and_slide()


func _check_platform_edge():
	# لو مفيش أرض قدام العدو → لف
	if is_on_floor() and not ground_ray.is_colliding():
		_flip()


func _check_wall():
	# لو خبط في حيطة → لف
	if is_on_wall():
		_flip()


func _flip():
	direction *= -1
	sprite.flip_h = direction == 1
	_update_ground_ray()


func _update_ground_ray():
	ground_ray.target_position.x = edge_offset * direction


func _update_animation():
	if sprite.animation != "Run":
		sprite.play("Run")


func die():
	dead = true
	velocity = Vector2.ZERO
	sprite.play("Dead")
