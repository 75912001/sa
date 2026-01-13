extends CharacterBody3D

const SPEED = 8.0 # 移动速度
const ROTATION_SPEED = 10.0 # 转身速度

func _physics_process(delta: float) -> void:
	# 1. 获取输入 (确保你在项目设置里绑定了 ui_up/down/left/right 对应的 WASD)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. 将 2D 输入转为 3D 向量 (x, 0, y)
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# 3. 【核心】修正方向：因为摄像机旋转了45度，移动方向也要旋转45度
	# 这样按 W 才是往屏幕上方走
	direction = direction.rotated(Vector3.UP, deg_to_rad(45))

	if direction:
		# 移动
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# 平滑转身：让角色面朝移动方向
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)
		
		#prints("direction:", direction," x:", velocity.x, " z:", velocity.z)
	else:
		# 停止
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 4. 处理重力
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
