extends Node2D
#
#@onready var goal_left: Goal = $GoalLeft
#@onready var goal_right: Goal = $GoalRight
#
## Mỗi level là danh sách các mẫu sóng
#var levels: Array = [
	## Level 1: tròn, 1 đợt, chậm
	#[ {rings = 1, speed = 120, thickness = 8, pause = 2.5} ],
	## Level 2: tròn, 2 đợt
	#[ {rings = 2, interval = 0.7, speed = 130, thickness = 8, pause = 2.0} ],
	## Level 3: bắt đầu méo, hai điểm tạo sóng
	#[ {rings = 2, interval = 0.6, speed = 150, lobes = 3, amplitude = 0.15},
	  #{rings = 2, interval = 0.6, speed = 150, delay = 1.5} ],
	## Level 4: hoa 5 cánh xoay, dày hơn, có khe hở
	#[ {rings = 3, interval = 0.5, speed = 180, thickness = 14,
	   #lobes = 5, amplitude = 0.3, spin = 1.2, gap_size = 0.9, damage = 2} ],
#]
#
#var level_index: int = 0
#var run_id: int = 0   # đổi mỗi level để các vòng lặp của level cũ tự dừng
#
#func _ready() -> void:
	#goal_left.body_entered.connect(_on_goal_entered.bind(goal_left))
	#goal_right.body_entered.connect(_on_goal_entered.bind(goal_right))
	#start_level(0)
#
## Level chẵn (0, 2, ...) đi trái sang phải; level lẻ đi ngược lại
#func _active_goal(index: int) -> Goal:
	#return goal_right if index % 2 == 0 else goal_left
#
#func start_level(index: int) -> void:
	#level_index = index
	#run_id += 1
	#var active := _active_goal(index)
	#for g in [goal_left, goal_right]:
		#g.set_active(g == active)
	#for pattern in levels[index]:
		#_run_pattern(pattern, run_id)
#
#func _on_goal_entered(body: Node2D, goal: Goal) -> void:
	#if not body.is_in_group("mind") or goal != _active_goal(level_index):
		#return
	#run_id += 1   # dừng mọi mẫu sóng đang lặp
	#get_tree().call_group("ripples", "queue_free")
	#if level_index + 1 >= levels.size():
		#print("Thắng toàn bộ game!")   # thay bằng màn hình chiến thắng
		#return
	#await get_tree().create_timer(1.0).timeout
	#start_level(level_index + 1)
#
#func _run_pattern(p: Dictionary, id: int) -> void:
	#await get_tree().create_timer(p.get("delay", 0.0)).timeout
	#while id == run_id:
		#var origin: Vector2 = p.get("origin", _random_origin())
		#for i in range(p.get("rings", 1)):
			#if id != run_id:
				#return
			#_spawn_ripple(origin, p)
			#await get_tree().create_timer(p.get("interval", 0.5)).timeout
		#await get_tree().create_timer(p.get("pause", 1.5)).timeout
#
#func _spawn_ripple(origin: Vector2, p: Dictionary) -> void:
	#var r := Ripple.new()
	#add_child(r)
	#r.global_position = origin
	#r.speed = p.get("speed", 150.0)
	#r.thickness = p.get("thickness", 10.0)
	#r.damage = p.get("damage", 1)
	#r.lobes = p.get("lobes", 0)
	#r.amplitude = p.get("amplitude", 0.0)
	#r.spin = p.get("spin", 0.0)
	#r.gap_size = p.get("gap_size", 0.0)
	#r.gap_angle = randf() * TAU
#
#func _random_origin() -> Vector2:
	## Đổi số cho khớp với khung của bạn
	#return Vector2(randf_range(150, 450), randf_range(150, 350))
#
#@export var divider_thickness: float = 1.0
#@export var goal_inset: float = 50.0
#@export var show_points: bool = true
#@export var touch_speed_gain: float = 1.2
#@export var speed_recovery: float = 0.25
#@export var max_speed_mult: float = 3.0
#@export var distortion_per_hit: float = 0.25    # mỗi lần dính tăng bao nhiêu (1.0 là đỉnh)
#@export var distortion_recovery: float = 0.12   # giảm mỗi giây khi không bị dính
#var distortion: float = 0.0
#
#@onready var goal_left: Goal = $GoalLeft
#@onready var goal_right: Goal = $GoalRight
#
#var levels: Array = [
	## 1: làm quen. Sóng tròn, chỗ đứt rộng, nghỉ lâu
	#[ {points = [2, 7], speed = 90, gap_width = 100, pause = 5.0} ],
#
	## 2: hai đợt liền nhau
	#[ {points = [3, 6], rings = 2, interval = 1.5, speed = 95,
	   #gap_width = 100, pause = 3.5} ],
#
	## 3: hai điểm phát lệch nhịp nhau
	#[ {points = [2], rings = 2, interval = 1.4, speed = 100, pause = 3.5},
	  #{points = [7], rings = 2, interval = 1.4, speed = 100, delay = 2.0, pause = 3.5} ],
#
	## 4: SÓNG MÉO (hình elip xoay chậm)
	#[ {points = [2, 6], lobes = 2, amplitude = 0.22, spin = 0.5, speed = 95,
	   #pause = 4.5} ],
#
	## 5: sóng méo ba cánh kèm sóng tròn lệch nhịp
	#[ {points = [3, 7], rings = 2, interval = 1.5, lobes = 3, amplitude = 0.12,
	   #spin = 0.4, speed = 100, pause = 3.5},
	  #{points = [1], speed = 90, delay = 2.5, pause = 5.0} ],
