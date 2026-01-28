extends CharacterBody3D
# 玩家-协调者

@export var character_id: int = 1000001

# --- 组件引用 ---
@onready var input_mgr: InputMgr = $InputMgr
@onready var weapon_mgr: WeaponMgr = $WeaponMgr
@onready var animation_mgr: AnimationMgr = $AnimationMgr
@onready var movement_mgr: MovementMgr = $MovementMgr
@onready var weapon_switch_mgr: WeaponSwitchMgr = $WeaponSwitchMgr
@onready var attack_mgr: AttackMgr = $AttackMgr
@onready var roll_mgr: RollMgr = $RollMgr

# 配置-角色-条目
var cfg_character_entry: CfgCharacterMgr.CfgCharacterEntry

func _ready() -> void:
	GGameMgr.player = self		
	cfg_character_entry = GCfgMgr.cfg_character_mgr.get_character(character_id)
	assert(cfg_character_entry != null, "角色配置不存在: %d" % character_id)
	_init_weapon_mgr()
	_init_weapon_switch_mgr()
	_init_attack_mgr()
	_init_movement_mgr()
	_init_roll_mgr()
	_init_aniamation_mgr()


func _physics_process(delta: float) -> void:
	weapon_switch_mgr.handle_input()
	move_and_slide()
	# 更新动画
	animation_mgr.update_lower_animation()
	animation_mgr.update_upper_animation()

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
	prints("weapon switch started")

func _on_weapon_switch_finished() -> void:
	prints("weapon switch finished")

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
	#prints("attack started")

func _on_attack_finished() -> void:
	pass
	#prints("attack finished")

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
func _init_aniamation_mgr() -> void:
	# 设置引用
	animation_mgr.input_mgr = input_mgr
	animation_mgr.movement_mgr = movement_mgr
	animation_mgr.weapon_switch_mgr = weapon_switch_mgr
	animation_mgr.attack_mgr = attack_mgr
