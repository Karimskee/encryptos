extends Node2D

# عدد المحاولات قبل الخسارة
@export var max_attempts: int = 3 

var attempts_left: int
var resets_left: int = 0

const ALPHABET := "abcdefghijklmnopqrstuvwxyz"

# متغيرات لحفظ حالة المرحلة الحالية
var current_level_config: Dictionary
var current_cipher_index: int = 0 
var current_cipher_name: String
var current_key: String
var ciphertext: String
var plaintext_target: String = "" # الكلمة المطلوبة (من الجيم مانجر)


func _ready():
	randomize()
	
	# ربط الأزرار
	if $CanvasLayer/Control/HBoxContainer.has_node("BtnSubmit"):
		$CanvasLayer/Control/HBoxContainer/BtnSubmit.pressed.connect(_on_submit)
	if $CanvasLayer/Control/HBoxContainer.has_node("BtnReset"):
		$CanvasLayer/Control/HBoxContainer/BtnReset.pressed.connect(_on_reset)
	
	# 1. هات بيانات الليفل الحالي من GameManager
	current_level_config = GameManager.get_current_level_data()
	
	# 2. حدد عدد الريسيت المتاح
	# (بيساوي عدد أنواع التشفير المتاحة - 1) عشان تقدر تقلب بينهم
	var available_ciphers = current_level_config["ciphers"] as Array
	resets_left = max(0, available_ciphers.size() - 1)
	
	# 3. ابدأ اللغز
	_start_new_round()


func _start_new_round():
	attempts_left = max_attempts
	
	# ناخد الكلمة من الكونفيج
	plaintext_target = current_level_config["text"]
	
	print(">>> Level:", GameManager.current_level, " | Text:", plaintext_target)
	
	# توليد اللغز
	_generate_cipher_puzzle()


func _generate_cipher_puzzle():
	# تحديد نوع التشفير بناءً على الـ Index الحالي (عشان الريسيت يغيره)
	var ciphers_list = current_level_config["ciphers"]
	
	if current_cipher_index >= ciphers_list.size():
		current_cipher_index = 0
		
	current_cipher_name = ciphers_list[current_cipher_index]
	
	# --- منطق التشفير ---
	match current_cipher_name:
		"Caesar":
			var k = randi() % 25 + 1
			current_key = str(k)
			ciphertext = _caesar_encrypt(plaintext_target, k)

		"Playfair":
			var keyphrase = _random_word(int(randi() % 5) + 4)
			current_key = keyphrase
			ciphertext = _playfair_encrypt(plaintext_target, keyphrase)

		"Hill":
			var key2x2 = _hill_generate_key()
			current_key = _hill_key_to_string(key2x2)
			ciphertext = _hill_encrypt(plaintext_target, key2x2)

		"Monoalphabetic":
			var map = _mono_generate_map()
			current_key = _mono_map_to_string(map)
			ciphertext = _mono_encrypt(plaintext_target, map)

		"Polyalphabetic", "Vigenere": # Both use Vigenere logic
			var klen = int(randi() % 6) + 5
			var k = ""
			for i in range(klen):
				k += ALPHABET[randi() % 26]
			current_key = k
			ciphertext = _vigenere_encrypt(plaintext_target, k)

		"One-Time Pad":
			var pad = _generate_pad(plaintext_target.length())
			current_key = _pad_to_string(pad)
			ciphertext = _otp_encrypt(plaintext_target, pad)

		"Rail Fence":
			var depth = (randi() % 4) + 2
			current_key = str(depth)
			ciphertext = _rail_fence_encrypt(plaintext_target, depth)

		"Row Column Transposition":
			var cols = (randi() % 5) + 3
			var order = _random_permutation(cols)
			current_key = _permutation_to_string(order)
			ciphertext = _columnar_encrypt(plaintext_target, order)

	# --- تحديث واجهة المستخدم (UI) ---
	_update_ui_elements()


func _update_ui_elements():
	var input_box = $CanvasLayer/Control/InputAnswer
	if GameManager.current_level == 5:
		input_box.placeholder_text = "Type the FULL sentence..."
	else:
		input_box.placeholder_text = "Type the decrypted word..."
	# النصوص
	$CanvasLayer/Control/LabelCipherName.text = "Cipher: " + current_cipher_name
	$CanvasLayer/Control/LabelCipher.text = "Ciphertext: " + ciphertext
	$CanvasLayer/Control/LabelKey.text = "Key: " + current_key
	
	# العدادات
	if $CanvasLayer/Control.has_node("LabelAttempts"):
		$CanvasLayer/Control/LabelAttempts.text = "%d" % attempts_left
	if $CanvasLayer/Control.has_node("LabelResets"):
		$CanvasLayer/Control/LabelResets.text = "%d" % resets_left
	
	# زر الريسيت
	if $CanvasLayer/Control/HBoxContainer.has_node("BtnReset"):
		$CanvasLayer/Control/HBoxContainer/BtnReset.disabled = (resets_left <= 0)
	
	# تنظيف حقل الإدخال
	$CanvasLayer/Control/InputAnswer.text = ""
	$CanvasLayer/Control/InputAnswer.grab_focus()


