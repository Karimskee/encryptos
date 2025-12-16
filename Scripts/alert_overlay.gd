extends CanvasLayer

@onready var bg: ColorRect = $ColorRect
@onready var icon: TextureRect = $TextureRect
@onready var alert_sound: AudioStreamPlayer = null

var blink_tween: Tween

func _ready():
	layer = 5  # الإنذار تحت DialogueBox
	
	# إنشاء مشغل الصوت
	_setup_audio()
	
	# إعداد النودز الموجودة
	_setup_existing_nodes()
	
	# البداية مخفي
	visible = false
	bg.visible = false
	icon.visible = false

func _setup_audio():
	alert_sound = AudioStreamPlayer.new()
	alert_sound.name = "AlertSound"
	alert_sound.bus = "Master"
	alert_sound.volume_db = 0.0  # مستوى الصوت
	add_child(alert_sound)
	
	# تحميل ملف الصوت
	var sound_path = "res://assets/sounds/warning.ogg"  # غيّر المسار حسب ملفك
	if ResourceLoader.exists(sound_path):
		alert_sound.stream = load(sound_path)
	else:
		push_warning("Alert sound not found: " + sound_path)

func _setup_existing_nodes():
	# الخلفية الحمراء
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(1.0, 0.0, 0.0, 0.4)  # أحمر شفاف
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# علامة التحذير (في النص تمامًا)
	icon.anchor_left = 0.5
	icon.anchor_top = 0.5
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = -128
	icon.offset_top = -128
	icon.offset_right = 128
	icon.offset_bottom = 128
	icon.pivot_offset = Vector2(128, 128)  # النقطة المرجعية في النص
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# إنشاء texture لعلامة التحذير إذا لم يكن موجود
	if icon.texture == null:
		icon.texture = _create_warning_icon()

func _create_warning_icon() -> ImageTexture:
	# إنشاء صورة 256x256 (أكبر) لعلامة تحذير
	var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center_x = 128.0
	var center_y = 128.0
	
	# رسم مثلث أصفر (أكبر)
	for y in range(int(center_y - 100), int(center_y + 100)):
		for x in range(int(center_x - 100), int(center_x + 100)):
			# حساب إذا النقطة داخل المثلث
			var top_y = center_y - 90
			var bottom_y = center_y + 90
			
			if y > top_y and y < bottom_y:
				var ratio = (y - top_y) / (bottom_y - top_y)
				var half_width = 90.0 * ratio
				var min_x = center_x - half_width
				var max_x = center_x + half_width
				
				if x >= min_x and x <= max_x:
					# حدود المثلث (أسود سميك)
					if abs(x - min_x) < 6 or abs(x - max_x) < 6 or abs(y - bottom_y) < 6:
						img.set_pixel(x, y, Color.BLACK)
					else:
						# داخل المثلث (أصفر)
						img.set_pixel(x, y, Color(1.0, 0.85, 0.0, 1.0))
	
	# رسم علامة التعجب (!) - أكبر
	# الخط الطويل
	for y in range(int(center_y - 60), int(center_y + 10)):
		for x in range(int(center_x - 8), int(center_x + 8)):
			img.set_pixel(x, y, Color.BLACK)
	
	# النقطة تحت علامة التعجب
	for y in range(int(center_y + 30), int(center_y + 45)):
		for x in range(int(center_x - 8), int(center_x + 8)):
			img.set_pixel(x, y, Color.BLACK)
	
	return ImageTexture.create_from_image(img)

func _create_alert_sound() -> AudioStreamGenerator:
	# إنشاء صوت تحذير (Siren/Beep)
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.5
	return stream

func show_alert():
	visible = true
	bg.visible = true
	icon.visible = true
	
	bg.modulate.a = 0.0
	icon.modulate.a = 0.0
	
	# 🔊 تشغيل صوت الإنذار
	if alert_sound and alert_sound.stream:
		alert_sound.play()
	
	# فلاش أحمر سريع
	create_tween().tween_property(bg, "modulate:a", 0.4, 0.3)
	
	# وميض علامة التحذير (Blink)
	if blink_tween:
		blink_tween.kill()
	
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property(icon, "modulate:a", 1.0, 0.4)
	blink_tween.tween_property(icon, "modulate:a", 0.2, 0.4)

func hide_alert():
	if blink_tween:
		blink_tween.kill()
	
	# 🔇 إيقاف الصوت
	if alert_sound:
		alert_sound.stop()
	
	# إخفاء تدريجي
	var fade_tween = create_tween()
	fade_tween.tween_property(bg, "modulate:a", 0.0, 0.3)
	fade_tween.parallel().tween_property(icon, "modulate:a", 0.0, 0.3)
	
	await fade_tween.finished
	
	visible = false
	bg.visible = false
	icon.visible = false