#
	## 6: THANH NGANG đầu tiên, dài gần hết màn, ba thanh liên tiếp mỗi thanh khe một chỗ
	#[ {kind = "bar", points = [2], span = 900, rings = 3, interval = 1.6,
	   #speed = 100, gap_count = 3, gap_width = 70, pause = 2.5} ],
#
	## 7: hai thanh đi ngược chiều cắt nhau giữa màn (điểm 3 đi xuống, điểm 6 đi lên)
	#[ {kind = "bar", points = [3, 6], span = 800, rings = 3, interval = 1.5,
	   #speed = 105, gap_width = 60, pause = 2.5} ],
#
	## 8: ZIGZAG dốc, kèm một sóng tròn ở góc
	#[ {kind = "zigzag", points = [2, 7], span = 800, wave_height = 34,
	   #wavelength = 80, rings = 3, interval = 1.7, speed = 105, gap_width = 60,
	   #pause = 2.5},
	  #{points = [1], speed = 85, delay = 1.0, pause = 5.0} ],
#
	## 9: lưới. Thanh dọc đi ngang từ mép phải cắt thanh ngang đi xuống
	#[ {kind = "sine", points = [4, 8], dir = "left", span = 400, wave_height = 24,
	   #wavelength = 110, drift = 2.0, rings = 3, interval = 1.5, speed = 110,
	   #gap_count = 2, gap_width = 70, pause = 2.5},
	  #{kind = "bar", points = [2], span = 700, rings = 2, interval = 2.0,
	   #speed = 100, gap_width = 65, delay = 1.0, pause = 3.0} ],
#
	## 10: hai thanh xuống chồng nhau + zigzag đi lên + sóng tròn
	#[ {kind = "bar", points = [2, 3], span = 700, rings = 3, interval = 1.4,
	   #speed = 115, gap_width = 60, pause = 2.0},
	  #{points = [6, 7], speed = 95, delay = 1.2, pause = 5.0} ],
#
#
	## 11: zigzag kết hợp sóng méo, chỗ đứt hẹp hơn
	#[ {kind = "zigzag", points = [3, 6], span = 440, wave_height = 26,
	   #wavelength = 100, rings = 2, interval = 1.8, speed = 115, pause = 2.5},
	  #{points = [2, 7], lobes = 2, amplitude = 0.2, spin = 0.6, speed = 100,
	   #gap_width = 70, delay = 1.2, pause = 4.5} ],
#
	## 12: màn cuối, thanh + sóng lượn + sóng méo cùng lúc
	#[ {kind = "bar", points = [2, 3], span = 320, rings = 3, interval = 1.5,
	   #speed = 120, pause = 2.5},
	  #{kind = "sine", points = [4, 8], dir = "left", span = 360, wave_height = 22,
	   #wavelength = 120, drift = 2.0, rings = 2, interval = 2.0, speed = 115,
	   #delay = 0.8, pause = 3.0},
	  #{points = [1, 5], lobes = 3, amplitude = 0.12, spin = 0.5, speed = 100,
	   #gap_width = 70, delay = 1.6, pause = 4.5} ],
#]
#
#var screen: Vector2
#var mid_y: float
#var clip_rect: Rect2
#var emit_points: Array[Vector2] = []   # phần tử 0..7 ứng với điểm 1..8
#
#var level_index: int = 0
#var run_id: int = 0
#var wave_speed_mult: float = 1.0
#
#func _ready() -> void:
	#screen = get_viewport_rect().size
	#mid_y = screen.y / 2.0
	#clip_rect = Rect2(0, 0, screen.x, mid_y - divider_thickness * 0.5)
#
	#_build_divider()
	#_build_points()
#
	#goal_left.position = Vector2(goal_inset, mid_y / 2.0)
	#goal_right.position = Vector2(screen.x - goal_inset, mid_y / 2.0)
	#goal_left.body_entered.connect(_on_goal_entered.bind(goal_left))
	#goal_right.body_entered.connect(_on_goal_entered.bind(goal_right))
#
	#start_level(0)
#
#func _build_divider() -> void:
	#var size := Vector2(screen.x, divider_thickness)
	#var body := StaticBody2D.new()
	#body.position = Vector2(screen.x / 2.0, mid_y)
#
	#var shape := CollisionShape2D.new()
	#var rect := RectangleShape2D.new()
	#rect.size = size
	#shape.shape = rect
	#body.add_child(shape)
#
	#var visual := ColorRect.new()
	#visual.size = size
	#visual.position = -size / 2.0
	#visual.color = Color(0.75, 0.75, 0.75)
	#body.add_child(visual)
#
	#add_child(body)
#
## 8 điểm phát sóng nằm trên viền của nửa trên, cách đều nhau
#func _build_points() -> void:
	#emit_points.clear()
	#var top_y := 0.0
	#var bottom_y := clip_rect.end.y   # mép trên của thanh ngăn
	#for y in [top_y, bottom_y]:
		#for col in range(4):
			#emit_points.append(Vector2(screen.x * col / 3.0, y))
	#queue_redraw()
#
#func _draw() -> void:
	#if not show_points:
		#return
	#var font := ThemeDB.fallback_font
	#for i in range(emit_points.size()):
		#var p := emit_points[i]
		#draw_circle(p, 4.0, Color(1, 1, 1, 0.4))
		#var label_offset := Vector2(
			#10.0 if p.x < screen.x * 0.5 else -22.0,
			#20.0 if p.y < mid_y * 0.5 else -8.0
		#)
		#draw_string(font, p + label_offset, str(i + 1),
			#HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.4))
#
#func _process(delta: float) -> void:
	#wave_speed_mult = move_toward(wave_speed_mult, 1.0, speed_recovery * delta)
	#distortion = move_toward(distortion, 0.0, distortion_recovery * delta)
	#for r in get_tree().get_nodes_in_group("ripples"):
		#r.speed_scale = wave_speed_mult
		#r.distortion = distortion
