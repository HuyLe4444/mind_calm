class_name Ripple
extends Node2D
#
#var speed: float = 150.0
#var thickness: float = 10.0
#var max_radius: float = 700.0
#var damage: int = 1
#var color: Color = Color.WHITE
#
## Hình dạng
#var lobes: int = 0            # 0 = hình tròn; 3, 5... = nhiều cánh
#var amplitude: float = 0.0    # độ méo của cánh (0 = tròn, 0.3 = méo rõ)
#var spin: float = 0.0         # tốc độ xoay (rad/giây)
#var gap_size: float = 0.0     # góc khe hở an toàn (rad), 0 = không có
#var gap_angle: float = 0.0    # hướng của khe hở
#
#var radius: float = 0.0
#var phase: float = 0.0
#var already_hit: bool = false
#var player: Node2D
#
#func _ready() -> void:
	#player = get_tree().get_first_node_in_group("mind")
	#add_to_group("ripples")
#
#func _physics_process(delta: float) -> void:
	#radius += speed * delta
	#phase += spin * delta
	#if radius > max_radius:
		#queue_free()
		#return
	#_check_hit()
	#queue_redraw()
#
## Bán kính của sóng ở một góc nhất định
#func radius_at(angle: float) -> float:
	#if lobes <= 0:
		#return radius
	#return radius * (1.0 + amplitude * cos(lobes * (angle - phase)))
#
#func _in_gap(angle: float) -> bool:
	#if gap_size <= 0.0:
		#return false
	#return abs(angle_difference(angle, gap_angle + phase)) < gap_size * 0.5
#
#func _check_hit() -> void:
	#if already_hit or player == null:
		#return
	#var offset := player.global_position - global_position
	#var angle := offset.angle()
	#if _in_gap(angle):
		#return
	#if abs(offset.length() - radius_at(angle)) <= thickness * 0.5:
		#already_hit = true
		#if player.has_method("take_damage"):
			#player.take_damage(damage)
#
#func _draw() -> void:
	#var steps := 128
	#var c := color
	#c.a = clamp(1.0 - radius / max_radius, 0.0, 1.0)
	#var segment := PackedVector2Array()
	#for i in range(steps + 1):
		#var a := TAU * i / steps
		#if _in_gap(a - PI * 2 * 0 ):   # góc a nằm trong 0..TAU, angle_difference lo phần còn lại
			#if segment.size() > 1:
				#draw_polyline(segment, c, thickness)
			#segment = PackedVector2Array()
			#continue
		#segment.append(Vector2.from_angle(a) * radius_at(a))
	#if segment.size() > 1:
		#draw_polyline(segment, c, thickness)


signal touched   # bắn ra mỗi lần người chơi chạm vào sóng

const POINT_SPACING := 6.0   # khoảng cách giữa hai điểm vẽ (pixel)
const HIT_MARGIN := 3.0      # vùng chạm rộng hơn nét vẽ mỗi bên bấy nhiêu pixel
# --- Nhiễu khi người chơi bị dính sóng ---
const DISTORT_MAX := 28.0            # độ lệch tối đa (pixel), bằng biên độ zigzag
const DISTORT_BEND_LENGTH := 220.0   # độ dài mỗi nhịp uốn cong
const DISTORT_ZIG_LENGTH := 90.0     # bước sóng zigzag khi nhiễu chạm đỉnh

var erase_center: Vector2 = Vector2.ZERO   # tâm vùng bị xóa (tọa độ toàn cục)
var erase_radius: float = -1.0             # < 0 = không xóa gì

var kind: String = "ring"        # "ring", "bar", "zigzag", "sine"
var dir_name: String = "down"    # hướng đi của bar, zigzag, sine
var color: Color = Color(0.33, 0.22, 0.15)

var speed: float = 90.0
var speed_scale: float = 1.0
var thickness: float = 3.0
var damage: int = 1

# Riêng "ring"
var lobes: int = 0
var amplitude: float = 0.0
var spin: float = 0.0

# Riêng "bar", "zigzag", "sine"
var span: float = 400.0          # độ dài của thanh (pixel), căn giữa tại điểm phát
var wave_height: float = 0.0
var wavelength: float = 100.0
var drift: float = 0.0

# Các chỗ đứt
var gap_count: int = 4
var gap_width: float = 80.0
var gap_phase: float = 0.0

var clip_rect: Rect2
var max_travel: float = 0.0

var travel: float = 0.0      # quãng sóng đã đi (với "ring" chính là bán kính)
var phase: float = 0.0
var time: float = 0.0
var was_touching: bool = false
var distortion: float = 0.0           # 0 = bình thường, 1 = đỉnh (main cập nhật mỗi frame)
var noise_phase: float = randf() * TAU   # mỗi sóng nhiễu lệch pha nhau
var player: Node2D

