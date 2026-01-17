extends CharacterBody3D
# 玩家-协调者

# --- 组件引用 ---
@onready var movement_mgr: MovementMgr = $MovementMgr
@onready var jump_mgr: JumpMgr = $JumpMgr
@onready var animation_mgr: AnimationMgr = $AnimationMgr
@onready var weapon_mgr: WeaponMgr = $WeaponMgr
@onready var weapon_switch_mgr: WeaponSwitchMgr = $WeaponSwitchMgr

func _ready() -> void:
	_init_jump_mgr()
	_init_weapon_mgr()
	_init_weapon_switch_mgr()

func _physics_process(delta: float) -> void:
	movement_mgr.handle_input(delta)
	jump_mgr.handle_input()
	weapon_switch_mgr.handle_input()
	# 处理重力
	jump_mgr.handle_gravity(delta)
	# 移动
	move_and_slide()
	# 更新动画
	animation_mgr.update(
		movement_mgr.is_moving(),
		weapon_mgr.has_weapon(),
		jump_mgr.is_jumping(),
		jump_mgr.is_in_air()
	)

############################################################
# JumpMgr
############################################################
func _init_jump_mgr() -> void:
	jump_mgr.jump_started.connect(_on_jump_started)
	jump_mgr.jump_executed.connect(_on_jump_executed)
	jump_mgr.jump_landed.connect(_on_jump_landed)

func _on_jump_started() -> void:
	movement_mgr.lock()
	animation_mgr.play("Unarmed_Jump")

func _on_jump_executed() -> void:
	movement_mgr.unlock()

func _on_jump_landed() -> void:
	movement_mgr.unlock()

############################################################
# WeaponMgr
############################################################
func _init_weapon_mgr() -> void:
	weapon_mgr.weapon_equipped.connect(_on_weapon_equipped)
	weapon_mgr.weapon_unequipped.connect(_on_weapon_unequipped)

func _on_weapon_equipped(_weapon_name: String) -> void:
	prints("weapon equipped:", _weapon_name)

func _on_weapon_unequipped() -> void:
	prints("weapon unequipped")

############################################################
# WeaponSwitchMgr
############################################################
func _init_weapon_switch_mgr() -> void:
	# 设置引用
	weapon_switch_mgr.animation_mgr = animation_mgr
	weapon_switch_mgr.weapon_mgr = weapon_mgr
	weapon_switch_mgr.movement_mgr = movement_mgr
	# 连接信号
	weapon_switch_mgr.switch_started.connect(_on_weapon_switch_started)
	weapon_switch_mgr.switch_completed.connect(_on_weapon_switch_completed)

func _on_weapon_switch_started() -> void:
	prints("weapon switch started")

func _on_weapon_switch_completed() -> void:
	prints("weapon switch completed")
