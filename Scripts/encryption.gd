extends Node2D

# عدد المحاولات قبل الخسارة
@export var max_attempts: int = 3 

var attempts_left: int
var resets_left: int = 0

# متغيرات لحفظ حالة المرحلة الحالية
var current_level_config: Dictionary
var current_cipher_index: int = 0 
var current_cipher_name: String
var current_key: String
var ciphertext: String
var plaintext_target: String = "" 

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
	plaintext_target = current_level_config["text"]
	
	print(">>> Level:", GameManager.current_level, " | Text:", plaintext_target)
	
	_generate_cipher_puzzle()

func _generate_cipher_puzzle():
	var ciphers_list = current_level_config["ciphers"]
	
	if current_cipher_index >= ciphers_list.size():
		current_cipher_index = 0
		
	current_cipher_name = ciphers_list[current_cipher_index]
	
	# ==================================================================
	# هنا الاستدعاء الجديد (النظيف) باستخدام الكلاسات الخارجية
	# ==================================================================
	match current_cipher_name:
		"Caesar":
			# Caesar.gd يستخدم int للمفتاح [cite: 42]
			var k_int = Caesar.generate_random_key()
			current_key = str(k_int)
			ciphertext = Caesar.encrypt(k_int, plaintext_target)

		"Playfair":
			# Playfair.gd يستخدم String للمفتاح [cite: 19]
			current_key = Playfair.generate_random_key()
			ciphertext = Playfair.encrypt(current_key, plaintext_target)

		"Hill":
			# Hill.gd يحتاج مفتاح 4 حروف صالح رياضياً [cite: 44]
			current_key = Hill.generate_valid_key()
			ciphertext = Hill.encrypt(current_key, plaintext_target)

		"Monoalphabetic":
			# Monoalphabetic.gd يولد مفتاح 26 حرف عشوائي [cite: 8]
			current_key = Monoalphabetic.generate_random_key()
			ciphertext = Monoalphabetic.encrypt(current_key, plaintext_target)

		"Polyalphabetic", "Vigenere":
			# Polyalphabetic.gd [cite: 13]
			current_key = Polyalphabetic.generate_random_key() # طول عشوائي
			ciphertext = Polyalphabetic.encrypt(current_key, plaintext_target)

		"One-Time Pad":
			# OTP يحتاج مفتاح بنفس طول النص [cite: 27]
			current_key = OneTimePad.generate_random_key(plaintext_target.length())
			ciphertext = OneTimePad.encrypt(current_key, plaintext_target)

		"Rail Fence":
			# RailFence.gd يستخدم int للسكك (Rails) [cite: 1]
			var rails_int = RailFence.generate_random_key()
			current_key = str(rails_int)
			ciphertext = RailFence.encrypt(rails_int, plaintext_target)

		"Row Column Transposition":
			# RowColumnTransposition.gd [cite: 30]
			current_key = RowColumnTransposition.generate_random_key()
			ciphertext = RowColumnTransposition.encrypt(current_key, plaintext_target)

	# --- تحديث الواجهة ---
	_update_ui_elements()

func _update_ui_elements():
	var input_box = $CanvasLayer/Control/InputAnswer
	
	if GameManager.current_level == 5:
		input_box.placeholder_text = "Type the FULL sentence..."
	else:
		input_box.placeholder_text = "Type the decrypted word..."
		
	$CanvasLayer/Control/LabelCipherName.text = "Cipher: " + current_cipher_name
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
		GameManager.next_level()
		var next_scene = GameManager.get_next_scene_path()
		get_tree().change_scene_to_file(next_scene)
		
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
