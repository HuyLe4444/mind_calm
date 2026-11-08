class_name Story
extends CanvasLayer

const FRONT_LAYER := 20
const BACK_LAYER := -1

# Vị trí box theo tỉ lệ màn hình (tâm box). 0 và 1 ở trên khung chơi, 2 và 3 ở dưới
const SLOTS := [
	Vector2(0.22, 0.09), Vector2(0.78, 0.15),
	Vector2(0.22, 0.87), Vector2(0.78, 0.92),
]

var portrait                       # Sprite2D hoặc TextureRect, main gán vào
var game_alpha: float = 0.35       # độ đậm của ảnh nền khi đang chơi
var busy: bool = false

var box_game_alpha: float = 0.30   # độ đậm của box khi lùi về sau
var box_texture_path: String = ""  # ảnh khung riêng (để trống thì dùng giấy kem vẽ bằng code)
var box_font_size: int = 22

var _normal_tex: Texture2D
var _breath_tex: Texture2D
var _breathing: bool = false
var _inited: bool = false
var _boxes: Array[Control] = []
var _pops_running: int = 0
var _pop_count: int = 0

func _ready() -> void:
	layer = BACK_LAYER

# ---------- Ảnh nền ----------

func _ensure_portrait() -> void:
	if portrait == null:
		_make_portrait()
	if not _inited:
		_inited = true
		_normal_tex = portrait.texture
		portrait.modulate.a = game_alpha

# Dự phòng khi main chưa gán portrait
func _make_portrait() -> void:
	var pl := CanvasLayer.new()
	pl.layer = -5
	add_child(pl)
	var tr := TextureRect.new()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pl.add_child(tr)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait = tr

func _to_tex(v) -> Texture2D:
	if v is Texture2D:
		return v
	if v is String and v != "" and ResourceLoader.exists(v):
		return load(v)
	return null

func set_portrait(image, breath_image = null) -> void:
	_ensure_portrait()
	_normal_tex = _to_tex(image)
	_breath_tex = _to_tex(breath_image)
	_breathing = false
	if _normal_tex != null:
		portrait.texture = _normal_tex

func set_breathing(on: bool) -> void:
	_ensure_portrait()
	if on == _breathing:
		return
	_breathing = on
	if _normal_tex == null:
		return
	if on and _breath_tex != null:
		portrait.texture = _breath_tex
	else:
		portrait.texture = _normal_tex

func fade_portrait(alpha: float, time: float) -> void:
	_ensure_portrait()
	var t := create_tween()
	t.tween_property(portrait, "modulate:a", alpha, time)
	await t.finished

# ---------- Chờ (nhấn ui_accept để bỏ qua) ----------

func _wait(t: float) -> void:
	var elapsed := 0.0
	while elapsed < t:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if Input.is_action_just_pressed("ui_accept"):
			return

# ---------- Cutscene đầy đủ (main await hàm này) ----------

func play(entry: Dictionary) -> void:
	busy = true
	_ensure_portrait()
	_clear_boxes()
	layer = FRONT_LAYER
	if entry.has("image"):
		set_portrait(entry["image"], entry.get("breath_image", null))
	await fade_portrait(1.0, 0.8)

	var step: float = entry.get("step", 1.3)
	var hold: float = entry.get("hold", 2.5)
	var slot := 0
	for b in entry.get("boxes", []):
		var box := await _spawn_box(b, slot)
		if box != null:
			_fade_box(box, 1.0, 0.4)
		await _wait(step)
		slot += 1
	await _wait(hold)

	# Ảnh nền và box cùng lùi về sau
	fade_portrait(game_alpha, 1.0)
	await _settle_boxes(1.0)
	busy = false

# ---------- Box nhỏ hiện lên giữa màn chơi (không chặn game) ----------

# main KHÔNG await hàm này. Box hiện lên rồi mờ về sau ngay.
func pop(texts: Array) -> void:
	if busy:
		return
	_pops_running += 1
	_clear_boxes()
	layer = FRONT_LAYER
	var base := _pop_count * 2   # lần sau đổi cặp vị trí trên/dưới
	_pop_count += 1
	var i := 0
	for entry in texts:
		var box := await _spawn_box(entry, base + i)
		if is_instance_valid(box):
			var t := box.create_tween()
			t.tween_property(box, "modulate:a", 1.0, 0.35)
			t.tween_property(box, "modulate:a", box_game_alpha, 1.4)
		await get_tree().create_timer(0.7).timeout
		i += 1
	await get_tree().create_timer(1.6).timeout
	_pops_running -= 1
	if _pops_running <= 0 and not busy:
		layer = BACK_LAYER

# ---------- Box ----------

