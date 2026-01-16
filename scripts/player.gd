extends CharacterBody3D
# 玩家-协调者

const JUMP_VELOCITY = 2.9 # 跳跃初速度
const JUMP_SQUAT_TIME = 0.8 # 下蹲蓄力时间（秒）

# 组件引用
@onready var movement_mgr: MovementMgr = $MovementMgr
@onready var animation_mgr: AnimationMgr = $AnimationMgr
@onready var weapon_mgr: WeaponMgr = $WeaponMgr

# 跳跃状态
var is_jumping := false
var jump_requested := false

func _ready() -> void:
	_init_weapon_mgr()

func _physics_process(delta: float) -> void:
	# 1. 处理输入
	movement_mgr.handle_input(delta)
	_handle_jump_input()
	weapon_mgr.handle_input()

	# 2. 处理重力
	_handle_gravity(delta)

	# 3. 移动
	move_and_slide()

	# 4. 更新动画
	animation_mgr.update(
		movement_mgr.is_moving(),
		weapon_mgr.has_weapon(),
		jump_requested or is_jumping,
		not is_on_floor()
	)

func _handle_jump_input() -> void:
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor() and not jump_requested and not is_jumping:
		jump_requested = true
		movement_mgr.lock()  # 锁定移动
		animation_mgr.play("Unarmed_Jump")

		# 等待蓄力后跳跃
		await get_tree().create_timer(JUMP_SQUAT_TIME).timeout
		if jump_requested:
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			jump_requested = false
			movement_mgr.unlock()  # 解锁移动

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if is_jumping:
			is_jumping = false
			jump_requested = false
			movement_mgr.unlock()

############################################################
# WeaponMgr 初始化和信号
############################################################
func _init_weapon_mgr() -> void:
	weapon_mgr.weapon_equipped.connect(_on_weapon_equipped)
	weapon_mgr.weapon_unequipped.connect(_on_weapon_unequipped)

func _on_weapon_equipped(_weapon_name: String) -> void:
	prints("weapon equipped:", _weapon_name)

func _on_weapon_unequipped() -> void:
	prints("weapon unequipped")
