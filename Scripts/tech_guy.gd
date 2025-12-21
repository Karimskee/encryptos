extends Area2D

# الصور
@onready var krimsky_portrait = preload("res://assets/Character/h2.png") 
@onready var player_portrait = preload("res://assets/Character/h1.png") 

# التلميح
@onready var hint_label = $Label 

var player_in_range = false
var player_ref = null 
var ability_given = false # عشان ميدكش القدرة كل مرة

func _ready():
	if hint_label:
		hint_label.text = "Press 'E'"
		hint_label.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		player_ref = body 
		if hint_label: hint_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		if hint_label: hint_label.visible = false

func _input(event):
	# التفاعل بزرار E
	if player_in_range and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		start_upgrade_dialogue()

func start_upgrade_dialogue():
	if hint_label: hint_label.visible = false
	
	var dialogue_data = []
	
	if not ability_given:
		# --- حوار الاكتشاف (اول مرة) ---
		dialogue_data = [
			{
				"speaker": "كريمسكي",
				"text": "عبدالرحمن! تعال بسرعة... انا اكتشفت اكتشاف هيودينا في داهية!",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "عبدالرحمن",
				"text": "يا ساتر يارب! في ايه؟ الفايروس مسح ملفات السيستم تاني؟",
				"portrait": player_portrait
			},
			{
				"speaker": "كريمسكي",
				"text": "لا يا عم... انا وانا بنبش في اكواد اللعبة لقيت سطر كود مكسور.",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "كريمسكي",
				"text": "الكود ده بيخليك تكسر الجاذبية... لو دوست نط وانت في الهوا، هتنط تاني!",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "عبدالرحمن",
				"text": "بتهزر؟ قصدك دبل جمب؟... طب ما تجيب الكود ده اجربه كدا.",
				"portrait": player_portrait
			},
			{
				"speaker": "كريمسكي",
				"text": "خد يا سيدي... بس اوعى تقع وتفضحنا، انا سارقه من ملفات الادمن.",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "النظام",
				"text": "تم تفعيل القدرة: القفزة المزدوجة (Double Jump).",
				"portrait": krimsky_portrait,
				"alert": true
			}
		]
	else:
		# --- حوار لو كلمته تاني ---
		dialogue_data = [
			{
				"speaker": "كريمسكي",
				"text": "ايه الاخبار؟ الكود شغال معاك ولا وقعت علي جدورك؟",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "عبدالرحمن",
				"text": "عيب عليك... ده انا بقيت بتنطط زي القرد.",
				"portrait": player_portrait
			}
		]
	
	# تشغيل الحوار
	DialogueBox.show_dialogue(dialogue_data, player_ref)
	
	await DialogueBox.dialogue_finished
	
	# تفعيل القدرة في سكريبت اللاعب
	# ... (بعد انتهاء الحوار)
	if not ability_given and player_ref:
		# 1. تفعيلها للاعب الحالي
		if "can_double_jump" in player_ref:
			player_ref.can_double_jump = true
		
		# 2. حفظها للأبد في الجيم مانجر (عشان الليفيلات الجاية)
		GameManager.unlocked_double_jump = true 
		
		ability_given = true
		print("Double Jump Unlocked & Saved!")
