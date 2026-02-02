# 配置-敌人组-管理器
class_name CfgEnemyGroupMgr

extends RefCounted

# --- 敌人数据 ---
class CfgEnemy extends RefCounted:
	var id: int                    # NPC ID (引用npc.yaml)
	var weight: int = 0            # 权重(0表示必定出现)

# --- 敌人组数据 ---
class CfgEnemyGroupEntry extends RefCounted:
	var id: int
	var name: String
	var countRange: Array[int]     # [最小数量, 最大数量]
	var enemies: Array[CfgEnemy]

	func show() -> String:
		return name

# --- 缓存数据 ---
var enemyGroups: Dictionary = {}  # 敌人组ID -> CfgEnemyGroupEntry

# 加载配置
func load(path: String) -> void:
	var data := GCfgMgr.load_yaml(path)
	var enemy_groups_array: Array = data.get("enemyGroups", [])
	for item in enemy_groups_array:
		var entry := CfgEnemyGroupEntry.new()
		entry.id = item.get("id", 0)
		assert(entry.id > 0, "敌人组ID无效: %d" % entry.id)
		entry.name = item.get("name", "")
		assert(not entry.name.is_empty(), "敌人组名称为空: ID:%d" % entry.id)

		# 解析数量范围
		var count_range_array: Array = item.get("countRange", [])
		assert(count_range_array.size() == 2, "敌人组数量范围格式错误: ID:%d" % entry.id)
		var min_count = count_range_array[0]
		var max_count = count_range_array[1]
		assert(1 <= min_count && min_count <= max_count && max_count <= 10,
			"敌人组数量范围非法: ID:%d, 范围:[%d,%d]" % [entry.id, min_count, max_count])
		entry.countRange = [min_count, max_count]

		# 解析敌人列表
		var enemies_array: Array = item.get("enemies", [])
		assert(enemies_array.size() > 0, "敌人组中没有敌人: ID:%d" % entry.id)
		entry.enemies = []
		for enemy_item in enemies_array:
			var enemy := CfgEnemy.new()
			enemy.id = enemy_item.get("id", 0)
			assert(enemy.id > 0, "敌人ID无效: 敌人组ID:%d" % entry.id)
			enemy.weight = enemy_item.get("weight", 0)
			entry.enemies.append(enemy)

		if enemyGroups.has(entry.id):
			assert(false, "敌人组ID-重复: %d" % entry.id)
		else:
			enemyGroups[entry.id] = entry

# 校验配置
func check() -> void:
	for group_id in enemyGroups:
		var entry: CfgEnemyGroupEntry = enemyGroups[group_id]
		# prints("敌人组:", entry.show())

		# 验证敌人组中的NPC存在
		for enemy in entry.enemies:
			assert(GCfgMgr.cfg_npc_mgr.get_npc(enemy.id) != null,
				"引用的NPC不存在: 敌人组ID:%d, NPC ID:%d" % [entry.id, enemy.id])

# 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

# 获取敌人组
func get_enemy_group(id: int) -> CfgEnemyGroupEntry:
	return enemyGroups.get(id, null)

# 从敌人组随机生成敌人
func spawn_enemies_from_group(group_id: int) -> Array[int]:
	var group = get_enemy_group(group_id)
	if group == null:
		push_error("敌人组不存在: %d" % group_id)
		return []

	var result: Array[int] = []
	var min_count = group.countRange[0]
	var max_count = group.countRange[1]
	var target_count = randi_range(min_count, max_count)

	# 先添加权重为0的敌人(必定出现)
	for enemy in group.enemies:
		if enemy.weight == 0:
			result.append(enemy.id)
			if result.size() >= target_count:
				return result

	# 再从权重池中随机选择
	while result.size() < target_count:
		var weighted_enemies = group.enemies.filter(func(e): return e.weight > 0)
		if weighted_enemies.is_empty():
			break
		# 简单的加权随机选择
		var total_weight = weighted_enemies.reduce(func(sum, e): return sum + e.weight, 0)
		var random_value = randi() % total_weight
		var accumulated = 0
		for enemy in weighted_enemies:
			accumulated += enemy.weight
			if random_value < accumulated:
				result.append(enemy.id)
				break

	return result