func _on_submit():
	var answer = $CanvasLayer/Control/InputAnswer.text.strip_edges()

	# 1. الإجابة صحيحة
	if answer.to_lower() == plaintext_target.to_lower():
		print("Correct Answer!")
		
		# نزود الليفل في الجيم مانجر
		GameManager.next_level()
		
		# نروح للمشهد التالي (الليفل الجاي أو شاشة الفوز)
		var next_scene = GameManager.get_next_scene_path()
		get_tree().change_scene_to_file(next_scene)
		
	# 2. الإجابة خاطئة
	else:
		attempts_left -= 1
		_update_ui_elements() # تحديث العدادات

		if attempts_left <= 0:
			print("Game Over - Restarting Puzzle")
			# لو خسر، يعيد نفس اللغز (أو ممكن تخليه يعيد الليفل كله لو حابب عقاب أكبر)
			get_tree().reload_current_scene()


func _on_reset():
	if resets_left > 0:
		resets_left -= 1
		
		# تغيير نوع التشفير (نقلب على النوع اللي بعده في القائمة)
		var ciphers_list = current_level_config["ciphers"]
		current_cipher_index = (current_cipher_index + 1) % ciphers_list.size()
		
		# إعادة توليد اللغز بنفس الكلمة بس بالتشفير الجديد
		_generate_cipher_puzzle()
	else:
		# المفروض الزرار يكون disabled بس زيادة تأكيد
		print("No resets left!")


# ======================================================
#                  خوارزميات التشفير
# ======================================================

# ---------- Caesar ----------
func _caesar_encrypt(text: String, shift: int) -> String:
	var out := ""
	for c in text:
		var code = c.unicode_at(0)
		if code >= 97 and code <= 122:
			out += String.chr(((code - 97 + shift) % 26) + 97)
		elif code >= 65 and code <= 90:
			out += String.chr(((code - 65 + shift) % 26) + 65)
		else:
			out += c
	return out

# ---------- Monoalphabetic ----------
func _mono_generate_map() -> Dictionary:
	var letters: Array = ALPHABET.split("")
	letters.erase("")
	letters.shuffle()
	var shuffled: Array = letters.duplicate()
	shuffled.shuffle()
	var map := {}
	for i in range(letters.size()):
		map[letters[i]] = shuffled[i]
	return map

func _mono_map_to_string(map: Dictionary) -> String:
	var s := ""
	for ch in ALPHABET:
		if map.has(ch): s += ch + "->" + str(map[ch]) + " "
	return s.strip_edges()

func _mono_encrypt(text: String, map: Dictionary) -> String:
	var out := ""
	for ch in text:
		var low := ch.to_lower()
		if map.has(low):
			var enc: String = str(map[low])
			if ch.to_upper() == ch and ch.to_lower() != ch:
				out += enc.to_upper()
			else:
				out += enc
		else:
			out += ch
	return out

# ---------- Vigenère / Polyalphabetic ----------
func _vigenere_encrypt(text: String, key: String) -> String:
	var out := ""
	var kidx := 0
	var klen := key.length()
	for c in text:
		var low := c.to_lower()
		if ALPHABET.find(low) != -1:
			var key_char = key[kidx % klen]
			var shift = ALPHABET.find(key_char)
			var base = 65 if (c.to_upper() == c and c.to_lower() != c) else 97
			var code = c.unicode_at(0)
			var letter_index = code - base
			var newc = ((letter_index + shift) % 26) + base
			out += String.chr(newc)
			kidx += 1
		else:
			out += c
	return out

# ---------- OTP ----------
func _generate_pad(length: int) -> PackedInt32Array:
	var pad := PackedInt32Array()
	for i in range(length):
		pad.append(randi() % 26)
	return pad

func _pad_to_string(pad: PackedInt32Array) -> String:
	var s := ""
	for v in pad: s += str(v) + " "
	return s.strip_edges()

func _otp_encrypt(text: String, pad: PackedInt32Array) -> String:
	var out := ""
	var idx := 0
	for c in text:
		var low := c.to_lower()
		if ALPHABET.find(low) != -1:
			var base = 65 if (c.to_upper() == c and c.to_lower() != c) else 97
			var code = c.unicode_at(0)
			var letter_index = code - base
			var shift = pad[idx] % 26
			var newc = ((letter_index + shift) % 26) + base
			out += String.chr(newc)
			idx += 1
		else:
			out += c
	return out

# ---------- Rail Fence ----------
func _rail_fence_encrypt(text: String, depth: int) -> String:
	if depth <= 1: return text
	var rails := []
	for i in range(depth): rails.append("")
	var rail = 0
	var dir = 1
	for c in text:
		rails[rail] += c
		rail += dir
		if rail == 0: dir = 1
		elif rail == depth:
			rail = depth - 2
			dir = -1
	var out := ""
	for r in rails: out += r
	return out