#
#func _on_ripple_touched() -> void:
	#wave_speed_mult = minf(wave_speed_mult * touch_speed_gain, max_speed_mult)
	#distortion = minf(distortion + distortion_per_hit, 1.0)
	#
## Level chẵn (0, 2, ...) đi trái sang phải; level lẻ đi ngược lại
#func _active_goal(index: int) -> Goal:
	#return goal_right if index % 2 == 0 else goal_left
#
#func start_level(index: int) -> void:
	#level_index = index
	#run_id += 1
	#wave_speed_mult = 1.0
	#distortion = 0.0
	#var active := _active_goal(index)
	#for g in [goal_left, goal_right]:
		#g.set_active(g == active)
	#for pattern in levels[index]:
		#_run_pattern(pattern, run_id)
#
#func _on_goal_entered(body: Node2D, goal: Goal) -> void:
	#if not body.is_in_group("player") or goal != _active_goal(level_index):
		#return
	#run_id += 1
	#get_tree().call_group("ripples", "queue_free")
	#goal.burst()
	#goal.set_active(false)
	#if level_index + 1 >= levels.size():
		#print("Thắng toàn bộ game!")
		#return
	#await get_tree().create_timer(1.2).timeout
	#start_level(level_index + 1)
#
#func _run_pattern(p: Dictionary, id: int) -> void:
	#await get_tree().create_timer(p.get("delay", 0.0)).timeout
	#while id == run_id:
		#var origins := _pattern_origins(p)
		#for i in range(p.get("rings", 1)):
			#if id != run_id:
				#return
			#for o in origins:
				#_spawn_ripple(o, p)
			#await get_tree().create_timer(p.get("interval", 1.0)).timeout
		#await get_tree().create_timer(p.get("pause", 2.0)).timeout
#
## Sóng tròn phát từ các điểm đã chọn; các loại thanh quét cả vùng nên chỉ cần một lần
#func _pattern_origins(p: Dictionary) -> Array[Vector2]:
	#var result: Array[Vector2] = []
	#for n in p.get("points", [randi_range(1, 8)]):
		#result.append(emit_points[n - 1])
	#return result
#
#func _spawn_ripple(origin: Vector2, p: Dictionary) -> void:
	#var r := Ripple.new()
	#r.setup(p, origin, clip_rect, wave_speed_mult)
	#r.distortion = distortion
	#r.touched.connect(_on_ripple_touched)
	#add_child(r)

@export var portrait: CanvasItem                  # node ảnh nền; kéo vào ở Inspector
@export var portrait_game_alpha: float = 0.35     # độ đậm của ảnh khi đang chơi
@export var ending_text: String = "Thank you for playing"

@export var frame_size: Vector2 = Vector2(900, 360)   # kích thước khung chơi (đặt giữa màn hình)
@export var wall_thickness: float = 32.0
@export var frame_color: Color = Color(1, 1, 1)
@export var goal_inset: float = 50.0
@export var show_points: bool = true
@export var touch_speed_gain: float = 1.2
@export var speed_recovery: float = 0.25
@export var max_speed_mult: float = 3.0
@export var distortion_per_hit: float = 0.25
@export var distortion_recovery: float = 0.12
@export var orb_margin: float = 60.0
@export var orb_min_gap: float = 130.0
@export var orb_avoid_gap: float = 110.0
@export var line_thickness: float = 8.0      # độ dày ở giữa đường kim
@export var line_overhang: float = 24.0      # đường kim dài vượt khung mỗi bên bấy nhiêu
@export var taper_power: float = 1.0         # 1 = thon đều, nhỏ hơn 1 = giữa đầy hơn, lớn hơn 1 = nhọn hơn
@export var breath_action: StringName = &"Action"   # tên action trong Input Map; đổi nếu bạn đặt tên khác
@export var touch_cooldown: float = 0.35   # giây chờ giữa hai lần tính "đụng"
@export var peak_hold: float = 1.0         # giây nhiễu giữ ở đỉnh trước khi giảm
@export_file("*.wav") var sfx_orb_path: String = "res://Assets/Hit.wav"
@export_file("*.wav") var sfx_goal_path: String = "res://Assets/Hit.wav"
@export_file("*.wav") var sfx_hit_path: String = "res://Assets/Hi.wav"
@export var sfx_volume_db: float = -4.0

var _sfx_orb: AudioStream
var _sfx_goal: AudioStream
var _sfx_hit: AudioStream

@onready var goal_left: Goal = $GoalLeft
@onready var goal_right: Goal = $GoalRight

# Nhạc theo màn mở đầu của mỗi arc. Sửa đường dẫn cho khớp file của bạn.
# Arc nào không có nhạc thì bài trước đó tiếp tục phát.
var arc_music: Dictionary = {
	0:  "res://Assets/NovBaby.wav",
	3:  "res://Assets/NovChild.wav",
	8:  "res://Assets/NovAdult.wav",
	22: "res://Audio/man.ogg",
}
@export var music_volume_db: float = -6.0
@export var music_fade: float = 1.5   # giây chuyển bài

var _music: AudioStreamPlayer
var _music_key: int = -2

