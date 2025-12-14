class_name Playfair
extends Node

# 🔒 ENCRYPTION
static func encrypt(key: String, text: String) -> String:
	var matrix = _generate_matrix(key)
	var pairs = _prepare_text(text) # Handles "LL" -> "LX", etc.
	var result = ""
	
	for pair in pairs:
		var a = pair[0]
		var b = pair[1]
		
		var pos_a = _get_pos(matrix, a)
		var pos_b = _get_pos(matrix, b)
		
		var col_a = pos_a.x
		var row_a = pos_a.y
		var col_b = pos_b.x
		var row_b = pos_b.y
		
		if row_a == row_b:
			# Rule 1: Same Row -> Shift Right (Wrap around)
			col_a = (col_a + 1) % 5
			col_b = (col_b + 1) % 5
			
		elif col_a == col_b:
			# Rule 2: Same Column -> Shift Down (Wrap around)
			row_a = (row_a + 1) % 5
			row_b = (row_b + 1) % 5
			
		else:
			# Rule 3: Rectangle -> Swap Columns
			var temp = col_a
			col_a = col_b
			col_b = temp
			
		result += matrix[row_a][col_a]
		result += matrix[row_b][col_b]
		
	return result

# 🔓 DECRYPTION
static func decrypt(key: String, text: String) -> String:
	var matrix = _generate_matrix(key)
	
	# Clean input (just in case)
	var clean_text = ""
	for i in range(text.length()):
		var c = text[i].to_upper()
		if c >= "A" and c <= "Z":
			clean_text += c
			
	var result = ""
	
	# Process in pairs (Diagraphs)
	for i in range(0, clean_text.length(), 2):
		if i + 1 >= clean_text.length(): break
		
		var a = clean_text[i]
		var b = clean_text[i+1]
		
		var pos_a = _get_pos(matrix, a)
		var pos_b = _get_pos(matrix, b)
		
		var col_a = pos_a.x
		var row_a = pos_a.y
		var col_b = pos_b.x
		var row_b = pos_b.y
		
		if row_a == row_b:
			# Rule 1: Same Row -> Shift Left
			# (+5 ensures we don't get negative modulo results)
			col_a = (col_a - 1 + 5) % 5
			col_b = (col_b - 1 + 5) % 5
			
		elif col_a == col_b:
			# Rule 2: Same Column -> Shift Up
			row_a = (row_a - 1 + 5) % 5
			row_b = (row_b - 1 + 5) % 5
			
		else:
			# Rule 3: Rectangle -> Swap Columns
			var temp = col_a
			col_a = col_b
			col_b = temp
			
		result += matrix[row_a][col_a]
		result += matrix[row_b][col_b]
		
	return result

# 🛠 HELPER: Generate 5x5 Matrix (Merges I/J)
static func _generate_matrix(key: String) -> Array:
	# Standard Playfair Alphabet (No J)
	var alphabet = "ABCDEFGHIKLMNOPQRSTUVWXYZ" 
	
	# Merge Key + Alphabet, remove J, Uppercase
	var clean_key = key.to_upper().replace("J", "I")
	var stream = clean_key + alphabet
	
	var matrix = []
	for r in range(5):
		matrix.append(["", "", "", "", ""])
		
	var used_chars = {}
	var r = 0
	var c = 0
	
	for i in range(stream.length()):
		var character = stream[i]
		# Only add letters we haven't seen yet
		if character >= "A" and character <= "Z" and not used_chars.has(character):
			matrix[r][c] = character
			used_chars[character] = true
			c += 1
			if c >= 5:
				c = 0
				r += 1
			if r >= 5: break
			
	return matrix

# 🛠 HELPER: Prepare Text (Pairs, Padding, Duplicates)
static func _prepare_text(text: String) -> Array:
	var clean = ""
	# Remove non-alpha, swap J->I
	var raw = text.to_upper().replace("J", "I")
	for i in range(raw.length()):
		if raw[i] >= "A" and raw[i] <= "Z":
			clean += raw[i]
			
	var pairs = []
	var i = 0
	while i < clean.length():
		var char_a = clean[i]
		var char_b = ""
		
		# Check next char
		if (i + 1) < clean.length():
			char_b = clean[i+1]
			
			if char_a == char_b:
				# Duplicate found (e.g. "LL") -> Insert 'X'
				char_b = "X"
				i += 1 # Only advanced 1 char in source
			else:
				# Normal pair
				i += 2 # Advanced 2 chars
		else:
			# Dangling last char -> Pad with 'X'
			char_b = "X"
			i += 1
			
		pairs.append(char_a + char_b)
		
	return pairs

# 🛠 HELPER: Find X,Y position of a char in Matrix
static func _get_pos(matrix: Array, character: String) -> Vector2i:
	for r in range(5):
		for c in range(5):
			if matrix[r][c] == character:
				return Vector2i(c, r) # Returns (Column, Row)
	return Vector2i(0,0)


# Calculates exactly what Playfair SHOULD return for any given input
static func get_expected_playfair_output(original_text: String) -> String:
	var clean = ""
	
	# Rule 1: Normalize (Upper, J->I, Alpha Only)
	var raw = original_text.to_upper().replace("J", "I")
	for i in range(raw.length()):
		var c = raw[i]
		if c >= "A" and c <= "Z":
			clean += c
			
	# Rule 2: Handle Double Letters and Padding (The 'X' Rules)
	var expected = ""
	var i = 0
	while i < clean.length():
		var char_a = clean[i]
		var char_b = ""
		
		# Check the neighbor
		if (i + 1) < clean.length():
			char_b = clean[i+1]
			if char_a == char_b:
				# Duplicate found (e.g. "LL") -> Expect "LX"
				char_b = "X"
				i += 1 
			else:
				# Normal pair -> Keep both
				i += 2 
		else:
			# Odd ending -> Expect Padding "X"
			char_b = "X"
			i += 1
			
		expected += char_a + char_b
		
	return expected