# entry: chuỗi, hoặc {text, pos}; pos là Vector2 (tỉ lệ màn hình) hoặc số thứ tự ô
func _spawn_box(entry, slot: int) -> Control:
	var text := ""
	var pos: Vector2 = SLOTS[slot % SLOTS.size()]
	if entry is Dictionary:
		text = str(entry.get("text", ""))
		var p = entry.get("pos", null)
		if p is Vector2:
			pos = p
		elif p is int:
			pos = SLOTS[p % SLOTS.size()]
	else:
		text = str(entry)

	var box := _make_box(text)
	box.modulate.a = 0.0
	add_child(box)
	_boxes.append(box)
	await get_tree().process_frame     # đợi layout tính xong kích thước
	if not is_instance_valid(box):
		return null
	box.size = box.get_combined_minimum_size()
	var screen := get_viewport().get_visible_rect().size
	var target := pos * screen - box.size * 0.5
	target.x = clampf(target.x, 8.0, maxf(8.0, screen.x - box.size.x - 8.0))
	target.y = clampf(target.y, 8.0, maxf(8.0, screen.y - box.size.y - 8.0))
	box.position = target
	return box

func _make_box(text: String) -> PanelContainer:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", _box_style())
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", box_font_size)
	label.add_theme_color_override("font_color", Color(0.20, 0.16, 0.14))
	if text.length() > 28:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(320, 0)
	box.add_child(label)
	return box

func _box_style() -> StyleBox:
	if box_texture_path != "" and ResourceLoader.exists(box_texture_path):
		var st := StyleBoxTexture.new()
		st.texture = load(box_texture_path)
		st.texture_margin_left = 16.0
		st.texture_margin_right = 16.0
		st.texture_margin_top = 16.0
		st.texture_margin_bottom = 16.0
		st.content_margin_left = 20.0
		st.content_margin_right = 20.0
		st.content_margin_top = 12.0
		st.content_margin_bottom = 12.0
		return st
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.96, 0.88)        # giấy kem, sáng hơn nền một chút
	sb.border_color = Color(0.25, 0.20, 0.18)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 20.0
	sb.content_margin_right = 20.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(4, 4)
	return sb

func _fade_box(box: Control, alpha: float, time: float) -> void:
	if not is_instance_valid(box):
		return
	box.create_tween().tween_property(box, "modulate:a", alpha, time)

# Box cũ mờ hẳn rồi xóa
func _clear_boxes() -> void:
	for b in _boxes:
		if is_instance_valid(b):
			var t := b.create_tween()
			t.tween_property(b, "modulate:a", 0.0, 0.3)
			t.tween_callback(b.queue_free)
	_boxes.clear()

# Box mờ xuống mức nền rồi chuyển ra sau màn chơi
func _settle_boxes(time: float) -> void:
	var valid: Array[Control] = []
	for b in _boxes:
		if is_instance_valid(b):
			valid.append(b)
	if not valid.is_empty():
		var t := create_tween().set_parallel(true)
		for b in valid:
			t.tween_property(b, "modulate:a", box_game_alpha, time)
		await t.finished
	layer = BACK_LAYER

# ---------- Màn kết thúc ----------

func show_end(text: String) -> void:
	busy = true
	_clear_boxes()
	layer = FRONT_LAYER
	var bg := ColorRect.new()
	bg.color = Color("f5ecd7")
	bg.modulate.a = 0.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(0.20, 0.16, 0.14))
	bg.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 80)
	await create_tween().tween_property(bg, "modulate:a", 1.0, 1.5).finished
	
# Dòng hướng dẫn giữa màn hình; chờ người chơi bấm phím hoặc hết timeout
func show_hint(text: String, action: StringName, timeout: float = 8.0) -> void:
	var cl := CanvasLayer.new()
	cl.layer = 25
	add_child(cl)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color(0.20, 0.16, 0.14))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate.a = 0.0
	cl.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await create_tween().tween_property(label, "modulate:a", 1.0, 0.8).finished
	var elapsed := 0.0
	while elapsed < timeout:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		label.modulate.a = 0.75 + 0.25 * sin(elapsed * 4.0)
		if InputMap.has_action(action) and Input.is_action_just_pressed(action):
			break
	await create_tween().tween_property(label, "modulate:a", 0.0, 0.5).finished
	cl.queue_free()
	
# Trả ảnh nền về hình đang dùng của arc hiện tại, hiện giữa màn như thường
func restore_portrait(time: float = 0.8) -> void:
	_ensure_portrait()
	portrait.visible = true
	_breathing = false
	if _normal_tex != null:
		portrait.texture = _normal_tex
	await fade_portrait(game_alpha, time)
