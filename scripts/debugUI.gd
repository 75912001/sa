extends Label

var target: Node3D

func _ready() -> void:
	# 查找玩家节点
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _process(_delta: float) -> void:
	if not target:
		return

	# 获取世界坐标
	var pos = target.global_position

	# 获取朝向角度 (Y轴旋转，转为度数)
	var facing_deg = rad_to_deg(target.rotation.y)

	# 获取朝向方向向量
	var facing_dir = Vector3.FORWARD.rotated(Vector3.UP, target.rotation.y)

	# 获取 FPS
	var fps = Engine.get_frames_per_second()
	
	# 更新显示
	text = "FPS:%.0f\nPosition:(x:%.2f, y:%.2f, z:%.2f)\nFacing:%.1f°\nDirection:(%.2f, %.2f)" % [
		fps,
		pos.x, pos.y, pos.z,
		facing_deg,
		facing_dir.x, facing_dir.z
	]
