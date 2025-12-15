extends Node2D

# --- تحميل صور الشخصيات ---
@onready var player_portrait = preload("res://assets/Character/h1.png")
@onready var system_portrait = preload("res://assets/Character/h2.png")
@onready var virus_portrait = preload("res://assets/Character/reload.png")

func _ready():
	# استنى نص ثانية عشان التحميل
	await get_tree().create_timer(0.5).timeout
	
	# 1. تجميد اللاعب (نفس الكود اللي فات)
	var player = get_tree().get_first_node_in_group("Player")
	
	if player:
		player.set_physics_process(false)
		player.set_process(false)
		player.velocity = Vector2.ZERO
		if player.has_node("AnimatedSprite2D"):
			player.get_node("AnimatedSprite2D").play("Idle")
	
	# 2. سيناريو النهاية
	var ending_dialogue = [
		{
			"speaker": "النظام",
			"text": "✅ تم قبول مفتاح فك التشفير: 'Sweet Duck Dance Time'.",
			"portrait": system_portrait,
			"alert": false
		},
		{
			"speaker": "الفايروس",
			"text": "لا... مستحيل! إزاي عرفت الكود؟! دي كانت خطتي المثالية!",
			"portrait": virus_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "بجد؟ 'بطة بترقص'؟ ده كان الباسورد اللي هيحمي النظام؟",
			"portrait": player_portrait
		},
		{
			"speaker": "الفايروس",
			"text": "أنا... بتمسح... لاااااااااا.....",
			"portrait": virus_portrait
		},
		{
			"speaker": "النظام",
			"text": "⚠️ تم حذف الملف الضار بنجاح. جاري استعادة جميع الملفات.",
			"portrait": system_portrait,
			"alert": true 
		},
		{
			"speaker": "النظام",
			"text": "أهلاً بعودتك يا عبدالرحمن. النظام آمن الآن بنسبة 100%.",
			"portrait": system_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "أخيراً... ملفاتي رجعت.",
			"portrait": player_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "أعتقد إني محتاج قهوة تانية... وإجازة طويلة.",
			"portrait": player_portrait
		}
	]
	
	# 3. تشغيل الحوار
	DialogueBox.show_dialogue(ending_dialogue, player)
	
	# استنى لما يخلص كلام
	await DialogueBox.dialogue_finished
	
	# 4. الخروج من اللعبة
	print("Game Finished. Exiting...")
	
	# (اختياري) استنى ثانيتين شاشة سوداء أو وقوف عشان النهاية تكون هادية
	await get_tree().create_timer(2.0).timeout 
	
	# قفل اللعبة
	get_tree().quit()
