# NPCMgr.gd - NPC生成和管理器
#
# 职责：
# - 管理所有NPC的生命周期（生成、销毁、查询）
# - 维护NPC的全局字典（UUID → NPC实例）
# - 提供API供地图/关卡使用
#
# 使用方式：
#   var npc_mgr = NPCMgr.new()
#   var npc = npc_mgr.spawn_npc(5000001, Vector3(0, 0, 0))
#   npc_mgr.despawn_npc(npc.uuid)

class_name NPCMgr extends RefCounted

# --- NPC容器节点（所有NPC的父节点） ---
var _npc_container: Node3D

# --- NPC字典：UUID -> NPC实例 ---
var _npc_dict: Dictionary = {}

# 初始化（需要传入一个Node3D作为NPC的父节点）
func setup(container: Node3D) -> void:
	_npc_container = container
	print("NPCMgr: 初始化完成")

# ============================================
# 创建单个NPC
# ============================================
func spawn_npc(npc_id: int, position: Vector3, rotation: float = 0.0) -> NPC:
	# 从配置读取NPC信息
	var npc_cfg = GCfgMgr.cfg_npc_mgr.get_npc(npc_id)
	assert(npc_cfg != null,"NPCMgr: NPC配置不存在 ID:%d" % npc_id)
	var _char_cfg = GCfgMgr.cfg_character_mgr.get_character(npc_cfg.character_id)
	# 加载NPC场景并实例化
	var npc_scene = load("res://Scenes/NPC.tscn")
	var npc: NPC = npc_scene.instantiate()
	# 配置NPC
	npc.character_id = npc_cfg.character_id
	npc.uuid = GUuidMgr.get_new_uuid()

	npc.position = position
	npc.rotation.y = rotation
	
	# 添加到场景树
	_npc_container.add_child(npc)

	npc.global_position = position

	npc.pending_weapon_id = npc_cfg.default_weapon_id
	npc.pending_armor_ids = npc_cfg.default_armor_ids.duplicate()
	# 记录到字典
	_npc_dict[npc.uuid] = npc
	print("NPCMgr: spawn NPC[%d] at %s with UUID[%d]" % [npc_id, position, npc.uuid])
	return npc

# ============================================
# 创建敌人组（引用enemy.groups.yaml）
# ============================================
func spawn_enemy_group(group_id: int, position: Vector3) -> Array[NPC]:
	# 使用CfgEnemyGroupMgr的随机生成功能
	var enemy_ids = GCfgMgr.cfg_enemy_group_mgr.spawn_enemies_from_group(group_id)
	if enemy_ids.is_empty():
		push_error("NPCMgr: 敌人组生成失败 group_id:%d" % group_id)
		return []
	# 生成敌人
	var npcs: Array[NPC] = []
	for i in range(enemy_ids.size()):
		var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		var npc = spawn_npc(enemy_ids[i], position + offset)
		if npc:
			npcs.append(npc)
	print("NPCMgr: spawn enemy group[%d] with %d enemies" % [group_id, npcs.size()])
	return npcs

# ============================================
# 通过UUID获取NPC
# ============================================
func get_npc_by_uuid(uuid: int) -> NPC:
	return _npc_dict.get(uuid, null)

# ============================================
# 销毁指定NPC
# ============================================
func despawn_npc(uuid: int) -> void:
	var npc = _npc_dict.get(uuid, null)
	assert(npc != null, "NPCMgr: 试图销毁不存在的NPC UUID:%d" % uuid)
	# 从字典移除
	_npc_dict.erase(uuid)
	# 销毁节点
	npc.queue_free()
	print("NPCMgr: despawn NPC UUID[%d]" % uuid)

# ============================================
# 获取所有NPC
# ============================================
func get_all_npcs() -> Array[NPC]:
	var result: Array[NPC] = []
	for uuid in _npc_dict:
		result.append(_npc_dict[uuid])
	return result

# ============================================
# 清空所有NPC（地图切换时调用）
# ============================================
func clear_all_npcs() -> void:
	var count = _npc_dict.size()
	for uuid in _npc_dict.keys():
		var npc = _npc_dict[uuid]
		npc.queue_free()
	_npc_dict.clear()
	print("NPCMgr: 清空所有NPC (共%d个)" % count)
