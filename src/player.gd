extends CharacterBody3D

const SPEED = 8.0 # 移动速度
const ROTATION_SPEED = 10.0 # 转身速度

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

	if direction:
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

	# 4. 处理重力
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
