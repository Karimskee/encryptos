extends Node


# Global variables
var plain_text = "Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz 1234567890 !@#$%^&*()_+-=~,./;:'\"[]{}<>"
var key = 3


func _ready():
	print("[TESTING CIPHERS]\n")
	
	# ADD NEW CIPHERS HERE
	var ciphers = [
		Caesar,
		Monoalphabetic
	]
	
	for cipher in ciphers:
		test(cipher, plain_text, key)


func test(cipher: Script, plain_text: String) -> void:
	var key
	var methods = cipher.get_script_method_list()
	
	# Different cipher need different key types
	# The code below adapts to the required cipher type
	if methods[0].args[0].type == 2:	# TYPE_INT == 2
		key = key_int
	else:								# TYPE_STRING == 4 or VARIANT == 0
		key = key_string
	
	# For debugging
	print(cipher.get_global_name() + " cipher")
	print("Key: ", key)
	print("Plain Text: ", plain_text)
	
	# Encrypt
	var cipher_text = cipher.encrypt(key, plain_text)
	print("Encrypted:  ", cipher_text) 
	
	# Decypt
	var decrypted_text = cipher.decrypt(key, cipher_text)
	print("Decrypted:  ", decrypted_text)
	
	if (plain_text == decrypted_text):
		print("[SUCCESS] %s cipher is working properly." % cipher.get_global_name())
	else:
		print("[FAIL] %s cipher is not working properly." % cipher.get_global_name())
	print()
