extends CharacterBody3D
# 玩家-协调者

# --- 组件引用 ---
@onready var movement_mgr: MovementMgr = $MovementMgr
@onready var jump_mgr: JumpMgr = $JumpMgr
@onready var animation_mgr: AnimationMgr = $AnimationMgr
@onready var weapon_mgr: WeaponMgr = $WeaponMgr

func _ready() -> void:
	_init_jump_mgr()
	_init_weapon_mgr()

func _physics_process(delta: float) -> void:
	movement_mgr.handle_input(delta)
	jump_mgr.handle_input()
	weapon_mgr.handle_input()
	# 处理重力
	jump_mgr.handle_gravity(delta)
	# 移动
	move_and_slide()
	# 更新动画
	animation_mgr.update(
		movement_mgr.is_moving(),
		weapon_mgr.has_weapon(),
		jump_mgr.is_jumping(),
		jump_mgr.is_in_air()  # 物理检查，包括跳跃和掉落
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