# Cốt truyện phát TRƯỚC màn có chỉ số này (bắt đầu từ 0 nên màn 1 là 0).
# Các câu chữ dưới đây là bản nháp để bạn thay bằng lời của riêng mình.
var story_data: Dictionary = {
	# Trước màn 1: em bé. Ảnh thường đã có sẵn trong cảnh nên chỉ cần ảnh thở
	0: {image = "res://Assets/baby.PNG",
		breath_image = "res://Assets/baby.PNG",
		boxes = ["Say Dada", "Let him sleep, Hon."]},
	# Trước màn 4: cấp 2
	3: {image = "res://Assets/child.png",
		breath_image = "res://Assets/child_breath.png",
		boxes = ["Why is your math grade only a 6?",
				 "Did you finish your homework?",
				 "Why can't you be more like your cousin?",
				 "Who were you texting in class?"]},
	# Trước màn 9: người lớn
	8: {image = "res://Assets/adult.png",
		breath_image = "res://Assets/adult_breath.png",
		boxes = ["When is your next raise?",
				 "Rent is due on Friday.",
				 "Are you coming home for dinner?",
				 "Did you pick up the kids?",
				 "Have you thought about a better job?"]},
	# Trước màn 16: cutscene riêng của bạn (xem hàm _play_custom bên dưới)
	15: {custom = "cutscene_4"},
	# Trước màn 23: người đàn ông
	22: {image = "res://Assets/man.png",
		breath_image = "res://Assets/man_breath.png",
		boxes = ["Did you call your mother?",
				 "What do you want to be remembered for?",
				 "Are you happy?"]},
}

# Số bóng cần nhặt ở từng màn (23 màn)
var orb_counts: Array = [
	1, 1, 2,
	2, 2, 3, 3, 3,
	3, 3, 4, 4, 4, 4, 5,
	4, 4, 4, 5, 5, 5, 5,
	5,
]

# Box hiện lên giữa chương adult (cách 2 màn), lần lượt từng cặp
# Chỉ số màn của sự kiện riêng (màn 16 là chỉ số 15)
var adult_custom_index: int = 15

# Trước sự kiện: chưa có vợ con, chỉ có công việc, tiền, bố mẹ
var adult_chatter_early: Array = [
	["Rent's due on Friday.", "I know. I'll cover it."],
	["Another late night at the office?", "The deadline's tomorrow. Almost done."],
	["Your mother keeps asking when you'll visit.", "Soon. Work's been crazy."],
]

# Sau sự kiện: đã có vợ con
var adult_chatter_late: Array = [
	["Dad, will you come to my recital?", "I'll try my best, sweetheart."],
	["The boss wants us this weekend.", "Again? You promised the kids a picnic."],
	["The raise didn't go through.", "We'll get through it together."],
]

