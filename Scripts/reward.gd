extends Area2D

var entered = false  

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)  

func _on_body_entered(body):
	if body.name == "Player":
		print("Player detected!")
		entered = true  
		if body.has_method("play_enter_animation"):
			body.play_enter_animation()

func _on_body_exited(body: PhysicsBody2D) -> void:
	if body.name == "Player":
		entered = false
		print("Player exited!")

func _process(delta: float) -> void:
	if entered == true:
		if Input.is_action_just_pressed("Enter"):
			print("Enter pressed! Changing scene...")
			Transition.fade_out(func ():get_tree().change_scene_to_file("res://Scens/encryption.tscn"))  
			
			
