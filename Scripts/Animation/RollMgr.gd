# 翻滚-管理器
class_name RollMgr
extends Node

# --- 依赖 ---
var animation_mgr: AnimationMgr

# --- 状态 ---
enum State {
	IDLE, # 空闲
	ROLLING, # 翻滚中
}

# --- 变量 ---
var _state: State = State.IDLE

# --- 核心配置：对应 Tscn 中的参数路径 ---
const PATH_MAIN_TRANSITION = "parameters/Action_Type/transition_request"
const PATH_ROLL_TRANSITION = "parameters/Action_Type_Roll/transition_request"
const PATH_ONESHOT_REQUEST = "parameters/Action_OneShot/request"

# --- 动作名称配置 ---
# 必须与 Action_Type_Roll 中的输入端口名完全一致
const ROLL_FWD = "roll_forward"
const ROLL_BACK = "roll_back"
const ROLL_LEFT = "roll_left"
const ROLL_RIGHT = "roll_right"

func setup() -> void:
	# 监听动画结束
	animation_mgr.one_shot.action_finished.connect(_on_roll_finished)

func _process(_delta: float) -> void:
	if _state == State.ROLLING:
		return

	if animation_mgr.input_mgr.get_roll_pressed():
		roll()

func roll() -> void:
	# 获取输入方向
	var dv = animation_mgr.input_mgr.get_move_vector()
	
	# 默认为后撤 (Backstep)
	var roll_dir_name = ROLL_BACK

	# 计算方向逻辑
	if dv.length_squared() > 0.1:
		if abs(dv.x) > abs(dv.y):
			# 横向为主
			roll_dir_name = ROLL_LEFT if dv.x < 0 else ROLL_RIGHT
		else:
			# 纵向为主
			roll_dir_name = ROLL_FWD if dv.y < 0 else ROLL_BACK
	
	_do_roll(roll_dir_name, dv)

func _do_roll(action_name: String, dir: Vector2) -> void:
	print("RollMgr: 执行动作 -> ", action_name)
	_state = State.ROLLING
	# 锁定移动
	animation_mgr.movement_mgr.add_lock("rolling")
	
	# 先设置二级路由 (具体方向)
	animation_mgr.animation_tree.set(PATH_ROLL_TRANSITION, action_name)
	# 设置一级路由 (告诉系统我要翻滚，而不是攻击)
	# 注意：这里的值 "roll" 必须对应 Action_Type 节点里那个连接 Action_Type_Roll 的端口名
	animation_mgr.animation_tree.set(PATH_MAIN_TRANSITION, "roll")
	# 激发 OneShot
	animation_mgr.animation_tree.set(PATH_ONESHOT_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_roll_finished(_anim_name: String) -> void:
	# (更严谨的做法是判断 anim_name 是否属于翻滚类，但在 OneShot 结束回调里通常意味着复位)
	if _state == State.ROLLING:
		_state = State.IDLE
		animation_mgr.movement_mgr.remove_lock("rolling")
