# Character.gd - 通用角色基类（第一阶段完成）
#
# 职责：
# 1. 管理所有组件的初始化（weapon、animation、movement等）
# 2. 提供通用的物理更新循环（move_and_slide）
# 3. 提供通用的动画更新循环（update_lower/upper_animation）
# 4. 支持多种角色类型：Player、NPC、Enemy等
#
# 架构说明：
# - Player 继承 Character，只需在 _ready_subclass() 做Player特化初始化
# - NPC 继承 Character，使用 AIInputMgr 代替 InputMgr
# - Enemy 继承 NPC，附加具体的AI行为
#
# 复用情况：
# ✓ 所有动画系统完全复用
# ✓ 所有移动系统完全复用
# ✓ 所有武器系统完全复用
# ✓ 所有攻击系统完全复用
# ✓ 所有翻滚系统完全复用
# ✓ 代码复用率 ~95%
#
# 下一步计划：
# - 步骤7-11：创建输入接口（IInputProvider、AIInputMgr）
# - 步骤12-16：创建NPC基类
# - 步骤17-25：实现AI逻辑

class_name Character extends CharacterBody3D

# --- 导出属性 ---
@export var character_id: int = 1000001

# --- 组件引用 ---
@onready var input_mgr: Node = $InputMgr
@onready var weapon_mgr: WeaponMgr = $WeaponMgr
@onready var animation_mgr: AnimationMgr = $AnimationMgr
@onready var movement_mgr: MovementMgr = $MovementMgr
@onready var weapon_switch_mgr: WeaponSwitchMgr = $WeaponSwitchMgr
@onready var attack_mgr: AttackMgr = $AttackMgr
@onready var roll_mgr: RollMgr = $RollMgr

# --- 配置 ---
var cfg_character_entry: CfgCharacterMgr.CfgCharacterEntry

func _ready() -> void:
	print("Character._ready() called - character_id: %d" % character_id)

	# 加载配置
	cfg_character_entry = GCfgMgr.cfg_character_mgr.get_character(character_id)
	assert(cfg_character_entry != null, "角色配置不存在: %d" % character_id)

	# 初始化所有管理器
	_init_weapon_mgr()
	_init_weapon_switch_mgr()
	_init_attack_mgr()
	_init_movement_mgr()
	_init_roll_mgr()
	_init_animation_mgr()

	# 子类特化初始化
	_ready_subclass()

func _physics_process(delta: float) -> void:
	move_and_slide()
	# 更新动画
	animation_mgr.update_lower_animation()
	animation_mgr.update_upper_animation()

func _ready_subclass() -> void:
	# 子类覆写这个方法，用于子类特化初始化
	pass

############################################################
# WeaponMgr
############################################################
func _init_weapon_mgr() -> void:
	weapon_mgr.weapon_equipped.connect(_on_weapon_equipped)
	weapon_mgr.weapon_unequipped.connect(_on_weapon_unequipped)
	# 根据存档初始化武器
	var right_hand_weapon_uuid = GPlayerData.get_right_hand_weapon_uuid()
	if right_hand_weapon_uuid != 0:
		weapon_mgr.equip_weapon_by_uuid(right_hand_weapon_uuid)

func _on_weapon_equipped(weapon_uuid: int) -> void:
	var cfg = GPlayerData.get_weapon_cfg_by_uuid(weapon_uuid)
	prints("weapon equipped: UUID=%d, Name=%s" % [weapon_uuid, cfg.name if cfg else "unknown"])

func _on_weapon_unequipped() -> void:
	prints("weapon unequipped")

############################################################
# WeaponSwitchMgr
############################################################
func _init_weapon_switch_mgr() -> void:
	# 设置引用
	weapon_switch_mgr.animation_mgr = animation_mgr
	weapon_switch_mgr.weapon_mgr = weapon_mgr
	# 连接信号
	weapon_switch_mgr.switch_started.connect(_on_weapon_switch_started)
	weapon_switch_mgr.switch_finished.connect(_on_weapon_switch_finished)

func _on_weapon_switch_started() -> void:
	pass

func _on_weapon_switch_finished() -> void:
	pass

############################################################
# MovementMgr
############################################################
func _init_movement_mgr() -> void:
	movement_mgr.animation_mgr = animation_mgr

############################################################
# AttackMgr
############################################################
func _init_attack_mgr() -> void:
	attack_mgr.animation_mgr = animation_mgr
	# 连接信号
	attack_mgr.attack_started.connect(_on_attack_started)
	attack_mgr.attack_finished.connect(_on_attack_finished)
	attack_mgr.setup()

func _on_attack_started() -> void:
	pass

func _on_attack_finished() -> void:
	pass

############################################################
# RollMgr
############################################################
func _init_roll_mgr() -> void:
	# 设置引用
	roll_mgr.animation_mgr = animation_mgr
	roll_mgr.setup()

############################################################
# AnimationMgr
############################################################
func _init_animation_mgr() -> void:
	# 设置引用
	animation_mgr.input_mgr = input_mgr
	animation_mgr.movement_mgr = movement_mgr
	animation_mgr.weapon_switch_mgr = weapon_switch_mgr
	animation_mgr.attack_mgr = attack_mgr
	animation_mgr.roll_mgr = roll_mgr
