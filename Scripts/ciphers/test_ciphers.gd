extends Node


var plain_text = "Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz 1234567890 !@#$%^&*()_+-=~,./;:'\"[]{}<>"
var key = 3


func _ready():
	print("[TESTING CIPHERS]\n")
	var ciphers = [Caesar]
	
	for cipher in ciphers:
		test(cipher, plain_text, key)


func test(cipher: Script, plain_text: String, key: Variant) -> void:
	# For debugging
	print(cipher.get_global_name() + " cipher")
	print("Key: ", key)
	print("Plain Text: ", plain_text)
	
	# Encrypt
	var cipher_text = cipher.encrypt(plain_text, key)
	print("Encrypted:  ", cipher_text) 
	
	# Decypt
	var decrypted_text = cipher.decrypt(cipher_text, key)
	print("Decrypted:  ", decrypted_text)
	
	if (plain_text == decrypted_text):
		print("[SUCCESS] %s cipher is working properly." % cipher.get_global_name())
	else:
		print("[FAIL] %s cipher is not working properly." % cipher.get_global_name())
	print()
