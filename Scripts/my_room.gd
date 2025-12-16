extends Node2D

@onready var player_portrait = preload("res://assets/Character/h1.png")
@onready var system_portrait = preload("res://assets/Character/h2.png")
@onready var virus_portrait  = preload("res://assets/Character/reload.png")

func _ready():
	# استنى شوية عشان كل حاجة تجهز
	await get_tree().create_timer(0.5).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("Player not found in group 'player'")
		return
	
	# 🧠 قصة بداية اللعبة
	var intro_dialogue = [
		{
			"speaker": "عبدالرحمن",
			"text": "يوم عادي في الشغل… شوية كود وشوية قهوة.",
			"portrait": player_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "استنى… إيه الصوت ده؟",
			"portrait": player_portrait
		},
		{
			"speaker": "النظام",
			"text": "⚠️ تحذير: تم اكتشاف برنامج ضار غير معروف.",
			"portrait": system_portrait,
			"alert": true  # 🔥 إنذار أحمر
		},
		{
			"speaker": "عبدالرحمن",
			"text": "إيه؟! أنا ما نزّلتش حاجة!",
			"portrait": player_portrait
		},
		{
			"speaker": "???",
			"text": "متخافش… أنا بس باخد اللي مش بتقراه.",
			"portrait": virus_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "إنت مين؟!",
			"portrait": player_portrait
		},
		{
			"speaker": "الفايروس",
			"text": "أنا الفوضى بين السطور… وأنا اللي هشفر كل حاجة.",
			"portrait": virus_portrait
		},
		{
			"speaker": "النظام",
			"text": "⚠️ تنبيه: جاري تشفير الملفات الحرجة.",
			"portrait": system_portrait,
			"alert": true  # 🔥 إنذار تاني
		},
		{
			"speaker": "عبدالرحمن",
			"text": "لا… ملفاتي!",
			"portrait": player_portrait
		},
		{
			"speaker": "الفايروس",
			"text": "لو عايزهم… تعالى خدهم بنفسك.",
			"portrait": virus_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "تمام… أنا داخل جوه النظام.",
			"portrait": player_portrait
		}
	]
	
	DialogueBox.show_dialogue(intro_dialogue, player)
	await DialogueBox.dialogue_finished
	print("Intro finished – gameplay starts")
