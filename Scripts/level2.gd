extends Node2D

@export var next_scene_path: String = "res://Scens/player.tscn"
@export var previous_scene_path: String = "res://Scens/level_1.tscn"

var plaintext_pool := [
	"attack at dawn",
	"defend the castle",
	"meet me outside",
	"follow the north star",
	"retreat to the woods",
	"find the hidden key",
	"unlock the secret door",
	"danger is coming",
	"prepare for battle",
	"protect the kingdom",
	"the code is broken",
	"the treasure is buried",
	"march before sunrise",
	"secure the perimeter",
	"signal the allies",
	"hold your position",
	"gather more supplies",
	"escape through the tunnel",
	"the enemy is close",
	"capture the outpost",
	"move to higher ground",
	"stay silent and watch",
	"send reinforcements now",
	"we strike at midnight",
	"remember the password",
	"advance without fear",
	"watch the southern gate",
	"shut down the main core",
	"the system is unstable",
	"reload and regroup",
	"activate the beacon",
	"avoid all detection",
	"cover the west flank",
	"turn off the alarm",
	"scan the entire area",
	"decode the final message",
	"trust no one inside",
	"cross the river quietly",
	"hide the evidence carefully",
	"repair the broken bridge",
	"silence the radio broadcast",
	"retrieve the stolen map",
	"destroy the forbidden file",
	"await further instructions",
	"hold the line strongly",
	"do not break formation",
	"reinforce the front wall",
	"the threat is increasing",
	"evacuate the base immediately"
]

@export var max_attempts: int = 2
@export var cipher_choice: String = "random" # "random" or one of choices below


var attempts_left: int
var resets_left: int = 1    


const ALPHABET := "abcdefghijklmnopqrstuvwxyz"


var current_cipher_name: String
var current_key: String
var ciphertext: String
var plaintext_default: String = ""


func _update_ui_counts():
	# تأكد ان الـ Nodes موجودة قبل الاستخدام
	if $CanvasLayer/Control.has_node("LabelAttempts"):
		$CanvasLayer/Control/LabelAttempts.text = "%d" % attempts_left
	if $CanvasLayer/Control.has_node("LabelResets"):
		$CanvasLayer/Control/LabelResets.text = "%d" % resets_left

	# تعطيل زر الريسيت بصريًا لو مفيش ريسيتات
	if $CanvasLayer/Control/HBoxContainer.has_node("BtnReset"):
		$CanvasLayer/Control/HBoxContainer/BtnReset.disabled = (resets_left <= 0)



func _ready():
	randomize()
	$CanvasLayer/Control/HBoxContainer/BtnSubmit.pressed.connect(_on_submit)
	$CanvasLayer/Control/HBoxContainer/BtnReset.pressed.connect(_on_reset)
	_start_new_round()


func _start_new_round():
	attempts_left = max_attempts
	_update_ui_counts()

	# اختار جملة عشوائية
	plaintext_default = plaintext_pool[randi() % plaintext_pool.size()]
	# اختياري: تطبع في الـ Output لأغراض الديباغ
	print(">>> PLAINTEXT:", plaintext_default)

	# القائمة بالترتيب اللي طلبته بالظبط
	var choices = [
		"Caesar",
		"Playfair",
		"Hill",
		"Mono",
		"Poly",
		"One-Time Pad",
		"Rail Fence",
		"Row Column Transposition"
	]

	if cipher_choice == "random":
		current_cipher_name = choices[randi() % choices.size()]
	else:
		current_cipher_name = cipher_choice if cipher_choice in choices else "Caesar"

	match current_cipher_name:
		"Caesar":
			var k = randi() % 25 + 1
			current_key = str(k)
			ciphertext = _caesar_encrypt(plaintext_default, k)

		"Playfair":
			var keyphrase = _random_word(int(randi() % 5) + 4)
			current_key = keyphrase
			ciphertext = _playfair_encrypt(plaintext_default, keyphrase)

		"Hill":
			var key2x2 = _hill_generate_key()
			current_key = _hill_key_to_string(key2x2)
			ciphertext = _hill_encrypt(plaintext_default, key2x2)

		"Monoalphabetic":
			var map = _mono_generate_map()
			current_key = _mono_map_to_string(map)
			ciphertext = _mono_encrypt(plaintext_default, map)

		"Polyalphabetic":
			var klen = int(randi() % 6) + 5
			var k = ""
			for i in range(klen):
				k += ALPHABET[randi() % 26]
			current_key = k
			ciphertext = _vigenere_encrypt(plaintext_default, k)

		"One-Time Pad":
			var pad = _generate_pad(plaintext_default.length())
			current_key = _pad_to_string(pad)
			ciphertext = _otp_encrypt(plaintext_default, pad)

		"Rail Fence":
			var depth = (randi() % 4) + 2
			current_key = str(depth)
			ciphertext = _rail_fence_encrypt(plaintext_default, depth)

		"Row Column Transposition":
			var cols = (randi() % 5) + 3
			var order = _random_permutation(cols)
			current_key = _permutation_to_string(order)
			ciphertext = _columnar_encrypt(plaintext_default, order)

	# تحديث UI
	$CanvasLayer/Control/LabelCipherName.text = "Cipher: " + current_cipher_name
	$CanvasLayer/Control/LabelCipher.text = "Ciphertext: " + ciphertext
	$CanvasLayer/Control/LabelKey.text = "Key: " + current_key
	$CanvasLayer/Control/InputAnswer.text = ""
	$CanvasLayer/Control/InputAnswer.grab_focus()