# ---------- Columnar ----------
func _random_permutation(n: int) -> PackedInt32Array:
	var arr := PackedInt32Array()
	for i in range(n): arr.append(i)
	for i in range(n - 1, 0, -1):
		var j = randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr

func _permutation_to_string(permutation: PackedInt32Array) -> String:
	var s := ""
	for v in permutation: s += str(v) + ","
	return s.trim_suffix(",")

func _columnar_encrypt(text: String, order: PackedInt32Array) -> String:
	var clean := text.replace(" ", "")
	var cols = order.size()
	var rows = int(ceil(float(clean.length()) / cols))
	var grid := []
	for r in range(rows):
		var row_s := ""
		for c in range(cols):
			var idx = r * cols + c
			row_s += clean[idx] if idx < clean.length() else "x"
		grid.append(row_s)
	var out := ""
	for idx in order:
		for r in range(rows):
			out += str(grid[r][idx])
	return out

# ---------- Playfair ----------
func _prepare_playfair_table(keyphrase: String) -> Array:
	var used := {}
	var table := []
	var s := (keyphrase + ALPHABET).to_lower().replace("j","i")
	for ch in s:
		if ch == " " or used.has(ch): continue
		if ch >= "a" and ch <= "z":
			used[ch] = true
			table.append(ch)
			if table.size() == 25: break
	return table

func _playfair_pos_of(table: Array, ch: String) -> Vector2i:
	ch = ch.replace("j","i")
	for i in range(table.size()):
		if table[i] == ch: return Vector2i(i / 5, i % 5)
	return Vector2i(-1, -1)

func _playfair_encrypt(text: String, keyphrase: String) -> String:
	var table = _prepare_playfair_table(keyphrase)
	var clean := text.to_lower().replace("j","i").replace(" ", "")
	var digraphs := []
	var i := 0
	while i < clean.length():
		var a = clean[i]
		var b = "x"
		if i + 1 < clean.length():
			b = clean[i + 1]
			if a == b:
				b = "x"
				i += 1
			else:
				i += 2
		else:
			i += 1
		digraphs.append([a, b])
	var out := ""
	for pair in digraphs:
		var pa = _playfair_pos_of(table, pair[0])
		var pb = _playfair_pos_of(table, pair[1])
		if pa.x == pb.x:
			out += table[pa.x * 5 + ((pa.y + 1) % 5)]
			out += table[pb.x * 5 + ((pb.y + 1) % 5)]
		elif pa.y == pb.y:
			out += table[((pa.x + 1) % 5) * 5 + pa.y]
			out += table[((pb.x + 1) % 5) * 5 + pb.y]
		else:
			out += table[pa.x * 5 + pb.y]
			out += table[pb.x * 5 + pa.y]
	return out

# ---------- Hill ----------
func _hill_generate_key() -> PackedInt32Array:
	var mat := PackedInt32Array()
	for _i in range(1000):
		var a = randi() % 26
		var b = randi() % 26
		var c = randi() % 26
		var d = randi() % 26
		var det = (a * d - b * c) % 26
		if det < 0: det += 26
		if det != 0 and _gcd(det, 26) == 1:
			mat.append(a); mat.append(b); mat.append(c); mat.append(d)
			return mat
	mat.append(1); mat.append(0); mat.append(0); mat.append(1)
	return mat

func _hill_key_to_string(mat: PackedInt32Array) -> String:
	if mat.size() < 4: return "1 0 0 1"
	return str(mat[0]) + " " + str(mat[1]) + " " + str(mat[2]) + " " + str(mat[3])

func _hill_encrypt(text: String, mat: PackedInt32Array) -> String:
	var clean := ""
	for ch in text.to_lower():
		if ch >= "a" and ch <= "z": clean += ch
	if clean.length() % 2 == 1: clean += "x"
	var out := ""
	var a = 1; var b = 0; var c = 0; var d = 1
	if mat.size() >= 4:
		a = mat[0]; b = mat[1]; c = mat[2]; d = mat[3]
	for i in range(0, clean.length(), 2):
		var x = clean[i].unicode_at(0) - 97
		var y = clean[i + 1].unicode_at(0) - 97
		var rx = (a * x + b * y) % 26
		var ry = (c * x + d * y) % 26
		if rx < 0: rx += 26
		if ry < 0: ry += 26
		out += String.chr(rx + 97) + String.chr(ry + 97)
	
	var spaced_out := ""
	var src_i = 0
	for ch in text:
		if ch == " ": spaced_out += " "
		elif (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z"):
			if src_i < out.length():
				spaced_out += out[src_i]
				src_i += 1
			else: spaced_out += "x"
		else: spaced_out += ch
	return spaced_out

func _gcd(a: int, b: int) -> int:
	a = abs(a)
	b = abs(b)
	while b != 0:
		var t = b
		b = a % b
		a = t
	return abs(a)

func _random_word(length: int) -> String:
	var s := ""
	for i in range(length): s += ALPHABET[randi() % 26]
	return s