var levels: Array = [
	# ===== Hồi 1: em bé (màn 1 đến 3, giới thiệu) =====
	# 1: sóng tròn ở điểm 2 và 6
	[ {points = [2, 6], speed = 90, gap_width = 100, pause = 5.0} ],
	# 2: hai đợt liền nhau
	[ {points = [3, 7], rings = 2, interval = 1.5, speed = 95,
	   gap_width = 100, pause = 3.5} ],
	# 3: hai điểm phát lệch nhịp
	[ {points = [2], rings = 2, interval = 1.4, speed = 100, pause = 3.5},
	  {points = [7], rings = 2, interval = 1.4, speed = 100, delay = 2.0, pause = 3.5} ],

	# ===== Hồi 2: cấp 2 (màn 4 đến 8) =====
	# 4: sóng méo (hình elip xoay chậm)
	[ {points = [2, 6], lobes = 2, amplitude = 0.22, spin = 0.5, speed = 95,
	   pause = 4.5} ],
	# 5: sóng méo ba cánh kèm sóng tròn lệch nhịp
	[ {points = [3, 7], rings = 2, interval = 1.5, lobes = 3, amplitude = 0.12,
	   spin = 0.4, speed = 100, pause = 3.5},
	  {points = [1], speed = 90, delay = 2.5, pause = 5.0} ],
	# 6: thanh ngang đầu tiên, dài gần hết màn
	[ {kind = "bar", points = [2], span = 900, rings = 3, interval = 1.6,
	   speed = 100, gap_count = 3, gap_width = 70, pause = 2.5} ],
	# 7: hai thanh đi ngược chiều cắt nhau giữa màn
	[ {kind = "bar", points = [3, 6], span = 800, rings = 3, interval = 1.5,
	   speed = 105, gap_width = 60, pause = 2.5} ],
	# 8: zigzag dốc, kèm một sóng tròn ở góc
	[ {kind = "zigzag", points = [2, 7], span = 800, wave_height = 34,
	   wavelength = 80, rings = 3, interval = 1.7, speed = 105, gap_width = 60,
	   pause = 2.5},
	  {points = [1], speed = 85, delay = 1.0, pause = 5.0} ],

	# ===== Hồi 3: người lớn (màn 9 đến 15) =====
	# 9: lưới. Thanh dọc đi ngang từ mép phải cắt thanh ngang đi xuống
	[ {kind = "sine", points = [4, 8], dir = "left", span = 400, wave_height = 24,
	   wavelength = 110, drift = 2.0, rings = 3, interval = 1.5, speed = 110,
	   gap_count = 2, gap_width = 70, pause = 2.5},
	  {kind = "bar", points = [2], span = 700, rings = 2, interval = 2.0,
	   speed = 100, gap_width = 65, delay = 1.0, pause = 3.0} ],
	# 10: hai thanh xuống chồng nhau + sóng tròn từ dưới
	[ {kind = "bar", points = [2, 3], span = 700, rings = 3, interval = 1.4,
	   speed = 115, gap_width = 60, pause = 2.0},
	  {points = [6, 7], speed = 95, delay = 1.2, pause = 5.0} ],
	# 11: zigzag rất dốc kèm sóng méo
	[ {kind = "zigzag", points = [3, 6], span = 900, wave_height = 36,
	   wavelength = 80, rings = 3, interval = 1.6, speed = 115, gap_width = 55,
	   pause = 2.0},
	  {points = [2, 7], lobes = 2, amplitude = 0.2, spin = 0.6, speed = 100,
	   gap_width = 70, delay = 1.2, pause = 4.5} ],
	# 12: thanh đi xuống cắt zigzag đi lên
	[ {kind = "bar", points = [2, 3], span = 800, rings = 3, interval = 1.5,
	   speed = 110, gap_width = 60, pause = 2.5},
	  {kind = "zigzag", points = [6, 7], span = 800, wave_height = 30,
	   wavelength = 90, rings = 2, interval = 2.0, speed = 105, gap_width = 60,
	   delay = 0.8, pause = 3.0} ],
	# 13: sóng lượn từ hai phía đi ngược chiều nhau, kèm sóng tròn
	[ {kind = "sine", points = [1, 5], dir = "right", span = 400, wave_height = 22,
	   wavelength = 110, drift = 2.0, rings = 2, interval = 1.8, speed = 110,
	   gap_count = 2, gap_width = 80, pause = 3.5},
	  {kind = "sine", points = [4, 8], dir = "left", span = 400, wave_height = 22,
	   wavelength = 110, drift = -2.0, rings = 2, interval = 1.8, speed = 110,
	   gap_count = 2, gap_width = 80, delay = 0.9, pause = 3.5},
	  {points = [3], speed = 85, delay = 1.5, pause = 5.0} ],
	# 14: thanh + sóng méo + sóng lượn
	[ {kind = "bar", points = [2, 3], span = 700, rings = 2, interval = 1.6,
	   speed = 115, gap_width = 60, pause = 2.5},
	  {points = [6, 7], lobes = 2, amplitude = 0.2, spin = 0.6, speed = 100,
	   gap_width = 70, delay = 1.0, pause = 4.0},
	  {kind = "sine", points = [4], dir = "left", span = 400, wave_height = 20,
	   wavelength = 110, rings = 2, interval = 2.0, speed = 110, gap_count = 2,
	   gap_width = 80, delay = 2.0, pause = 3.5} ],
	# 15: cuối hồi: thanh + sóng lượn + sóng méo cùng lúc
	[ {kind = "bar", points = [2, 3], span = 800, rings = 3, interval = 1.4,
	   speed = 120, gap_width = 55, pause = 2.0},
	  {kind = "sine", points = [4, 8], dir = "left", span = 360, wave_height = 24,
	   wavelength = 110, drift = 2.0, rings = 3, interval = 1.6, speed = 115,
	   gap_count = 2, gap_width = 60, delay = 0.8, pause = 2.5},
	  {points = [1, 5], lobes = 3, amplitude = 0.12, spin = 0.5, speed = 100,
	   gap_width = 70, delay = 1.6, pause = 4.5} ],

	# ===== Hồi 4: sau cutscene (màn 16 đến 22) =====
	# 16: mở màn nhẹ lại: bốn điểm phát sóng tròn dày đặc
	[ {points = [1, 4, 6, 7], rings = 3, interval = 1.0, speed = 100,
	   gap_width = 80, pause = 3.5} ],
	# 17: hai làn zigzag đi ngược chiều nhau
	[ {kind = "zigzag", points = [2, 3], span = 900, wave_height = 36,
	   wavelength = 80, rings = 3, interval = 1.5, speed = 115, gap_width = 55,
	   pause = 2.0},
	  {kind = "zigzag", points = [6, 7], span = 900, wave_height = 36,
	   wavelength = 80, rings = 3, interval = 1.5, speed = 115, gap_width = 55,
	   delay = 0.75, pause = 2.0} ],
	# 18: lưới thanh ngang + thanh dọc
	[ {kind = "bar", points = [2, 3], span = 800, rings = 3, interval = 1.4,
	   speed = 120, gap_width = 55, pause = 2.0},
	  {kind = "sine", points = [4, 8], dir = "left", span = 360, wave_height = 24,
	   wavelength = 110, drift = 2.0, rings = 2, interval = 1.8, speed = 115,
	   gap_count = 2, gap_width = 65, delay = 0.6, pause = 3.0} ],
	# 19: zigzag dốc + sóng méo ba cánh
	[ {kind = "zigzag", points = [3, 6], span = 900, wave_height = 36,
	   wavelength = 80, rings = 3, interval = 1.6, speed = 118, gap_width = 55,
	   pause = 2.0},
	  {points = [2, 7], lobes = 3, amplitude = 0.15, spin = 0.7, speed = 105,
	   gap_width = 65, delay = 1.0, pause = 3.5} ],
	# 20: bốn thanh cùng lúc từ hai phía + sóng tròn
	[ {kind = "bar", points = [2, 3, 6, 7], span = 650, rings = 3, interval = 1.5,
	   speed = 120, gap_width = 55, pause = 2.0},
	  {points = [1, 4], speed = 95, delay = 1.0, pause = 4.0} ],
	# 21: thanh + zigzag + sóng lượn
	[ {kind = "bar", points = [2, 3], span = 800, rings = 3, interval = 1.4,
	   speed = 120, gap_width = 55, pause = 2.0},
	  {kind = "zigzag", points = [6, 7], span = 800, wave_height = 32,
	   wavelength = 85, rings = 2, interval = 1.8, speed = 115, gap_width = 55,
	   delay = 0.7, pause = 2.5},
	  {kind = "sine", points = [4, 8], dir = "left", span = 360, wave_height = 24,
	   wavelength = 110, drift = 2.0, rings = 2, interval = 1.8, speed = 115,
	   gap_count = 2, gap_width = 60, delay = 1.4, pause = 3.0} ],
	# 22: sóng méo + thanh + zigzag
	[ {points = [1, 4, 6, 7], lobes = 2, amplitude = 0.2, spin = 0.8, rings = 2,
	   interval = 1.2, speed = 105, gap_width = 65, pause = 3.0},
	  {kind = "bar", points = [2, 3], span = 800, rings = 3, interval = 1.3,
	   speed = 125, gap_width = 55, delay = 0.8, pause = 2.0},
	  {kind = "zigzag", points = [6, 7], span = 800, wave_height = 34,
	   wavelength = 80, rings = 3, interval = 1.5, speed = 120, gap_width = 55,
	   delay = 1.6, pause = 2.0} ],

	# ===== Hồi cuối: người đàn ông (màn 23) =====
	# 23: mọi loại sóng cùng lúc
	[ {kind = "bar", points = [2, 3], span = 800, rings = 3, interval = 1.3,
	   speed = 125, gap_width = 55, pause = 2.0},
	  {kind = "zigzag", points = [6, 7], span = 800, wave_height = 34,
	   wavelength = 80, rings = 3, interval = 1.5, speed = 120, gap_width = 55,
	   delay = 0.7, pause = 2.0},
	  {kind = "sine", points = [4, 8], dir = "left", span = 360, wave_height = 26,
	   wavelength = 100, drift = 2.5, rings = 2, interval = 1.8, speed = 120,
	   gap_count = 2, gap_width = 60, delay = 1.4, pause = 2.5},
	  {points = [1, 5], lobes = 3, amplitude = 0.15, spin = 0.9, speed = 105,
	   gap_width = 65, delay = 2.0, pause = 3.5} ],
]

