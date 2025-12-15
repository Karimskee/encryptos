extends Area2D

# الصور
@onready var krimsky_portrait = preload("res://assets/Character/h2.png") 
@onready var player_portrait = preload("res://assets/Character/h1.png") 

# التلميح
@onready var hint_label = $Label 

var player_in_range = false
var player_ref = null 
var ability_given = false 

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
	if player_in_range and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		start_buff_dialogue()

func start_buff_dialogue():
	if hint_label: hint_label.visible = false
	
	var dialogue_data = []
	
	if not ability_given:
		# --- حوار ما قبل المعركة ---
		dialogue_data = [
			{
				"speaker": "كريمسكي",
				"text": "استنى يا عبدو! ... سمعت انك رايح تقابل 'الفايروس' وش لوش.",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "عبدالرحمن",
				"text": "اه... لازم انهي المهزلة دي. وسع كدا خليني اروح له.",
				"portrait": player_portrait
			},
			{
				"speaker": "كريمسكي",
				"text": "تروح له كدا؟ بمسدس الماية ده؟ ده هيفرمك يا ابني!",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "كريمسكي",
				"text": "الفايروس ده الـ Armor بتاعه عالي جدا... ضرباتك العادية دي هتدغدغه بس.",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "عبدالرحمن",
				"text": "طب والعمل؟ مفيش وقت نضيعه!",
				"portrait": player_portrait
			},
			{
				"speaker": "كريمسكي",
				"text": "خد... ده كود 'Overclock' لسه سارقه حالا من ملفات الكيرنل.",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "كريمسكي",
				"text": "الكود ده هيخلي دمج سلاحك الضعف... يعني الضربة الواحدة بـ 2.",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "عبدالرحمن",
				"text": "ايوة بقى! هو ده الكلام... جهز نفسك يا فايروس الكلب.",
				"portrait": player_portrait
			},
			{
				"speaker": "النظام",
				"text": "تم تفعيل التحديث: مضاعفة الضرر (Damage x2).",
				"portrait": krimsky_portrait,
				"alert": true
			}
		]
	else:
		# --- لو رجعت تكلمه تاني ---
		dialogue_data = [
			{
				"speaker": "كريمسكي",
				"text": "انت لسه هنا؟ اجري يا مجنون قبل ما الفايروس يغير الشفرة!",
				"portrait": krimsky_portrait
			},
			{
				"speaker": "عبدالرحمن",
				"text": "خلاص رايح اهو... ادعيلي.",
				"portrait": player_portrait
			}
		]
	
	# تشغيل الحوار
	DialogueBox.show_dialogue(dialogue_data, player_ref)
	
	await DialogueBox.dialogue_finished
	
	# --- تفعيل القوة ---
	# ... (بعد انتهاء الحوار)
	if not ability_given and player_ref:
		# 1. تفعيلها للاعب الحالي
		if "attack_damage" in player_ref:
			player_ref.attack_damage = 2
		
		# 2. حفظها للأبد في الجيم مانجر
		GameManager.current_damage = 2
		
		ability_given = true
		print("Damage Upgraded & Saved!")
