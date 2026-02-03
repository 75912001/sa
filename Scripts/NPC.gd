# NPC.gd - NPC基类
#
# 所有NPC（敌人、友方NPC等）都继承这个类
#
# 职责：
# - 使用AIInputMgr代替InputMgr
# - 支持AI控制器
# - 继承Character的所有功能
#
# 优点：
# ✓ 所有NPC动作完全复用Player
# ✓ AI通过设置AIInputMgr来控制角色
# ✓ 代码极其简洁（< 30行）

class_name NPC extends Character

# --- NPC唯一标识 ---
var uuid: int = 0

# --- 待装配的装备（NPCMgr设置） ---
var pending_weapon_id: int = 0
var pending_armor_ids: Array[int] = []

# --- AI控制器（由子类设置） ---
var ai_controller #: NPCAIController

func _ready_subclass() -> void:
	input_mgr = $AIInputMgr
	# NPC不注册到GGameMgr.player

	# 装配装备（由NPCMgr设置的pending数据）
	_equip_pending_equipment()

	# 创建AI控制器
	_create_ai_controller()

# 装配待装配的装备（暂时不装配，后续完善）
func _equip_pending_equipment() -> void:
	# TODO: 实现NPC装备系统
	# 目前装备ID来自配置文件，不是存档UUID
	# 需要在WeaponMgr和ArmorMgr中添加equip_by_config_id()方法
	pass

func _create_ai_controller() -> void:
	# 由子类覆写此方法创建具体的AI
	pass

func _physics_process(delta: float) -> void:
	# AI控制器每帧更新决策
	if ai_controller:
		ai_controller.update(delta)

	# 调用父类逻辑（move_and_slide、动画更新等）
	super._physics_process(delta)
