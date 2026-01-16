extends Node
# 移动-管理器
class_name MovementMgr

# --- 配置 ---
@export var speed: float = 4.0
@export var rotation_speed: float = 6.0

# --- 变量 ---
var _body: CharacterBody3D
var _is_locked: bool = false  # 锁定移动（如跳跃蓄力时）

func _ready() -> void:
	_body = get_parent() as CharacterBody3D

# 处理-输入（应用速度和转身）
func handle_input(delta: float) -> void:
	var direction := _get_input_direction()

	if _is_locked:
		_body.velocity.x = 0
		_body.velocity.z = 0
		return

	if direction:
		_body.velocity.x = direction.x * speed
		_body.velocity.z = direction.z * speed
		# 平滑转身
		var target_rotation = atan2(direction.x, direction.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, target_rotation, rotation_speed * delta)
	else:
		_body.velocity.x = move_toward(_body.velocity.x, 0, speed)
		_body.velocity.z = move_toward(_body.velocity.z, 0, speed)

# 是否在移动
func is_moving() -> bool:
	return _get_horizontal_speed() > 0.1

# 锁定/解锁移动
func lock() -> void:
	_is_locked = true

func unlock() -> void:
	_is_locked = false
	
# 获取输入方向（已旋转45度适配摄像机）
func _get_input_direction() -> Vector3:
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

# 获取水平速度
func _get_horizontal_speed() -> float:
	return Vector2(_body.velocity.x, _body.velocity.z).length()
