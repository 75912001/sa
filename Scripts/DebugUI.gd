extends Label

func _ready() -> void:
	return

func _process(_delta: float) -> void:
	# 获取世界坐标
	var pos = GGameMgr.player.global_position

	# 获取朝向角度 (Y轴旋转，转为度数)
	var facing_deg = rad_to_deg(GGameMgr.player.rotation.y)

	# 获取朝向方向向量
	var facing_dir = Vector3.FORWARD.rotated(Vector3.UP, GGameMgr.player.rotation.y)

	# 获取 FPS
	var fps = Engine.get_frames_per_second()
	
	# 更新显示
	text = "FPS:%.0f\nPosition:(x:%.2f, y:%.2f, z:%.2f)\nFacing:%.1f°\nDirection:(%.2f, %.2f)" % [
		fps,
		pos.x, pos.y, pos.z,
		facing_deg,
		facing_dir.x, facing_dir.z
	]
