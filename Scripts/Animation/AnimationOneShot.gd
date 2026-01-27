class_name AnimationOneShot
extends Node

# --- 信号 ---
signal action_started(action_name: String)
signal action_finished(action_name: String) # 当 OneShot 播放完毕（或被打断）时发出

# --- 内部变量 ---
var _current_action: String = ""

# --- 引用（在 Player.gd 中设置）---
var animation_mgr: AnimationMgr

# --- 路径常量 (必须与你的 AnimationTree 节点名一致) ---
const PATH_REQUEST = "parameters/Action_OneShot/request"
const PATH_ACTIVE = "parameters/Action_OneShot/active"
# 动作路由节点 (Transition)
const PATH_TRANSITION = "parameters/Action_Type/transition_request"

# 播放指定动作
func play(action_name: String) -> void:
	_current_action = action_name
	# 设置路由 (Transition)
	animation_mgr.animation_tree.set(PATH_TRANSITION, action_name)
	# 触发 OneShot
	animation_mgr.animation_tree.set(PATH_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	action_started.emit(action_name)
	# 开始异步监控
	_monitor_loop()

# 强制停止
func stop() -> void:
	# 或者使用 REQUEST_ABORT (生硬切断，通常不推荐，除非是受击瞬间切入受击状态)
	# animation_mgr.animation_tree.set(PATH_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	animation_mgr.animation_tree.set(PATH_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	# 注意：停止后 active 会变 false，monitor_loop 会自动结束并触发 finished

# 异步监控动画状态
func _monitor_loop() -> void:
	# 等待一帧，确保 AnimationTree 更新 active 状态
	await get_tree().process_frame
	
	# 只要 OneShot 是激活状态，就一直等待
	while animation_mgr.animation_tree.get(PATH_ACTIVE):
		await get_tree().process_frame
	
	# 循环结束，说明动画播完了
	var last_action = _current_action
	_current_action = ""
	action_finished.emit(last_action)
