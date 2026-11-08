class_name Sweep
extends Control

var center: Vector2 = Vector2.ZERO          # tâm trong tọa độ của chính Control này
var color: Color = Color(1.0, 0.45, 0.70)   # hồng
var thickness: float = 5.0
var radius: float = 0.0:
	set(value):
		radius = value
		queue_redraw()

func _draw() -> void:
	if radius <= 0.0:
		return
	draw_arc(center, radius, 0.0, TAU, 180, Color(color, 0.22), thickness * 4.0, true)
	draw_arc(center, radius, 0.0, TAU, 180, color, thickness, true)
