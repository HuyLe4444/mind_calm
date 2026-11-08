extends Control

# Scene game thật sự. Sửa đường dẫn cho khớp scene Main của bạn
@export_file("*.tscn") var game_scene: String = "res://Scenes/main.tscn"
@export var breath_action: StringName = &"Action"
@export var title_text: String = "mind_flow"
@export var hint_timeout: float = 999999999.0   # giây tự vào game nếu người chơi không bấm phím

const SHADER_PATH := "res://Assets/crt.gdshader"
const CREAM := Color("f5ecd7")
const INK := Color(0.20, 0.16, 0.14)

var _ui: Control
var _button: Button
var _hint: Label
var _cover: ColorRect
var _time: float = 0.0
var _started: bool = false
var _waiting: bool = false
var _leaving: bool = false

func _ready() -> void:
	RenderingServer.set_default_clear_color(CREAM)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_build_hint()
	_build_cover()
	_build_filter()
	_button.grab_focus()   # Enter hoặc Space cũng bấm được

func _process(delta: float) -> void:
	_time += delta
	if _waiting:
		_hint.modulate.a = 0.75 + 0.25 * sin(_time * 4.0)
		if InputMap.has_action(breath_action) and Input.is_action_just_pressed(breath_action):
			_go()

# ---------- Dựng giao diện ----------

func _build_ui() -> void:
	_ui = CenterContainer.new()
	add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 48)
	_ui.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", INK)
	box.add_child(title)

	_button = Button.new()
	_button.text = "Start"
	_button.custom_minimum_size = Vector2(240, 64)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.add_theme_font_size_override("font_size", 28)
	_button.add_theme_color_override("font_color", INK)
	_button.add_theme_color_override("font_hover_color", INK)
	_button.add_theme_color_override("font_pressed_color", INK)
	_button.add_theme_color_override("font_focus_color", INK)
	_button.add_theme_stylebox_override("normal", _button_style(Color(0.99, 0.96, 0.88)))
	_button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.99, 0.94)))
	_button.add_theme_stylebox_override("focus", _button_style(Color(1.0, 0.99, 0.94)))
	_button.add_theme_stylebox_override("pressed", _button_style(Color(0.93, 0.88, 0.78)))
	_button.add_theme_stylebox_override("disabled", _button_style(Color(0.93, 0.88, 0.78)))
	_button.pressed.connect(_on_start_pressed)
	box.add_child(_button)

func _button_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(4, 4)
	return sb

func _build_hint() -> void:
	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 44)
	_hint.add_theme_color_override("font_color", INK)
	_hint.modulate.a = 0.0
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _build_cover() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_cover = ColorRect.new()
	_cover.color = Color(CREAM, 0.0)
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_cover)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# Cùng bộ lọc TV cũ như trong game
func _build_filter() -> void:
	if not ResourceLoader.exists(SHADER_PATH):
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	rect.material = mat
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# ---------- Luồng ----------

func _on_start_pressed() -> void:
	if _started:
		return
	_started = true
	_button.disabled = true

	# Tiêu đề và nút mờ đi
	await create_tween().tween_property(_ui, "modulate:a", 0.0, 0.6).finished
	_ui.visible = false

	# Hiện dòng hướng dẫn
	_hint.text = "Press %s to breathe" % _key_name()
	await create_tween().tween_property(_hint, "modulate:a", 1.0, 0.8).finished
	_waiting = true
	get_tree().create_timer(hint_timeout).timeout.connect(_go)

func _go() -> void:
	if _leaving:
		return
	_leaving = true
	_waiting = false
	await create_tween().tween_property(_hint, "modulate:a", 0.0, 0.5).finished
	await create_tween().tween_property(_cover, "color:a", 1.0, 0.6).finished
	get_tree().change_scene_to_file(game_scene)

# Lấy tên phím thật đang gán cho hành động
func _key_name() -> String:
	if InputMap.has_action(breath_action):
		for e in InputMap.action_get_events(breath_action):
			if e is InputEventKey:
				var code: int = e.physical_keycode
				if code == 0:
					code = e.keycode
				return OS.get_keycode_string(code)
			if e is InputEventJoypadButton:
				return "Button " + str(e.button_index)
	return "X"
