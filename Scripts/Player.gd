extends Character
# 玩家-协调者（第一阶段完成）
#
# 职责：
# - 作为全局玩家引用（GGameMgr.player）
# - 所有其他功能都继承自Character
#
# 说明：
# 此文件在第一阶段重构后已大幅简化
# 所有通用逻辑已移到Character.gd
# Player只需做玩家特化的初始化

func _ready_subclass() -> void:
	GGameMgr.player = self
	input_mgr = $InputMgr
