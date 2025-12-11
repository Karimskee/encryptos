extends Node

func _ready():
	var plain_text = "Aa Bb Cc Dd Ee Ff Gg Hh Ii Jj Kk Ll Mm Nn Oo Pp Qq Rr Ss Tt Uu Vv Ww Xx Yy Zz 1234567890 !@#$%^&*()_+-=~,./;:'\"[]{}<>"
	print()
	var key = 1
	
	# Caesar Cipher
	print("Caesar cipher")
	print("Key: ", key)
	print("Plain Text: ", plain_text)
	
	# # Encrypt
	var secret = Caesar.encrypt(plain_text, key)
	print("Encrypted:  ", secret) 
	
	# # Decrypt
	var recovered = Caesar.decrypt(secret, key)
	print("Decrypted:  ", recovered)
	print()
