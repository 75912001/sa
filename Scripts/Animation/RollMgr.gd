# 翻滚-管理器
class_name RollMgr
extends Node

# --- 依赖 ---
var animation_mgr: AnimationMgr

func setup() -> void:
	animation_mgr.one_shot.action_finished.connect(_on_roll_finished)

func _process(_delta: float) -> void:
	if !animation_mgr.lock_mgr.can_act(LockMgr.ACT_ROLLING):
		return
	if animation_mgr.input_mgr.get_roll_pressed():
		roll()

func roll() -> void:
	animation_mgr.lock_mgr.add_lock(LockMgr.ACT_ROLLING)
	animation_mgr.one_shot.play("roll")

func _on_roll_finished(action_name: String) -> void:
	if action_name == "roll":
		animation_mgr.lock_mgr.remove_lock(LockMgr.ACT_ROLLING)
