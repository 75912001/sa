# Character.gd - 通用角色基类
#
# 职责：
# - 管理所有组件的初始化
# - 提供通用的物理和动画更新循环
# - 支持Player、NPC、Enemy等多种角色类型
#
# 使用方式：
# - Player 继承 Character，只需简单初始化
# - NPC 继承 Character，使用 AIInputMgr 代替 InputMgr
# - Enemy 继承 Character，附加AI控制器

class_name Character extends CharacterBody3D

# --- 导出属性 ---
@export var character_id: int = 1000001

# --- 配置 ---
var cfg_character_entry: CfgCharacterMgr.CfgCharacterEntry

func _ready() -> void:
	print("Character._ready() called - character_id: %d" % character_id)
	_ready_subclass()

func _physics_process(delta: float) -> void:
	move_and_slide()

func _ready_subclass() -> void:
	# 子类覆写这个方法，用于子类特化初始化
	pass
