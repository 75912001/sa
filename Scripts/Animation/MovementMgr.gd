# 移动-管理器
class_name MovementMgr

extends Node

# --- 依赖 ---
var character: Character

func _physics_process(delta: float) -> void:
	if !character.animation_mgr.lock_mgr.can_act(LockMgr.ACT_MOVE):
		character.velocity.x = 0
		character.velocity.z = 0
		if character.animation_mgr.lock_mgr.has_lock(LockMgr.ACT_ROLLING): # 翻滚中
			character.velocity = character.roll_mgr.roll_direction * character.roll_mgr.roll_speed
			character.animation_mgr.character_body.move_and_slide()
			return
		return

	var input_direction = character.input_mgr.get_move_vector()
	var direction = Vector3(input_direction.x, 0, input_direction.y).normalized()
	# 旋转45度适配等距摄像机
	direction = direction.rotated(Vector3.UP, deg_to_rad(45))
	if direction:
		character.velocity.x = direction.x * character.cfg_character_entry.speed
		character.velocity.z = direction.z * character.cfg_character_entry.speed
		# 平滑转身
		var target_rotation = atan2(direction.x, direction.z)
		character.rotation.y = lerp_angle(character.rotation.y, target_rotation, character.cfg_character_entry.rotation_speed * delta)
	else:
		# 处理停止时的逻辑
		character.velocity.x = move_toward(character.velocity.x, 0, character.cfg_character_entry.speed)
		character.velocity.z = move_toward(character.velocity.z, 0, character.cfg_character_entry.speed)

	character.move_and_slide()

func setup(_character: Character) -> void:
	character = _character
	return

# 是否在移动
func is_moving() -> bool:
	return _get_horizontal_speed() > 0.1

# 获取水平速度
func _get_horizontal_speed() -> float:
	return Vector2(character.animation_mgr.character_body.velocity.x, character.animation_mgr.character_body.velocity.z).length()
