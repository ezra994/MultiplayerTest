extends CenterContainer

var test = Vector2(7,7)
@export var dot_rad: float = 1.0
@export var dot_color: Color = Color.WHEAT
var lines: Array


func _ready() -> void:
	if is_multiplayer_authority():
		
		lines = get_children()
		
		var i = 0
		for line in lines:
			if line is Line2D:
				match i:
					0:
						# Right line
						line.set_point_position(0, Vector2(test.x, 0.0))
						line.set_point_position(1, Vector2(0, test.y))
					1:
						# Down line
						line.set_point_position(0, Vector2(test.x, 0.0))
						line.set_point_position(1, Vector2(0.0, -test.y))
					2:
						# Left line
						line.set_point_position(0, Vector2(-test.x, 0.0))
						line.set_point_position(1, Vector2(0.0, -test.y))
					3:
						# Up line
						line.set_point_position(0, Vector2(-test.x, 0.0))
						line.set_point_position(1, Vector2(0.0, test.y))
				i += 1

var boo = true
func _input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		if event.is_action_pressed("hit"):
			test2(true)
		elif event.is_action_released("hit"):
			test2(false)
		
var duration: float = 1.5
var charge_tween: Tween
func test2(charging: bool) -> void:
	if charge_tween: charge_tween.kill()
	charge_tween = create_tween().set_parallel(true)
	if charging:
		for line in lines:
			if line is Line2D:
				charge_tween.tween_property(line, "rotation", deg_to_rad(360), duration)
				var target_scale = Vector2(0.3, 0.3)
				charge_tween.tween_property(line, "scale", target_scale, duration)
	else:
		for line in lines:
			if line is Line2D:
				charge_tween.tween_property(line, "rotation", deg_to_rad(-360), duration/5)
				var target_scale = Vector2(1.5, 1.5)
				charge_tween.tween_property(line, "scale", target_scale, duration/5)

func _draw() -> void:
	if is_multiplayer_authority():
		draw_circle(Vector2(0.0, 0.0), dot_rad, dot_color)
