extends Node2D

# عدد المحاولات قبل الخسارة
@export var max_attempts: int = 3 

var attempts_left: int
var resets_left: int = 0

# متغيرات لحفظ حالة المرحلة الحالية
var current_level_config: Dictionary
var current_cipher_index: int = 0 
var current_cipher_name: String
var current_cipher: Script
var current_key: Variant
var ciphertext: String
var plaintext_target: String = "" 

var plaintexts_list = [
	"DAVID",
	"KARIMSKEE",
	"ZAUZUO",
	"CAT",
	"DUCK",
	"ALGORITHM",
	"BINARY",
	"CIPHER",
	"DECRYPT",
	"ENCRYPT",
	"FIREWALL",
	"GLITCH",
	"HACKER",
	"INTERNET",
	"JAVA",
	"KERNEL",
	"LOGIC",
	"MATRIX",
	"NETWORK",
	"OFFSET",
	"PROTOCOL",
	"QUANTUM",
	"ROUTER",
	"SECURITY",
	"TOGGLE",
	"UPLOAD",
	"VECTOR",
	"WIZARD",
	"XENON",
	"YIELD",
	"ZIGZAG",
]

func _ready():
	randomize()
	
	if $CanvasLayer/Control/HBoxContainer.has_node("BtnSubmit"):
		$CanvasLayer/Control/HBoxContainer/BtnSubmit.pressed.connect(_on_submit)
	if $CanvasLayer/Control/HBoxContainer.has_node("BtnReset"):
		$CanvasLayer/Control/HBoxContainer/BtnReset.pressed.connect(_on_reset)
	
	# 1. هات بيانات الليفل الحالي
	current_level_config = GameManager.get_current_level_data()
	
	# 2. حدد عدد الريسيت المتاح
	var available_ciphers = current_level_config["ciphers"] as Array
	resets_left = max(0, available_ciphers.size() - 1)
	
	# 3. ابدأ اللغز
	_start_new_round()

func _start_new_round():
	attempts_left = max_attempts
	plaintext_target = plaintexts_list[randi() % plaintexts_list.size()]
	
	print(">>> Level:", GameManager.current_level, " | Text:", plaintext_target)
	
	_generate_cipher_puzzle()

func _generate_cipher_puzzle():
	var ciphers_list = Ciphers.ciphers_list
	
	# Choose a random cipher
	current_cipher_index = randi() % ciphers_list.size()
	current_cipher = ciphers_list[current_cipher_index]
	
	# Generate a random key
	if current_cipher != OneTimePad:
		current_key = current_cipher.generate_random_key()
	else:
		# OneTimePad's key is dependant on the plaintext's length
		current_key = current_cipher.generate_random_key(plaintext_target.length())
			
	# Get the ciphertext
	ciphertext = current_cipher.encrypt(current_key, plaintext_target)
	
	# Ensure current_key is a string (for UI)
	if (typeof(current_key) == typeof(0)):
		current_key = str(current_key)
	
	# Update UI based on previous results
	_update_ui_elements()

func _update_ui_elements():
	var input_box = $CanvasLayer/Control/InputAnswer
	
	if GameManager.current_level == 5:
		input_box.placeholder_text = "Type the FULL sentence..."
	else:
		input_box.placeholder_text = "Type the decrypted word..."
		
	$CanvasLayer/Control/LabelCipherName.text = "Cipher: " + current_cipher.get_global_name()
	$CanvasLayer/Control/LabelCipher.text = "Ciphertext: " + ciphertext
	$CanvasLayer/Control/LabelKey.text = "Key: " + current_key
	
	if $CanvasLayer/Control.has_node("LabelAttempts"):
		$CanvasLayer/Control/LabelAttempts.text = "%d" % attempts_left
	if $CanvasLayer/Control.has_node("LabelResets"):
		$CanvasLayer/Control/LabelResets.text = "%d" % resets_left
	
	if $CanvasLayer/Control/HBoxContainer.has_node("BtnReset"):
		$CanvasLayer/Control/HBoxContainer/BtnReset.disabled = (resets_left <= 0)
	
	$CanvasLayer/Control/InputAnswer.text = ""
	$CanvasLayer/Control/InputAnswer.grab_focus()

func _on_submit():
	var answer = $CanvasLayer/Control/InputAnswer.text.strip_edges()

	# مقارنة الإجابة (تجاهل حالة الأحرف)
	if answer.to_lower() == plaintext_target.to_lower():
		print("Correct Answer!")

		Transition.fade_out(func ():get_tree().change_scene_to_file("res://Scens/practice.tscn"))
		
	else:
		attempts_left -= 1
		_update_ui_elements()

		if attempts_left <= 0:
			print("Game Over - Restarting Puzzle")
			get_tree().reload_current_scene()

func _on_reset():
	if resets_left > 0:
		resets_left -= 1
		
		var ciphers_list = current_level_config["ciphers"]
		current_cipher_index = (current_cipher_index + 1) % ciphers_list.size()
		
		_generate_cipher_puzzle()
	else:
		print("No resets left!")
