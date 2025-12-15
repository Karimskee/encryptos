class_name Hill
extends Node

# ENCRYPTION
# Key MUST be exactly 4 characters long (for a 2x2 matrix)
static func encrypt(key: String, text: String) -> String:
	var matrix = _key_to_matrix(key)
	if matrix.is_empty():
		printerr("Hill Cipher Error: Key must be exactly 4 characters.")
		return ""

	var vectors = _text_to_vectors(text) # Array of Vector2i
	var result = ""
	
	for vec in vectors:
		# Matrix Multiplication: [x, y] * [[a,b], [c,d]]
		# New X = (x*a + y*c) % 26
		# New Y = (x*b + y*d) % 26
		
		var x = (vec.x * matrix[0][0] + vec.y * matrix[1][0]) % 26
		var y = (vec.x * matrix[0][1] + vec.y * matrix[1][1]) % 26
		
		result += String.chr(x + 65)
		result += String.chr(y + 65)
		
	return result

# DECRYPTION
static func decrypt(key: String, text: String) -> String:
	var matrix = _key_to_matrix(key)
	if matrix.is_empty(): return ""
	
	# 1. Calculate Determinant
	# det = (ad - bc)
	var det = (matrix[0][0] * matrix[1][1]) - (matrix[0][1] * matrix[1][0])
	
	# 2. Modular Inverse of Determinant
	# We need a number 'x' where (det * x) % 26 == 1
	var det_inv = _mod_inverse(det, 26)
	
	if det_inv == -1:
		printerr("Hill Cipher Error: Key is not invertible (Determinant %d has no inverse mod 26)." % det)
		return ""
		
	# 3. Calculate Inverse Matrix
	# Inv = det_inv * [[d, -b], [-c, a]]
	var inv_matrix = [
		[0, 0],
		[0, 0]
	]
	
	# Apply formula and ensure positive modulo
	inv_matrix[0][0] = (det_inv * matrix[1][1]) % 26
	inv_matrix[0][1] = (det_inv * -matrix[0][1]) % 26
	inv_matrix[1][0] = (det_inv * -matrix[1][0]) % 26
	inv_matrix[1][1] = (det_inv * matrix[0][0]) % 26
	
	# Normalize negatives (Python/GDScript % allows negatives, math mod doesn't)
	for r in range(2):
		for c in range(2):
			if inv_matrix[r][c] < 0:
				inv_matrix[r][c] += 26
				
	# 4. Decrypt using the Inverse Matrix
	var vectors = _text_to_vectors(text)
	var result = ""
	
	for vec in vectors:
		var x = (vec.x * inv_matrix[0][0] + vec.y * inv_matrix[1][0]) % 26
		var y = (vec.x * inv_matrix[0][1] + vec.y * inv_matrix[1][1]) % 26
		
		result += String.chr(x + 65)
		result += String.chr(y + 65)
		
	return result

# 🔢 HELPER: Convert 4-char Key to 2x2 Matrix
static func _key_to_matrix(key: String) -> Array:
	var clean = ""
	for i in range(key.length()):
		var c = key[i].to_upper()
		if c >= "A" and c <= "Z":
			clean += c
			
	if clean.length() != 4:
		return []
		
	# Map A=0, B=1...
	var k = clean.to_utf8_buffer()
	return [
		[k[0]-65, k[1]-65],
		[k[2]-65, k[3]-65]
	]

# 📝 HELPER: Convert Text to Vectors (Pairs of numbers)
static func _text_to_vectors(text: String) -> Array:
	var clean = ""
	for i in range(text.length()):
		var c = text[i].to_upper()
		if c >= "A" and c <= "Z":
			clean += c
			
	# Pad with 'X' if odd length
	if clean.length() % 2 != 0:
		clean += "X"
		
	var vectors = []
	var buffer = clean.to_utf8_buffer()
	
	for i in range(0, buffer.size(), 2):
		var x = buffer[i] - 65
		var y = buffer[i+1] - 65
		vectors.append(Vector2i(x, y))
		
	return vectors

# 🧮 HELPER: Modular Multiplicative Inverse
# Brute force search is instant for small modulus like 26
static func _mod_inverse(a: int, m: int) -> int:
	a = a % m
	for x in range(1, m):
		if (a * x) % m == 1:
			return x
	return -1 # No inverse exists (Key is invalid)

## Call this from your UI when the user types a key
#static func is_key_valid(key: String) -> bool:
	#var matrix = _key_to_matrix(key)
	#
	## 1. Check length
	#if matrix.is_empty(): 
		#return false
		#
	## 2. Calculate Determinant
	#var det = (matrix[0][0] * matrix[1][1]) - (matrix[0][1] * matrix[1][0])
	#
	## 3. Check if Determinant has an inverse mod 26
	## We reuse the existing _mod_inverse helper
	#if _mod_inverse(det, 26) == -1:
		#return false # Invalid
		#
	#return true # Valid!
	
	
static func generate_valid_key() -> String:
	while true:
		# 1. Generate 4 random letters
		var chars = []
		for i in range(4):
			chars.append(randi_range(65, 90)) # A-Z
		
		var candidate_key = String.chr(chars[0]) + String.chr(chars[1]) + String.chr(chars[2]) + String.chr(chars[3])
		
		# 2. Check if it works
		if is_key_valid(candidate_key):
			return candidate_key
			
	return "HILL" # Fallback (should never happen)


# Calculates exactly what Hill Cipher SHOULD return for any given input
# (Strips symbols, Uppercases, and Pads with 'X' if length is odd)
static func get_expected_hill_output(original_text: String) -> String:
	var clean = ""
	
	# Rule 1: Normalize (Upper, Alpha Only)
	# Hill Cipher math only works on 0-25 (A-Z)
	var raw = original_text.to_upper()
	for i in range(raw.length()):
		var c = raw[i]
		if c >= "A" and c <= "Z":
			clean += c
			
	# Rule 2: Padding
	# Hill Cipher (2x2) processes pairs. If we have an odd number of letters,
	# it adds 'X' to the end.
	if clean.length() % 2 != 0:
		clean += "X"
		
	return clean


# Place inside HillCipher class
static func generate_random_key() -> String:
	# Keep trying until we find a mathematically valid key
	while true:
		var candidate = ""
		for i in range(4): # 2x2 Matrix requires 4 chars
			candidate += String.chr(randi_range(65, 90))
			
		if is_key_valid(candidate):
			return candidate
			
	return "HILL" # Fallback

# Helper to check validity (if you don't have it yet)
static func is_key_valid(key: String) -> bool:
	var matrix = _key_to_matrix(key)
	if matrix.is_empty(): return false
	var det = (matrix[0][0] * matrix[1][1]) - (matrix[0][1] * matrix[1][0])
	return _mod_inverse(det, 26) != -1
