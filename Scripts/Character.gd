# Character.gd - 通用角色基类
#
# 职责：
# 1. 管理所有组件的初始化（weapon、animation、movement等）
# 2. 提供通用的物理更新循环（move_and_slide）
# 3. 提供通用的动画更新循环（update_lower/upper_animation）
# 4. 支持多种角色类型：Player、NPC、Enemy等
#
# 架构说明：
# - Player 继承 Character，只需在 _ready_subclass() 做Player特化初始化
# - NPC 继承 Character，使用 AIInputMgr 代替 InputMgr
# - Enemy 继承 NPC，附加具体的AI行为
#
# 复用情况：
# ✓ 所有动画系统完全复用
# ✓ 所有移动系统完全复用
# ✓ 所有武器系统完全复用
# ✓ 所有攻击系统完全复用
# ✓ 所有翻滚系统完全复用
# ✓ 代码复用率 ~95%
#
# 下一步计划：
# - 步骤7-11：创建输入接口（IInputProvider、AIInputMgr）
# - 步骤12-16：创建NPC基类
# - 步骤17-25：实现AI逻辑

class_name Character extends CharacterBody3D

# --- 导出属性 ---
@export var character_id: int = 1000001

# --- 组件引用 ---
@onready var armor_mgr: ArmorMgr 
@onready var weapon_mgr: WeaponMgr = $WeaponMgr
@onready var animation_mgr: AnimationMgr = $AnimationMgr
@onready var movement_mgr: MovementMgr = $MovementMgr
@onready var weapon_switch_mgr: WeaponSwitchMgr = $WeaponSwitchMgr
@onready var attack_mgr: AttackMgr = $AttackMgr
@onready var roll_mgr: RollMgr = $RollMgr

var input_mgr: IInputProvider

# --- 配置 ---
var cfg_character_entry: CfgCharacterMgr.CfgCharacterEntry
var skeleton: Skeleton3D

func _ready() -> void:
	# 加载配置
	cfg_character_entry = GCfgMgr.cfg_character_mgr.get_character(character_id)
	assert(cfg_character_entry != null, "角色配置不存在: %d" % character_id)
	# 动态加载角色模型
	_load_character_model()

	# 初始化装备系统(寻找骨架)
	skeleton = $ModelContainer.get_node(cfg_character_entry.skeleton_path)
	assert(skeleton and skeleton is Skeleton3D, "找不到骨架: %s" % cfg_character_entry.skeleton_path)

	# 修复动画警告: 动画中使用 %GeneralSkeleton 访问骨架
	# 确保骨架名字匹配且能作为唯一名称被访问
	if skeleton.name != "GeneralSkeleton":
		skeleton.name = "GeneralSkeleton"
	skeleton.unique_name_in_owner = true
	# 动态加载的节点 Owner 为空，需手动设为当前场景根节点，AnimationPlayer 才能通过 % 找到它
	skeleton.owner = self

	# 加载动画库
	_load_animation_library()

	# 初始化所有管理器
	_init_armor_mgr()
	weapon_mgr.setup(self)
	weapon_switch_mgr.setup(self)
	attack_mgr.setup(self)
	movement_mgr.setup(self)
	roll_mgr.setup(self)
	animation_mgr.setup(self)

func _physics_process(_delta: float) -> void:
	move_and_slide()
	# 更新动画
	animation_mgr.update_lower_animation()
	animation_mgr.update_upper_animation()

############################################################
# ArmorMgr
############################################################
func _init_armor_mgr() -> void:
	# --- 装备管理器 ---
	armor_mgr = ArmorMgr.new()
	add_child(armor_mgr)

	armor_mgr.setup(self)

############################################################
# 模型加载
############################################################
func _load_character_model() -> void:
	var model_scene = load(cfg_character_entry.model_path) as PackedScene
	assert(model_scene, "无法加载角色模型: %s" % cfg_character_entry.model_path)
	var model_instance = model_scene.instantiate()
	var model_container = $ModelContainer
	model_container.add_child(model_instance)

func _load_animation_library() -> void:
	var libs_map = GCfgMgr.cfg_animation_mgr.get_animation_libraries_map(cfg_character_entry.animation_library_ref)
	assert(libs_map.size() > 0, "动画库集合为空或加载失败: %s" % cfg_character_entry.animation_library_ref)
	
	var anim_player = $AnimationPlayer
	# 清空现有动画库
	for lib_name in anim_player.get_animation_library_list():
		anim_player.remove_animation_library(lib_name)
		
	# 添加新的动画库
	for category_name in libs_map:
		var lib = libs_map[category_name]
		anim_player.add_animation_library(category_name, lib)
		
	print("动画库集合已加载: %s, 包含分类: %s" % [cfg_character_entry.animation_library_ref, libs_map.keys()])