var _segments: Array[PackedVector2Array] = []   # các đoạn sóng đang nhìn thấy

# Đọc cấu hình từ một mẫu sóng trong dữ liệu level
func setup(p: Dictionary, origin: Vector2, area: Rect2, speed_mult: float) -> void:
	position = origin
	clip_rect = area
	kind = p.get("kind", "ring")
	var is_ring := kind == "ring"
	# Điểm ở nửa trên của vùng chơi thì đi xuống, nửa dưới thì đi lên
	var default_dir := "down" if origin.y < area.get_center().y else "up"
	dir_name = p.get("dir", default_dir)
	speed = p.get("speed", 90.0)
	speed_scale = speed_mult
	thickness = p.get("thickness", 3.0)
	damage = p.get("damage", 1)
	lobes = p.get("lobes", 0)
	amplitude = p.get("amplitude", 0.0)
	spin = p.get("spin", 0.0)
	span = p.get("span", 400.0)
	var default_height := 30.0 if kind == "zigzag" or kind == "sine" else 0.0
	wave_height = p.get("wave_height", default_height)
	wavelength = p.get("wavelength", 100.0)
	drift = p.get("drift", 0.0)
	gap_count = p.get("gap_count", randi_range(3, 5) if is_ring else 3)
	gap_width = p.get("gap_width", 80.0 if is_ring else 50.0)
	gap_phase = randf() / float(maxi(gap_count, 1))

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	add_to_group("ripples")
	if kind == "ring":
		var corners: Array[Vector2] = [
			clip_rect.position,
			Vector2(clip_rect.end.x, clip_rect.position.y),
			Vector2(clip_rect.position.x, clip_rect.end.y),
			clip_rect.end,
		]
		for c in corners:
			max_travel = maxf(max_travel, global_position.distance_to(c))
		max_travel = max_travel * (1.0 + amplitude) + thickness + DISTORT_MAX
	else:
		# Thanh biến mất khi đã đi hẳn ra khỏi vùng chơi theo hướng của nó
		var margin := wave_height + thickness + DISTORT_MAX
		match dir_name:
			"down": max_travel = clip_rect.end.y - global_position.y + margin
			"up": max_travel = global_position.y - clip_rect.position.y + margin
			"right": max_travel = clip_rect.end.x - global_position.x + margin
			_: max_travel = global_position.x - clip_rect.position.x + margin

func _process(delta: float) -> void:
	travel += speed * speed_scale * delta
	phase += spin * delta
	time += delta
	if travel > max_travel:
		queue_free()
		return
	_rebuild()
	_check_touch()
	queue_redraw()

# --- Hình học của từng loại sóng ---
# Mỗi sóng là một đường cong tham số: _point(t) với t từ 0 đến 1,
# toạ độ tính từ điểm phát (vị trí của node)

func _vertical_motion() -> bool:
	return dir_name == "down" or dir_name == "up"

func _dir_sign() -> float:
	return 1.0 if dir_name == "down" or dir_name == "right" else -1.0

# Độ dài đường sóng (pixel), dùng để đổi bề rộng chỗ đứt và số điểm vẽ
func _length() -> float:
	if kind == "ring":
		return TAU * maxf(travel, 1.0)
	return span

func _triangle(x: float) -> float:
	return 4.0 * absf(x - floorf(x + 0.5)) - 1.0   # sóng tam giác, giá trị từ -1 đến 1

func _point(t: float) -> Vector2:
	if kind == "ring":
		var k := 1.0
		if lobes > 0:
			k += amplitude * cos(lobes * TAU * t)
		# Nhiễu làm bán kính lệch ra hoặc vào
		var r := travel * k + _distort(t * _length())
		return Vector2.from_angle(TAU * t + phase) * maxf(r, 0.0)
	# Các loại thanh: căn giữa tại điểm phát, dịch dần theo hướng đi
	var s := (t - 0.5) * span
	var disp := 0.0
	if kind == "zigzag":
		disp = wave_height * _triangle(s / wavelength)
	elif kind == "sine":
		disp = wave_height * sin(TAU * s / wavelength + drift * time)
	var front := _dir_sign() * travel + disp + _distort(s)
	if _vertical_motion():
		return Vector2(s, front)
	return Vector2(front, s)

