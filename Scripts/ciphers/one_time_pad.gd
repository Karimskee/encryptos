class_name OneTimePad
extends Node

# 🔒 ENCRYPTION
# Logic: (PlainChar + KeyChar) % 26
static func encrypt(key: String, text: String) -> String:
	var buffer: PackedByteArray = text.to_utf8_buffer()
	var key_buffer: PackedByteArray = key.to_upper().to_utf8_buffer()
	var size: int = buffer.size()
	
	# OTP RULE: Key must be >= Text Length
	if key_buffer.size() < size:
		printerr("OTP Error: Key is too short! Must be at least %d chars." % size)
		return "" # Return empty to signal failure

	for i in range(size):
		var byte: int = buffer[i]
		
		# Get the shift from the key (A=0, B=1, etc.)
		# We use 'i' for both because OTP never repeats the key
		var shift = key_buffer[i] - 65 
		
		if byte >= 65 and byte <= 90: # A-Z
			buffer[i] = ((byte - 65 + shift) % 26) + 65
			
		elif byte >= 97 and byte <= 122: # a-z
			buffer[i] = ((byte - 97 + shift) % 26) + 97
			
	return buffer.get_string_from_utf8()

# 🔓 DECRYPTION
# Logic: (CipherChar - KeyChar) % 26
static func decrypt(key: String, text: String) -> String:
	var buffer: PackedByteArray = text.to_utf8_buffer()
	var key_buffer: PackedByteArray = key.to_upper().to_utf8_buffer()
	var size: int = buffer.size()
	
	if key_buffer.size() < size:
		printerr("OTP Error: Key is too short!")
		return ""

	for i in range(size):
		var byte: int = buffer[i]
		var shift = key_buffer[i] - 65
		
		if byte >= 65 and byte <= 90: # A-Z
			var val = byte - 65 - shift
			if val < 0: val += 26
			buffer[i] = val + 65
			
		elif byte >= 97 and byte <= 122: # a-z
			var val = byte - 97 - shift
			if val < 0: val += 26
			buffer[i] = val + 97
			
	return buffer.get_string_from_utf8()

# 🎲 HELPER: GENERATE RANDOM KEY
# Since OTP requires a random key of specific length, this helper is essential for your game UI.
static func generate_random_key(length: int) -> String:
	var result = PackedByteArray()
	result.resize(length)
	
	for i in range(length):
		# Random ASCII between 65 (A) and 90 (Z)
		result[i] = randi_range(65, 90)
		
	return result.get_string_from_utf8()