var story: Story
var frame: Node2D                       # chứa tường và viền của khung chơi
var screen: Vector2
var clip_rect: Rect2                    # vùng chơi (phần bên trong khung)
var emit_points: Array[Vector2] = []    # phần tử 0..7 ứng với điểm 1..8

var level_index: int = 0
var run_id: int = 0
var wave_speed_mult: float = 1.0
var distortion: float = 0.0
var orbs_left: int = 0
var _breathing: bool = false
# Chỉ số màn mở đầu mỗi arc: em bé, cấp 2, người lớn, người đàn ông.
# Muốn đoạn sau cutscene (màn 16) là điểm quay về riêng thì thêm 15 vào.
var arc_starts: Array = [0, 3, 8, 22]

var peak_timer: float = 0.0
var _last_touch_time: float = -10.0
var _restarting: bool = false
var _cover: ColorRect
var _orb_nodes: Array[Orb] = []

func _ready() -> void:
	screen = get_viewport_rect().size
	# Khung chơi nằm giữa màn hình
	clip_rect = Rect2((screen - frame_size) / 2.0, frame_size)
	RenderingServer.set_default_clear_color(Color("f5ecd7"))   # màu kem sữa
	_build_screen_filter()
	_load_sfx()

	_build_frame()
	_build_points()

	# Goal nằm ở hai bên khung, giữa chiều cao
	var cy := clip_rect.get_center().y
	goal_left.position = Vector2(clip_rect.position.x + goal_inset, cy)
	goal_right.position = Vector2(clip_rect.end.x - goal_inset, cy)
	goal_left.body_entered.connect(_on_goal_entered.bind(goal_left))
	goal_right.body_entered.connect(_on_goal_entered.bind(goal_right))

	# Đặt người chơi vào giữa khung
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		player.global_position = _player_start_pos(0)

	story = Story.new()
	story.portrait = portrait
	story.game_alpha = portrait_game_alpha
	add_child(story)

	start_level(0)

func _player_start_pos(index: int) -> Vector2:
	if index % 2 == 0:
		return goal_left.global_position
	return goal_right.global_position
	
func _load_sfx() -> void:
	_sfx_orb = _try_load_audio(sfx_orb_path)
	_sfx_goal = _try_load_audio(sfx_goal_path)
	_sfx_hit = _try_load_audio(sfx_hit_path)

func _try_load_audio(path: String) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		push_warning("Không tìm thấy âm thanh: " + path)
		return null
	return load(path) as AudioStream

# Mỗi lần phát dùng một player riêng, phát xong tự xóa, nên không bị cắt tiếng
func _play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = sfx_volume_db
	p.pitch_scale = pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

# Bốn bức tường bao quanh khung (nằm ngoài vùng chơi) và viền trắng
func _build_frame() -> void:
	frame = Node2D.new()
	add_child(frame)

	var t := wall_thickness
	var r := clip_rect
	var walls := [
		[Vector2(r.get_center().x, r.position.y - t * 0.5), Vector2(r.size.x + 2.0 * t, t)],  # trên
		[Vector2(r.get_center().x, r.end.y + t * 0.5), Vector2(r.size.x + 2.0 * t, t)],       # dưới
		[Vector2(r.position.x - t * 0.5, r.get_center().y), Vector2(t, r.size.y)],            # trái
		[Vector2(r.end.x + t * 0.5, r.get_center().y), Vector2(t, r.size.y)],                 # phải
	]
	for w in walls:
		var body := StaticBody2D.new()
		body.position = w[0]
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = w[1]
		shape.shape = rect
		body.add_child(shape)
		frame.add_child(body)

	# Hai đường kim sát ngoài vùng chơi: nửa độ dày nằm ngoài mép
	var half := line_thickness * 0.5
	frame.add_child(_make_needle(clip_rect.position.y - half))
	frame.add_child(_make_needle(clip_rect.end.y + half))
	
# Nửa độ dày của đường kim tại vị trí t (0 đến 1 dọc theo chiều dài)
func _needle_half(t: float) -> float:
	return line_thickness * 0.5 * pow(1.0 - absf(2.0 * t - 1.0), taper_power)

