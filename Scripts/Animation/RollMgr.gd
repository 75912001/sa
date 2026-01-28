# 翻滚-管理器
class_name RollMgr
extends Node

# --- 依赖 ---
var animation_mgr: AnimationMgr

func setup() -> void:
	# 监听动画结束
	animation_mgr.one_shot.action_finished.connect(_on_roll_finished)

func _process(_delta: float) -> void:
	if animation_mgr.input_mgr.get_roll_pressed():
		roll()

func roll() -> void:
	# 检查是否可以翻滚
	if not animation_mgr.can_roll():
		return
	animation_mgr.lock_mgr.add_lock(LockMgr.ACT_ROLLING)
	animation_mgr.one_shot.play("roll")

func _on_roll_finished(action_name: String) -> void:
	# 只有结束的动作是 "roll" 时才处理
	if action_name == "roll":
		animation_mgr.lock_mgr.remove_lock(LockMgr.ACT_ROLLING)
