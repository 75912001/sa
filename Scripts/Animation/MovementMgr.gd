# 移动-管理器
class_name MovementMgr

extends Node

# --- 变量 ---
var animation_mgr: AnimationMgr
var _movement_locks: Dictionary = {} # 使用字典作为 Set 使用, 防止重复添加同名锁

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if is_locked():
		animation_mgr.character_body.velocity.x = 0
		animation_mgr.character_body.velocity.z = 0
		return

	var input_direction = animation_mgr.input_mgr.get_move_vector()
	var direction = Vector3(input_direction.x, 0, input_direction.y).normalized()
	# 旋转45度适配等距摄像机
	direction = direction.rotated(Vector3.UP, deg_to_rad(45))
	if direction:
		animation_mgr.character_body.velocity.x = direction.x * GGameMgr.player.cfg_character_entry.speed
		animation_mgr.character_body.velocity.z = direction.z * GGameMgr.player.cfg_character_entry.speed
		# 平滑转身
		var target_rotation = atan2(direction.x, direction.z)
		animation_mgr.character_body.rotation.y = lerp_angle(animation_mgr.character_body.rotation.y, target_rotation, GGameMgr.player.cfg_character_entry.rotation_speed * delta)
	else:
		# 处理停止时的逻辑
		animation_mgr.character_body.velocity.x = move_toward(animation_mgr.character_body.velocity.x, 0, GGameMgr.player.cfg_character_entry.speed)
		animation_mgr.character_body.velocity.z = move_toward(animation_mgr.character_body.velocity.z, 0, GGameMgr.player.cfg_character_entry.speed)

	animation_mgr.character_body.move_and_slide()

# 是否在移动
func is_moving() -> bool:
	return _get_horizontal_speed() > 0.1

# 获取水平速度
func _get_horizontal_speed() -> float:
	return Vector2(animation_mgr.character_body.velocity.x, animation_mgr.character_body.velocity.z).length()

# 加锁
func add_lock(source: String) -> void:
	_movement_locks[source] = true

# 解锁
func remove_lock(source: String) -> void:
	if _movement_locks.has(source):
		_movement_locks.erase(source)

# 检查是否被锁
func is_locked() -> bool:
	return not _movement_locks.is_empty()
