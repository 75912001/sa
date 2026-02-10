# AI 类型定义
# 包含所有AI相关的枚举
# 注意: NPC 立场（Stance）定义在 Pb.NPCStance（Pb/Common.proto）中
# 注意: NPC 行为类型（BehaviorType）定义在 Pb.NPCBehaviorType（Pb/Common.proto）中

class_name AITypes extends RefCounted

# AI 状态机中的状态（运行时状态，不同于Pb.NPCBehaviorType）
enum AIState {
	IDLE,      # 待机状态
	WANDER,    # 游荡状态
	PATROL,    # 巡逻状态
	CHASE,     # 追击玩家状态
	ATTACK     # 攻击玩家状态
}
