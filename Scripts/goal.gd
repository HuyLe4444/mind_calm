extends Area2D
class_name Goal
#
#@export var glow_color: Color = Color(0.2, 1.0, 0.4)   # xanh lá
#@export var particle_amount: int = 40
#@export var drift_speed: float = 12.0   # tốc độ toả ra, càng nhỏ càng "nhẹ"
#
#@onready var particles: CPUParticles2D = $CPUParticles2D
#@onready var shape_node: CollisionShape2D = $CollisionShape2D
#
#func _ready() -> void:
	#_setup_particles()
#
#func _setup_particles() -> void:
	## Hạt tròn: texture hình tròn mờ dần ra rìa
	#var base := Gradient.new()
	#base.set_color(0, Color(1, 1, 1, 1))
	#base.set_color(1, Color(1, 1, 1, 0))
	#var tex := GradientTexture2D.new()
	#tex.gradient = base
	#tex.fill = GradientTexture2D.FILL_RADIAL
	#tex.fill_from = Vector2(0.5, 0.5)
	#tex.fill_to = Vector2(1.0, 0.5)
	#tex.width = 32
	#tex.height = 32
	#particles.texture = tex
#
	## Mờ vào lúc sinh ra và mờ ra lúc biến mất
	#var fade := Gradient.new()
	#fade.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
	#fade.colors = PackedColorArray([
		#Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)
	#])
	#particles.color_ramp = fade
	#particles.color = glow_color
#
	## Phát ra trên toàn bộ vùng chạm của goal
	#particles.position = shape_node.position
	#if shape_node.shape is CircleShape2D:
		#particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		#particles.emission_sphere_radius = (shape_node.shape as CircleShape2D).radius
	#elif shape_node.shape is RectangleShape2D:
		#particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		#particles.emission_rect_extents = (shape_node.shape as RectangleShape2D).size * 0.5
#
	## Toả ra nhẹ theo mọi hướng, không bị rơi xuống
	#particles.direction = Vector2.UP
	#particles.spread = 180.0
	#particles.gravity = Vector2.ZERO
	#particles.initial_velocity_min = drift_speed * 0.5
	#particles.initial_velocity_max = drift_speed
#
	#particles.amount = particle_amount
	#particles.lifetime = 1.6
	#particles.scale_amount_min = 0.4
	#particles.scale_amount_max = 0.9
	#particles.local_coords = true
#
	## Cộng ánh sáng để hạt có cảm giác phát sáng
	#var mat := CanvasItemMaterial.new()
	#mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	#particles.material = mat
#
	#particles.emitting = false
#
## Bật hoặc tắt goal, dùng cho cả vùng chạm lẫn hiệu ứng
#func set_active(active: bool) -> void:
	#set_deferred("monitoring", active)
	#visible = active
	#particles.emitting = active
@export var glow_color: Color = Color(0.10, 0.65, 0.25)   # ruột xanh lá
@export var edge_color: Color = Color(0.03, 0.32, 0.12)   # viền xanh sẫm
@export var radius: float = 22.0
@export var particle_amount: int = 40
@export var drift_speed: float = 12.0

var _time: float = 0.0
var _active: bool = false
var _halo: Sprite2D
var _particles: CPUParticles2D
var _tex: GradientTexture2D

func _ready() -> void:
	# Bỏ node hạt cũ trong scene (nếu còn), vì giờ hạt tạo bằng code
	var old := get_node_or_null("Particles")
	if old != null:
		old.queue_free()

	# Giữ CollisionShape2D có sẵn trong scene; chưa có thì tự tạo
	var has_shape := false
	for c in get_children():
		if c is CollisionShape2D:
			has_shape = true
	if not has_shape:
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = radius + 4.0
		shape.shape = circle
		add_child(shape)

	_tex = _make_radial_texture()

	# Quầng mờ phía sau
	_halo = Sprite2D.new()
	_halo.texture = _tex
	_halo.modulate = Color(glow_color, 0.30)
	_halo.scale = Vector2.ONE * (radius * 4.0 / 128.0)
	add_child(_halo)

	# Hạt xanh bay quanh
	_particles = CPUParticles2D.new()
	_particles.texture = _tex
	_particles.amount = particle_amount
	_particles.lifetime = 1.8
	_particles.local_coords = true
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = radius * 0.9
	_particles.direction = Vector2.UP
	_particles.spread = 180.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = drift_speed * 0.3
	_particles.initial_velocity_max = drift_speed
	_particles.scale_amount_min = 0.06
	_particles.scale_amount_max = 0.12
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(glow_color, 0.8), Color(glow_color, 0.0)])
	_particles.color_ramp = g
	_particles.emitting = false
	add_child(_particles)

	# Mặc định ẩn cho tới khi main bật
	visible = false
	set_process(false)
	monitoring = false

func set_active(active: bool) -> void:
	_active = active
	set_deferred("monitoring", active)
	set_process(active)
	visible = active
	if _particles != null:
		_particles.emitting = active
	if active:
		scale = Vector2.ZERO
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_time += delta
	var pulse := 1.0 + sin(_time * 3.0) * 0.12
	_halo.scale = Vector2.ONE * (radius * 4.0 / 128.0) * pulse
	queue_redraw()

func _draw() -> void:
	if not _active:
		return
	# Hai vòng xung lệch pha lan ra rồi mờ dần
	for i in range(2):
		var t := fposmod(_time * 0.7 + float(i) * 0.5, 1.0)
		var ring_r := radius + 4.0 + t * 20.0
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 48,
			Color(glow_color, 0.55 * (1.0 - t)), 2.5, true)
	# Viên đặc: viền, ruột, điểm sáng
	draw_circle(Vector2.ZERO, radius, edge_color)
	draw_circle(Vector2.ZERO, radius - 3.0, glow_color)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.28,
		Color(0.8, 1.0, 0.8, 0.85))

# Nổ tung một lần khi người chơi chạm
func burst() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var b := CPUParticles2D.new()
	b.texture = _tex
	b.one_shot = true
	b.explosiveness = 1.0
	b.amount = 36
	b.lifetime = 0.8
	b.spread = 180.0
	b.direction = Vector2.UP
	b.gravity = Vector2.ZERO
	b.initial_velocity_min = 80.0
	b.initial_velocity_max = 200.0
	b.scale_amount_min = 0.08
	b.scale_amount_max = 0.16
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(glow_color, 0.9), Color(glow_color, 0.0)])
	b.color_ramp = g
	parent.add_child(b)
	b.global_position = global_position
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
