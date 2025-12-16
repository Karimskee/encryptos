class_name Polyalphabetic
extends Node

# 🔒 ENCRYPTION
static func encrypt(key: String, text: String) -> String:
	if key.is_empty():
		return text
		
	var buffer: PackedByteArray = text.to_utf8_buffer()
	var key_buffer: PackedByteArray = key.to_upper().to_utf8_buffer()
	
	var size: int = buffer.size()
	var key_len: int = key_buffer.size()
	var key_idx: int = 0  # <--- NEW: Track key position separately
	
	for i in range(size):
		var byte: int = buffer[i]
		var shift = 0
		var is_letter = false
		
		# Uppercase A-Z
		if byte >= 65 and byte <= 90:
			# Calculate shift based on key_idx, NOT i
			shift = key_buffer[key_idx % key_len] - 65
			buffer[i] = ((byte - 65 + shift) % 26) + 65
			is_letter = true
			
		# Lowercase a-z
		elif byte >= 97 and byte <= 122:
			shift = key_buffer[key_idx % key_len] - 65
			buffer[i] = ((byte - 97 + shift) % 26) + 97
			is_letter = true
		
		# ONLY advance the key if we actually encrypted a letter
		if is_letter:
			key_idx += 1
			
	return buffer.get_string_from_utf8()

# 🔓 DECRYPTION
static func decrypt(key: String, text: String) -> String:
	if key.is_empty():
		return text

	var buffer: PackedByteArray = text.to_utf8_buffer()
	var key_buffer: PackedByteArray = key.to_upper().to_utf8_buffer()
	
	var size: int = buffer.size()
	var key_len: int = key_buffer.size()
	var key_idx: int = 0 # <--- NEW
	
	for i in range(size):
		var byte: int = buffer[i]
		var shift = 0
		var is_letter = false
		
		# Uppercase
		if byte >= 65 and byte <= 90:
			shift = key_buffer[key_idx % key_len] - 65
			var val = byte - 65 - shift
			if val < 0: val += 26
			buffer[i] = val + 65
			is_letter = true
			
		# Lowercase
		elif byte >= 97 and byte <= 122:
			shift = key_buffer[key_idx % key_len] - 65
			var val = byte - 97 - shift
			if val < 0: val += 26
			buffer[i] = val + 97
			is_letter = true
			
		if is_letter:
			key_idx += 1
			
	return buffer.get_string_from_utf8()


static func generate_random_key(length: int = 0) -> String:
	# If no length provided, pick random between 4 and 8
	if length == 0: length = randi_range(4, 8)
	
	var result = ""
	for i in range(length):
		result += String.chr(randi_range(65, 90))
	return result
