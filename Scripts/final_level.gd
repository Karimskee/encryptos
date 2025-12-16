extends Node2D

# 🖼️ تعريف الصور (تأكد إن المسارات صحيحة عندك)
@onready var player_portrait = preload("res://assets/Character/h1.png")
@onready var boss_portrait = preload("res://assets/Character/vairos.png") # أو صورة البوس لو عندك

# 🔗 ربط النودز
@onready var boss = $Final_boss # تأكد من اسم نود البوس في الشجرة

func _ready():
	# استنى لحظة عشان التحميل
	await get_tree().create_timer(0.5).timeout
	
	var player = get_tree().get_first_node_in_group("Player")
	
	if not player or not boss:
		print("Error: Player or Boss not found!")
		return
	
	# 💬 سيناريو الحوار
	var boss_dialogue = [
		{
			"speaker": "الفايروس (The Core)",
			"text": "وصلت لحد هنا؟ مجهود يحترم... بس دي نهايتك.",
			"portrait": boss_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "رجع كل الملفات اللي شفرتها، وامسح نفسك حالا!",
			"portrait": player_portrait
		},
		{
			"speaker": "الفايروس (The Core)",
			"text": "ههههه... أنت فاكر إنك لسه ليك سيطرة هنا؟",
			"portrait": boss_portrait
		},
		{
			"speaker": "الفايروس (The Core)",
			"text": "أنا بقيت جزء من النظام... لو مسحتني، الجهاز كله هيقع.",
			"portrait": boss_portrait
		},
		{
			"speaker": "النظام",
			"text": "⚠️ تحذير: مستوى الخطر 99%. التكامل مع النواة اكتمل.",
			"portrait": null, # ممكن تحط صورة النظام هنا
			"alert": true
		},
		{
			"speaker": "عبدالرحمن",
			"text": "مش هسمح بده يحصل... معايا الـ Access Code الأخير.",
			"portrait": player_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "والكود ده هو... سيفي!",
			"portrait": player_portrait
		},
		{
			"speaker": "الفايروس (The Core)",
			"text": "وريني شطارتك يا... 'Antivirus'",
			"portrait": boss_portrait
		}
	]
	
	# 1. تشغيل الحوار
	DialogueBox.show_dialogue(boss_dialogue, player)
	
	# 2. انتظار انتهاء الحوار
	await DialogueBox.dialogue_finished
	
	# 3. بدء المعركة!
	if boss.has_method("start_battle"):
		boss.start_battle()
	
	# (اختياري) تشغيل موسيقى الحماس هنا
	# $Audio/BossMusic.play()
