extends CharacterBody3D

const SPEED = 4.0 # 移动速度
const ROTATION_SPEED = 6.0 # 转身速度
const JUMP_VELOCITY = 2.9 # 跳跃初速度
const JUMP_SQUAT_TIME = 0.8 # 下蹲蓄力时间（秒） 空中时间 [0.8-1.4]

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

var is_jumping := false
var jump_requested := false # 是否请求了跳跃（等待蓄力）
var current_anim_state := "" # 当前动画状态，避免重复切换

func _ready() -> void:
	# 强制激活动画树，防止编辑器中未勾选 Active 导致 T-pose
	if animation_tree:
		prints("animation_tree active:", animation_tree.active)
		animation_tree.active = true

func _physics_process(delta: float) -> void:
	var wasd_x := 0.0
	var wasd_y := 0.0
	# 使用全局键常量以兼容不同 Godot 版本
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		wasd_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		wasd_x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		wasd_y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		wasd_y += 1.0

	# 2. 将 2D 输入转为 3D 向量 (x, 0, y)
	var direction := Vector3(wasd_x, 0, wasd_y).normalized()
	# 3. 【核心】修正方向：因为摄像机旋转了45度，移动方向也要旋转45度
	# 这样按 W 才是往屏幕上方走
	direction = direction.rotated(Vector3.UP, deg_to_rad(45))

	# 蓄力时不能移动
	if jump_requested:
		velocity.x = 0
		velocity.z = 0
	elif direction:
		# 移动
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# 平滑转身：让角色面朝移动方向
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)
	else:
		# 停止
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 跳跃：空格键（带蓄力延迟）
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor() and not jump_requested and not is_jumping:
		jump_requested = true
		current_anim_state = "Global_Jump"
		state_machine.travel("Global_Jump")
		# 等待下蹲动画后再施加跳跃力
		await get_tree().create_timer(JUMP_SQUAT_TIME).timeout
		if jump_requested: # 确保还在跳跃状态
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			jump_requested = false

	# 4. 处理重力
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if is_jumping: # 刚落地
			is_jumping = false
			jump_requested = false

	move_and_slide()

	# 动画状态切换（只在状态改变时才切换，避免闪烁）
	var target_state := ""
	if jump_requested or is_jumping or not is_on_floor():
		target_state = "Global_Jump"
	elif velocity.length() > 0.1: # 如果在移动
		target_state = "Global_Walking"
	else:
		target_state = "Global_Idle"

	if target_state != current_anim_state:
		current_anim_state = target_state
		state_machine.travel(target_state)
