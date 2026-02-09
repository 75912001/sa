# 配置-NPC组-管理器
class_name CfgNpcGroupMgr

extends RefCounted

# --- 敌人数据 ---
class CfgNpc extends RefCounted:
	var id: int                    # NPC ID (引用npc.yaml)
	var weight: int = 0            # 权重(0表示必定出现)

# --- NPC组数据 ---
class CfgNpcGroupEntry extends RefCounted:
	var id: int
	var name: String
	var countRange: Array[int]     # [最小数量, 最大数量]
	# 默认行为
	var default_stance: PbCommon.NPCStance = PbCommon.NPCStance.NPCStance_Unknown
	var default_behavior: PbCommon.NPCBehaviorType = PbCommon.NPCBehaviorType.NPCBehaviorType_Unknown
	var default_behavior_params: Dictionary = {}
	var npcs: Array[CfgNpc]

	func show() -> String:
		return name

# --- 缓存数据 ---
var npcGroups: Dictionary = {}  # NPC组ID -> CfgNpcGroupEntry

# 加载配置
func load(path: String) -> void:
	var data := GCfgMgr.load_yaml(path)
	var npc_groups_array: Array = data.get("npcGroups", [])
	for item in npc_groups_array:
		var entry := CfgNpcGroupEntry.new()
		entry.id = item.get("id", 0)
		assert(entry.id > 0, "NPC组ID无效: %d" % entry.id)
		entry.name = item.get("name", "")
		assert(not entry.name.is_empty(), "NPC组名称为空: ID:%d" % entry.id)

		# 解析数量范围
		var count_range_array: Array = item.get("countRange", [])
		assert(count_range_array.size() == 2, "NPC组数量范围格式错误: ID:%d" % entry.id)
		var min_count = count_range_array[0]
		var max_count = count_range_array[1]
		assert(1 <= min_count && min_count <= max_count && max_count <= 10,
			"NPC组数量范围非法: ID:%d, 范围:[%d,%d]" % [entry.id, min_count, max_count])
		entry.countRange = [min_count, max_count]

		# 解析默认行为
		entry.default_stance = item.get("defaultStance", PbCommon.NPCStance.NPCStance_Neutral)
		assert(PbCommon.NPCStance.NPCStance_Unknown < entry.default_stance and entry.default_stance < PbCommon.NPCStance.NPCStance_Max,
			"NPC组默认立场无效: ID:%d, stance:%d" % [entry.id, entry.default_stance])
		entry.default_behavior = item.get("defaultBehavior", PbCommon.NPCBehaviorType.NPCBehaviorType_Idle)
		assert(PbCommon.NPCBehaviorType.NPCBehaviorType_Unknown < entry.default_behavior and entry.default_behavior < PbCommon.NPCBehaviorType.NPCBehaviorType_Max,
			"NPC组默认行为无效: ID:%d, behavior:%d" % [entry.id, entry.default_behavior])
		entry.default_behavior_params = item.get("defaultBehaviorParams", {})

		# 解析NPC列表
		var npcs_array: Array = item.get("npcs", [])
		assert(npcs_array.size() > 0, "Npc组中没有npc: ID:%d" % entry.id)
		entry.npcs = []
		var required_npc_count = 0  # 必出NPC数量（weight=0）
		var random_npc_count = 0    # 随机出NPC数量（weight>0）
		for npc_item in npcs_array:
			var npc := CfgNpc.new()
			npc.id = npc_item.get("id", 0)
			assert(npc.id > 0, "Npc ID无效: Npc组ID:%d" % entry.id)
			npc.weight = npc_item.get("weight", 0)
			if npc.weight == 0:
				required_npc_count += 1
			else:
				random_npc_count += 1
			entry.npcs.append(npc)

		# 校验countRange与npcs数量的合理性
		# 生成逻辑：先放入必出NPC，不足则从随机池循环选择直到达到目标
		# 规则1: 必出NPC <= max_count
		# 规则2: 必出NPC >= min_count OR 随机NPC >= 1（只要有随机NPC，就能无限填充）
		assert(required_npc_count <= max_count,
			"NPC组配置不合理: ID:%d, 必出NPC(%d)超过最大生成数(%d)" % [entry.id, required_npc_count, max_count])
		assert(required_npc_count >= min_count or random_npc_count >= 1,
			"NPC组配置不合理: ID:%d, 必出NPC(%d)不足最小(%d)，且无随机NPC补充" % [entry.id, required_npc_count, min_count])

		if npcGroups.has(entry.id):
			assert(false, "Npc组ID-重复: %d" % entry.id)
		else:
			npcGroups[entry.id] = entry

# 校验配置
func check() -> void:
	for group_id in npcGroups:
		var entry: CfgNpcGroupEntry = npcGroups[group_id]
		# prints("Npc组:", entry.show())

		# 验证Npc组中的NPC存在
		for npc in entry.npcs:
			assert(GCfgMgr.cfg_npc_mgr.get_npc(npc.id) != null,
				"引用的NPC不存在: Npc组ID:%d, NPC ID:%d" % [entry.id, npc.id])

# 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

# 获取Npc组
func get_npc_group(id: int) -> CfgNpcGroupEntry:
	return npcGroups.get(id, null)

# 从Npc组随机生成npc
func spawn_npcs_from_group(group_id: int) -> Array[int]:
	var group = get_npc_group(group_id)
	if group == null:
		push_error("Npc组不存在: %d" % group_id)
		return []

	var result: Array[int] = []
	var min_count = group.countRange[0]
	var max_count = group.countRange[1]
	var target_count = randi_range(min_count, max_count)

	# 先添加权重为0的npc(必定出现)
	for npc in group.npcs:
		if npc.weight == 0:
			result.append(npc.id)
			if result.size() >= target_count:
				return result

	# 再从权重池中随机选择
	while result.size() < target_count:
		var weighted_npcs = group.npcs.filter(func(e): return e.weight > 0)
		if weighted_npcs.is_empty():
			break
		# 简单的加权随机选择
		var total_weight = weighted_npcs.reduce(func(sum, e): return sum + e.weight, 0)
		var random_value = randi() % total_weight
		var accumulated = 0
		for npc in weighted_npcs:
			accumulated += npc.weight
			if random_value < accumulated:
				result.append(npc.id)
				break

	return result
