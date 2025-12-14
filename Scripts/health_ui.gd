extends CanvasLayer

@onready var heart_container = $MarginContainer/HeartContainer

# حط مسار الصور بتاعتك هنا
@export var heart_full_texture: Texture2D
@export var heart_empty_texture: Texture2D

var hearts: Array[TextureRect] = []

func _ready():
	# اجمع كل القلوب
	for child in heart_container.get_children():
		if child is TextureRect:
			hearts.append(child)
	
	# ابحث عن اللاعب
	await get_tree().process_frame  # استنى فريم واحد عشان اللاعب يتحمل
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		_update_hearts(player.current_health, player.max_health)
	else:
		print("Warning: Player not found in 'player' group!")


func _on_health_changed(current_health: int, max_health: int):
	_update_hearts(current_health, max_health)


func _update_hearts(current: int, maximum: int):
	# خلي عدد القلوب يساوي الـ max_health
	_adjust_heart_count(maximum)
	
	# حدّث كل قلب
	for i in range(hearts.size()):
		if i < maximum:
			hearts[i].visible = true
			if i < current:
				# قلب ممتلئ
				hearts[i].texture = heart_full_texture
			else:
				# قلب فاضي
				hearts[i].texture = heart_empty_texture
		else:
			hearts[i].visible = false


func _adjust_heart_count(needed_count: int):
	# لو محتاجين قلوب أكتر
	while hearts.size() < needed_count:
		var new_heart = TextureRect.new()
		new_heart.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		new_heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		new_heart.custom_minimum_size = Vector2(32, 32)
		heart_container.add_child(new_heart)
		hearts.append(new_heart)
	
	# لو القلوب أكتر من اللازم، خبيهم
	for i in range(needed_count, hearts.size()):
		hearts[i].visible = false
