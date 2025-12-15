class_name Caesar
extends Node

# 🔒 ENCRYPTION
static func encrypt(key: int, text: String) -> String:
	# Convert to raw bytes for speed (avoiding String concatenation)
	var buffer: PackedByteArray = text.to_utf8_buffer()
	var size: int = buffer.size()
	
	# Normalize key to 0-25
	key = key % 26
	
	for i in range(size):
		var byte: int = buffer[i]
		
		# Uppercase (A-Z is 65-90)
		if byte >= 65 and byte <= 90:
			buffer[i] = ((byte - 65 + key) % 26) + 65
			
		# Lowercase (a-z is 97-122)
		elif byte >= 97 and byte <= 122:
			buffer[i] = ((byte - 97 + key) % 26) + 97
			
		# Non-letters are left alone automatically
		
	return buffer.get_string_from_utf8()

# 🔓 DECRYPTION
static func decrypt(key: int, text: String) -> String:
	var buffer: PackedByteArray = text.to_utf8_buffer()
	var size: int = buffer.size()
	
	key = key % 26
	
	for i in range(size):
		var byte: int = buffer[i]
		
		# Uppercase
		if byte >= 65 and byte <= 90:
			var val = byte - 65 - key
			# Handle negative wrap (e.g. if val is -3, wrap to 23)
			if val < 0: val += 26
			buffer[i] = val + 65
			
		# Lowercase
		elif byte >= 97 and byte <= 122:
			var val = byte - 97 - key
			if val < 0: val += 26
			buffer[i] = val + 97
			
	return buffer.get_string_from_utf8()


static func generate_random_key() -> int:
	# Returns a shift between 1 and 25
	return randi_range(1, 25)
