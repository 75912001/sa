extends CharacterBody3D

const SPEED = 4.0 # 移动速度
const ROTATION_SPEED = 6.0 # 转身速度
const JUMP_VELOCITY = 2.9 # 跳跃初速度
const JUMP_SQUAT_TIME = 0.8 # 下蹲蓄力时间（秒） 空中时间 [0.8-1.4]

var is_jumping := false
var jump_requested := false # 是否请求了跳跃（等待蓄力）
var current_anim := "" # 当前动画，避免重复播放

func _ready() -> void:
	_ready_weapon_mgr()

func _physics_process(delta: float) -> void:
	_handle_movement_input(delta)
	_handle_jump_input()
	weapon_mgr.handle_input()
	_handle_gravity(delta)
	move_and_slide()
	_update_animation()

func _handle_movement_input(delta: float) -> void:
	var wasd_x := 0.0
	var wasd_y := 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		wasd_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		wasd_x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		wasd_y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		wasd_y += 1.0

	var direction := Vector3(wasd_x, 0, wasd_y).normalized()
	direction = direction.rotated(Vector3.UP, deg_to_rad(45))

	# 蓄力时不能移动
	if jump_requested:
		velocity.x = 0
		velocity.z = 0
	elif direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		# 平滑转身
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func _handle_jump_input() -> void:
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor() and not jump_requested and not is_jumping:
		jump_requested = true
		# 跳跃动画（目前只有空手跳跃）
		animation_mgr.play("Unarmed_Jump")
		# 等待下蹲动画后再施加跳跃力
		await get_tree().create_timer(JUMP_SQUAT_TIME).timeout
		if jump_requested:
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			jump_requested = false

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if is_jumping:
			is_jumping = false
			jump_requested = false

func _update_animation() -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	# 跳跃状态优先
	if jump_requested or is_jumping or not is_on_floor():
		# TODO: 添加持剑跳跃动画后修改
		animation_mgr.play("Unarmed_Jump")
		return

	# 根据武器状态选择动画
	if weapon_mgr.has_weapon():
		if horizontal_speed > 0.1:
			# TODO: 添加持剑行走动画后改为 SwordAndShield_Walking
			animation_mgr.play("SwordAndShield_Idle_004")  # 暂时用 idle 代替
		else:
			animation_mgr.play("SwordAndShield_Idle_004")
	else:
		if horizontal_speed > 0.1:
			animation_mgr.play("Unarmed_Walking")
		else:
			animation_mgr.play("Unarmed_Idle")
			
############################################################
# animation
############################################################
@onready var animation_mgr: AnimationMgr = $AnimationMgr

############################################################
# weapon mgr
############################################################
@onready var weapon_mgr: WeaponMgr = $WeaponMgr
func _ready_weapon_mgr() -> void:
	# 连接武器管理器信号
	weapon_mgr.weapon_equipped.connect(_on_weapon_equipped)
	weapon_mgr.weapon_unequipped.connect(_on_weapon_unequipped)
	if weapon_mgr.has_weapon():
		prints("weapon mgr has weapon")
	else:
		prints("weapon mgr no weapon")

func _on_weapon_equipped(_weapon_name: String) -> void:
	prints("weapon equipped:", _weapon_name)

func _on_weapon_unequipped() -> void:
	prints("weapon unequipped")
