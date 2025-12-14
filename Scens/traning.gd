extends Area2D

var changed := false
func _ready():
	body_entered.connect(_on_body_entered)
	

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not changed:
		changed = true
		get_tree().change_scene_to_file("res://Scens/level_2.tscn")