# Đường kim nằm ngang tại toạ độ y: nhọn hai đầu, dày nhất ở giữa
func _make_needle(y: float) -> Polygon2D:
	var x0 := clip_rect.position.x - line_overhang
	var x1 := clip_rect.end.x + line_overhang
	var steps := 48
	var pts := PackedVector2Array()
	# Cạnh trên từ trái sang phải
	for i in range(steps + 1):
		var t := float(i) / steps
		pts.append(Vector2(lerpf(x0, x1, t), y - _needle_half(t)))
	# Cạnh dưới quay về từ phải sang trái (bỏ hai đầu mút để không trùng điểm)
	for i in range(steps - 1, 0, -1):
		var t := float(i) / steps
		pts.append(Vector2(lerpf(x0, x1, t), y + _needle_half(t)))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = frame_color
	poly.antialiased = true
	return poly

# Hiện hoặc ẩn khung (ẩn trong lúc kể chuyện, hiện mờ dần khi bắt đầu chơi)
func _show_frame(is_shown: bool) -> void:
	frame.visible = is_shown
	if is_shown:
		frame.modulate.a = 0.0
		create_tween().tween_property(frame, "modulate:a", 1.0, 0.5)
	queue_redraw()

# 8 điểm phát sóng nằm trên viền khung, cách đều nhau
func _build_points() -> void:
	emit_points.clear()
	for y in [clip_rect.position.y, clip_rect.end.y]:
		for col in range(4):
			emit_points.append(Vector2(
				clip_rect.position.x + clip_rect.size.x * col / 3.0, y))
	queue_redraw()

func _draw() -> void:
	if not show_points or frame == null or not frame.visible:
		return
	var font := ThemeDB.fallback_font
	var center := clip_rect.get_center()
	for i in range(emit_points.size()):
		var p := emit_points[i]
		draw_circle(p, 4.0, Color(1, 1, 1, 0.4))
		var label_offset := Vector2(
			10.0 if p.x < center.x else -22.0,
			20.0 if p.y < center.y else -8.0
		)
		draw_string(font, p + label_offset, str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.4))

func _process(delta: float) -> void:
	wave_speed_mult = move_toward(wave_speed_mult, 1.0, speed_recovery * delta)
	if peak_timer > 0.0:
		peak_timer -= delta
	else:
		distortion = move_toward(distortion, 0.0, distortion_recovery * delta)
	for r in get_tree().get_nodes_in_group("ripples"):
		r.speed_scale = wave_speed_mult
		r.distortion = distortion
	_update_breathing()

# Giữ nút thì ảnh nền đổi sang ảnh thở, thả ra thì về ảnh thường
func _update_breathing() -> void:
	if story == null or story.busy:
		return
	var want := InputMap.has_action(breath_action) and Input.is_action_pressed(breath_action)
	if want != _breathing:
		_breathing = want
		story.set_breathing(want)

func _on_ripple_touched() -> void:
	if _restarting:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_touch_time < touch_cooldown:
		return
	_last_touch_time = now
	_play_sfx(_sfx_hit, 1.0 - distortion * 0.3)
	# Đang ở đỉnh (zigzag) mà vẫn đụng thêm: quay về đầu arc
	if distortion >= 1.0:
		_restart_arc()
		return
	wave_speed_mult = minf(wave_speed_mult * touch_speed_gain, max_speed_mult)
	distortion = minf(distortion + distortion_per_hit, 1.0)
	if distortion >= 1.0:
		peak_timer = peak_hold

# Màn có chỉ số chẵn (màn 1, 3, ...) đi trái sang phải; màn lẻ đi ngược lại
func _active_goal(index: int) -> Goal:
	return goal_right if index % 2 == 0 else goal_left

func start_level(index: int, skip_story: bool = false) -> void:
	level_index = index
	run_id += 1
	wave_speed_mult = 1.0
	distortion = 0.0
	peak_timer = 0.0
	_play_arc_music(index)
	# Goal ẩn cho tới khi nhặt hết bóng
	goal_left.set_active(false)
	goal_right.set_active(false)
	if story_data.has(index) and not skip_story:
		await _play_story(story_data[index])
	_maybe_chatter(index)
	_spawn_orbs(orb_counts[index] if index < orb_counts.size() else 3)
	for pattern in levels[index]:
		_run_pattern(pattern, run_id)

# --- Cốt truyện ---
func _play_story(entry: Dictionary) -> void:
	_show_frame(false)
	story.busy = true
	story.set_breathing(false)
	_breathing = false
	# Giữ người chơi đứng yên trong lúc kể chuyện
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	if entry.has("custom"):
		await _play_custom(entry["custom"])
	else:
		await story.play(entry)
	if player != null:
		player.process_mode = Node.PROCESS_MODE_INHERIT
	story.busy = false
	_show_frame(true)

# Chỗ để bạn chèn các cutscene tự làm
func _play_custom(cutscene_name: String) -> void:
	match cutscene_name:
		"cutscene_4":
			# TODO: thay bằng cutscene của bạn. Tạm thời chỉ chờ 1 giây.
			await get_tree().create_timer(1.0).timeout
		_:
			pass

func _on_goal_entered(body: Node2D, goal: Goal) -> void:
	if not body.is_in_group("player") or goal != _active_goal(level_index) or orbs_left > 0:
		return
	run_id += 1
	get_tree().call_group("ripples", "queue_free")
	_play_sfx(_sfx_goal)
	goal.burst()
	goal.set_active(false)
	if level_index + 1 >= levels.size():
		await get_tree().create_timer(1.2).timeout
		await story.show_end(ending_text)
		return
	await get_tree().create_timer(1.2).timeout
	start_level(level_index + 1)

