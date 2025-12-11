class_name Monoalphabetic
extends Node

# 🔒 ENCRYPTION
# Key must be a 26-character string representing the shuffled alphabet
# Example Key: "QWERTYUIOPASDFGHJKLZXCVBNM"
static func encrypt(key_string: Variant, text: String) -> String:
	key_string = str(key_string)
	
	# validation
	if key_string.length() != 26:
		push_error("Monoalphabetic Key must be exactly 26 characters.")
		return ""

	var buffer: PackedByteArray = text.to_utf8_buffer()
	# Ensure key is uppercase for consistent math
	var key_map: PackedByteArray = key_string.to_upper().to_utf8_buffer()
	var size: int = buffer.size()

	for i in range(size):
		var byte: int = buffer[i]
		
		# Uppercase (A-Z) -> Map directly to Key
		if byte >= 65 and byte <= 90:
			var index = byte - 65
			buffer[i] = key_map[index]
			
		# Lowercase (a-z) -> Map to Key, then convert Key char back to lowercase
		elif byte >= 97 and byte <= 122:
			var index = byte - 97
			# key_map stores uppercase, so we add 32 to make it lowercase again
			buffer[i] = key_map[index] + 32
			
	return buffer.get_string_from_utf8()

# 🔓 DECRYPTION
static func decrypt(key_string: Variant, text: String) -> String:
	key_string = str(key_string)
	
	if key_string.length() != 26:
		return text

	var buffer: PackedByteArray = text.to_utf8_buffer()
	var key_map: PackedByteArray = key_string.to_upper().to_utf8_buffer()
	var size: int = buffer.size()
	
	# PRE-CALCULATION STEP (Crucial for Speed)
	# We need to reverse the key map. Instead of searching the key_string 
	# for every single character (slow), we build an "Inverse Map" once (fast).
	# inverse_map[CipherChar] = PlainChar
	var inverse_map: PackedByteArray = PackedByteArray()
	inverse_map.resize(26)
	
	for i in range(26):
		# key_map[i] is the cipher character (e.g., 'Q' or 81)
		# We want inverse_map[81 - 65] to store 'A' (which is i + 65)
		var cipher_char_code = key_map[i] - 65
		inverse_map[cipher_char_code] = i + 65

	# Now perform the substitution using the inverse map
	for i in range(size):
		var byte: int = buffer[i]
		
		if byte >= 65 and byte <= 90: # A-Z
			var index = byte - 65
			buffer[i] = inverse_map[index]
			
		elif byte >= 97 and byte <= 122: # a-z
			var index = byte - 97
			buffer[i] = inverse_map[index] + 32
			
	return buffer.get_string_from_utf8()