func _on_submit():
	var answer = $CanvasLayer/Control/InputAnswer.text.strip_edges()

	# صح
	if answer.to_lower() == plaintext_default.to_lower():
		# نجاح — ممكن تنقّل المشهد
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)
			return
		else:
			_start_new_round()
			return

	# غلط → نقص محاولة
	attempts_left -= 1
	_update_ui_counts()

	if attempts_left > 0:
		$CanvasLayer/Control/InputAnswer.text = ""
		$CanvasLayer/Control/InputAnswer.grab_focus()
		return
	else:
		# خلصت المحاولات -> يموت أو يروح previous
		if previous_scene_path != "":
			get_tree().change_scene_to_file(previous_scene_path)
			return
		else:
			_start_new_round()
			return




func _on_reset():
	if resets_left > 0:
		resets_left -= 1
		# تعيد المحاولات للمقدار الأقصى (أو لو عايز تغيّر السلوك خليه يعيد نفس الجملة)
		attempts_left = max_attempts
		# لو بتحب تختار جملة جديدة: plaintext_default = plaintext_pool[randi() % plaintext_pool.size()]
		# ثم أعد توليد ciphertext مثل _start_new_round (أو مناداة _start_new_round مباشرة لو مقبول)
		# لو عايز الريسيت لا يغير الجملة، نفّذ تهيئة جزئية بدل _start_new_round()
		# هنا أسهل حل: نعيد نفس السيناريو بالكامل بدون إعادة resets_left:
		_start_new_round()
	else:
		# ممنوع — تعطيل الزر أو رسالة
		$CanvasLayer/Control/HBoxContainer.BtnReset.disabled = true
	_update_ui_counts()




# ======================================================
#                     CIPHERS
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
		s += ch + "->" + str(map[ch]) + " "
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


# ---------- Vigenère (used for Polyalphabetic) ----------
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
	for v in pad:
		s += str(v) + " "
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
	if depth <= 1:
		return text
	
	var rails := []
	for i in range(depth):
		rails.append("")
		
	var rail = 0
	var dir = 1 # 1 for down, -1 for up
	
	for c in text:
		# Check boundary *before* adding the character and update direction
		# If we hit the top rail (index 0) OR the bottom rail (index depth - 1)
		if rail == 0:
			dir = 1  # Must go down
		elif rail == depth - 1:
			dir = -1 # Must go up
			
		# Place the character on the rail
		rails[rail] += c
		
		# Move to the next rail
		rail += dir
		
	var out := ""
	for r in rails:
		out += r
	return out


# ---------- Columnar (Row Column Transposition) ----------
func _random_permutation(n: int) -> PackedInt32Array:
	var arr := PackedInt32Array()
	for i in range(n):
		arr.append(i)
	for i in range(n - 1, 0, -1):
		var j = randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr


