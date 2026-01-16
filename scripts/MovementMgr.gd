extends Node
# 移动-管理器
class_name MovementMgr

@export var speed: float = 4.0
@export var rotation_speed: float = 6.0

var body: CharacterBody3D
var is_locked: bool = false  # 锁定移动（如跳跃蓄力时）

func _ready() -> void:
	body = get_parent() as CharacterBody3D

# 获取输入方向（已旋转45度适配摄像机）
func get_input_direction() -> Vector3:
	var wasd_x := 0.0
	var wasd_y := 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		wasd_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		wasd_x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		wasd_y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		wasd_y += 1.0

	var direction := Vector3(wasd_x, 0, wasd_y).normalized()
	# 旋转45度适配等距摄像机
	return direction.rotated(Vector3.UP, deg_to_rad(45))

# 处理移动（应用速度和转身）
func handle_movement(delta: float) -> void:
	var direction := get_input_direction()

	if is_locked:
		body.velocity.x = 0
		body.velocity.z = 0
		return

	if direction:
		body.velocity.x = direction.x * speed
		body.velocity.z = direction.z * speed
		# 平滑转身
		var target_rotation = atan2(direction.x, direction.z)
		body.rotation.y = lerp_angle(body.rotation.y, target_rotation, rotation_speed * delta)
	else:
		body.velocity.x = move_toward(body.velocity.x, 0, speed)
		body.velocity.z = move_toward(body.velocity.z, 0, speed)

# 获取水平速度
func get_horizontal_speed() -> float:
	return Vector2(body.velocity.x, body.velocity.z).length()

# 是否在移动
func is_moving() -> bool:
	return get_horizontal_speed() > 0.1

# 锁定/解锁移动
func lock() -> void:
	is_locked = true

func unlock() -> void:
	is_locked = false