func _run_pattern(p: Dictionary, id: int) -> void:
	await get_tree().create_timer(p.get("delay", 0.0)).timeout
	while id == run_id:
		var origins := _pattern_origins(p)
		for i in range(p.get("rings", 1)):
			if id != run_id:
				return
			for o in origins:
				_spawn_ripple(o, p)
			await get_tree().create_timer(p.get("interval", 1.0)).timeout
		await get_tree().create_timer(p.get("pause", 2.0)).timeout

func _pattern_origins(p: Dictionary) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for n in p.get("points", [randi_range(1, 8)]):
		result.append(emit_points[n - 1])
	return result

func _spawn_ripple(origin: Vector2, p: Dictionary) -> void:
	var r := Ripple.new()
	r.setup(p, origin, clip_rect, wave_speed_mult)
	r.distortion = distortion
	r.touched.connect(_on_ripple_touched)
	add_child(r)

# --- Bóng cần nhặt ---
func _spawn_orbs(count: int) -> void:
	orbs_left = count
	_orb_nodes.clear()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var avoid: Array[Vector2] = [goal_left.position, goal_right.position]
	if player != null:
		avoid.append(player.global_position)
	var placed: Array[Vector2] = []
	for i in range(count):
		var pos := _random_orb_position(placed, avoid)
		placed.append(pos)
		var orb := Orb.new()
		orb.position = pos
		orb.collected.connect(_on_orb_collected)
		add_child(orb)
		_orb_nodes.append(orb)

func _random_orb_position(placed: Array[Vector2], avoid: Array[Vector2]) -> Vector2:
	var area := clip_rect.grow(-orb_margin)
	var candidate := area.get_center()
	for attempt in range(60):
		candidate = Vector2(
			randf_range(area.position.x, area.end.x),
			randf_range(area.position.y, area.end.y)
		)
		var ok := true
		for q in placed:
			if candidate.distance_to(q) < orb_min_gap:
				ok = false
				break
		if ok:
			for q in avoid:
				if candidate.distance_to(q) < orb_avoid_gap:
					ok = false
					break
		if ok:
			return candidate
	return candidate

func _on_orb_collected(_orb: Orb) -> void:
	orbs_left -= 1
	_play_sfx(_sfx_orb, randf_range(0.95, 1.08))
	if orbs_left <= 0:
		_active_goal(level_index).set_active(true)
		
# Màn mở đầu của arc chứa màn index
func _arc_start(index: int) -> int:
	var start := 0
	for s in arc_starts:
		if s <= index:
			start = s
	return start

# Tối dần, dọn sạch, bắt đầu lại từ đầu arc, rồi sáng dần
func _restart_arc() -> void:
	if _restarting:
		return
	_restarting = true
	run_id += 1   # dừng mọi mẫu sóng đang lặp
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		player.process_mode = Node.PROCESS_MODE_DISABLED
	await _fade_cover(1.0, 0.5)

	get_tree().call_group("ripples", "queue_free")
	for o in _orb_nodes:
		if is_instance_valid(o):
			o.queue_free()
	_orb_nodes.clear()
	if player != null:
		player.global_position = _player_start_pos(_arc_start(level_index))
		if player.has_method("on_arc_restart"):
			player.on_arc_restart()   # chỗ để bạn hồi máu hoặc đặt lại trạng thái người chơi
		player.process_mode = Node.PROCESS_MODE_INHERIT

	start_level(_arc_start(level_index), true)
	await _fade_cover(0.0, 0.5)
	_restarting = false

func _fade_cover(alpha: float, time: float) -> void:
	if _cover == null:
		var cover_layer := CanvasLayer.new()
		cover_layer.layer = 30
		add_child(cover_layer)
		_cover = ColorRect.new()
		_cover.color = Color(0, 0, 0, 0)
		_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover_layer.add_child(_cover)
		_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(_cover, "color:a", alpha, time)
	await tween.finished
	
# Chọn bài phù hợp với màn index; cùng bài đang phát thì không làm gì
func _play_arc_music(index: int) -> void:
	var key := -1
	for k in arc_music.keys():
		if k <= index and k > key:
			key = k
	if key == _music_key:
		return
	_music_key = key

	# Bài cũ nhỏ dần rồi tự xóa
	if _music != null:
		var old := _music
		var t := old.create_tween()
		t.tween_property(old, "volume_db", -60.0, music_fade)
		t.tween_callback(old.queue_free)
		_music = null

	if key < 0:
		return
	var path: String = arc_music[key]
	if not ResourceLoader.exists(path):
		push_warning("Không tìm thấy nhạc: " + path)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = true   # ogg và mp3 lặp lại vô hạn

	_music = AudioStreamPlayer.new()
	_music.stream = stream
	_music.volume_db = -60.0
	add_child(_music)
	_music.play()
	_music.create_tween().tween_property(_music, "volume_db", music_volume_db, music_fade)

# Dùng khi hết game nếu muốn nhạc tắt dần
func _fade_out_music(time: float = 2.0) -> void:
	if _music == null:
		return
	var m := _music
	_music = null
	_music_key = -2
	var t := m.create_tween()
	t.tween_property(m, "volume_db", -60.0, time)
	t.tween_callback(m.queue_free)

func _build_screen_filter() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100   # nằm trên cả cốt truyện và màn che
	add_child(layer)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://Assets/crt.gdshader")
	rect.material = mat
	layer.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
func _maybe_chatter(index: int) -> void:
	if story == null:
		return
	if _arc_start(index) != 8 or index == 8:
		return
	if (index - 8) % 2 != 0 or story_data.has(index):
		return
	var list: Array
	var n: int
	if index < adult_custom_index:
		list = adult_chatter_early
		n = floori((index - 10) / 2.0)
	else:
		list = adult_chatter_late
		n = floori((index - (adult_custom_index + 1)) / 2.0)
	if list.is_empty():
		return
	story.pop(list[n % list.size()])
