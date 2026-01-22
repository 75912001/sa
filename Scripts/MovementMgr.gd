# 移动-管理器
class_name MovementMgr

extends Node

@export var input_mgr: InputMgr

# --- 变量 ---
var character_body: CharacterBody3D
var _is_locked: bool = false  # 锁定移动（如跳跃蓄力时）

func _ready() -> void:
	character_body = get_parent() as CharacterBody3D

func _physics_process(delta: float) -> void:
	if _is_locked:
		character_body.velocity.x = 0
		character_body.velocity.z = 0
		return

	var input_direction = input_mgr.get_move_vector()
	var direction = Vector3(input_direction.x, 0, input_direction.y).normalized()
	# 旋转45度适配等距摄像机
	direction = direction.rotated(Vector3.UP, deg_to_rad(45))
	if direction:
		character_body.velocity.x = direction.x * GGameMgr.player.cfg_character_entry.speed
		character_body.velocity.z = direction.z * GGameMgr.player.cfg_character_entry.speed
		# 平滑转身
		var target_rotation = atan2(direction.x, direction.z)
		character_body.rotation.y = lerp_angle(character_body.rotation.y, target_rotation, GGameMgr.player.cfg_character_entry.rotation_speed * delta)
	else:
		# 处理停止时的逻辑
		character_body.velocity.x = move_toward(character_body.velocity.x, 0, GGameMgr.player.cfg_character_entry.speed)
		character_body.velocity.z = move_toward(character_body.velocity.z, 0, GGameMgr.player.cfg_character_entry.speed)

	character_body.move_and_slide()

# 是否在移动
func is_moving() -> bool:
	return _get_horizontal_speed() > 0.1

# 锁定/解锁移动
func lock() -> void:
	_is_locked = true

func unlock() -> void:
	_is_locked = false
	
# 获取水平速度
func _get_horizontal_speed() -> float:
	return Vector2(character_body.velocity.x, character_body.velocity.z).length()
