# 翻滚-管理器
class_name RollMgr
extends Node

# --- 依赖 ---
var character: Character

# --- 变量 ---
var roll_direction: Vector3 # 翻滚方向
var roll_speed: float # 翻滚速度

func _process(_delta: float) -> void:
	if !character.animation_mgr.lock_mgr.can_act(LockMgr.ACT_ROLLING):
		return
	if character.input_mgr.get_roll_pressed():
		roll()

func setup(_character: Character) -> void:
	character = _character
	character.animation_mgr.one_shot.action_finished.connect(_on_roll_finished)

func roll() -> void:
	# 获取当前输入方向（翻滚开始时）
	var input_dir = character.input_mgr.get_move_vector()
	# 如果没有输入，使用角色当前面朝方向
	if input_dir == Vector2.ZERO:
		# 根据当前 rotation.y 计算方向向量
		roll_direction = character.animation_mgr.character_body.transform.basis.z
	else:
		# 将输入方向转换为世界坐标，适配摄像机45度旋转
		roll_direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
		roll_direction = roll_direction.rotated(Vector3.UP, deg_to_rad(45))
	# 从配置获取翻滚参数
	roll_speed = GGameMgr.player.cfg_character_entry.roll_distance / GGameMgr.player.cfg_character_entry.roll_duration

	character.animation_mgr.lock_mgr.add_lock(LockMgr.ACT_ROLLING)
	character.animation_mgr.one_shot.play("roll")

func _on_roll_finished(action_name: String) -> void:
	if action_name == "roll":
		character.animation_mgr.lock_mgr.remove_lock(LockMgr.ACT_ROLLING)
