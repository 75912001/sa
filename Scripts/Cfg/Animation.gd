# 配置-动画库-管理器
class_name CfgAnimationMgr

extends RefCounted

# --- 单个动画库数据 ---
class CfgAnimationLibrary extends RefCounted:
	var name: String
	var base_path: String
	var categories: Dictionary  # category_name -> Array[String]

	func show() -> String:
		return name

# --- 缓存数据 ---
var libraries: Dictionary = {}  # library_name -> CfgAnimationLibrary
var godot_libraries_cache: Dictionary = {} # config_name -> Dictionary[category_name, AnimationLibrary]

# 加载配置
func load(path: String) -> void:
	var data := GCfgMgr.load_yaml(path)
	var animation_libraries_dict: Dictionary = data.get("animationLibraries", {})

	for lib_name in animation_libraries_dict:
		var lib_data = animation_libraries_dict[lib_name]
		var entry := CfgAnimationLibrary.new()
		entry.name = lib_name
		entry.base_path = lib_data.get("basePath", "")
		assert(not entry.base_path.is_empty(), "动画库基础路径为空: %s" % lib_name)

		# 解析分类和动画列表
		entry.categories = {}
		var categories_dict: Dictionary = lib_data.get("categories", {})
		for category_name in categories_dict:
			var animation_list: Array = categories_dict[category_name]
			entry.categories[category_name] = animation_list

		assert(entry.categories.size() > 0, "动画库没有分类: %s" % lib_name)

		if libraries.has(entry.name):
			assert(false, "动画库名称重复: %s" % entry.name)
		else:
			libraries[entry.name] = entry

# 校验配置
func check() -> void:
	for lib_name in libraries:
		var entry: CfgAnimationLibrary = libraries[lib_name]
		# prints("动画库:", entry.show())

		# 校验每个分类下的动画文件是否存在
		for category_name in entry.categories:
			var animation_list: Array = entry.categories[category_name]
			for anim_name in animation_list:
				var full_path = entry.base_path + category_name + "/" + anim_name + ".res"
				assert(ResourceLoader.exists(full_path),
					"动画文件不存在: 库:%s, 分类:%s, 动画:%s, 路径:%s" % [lib_name, category_name, anim_name, full_path])

# 组装配置 (预处理/索引构建)
func assemble() -> void:
	pass

# 获取动画库数据
func get_library(name: String) -> CfgAnimationLibrary:
	return libraries.get(name, null)

# 获取Godot动画库资源字典
# 返回: Dictionary[String, AnimationLibrary]  CategoryName -> AnimationLibrary
func get_animation_libraries_map(name: String) -> Dictionary:
	if godot_libraries_cache.has(name):
		return godot_libraries_cache[name]
		
	var entry = get_library(name)
	assert(entry, "未找到动画库: %s" % name)
		
	var libs_map = {}
	
	for category_name in entry.categories:
		var lib_for_category = AnimationLibrary.new()
		var animation_list: Array = entry.categories[category_name]
		
		for anim_name in animation_list:
			var full_path = entry.base_path + category_name + "/" + anim_name + ".res"
			if ResourceLoader.exists(full_path):
				var anim_res = load(full_path)
				if anim_res is Animation:
					# 直接使用 anim_name，因为这个库会被命名为 category_name
					# 最终效果是: category_name/anim_name
					lib_for_category.add_animation(anim_name, anim_res)
				else:
					assert(false, "资源不是动画: %s" % full_path)
			else:
				assert(false, "动画文件丢失(运行时): %s" % full_path)
		
		libs_map[category_name] = lib_for_category
	
	godot_libraries_cache[name] = libs_map
	return libs_map