# Độ lệch do nhiễu tại vị trí s (pixel dọc theo sóng), theo phương vuông góc với sóng
func _distort(s: float) -> float:
	if distortion <= 0.001:
		return 0.0
	# Uốn cong chậm
	var bend := sin(TAU * s / DISTORT_BEND_LENGTH + time * 1.2 + noise_phase)
	# Rung rè nhanh: hai tần số chồng nhau, đổi theo thời gian
	var jitter := 0.6 * sin(TAU * s / 26.0 + time * 31.0 + noise_phase) \
		+ 0.4 * sin(TAU * s / 17.0 - time * 47.0)
	var rough := bend * 0.55 + jitter * 0.3
	# Gần đỉnh thì chuyển dần sang zigzag
	var zig := _triangle(s / DISTORT_ZIG_LENGTH)
	var m := smoothstep(0.7, 1.0, distortion)
	return DISTORT_MAX * distortion * lerpf(rough, zig, m)

func _spacing() -> float:
	var base := POINT_SPACING
	if kind == "zigzag" or kind == "sine":
		base = minf(POINT_SPACING, wavelength / 12.0)
	if distortion > 0.05:
		base = minf(base, 5.0)
	return base

func _inside(t: float) -> bool:
	return clip_rect.has_point(global_position + _point(t))

# --- Chỗ đứt ---
func _gap_t() -> float:
	return minf(gap_width / _length(), 0.8 / maxf(gap_count, 1))

# Các khoảng t nhìn thấy, nằm giữa hai chỗ đứt
func _visible_arcs() -> Array[Vector2]:
	var arcs: Array[Vector2] = []
	if gap_count <= 0:
		arcs.append(Vector2(0.0, 1.0))
		return arcs
	var period := 1.0 / gap_count
	var gap := _gap_t()
	var closed := kind == "ring"
	for k in range(0 if closed else -1, gap_count):
		var t0 := gap_phase + k * period + gap
		var t1 := gap_phase + (k + 1) * period
		if not closed:
			t0 = clampf(t0, 0.0, 1.0)
			t1 = clampf(t1, 0.0, 1.0)
			if t1 - t0 < 0.0005:
				continue
		arcs.append(Vector2(t0, t1))
	return arcs

# --- Dựng các đoạn sóng nhìn thấy (dùng chung cho vẽ và va chạm) ---
func _rebuild() -> void:
	_segments.clear()
	for arc in _visible_arcs():
		_collect_arc(arc.x, arc.y)

func _store(segment: PackedVector2Array) -> void:
	if segment.size() >= 2:
		_segments.append(segment)

func _collect_arc(t0: float, t1: float) -> void:
	var steps := maxi(int((t1 - t0) * _length() / _spacing()), 4)
	var segment := PackedVector2Array()
	var prev_t := t0
	var prev_in := _inside(t0)
	if prev_in:
		segment.append(_point(t0))
	for i in range(1, steps + 1):
		var t := lerpf(t0, t1, float(i) / steps)
		var cur_in := _inside(t)
		if cur_in != prev_in:
			# Vừa đi qua biên: dò đúng điểm cắt để đầu đoạn trượt mượt
			var edge := _find_edge(prev_t, t, prev_in)
			segment.append(_point(edge))
			if prev_in:
				_store(segment)
				segment = PackedVector2Array()
		if cur_in:
			segment.append(_point(t))
		prev_t = t
		prev_in = cur_in
	_store(segment)

func _find_edge(from_t: float, to_t: float, from_inside: bool) -> float:
	var lo := from_t
	var hi := to_t
	for i in range(8):
		var mid := (lo + hi) * 0.5
		if _inside(mid) == from_inside:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5

# --- Va chạm: khoảng cách từ người chơi tới đường sóng đang hiện ---
func _check_touch() -> void:
	if player == null:
		return
	var touching := _is_touching_player()
	if touching and not was_touching:
		touched.emit()
		if player.has_method("take_damage"):
			player.take_damage(damage)
	was_touching = touching

func _is_touching_player() -> bool:
	if player.get("invincible") == true:
		return false
	var p := player.global_position - global_position
	var limit := thickness * 0.5 + HIT_MARGIN
	var limit_sq := limit * limit
	for seg in _segments:
		for i in range(seg.size() - 1):
			var c := Geometry2D.get_closest_point_to_segment(p, seg[i], seg[i + 1])
			if p.distance_squared_to(c) <= limit_sq:
				return true
	return false

# --- Vẽ ---
func _draw() -> void:
	for seg in _segments:
		if erase_radius < 0.0:
			draw_polyline(seg, color, thickness, true)
			continue
		# Chỉ vẽ những đoạn nằm ngoài vòng sóng hồng
		var run := PackedVector2Array()
		for p in seg:
			if (global_position + p).distance_to(erase_center) >= erase_radius:
				run.append(p)
			else:
				if run.size() >= 2:
					draw_polyline(run, color, thickness, true)
				run = PackedVector2Array()
		if run.size() >= 2:
			draw_polyline(run, color, thickness, true)