func _permutation_to_string(permutation: PackedInt32Array) -> String:
	var s := ""
	for v in permutation:
		s += str(v) + ","
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
		if ch == " ":
			continue
		if used.has(ch):
			continue
		if ch >= "a" and ch <= "z":
			used[ch] = true
			table.append(ch)
			if table.size() == 25:
				break
	return table


func _playfair_pos_of(table: Array, ch: String) -> Vector2i:
	ch = ch.replace("j","i")
	for i in range(table.size()):
		if table[i] == ch:
			return Vector2i(i / 5, i % 5)
	return Vector2i(-1, -1)


func _playfair_encrypt(text: String, keyphrase: String) -> String:
	var table = _prepare_playfair_table(keyphrase)
	var clean := text.to_lower().replace("j","i").replace(" ", "")
	var digraphs := []
	var i := 0
	while i < clean.length():
		var a = clean[i]
		var b = ""
		if i + 1 < clean.length():
			b = clean[i + 1]
			if a == b:
				b = "x"
				i += 1
			else:
				i += 2
		else:
			b = "x"
			i += 1
		digraphs.append([a, b])
	var out := ""
	for pair in digraphs:
		var pa = _playfair_pos_of(table, pair[0])
		var pb = _playfair_pos_of(table, pair[1])
		if pa.x == pb.x:
			var ca = table[pa.x * 5 + ((pa.y + 1) % 5)]
			var cb = table[pb.x * 5 + ((pb.y + 1) % 5)]
			out += ca + cb
		elif pa.y == pb.y:
			var ca = table[((pa.x + 1) % 5) * 5 + pa.y]
			var cb = table[((pb.x + 1) % 5) * 5 + pb.y]
			out += ca + cb
		else:
			var ca = table[pa.x * 5 + pb.y]
			var cb = table[pb.x * 5 + pa.y]
			out += ca + cb
	return out


# ---------- Hill (2x2) ----------
func _hill_generate_key() -> PackedInt32Array:
	var mat := PackedInt32Array()
	# نحاول لحد ما نطلع مصفوفة قابلة للانعكاس mod26
	for _i in range(1000): # حط حدّ محاولات آمن
		var a = randi() % 26
		var b = randi() % 26
		var c = randi() % 26
		var d = randi() % 26
		var det = (a * d - b * c) % 26
		if det < 0:
			det += 26
		# matrix قابلة للعكس iff gcd(det,26) == 1
		if det != 0 and _gcd(det, 26) == 1:
			mat.append(a); mat.append(b); mat.append(c); mat.append(d)
			return mat
	# كحالة افتراضية نعيد مصفوفة ثابتة قابلة للعكس (مثال)
	mat.append(1); mat.append(0); mat.append(0); mat.append(1)
	return mat


func _hill_key_to_string(mat: PackedInt32Array) -> String:
	# حماية بسيطة لو المصفوفة أقصر
	if mat.size() < 4:
		return "1 0 0 1"
	return str(mat[0]) + " " + str(mat[1]) + " " + str(mat[2]) + " " + str(mat[3])


func _hill_encrypt(text: String, mat: PackedInt32Array) -> String:
	# clean letters only (lowercase)
	var clean := ""
	for ch in text.to_lower():
		if ch >= "a" and ch <= "z":
			clean += ch
	# pad to even length
	if clean.length() % 2 == 1:
		clean += "x"
	var out := ""
	# safety: ensure mat has 4 elements
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

	# reinsert spaces and non-letters similarly to original positions
	var spaced_out := ""
	var src_i = 0
	for ch in text:
		if ch == " ":
			spaced_out += " "
		elif (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z"):
			# safety: if out exhausted, append 'x'
			if src_i < out.length():
				spaced_out += out[src_i]
				src_i += 1
			else:
				spaced_out += "x"
		else:
			spaced_out += ch
	return spaced_out


func _gcd(a: int, b: int) -> int:
	a = abs(a)
	b = abs(b)
	while b != 0:
		var t = b
		b = a % b
		a = t
	return abs(a)


# ---------- Helpers ----------
func _random_word(length: int) -> String:
	var s := ""
	for i in range(length):
		s += ALPHABET[randi() % 26]
	return s
	
	
