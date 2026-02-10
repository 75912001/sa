# NPCAIController.gd - NPC AI 控制器基类
#
# 职责：
# - 根据 NPC 的 behavior_type 和 behavior_params 控制行为
# - 每帧更新 AIInputMgr，设置移动方向
# - 支持 Idle 和 PatrolArea 行为

class_name NPCAIController extends Node

# 引用
var npc: NPC

# 出生点（用于巡逻）
var spawn_position: Vector3

# 巡逻相关
var patrol_target: Vector3  # 当前巡逻目标点
var patrol_timer: float = 0.0  # 到达目标后的等待时间
var patrol_wait_duration: float = 2.0  # 到达目标后等待的时间（秒）

# 初始化
func setup(_npc: NPC) -> void:
	npc = _npc
	spawn_position = npc.global_position

	# 根据行为类型初始化
	if npc.behavior_type == PbCommon.NPCBehaviorType.NPCBehaviorType_PatrolArea:
		_generate_new_patrol_target()

func _process(delta: float) -> void:
	# 根据行为类型执行对应逻辑
	match npc.behavior_type:
		PbCommon.NPCBehaviorType.NPCBehaviorType_Idle:
			_update_idle()
		PbCommon.NPCBehaviorType.NPCBehaviorType_PatrolArea:
			_update_patrol_area(delta)
		_:
			_update_idle()

# ============================================
# Idle 行为：原地不动
# ============================================
func _update_idle() -> void:
	npc.ai_input.set_move_direction(Vector2.ZERO)

# ============================================
# PatrolArea 行为：在出生点周围随机巡逻
# ============================================
func _update_patrol_area(delta: float) -> void:
	# 如果在等待，倒计时
	if patrol_timer > 0:
		patrol_timer -= delta
		npc.ai_input.set_move_direction(Vector2.ZERO)
		return

	# 计算到目标的距离（忽略Y轴）
	var current_pos = npc.global_position
	var target_pos = patrol_target
	var distance = Vector2(
		target_pos.x - current_pos.x,
		target_pos.z - current_pos.z
	).length()

	# 如果接近目标（1米内），生成新目标并等待
	if distance < 1.0:
		patrol_timer = patrol_wait_duration
		_generate_new_patrol_target()
		npc.ai_input.set_move_direction(Vector2.ZERO)
		return

	# 计算移动方向（2D平面）
	var direction_3d = (target_pos - current_pos).normalized()
	var direction_2d = Vector2(direction_3d.x, direction_3d.z)

	# 设置移动方向
	npc.ai_input.set_move_direction(direction_2d)

# 生成新的巡逻目标点
func _generate_new_patrol_target() -> void:
	var patrol_radius = npc.behavior_params.get("patrolRadius", 10.0)

	# 在出生点周围随机生成目标
	var random_angle = randf() * TAU  # 0 到 2π
	var random_distance = randf() * patrol_radius

	patrol_target = spawn_position + Vector3(
		cos(random_angle) * random_distance,
		0,
		sin(random_angle) * random_distance
	)
