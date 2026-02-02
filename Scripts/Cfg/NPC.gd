# 配置-NPC-管理器
class_name CfgNpcMgr

extends RefCounted

# --- 元素属性 ---
class CfgElemental extends RefCounted:
	var earth: int = 0      # 土
	var water: int = 0      # 水
	var fire: int = 0       # 火
	var wind: int = 0       # 风

# --- 属性数据 ---
class CfgAttributes extends RefCounted:
	var attack: int = 0
	var defense: int = 0
	var agility: int = 0
	var hp: int = 0
	var critRate: float = 0.1
	var counterRate: float = 0.1
	var dodgeRate: float = 0.1
	var hitRate: float = 0.9
	var critDamageBonusRate: float = 0.5
	var statusResistRate: float = 0.2

# --- 单个NPC数据 ---
class CfgNpcEntry extends RefCounted:
	var id: int
	var name: String
	var description: String
	var elemental: CfgElemental
	var attributes: CfgAttributes

	func show() -> String:
		return name

# --- 缓存数据 ---
var npcs: Dictionary = {}  # NPC ID -> CfgNpcEntry

# 加载配置
func load(path: String) -> void:
	var data := GCfgMgr.load_yaml(path)
	var npcs_array: Array = data.get("npcs", [])
	for item in npcs_array:
		var entry := CfgNpcEntry.new()
		entry.id = item.get("id", 0)
		assert(PbAsset.AssetIDRange.AssetIDRange_NPC_Start <= entry.id && entry.id <= PbAsset.AssetIDRange.AssetIDRange_NPC_End,
			"NPC ID-超出范围: %d" % entry.id)
		entry.name = item.get("name", "")
		assert(not entry.name.is_empty(), "NPC名称为空: ID:%d" % entry.id)
		entry.description = item.get("description", "")

		# 解析元素属性
		entry.elemental = CfgElemental.new()
		var elemental_data = item.get("elemental", {})
		entry.elemental.earth = elemental_data.get("earth", 0)
		entry.elemental.water = elemental_data.get("water", 0)
		entry.elemental.fire = elemental_data.get("fire", 0)
		entry.elemental.wind = elemental_data.get("wind", 0)
		var total_elemental = entry.elemental.earth + entry.elemental.water + entry.elemental.fire + entry.elemental.wind
		assert(total_elemental == 10, "NPC元素属性总和必须为10: ID:%d, 当前:%d" % [entry.id, total_elemental])
		# todo menglc 属性最多两个, 且相邻

		# 解析属性
		entry.attributes = CfgAttributes.new()
		var attributes_data = item.get("attributes", {})
		entry.attributes.attack = attributes_data.get("attack", 0)
		entry.attributes.defense = attributes_data.get("defense", 0)
		entry.attributes.agility = attributes_data.get("agility", 0)
		entry.attributes.hp = attributes_data.get("hp", 0)
		entry.attributes.critRate = attributes_data.get("critRate", 0.1)
		entry.attributes.counterRate = attributes_data.get("counterRate", 0.1)
		entry.attributes.dodgeRate = attributes_data.get("dodgeRate", 0.1)
		entry.attributes.hitRate = attributes_data.get("hitRate", 0.9)
		entry.attributes.critDamageBonusRate = attributes_data.get("critDamageBonusRate", 0.5)
		entry.attributes.statusResistRate = attributes_data.get("statusResistRate", 0.2)

		if npcs.has(entry.id):
			assert(false, "NPC ID-重复: %d" % entry.id)
		else:
			npcs[entry.id] = entry

# 校验配置
func check() -> void:
	for npc_id in npcs:
		var entry: CfgNpcEntry = npcs[npc_id]
		# prints("NPC:", entry.show())

# 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

# 获取NPC
func get_npc(id: int) -> CfgNpcEntry:
	return npcs.get(id, null)
