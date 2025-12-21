extends Area2D

# الصور
@onready var krimsky_portrait = preload("res://assets/Character/h2.png") 
@onready var player_portrait = preload("res://assets/Character/h1.png") 

# التلميح اللي فوق راسه
@onready var hint_label = $Label 

var player_in_range = false
var player_ref = null 

func _ready():
	# اعداد التلميح
	if hint_label:
		hint_label.text = "Press 'E'" # نوضح للاعب يدوس ايه
		hint_label.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		player_ref = body 
		if hint_label:
			hint_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		player_ref = null
		if hint_label:
			hint_label.visible = false

func _input(event):
	# الشرط: اللاعب قريب + ضغط زرار E
	if player_in_range and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		start_tutorial_dialogue()

func start_tutorial_dialogue():
	# حوار كريمسكي وعبدالرحمن (ستايل انمي مصري)
	var dialogue_data = [
		{
			"speaker": "عبدالرحمن",
			"text": "ايه ده؟! كريمسكي؟!!... انت ايه اللي جابك هنا يا ابني؟",
			"portrait": player_portrait
		},
		{
			"speaker": "كريمسكي",
			"text": "والله مش بايدي يا خويا... كله بسبب الفايروس الهباب اللي انت حملته ده!",
			"portrait": krimsky_portrait
		},
		{
			"speaker": "كريمسكي",
			"text": "اديني اتحبست معاك جوه الكود... ولازم ننفد بجلدنا قبل ما يتمسح بينا البلاط.",
			"portrait": krimsky_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "طب والعمل يا هندسة؟ الباب مقفول والدنيا بايظة خالص.",
			"portrait": player_portrait
		},
		{
			"speaker": "كريمسكي",
			"text": "بص يا سيدي، الفايروس شفر ملفات السيستم كلها.",
			"portrait": krimsky_portrait
		},
		{
			"speaker": "كريمسكي",
			"text": "عشان نعدي من اي ليفل، لازم تحل لغز التشفير اللي هيظهرلك في الاخر.",
			"portrait": krimsky_portrait
		},
		{
			"speaker": "كريمسكي",
			"text": "وكل لغز هتحله هيديك 'كلمة'... جمع الكلمات دي عشان دي اللي هنفرتك بيها البوس في الاخر.",
			"portrait": krimsky_portrait
		},
		{
			"speaker": "عبدالرحمن",
			"text": "يعني احل الغاز واجمع كلمات عشان نطلع؟... قشطة، سيب الطلعة دي عليا!",
			"portrait": player_portrait
		}
	]
	
	# نخفي التلميح اثناء الكلام
	if hint_label:
		hint_label.visible = false
	
	# تشغيل الحوار
	DialogueBox.show_dialogue(dialogue_data, player_ref)
