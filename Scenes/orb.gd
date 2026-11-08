class_name Orb
extends Area2D


signal collected(orb)

@export var core_color: Color = Color(0.85, 0.08, 0.08)   # ruột đỏ
@export var edge_color: Color = Color(0.45, 0.02, 0.05)   # viền đỏ sẫm
@export var radius: float = 14.0
@export var particle_amount: int = 22
@export var softness: float = 0.0   # 0 = bình thường, 1 = rất nhạt và ít tương phản

var base_alpha: float = 1.0
var _time: float = randf() * TAU
var _halo: Sprite2D
var _tex: GradientTexture2D
var _got: bool = false

func _ready() -> void:
	if softness > 0.0:
		var bg := Color("f5ecd7")
		core_color = core_color.lerp(bg, softness * 0.55)
		edge_color = edge_color.lerp(bg, softness * 0.5)
		base_alpha = 1.0 - softness * 0.3
		modulate.a = base_alpha
	# Vùng chạm lớn hơn hình vẽ 4 px cho dễ nhặt
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius + 4.0
	shape.shape = circle
	add_child(shape)

	_tex = _make_radial_texture()

	# Quầng mờ phía sau (blend thường, không cộng sáng)
	_halo = Sprite2D.new()
	_halo.texture = _tex
	_halo.modulate = Color(core_color, 0.30)
	_halo.scale = Vector2.ONE * (radius * 4.0 / 128.0)
	add_child(_halo)

	# Hạt đỏ nhẹ bay quanh viên orb
	var p := CPUParticles2D.new()
	p.texture = _tex
	p.amount = particle_amount
	p.lifetime = 1.6
	p.local_coords = true
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius * 0.9
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 16.0
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.10
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(core_color, 0.8), Color(core_color, 0.0)])
	p.color_ramp = g
	add_child(p)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	var pulse := 1.0 + sin(_time * 3.0) * 0.12
	_halo.scale = Vector2.ONE * (radius * 4.0 / 128.0) * pulse
	queue_redraw()

func _draw() -> void:
	# Vòng xung lan ra rồi mờ dần, lặp lại
	var t := fposmod(_time * 0.9, 1.0)
	var ring_r := radius + 4.0 + t * 14.0
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 40,
		Color(core_color, 0.55 * (1.0 - t)), 2.0, true)
	# Viên đặc: viền, ruột, điểm sáng
	draw_circle(Vector2.ZERO, radius, edge_color)
	draw_circle(Vector2.ZERO, radius - 2.5, core_color)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.28,
		Color(1.0, 0.75, 0.7, 0.85))

func _on_body_entered(body: Node) -> void:
	if _got or not body.is_in_group("player"):
		return
	_got = true
	_burst()
	collected.emit(self)
	queue_free()

# Nổ tung một lần khi nhặt
func _burst() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var b := CPUParticles2D.new()
	b.texture = _tex
	b.position = position
	b.one_shot = true
	b.explosiveness = 1.0
	b.amount = 18
	b.lifetime = 0.6
	b.spread = 180.0
	b.direction = Vector2.UP
	b.gravity = Vector2.ZERO
	b.initial_velocity_min = 60.0
	b.initial_velocity_max = 140.0
	b.scale_amount_min = 0.06
	b.scale_amount_max = 0.12
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(core_color, 0.9), Color(core_color, 0.0)])
	b.color_ramp = g
	parent.add_child(b)
	b.emitting = true
	b.finished.connect(b.queue_free)

func _make_radial_texture() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = grad
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t
