extends CharacterBody2D

@export var health: int = 6
@export var speed: float = 150.0
@export var stealth_duration: float = 0.5   # tàng hình tối đa mỗi lần bấm
@export var cooldown_duration: float = 0.0  # thời gian hồi sau khi kết thúc

var invincible: bool = false
var stealth_time_left: float = 0.0
var cooldown_left: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("left", "right", "up", "down")
	velocity = dir * speed
	move_and_slide()

	_handle_stealth(delta)

func _handle_stealth(delta: float) -> void:
	if cooldown_left > 0.0:
		cooldown_left = max(cooldown_left - delta, 0.0)

	if invincible:
		stealth_time_left -= delta
		# Kết thúc khi thả nút hoặc hết 0.5s
		if not Input.is_action_pressed("Action") or stealth_time_left <= 0.0:
			_end_stealth()
	elif cooldown_left <= 0.0 and Input.is_action_just_pressed("Action"):
		invincible = true
		stealth_time_left = stealth_duration

	sprite.modulate.a = 0.25 if invincible else 1.0

func _end_stealth() -> void:
	invincible = false
	var used := stealth_duration - stealth_time_left
	cooldown_left = cooldown_duration * (used / stealth_duration)

func take_damage(amount: int) -> void:
	if invincible:
		return
	health = health - 1
