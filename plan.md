# 基本要求
    阅读 README.md
    深度思考
    分析背景
    明确问题
    评审当前想法
    查阅可参考资料
    完成任务
    给出详细的解决方案.
    注重逻辑清晰和步骤明确.
    不要直接给出代码实现, 而是给出如何实现的思路.
    注重性能和可维护性.
    如若有更好的方案, 请一并给出.并给出理由和对比.
    可以完全访问当前项目的代码和资源.
# 背景
    现在是只有一个武器, D:\sa\Assets\Equipment\Weapon\Sword.001
    按E键可以拿起和放下剑.
# 问题
    现在增加了一个武器, D:\sa\Assets\Equipment\Weapon\Sword.002
# 当前想法
   使用按键 Alt+1 来装备 Sword.001, 按键 Alt+2 来装备 Sword.002. alt+0 卸下武器.
# 可参考资料
# 任务
    非常详细的一步步指引我完成.
    给出方案. 将解决方案分步骤列出.写入 plan.md 下方的 "# 解决方案" 处.

# 解决方案

## 分析总结

### 现有资源
| 武器模型 | 路径 |
|---------|------|
| Sword.001 | Assets/Equipment/Weapon/Sword.001 |
| Sword.002 | Assets/Equipment/Weapon/Sword.002 |

### 现有代码结构
- `WeaponMgr.gd`: 武器管理器，`_weapon_scenes` 字典存储武器，`handle_input()` 用 E 键切换
- `Player.gd`: 协调者，调用 `weapon_mgr.handle_input()`
- `Scenes/Weapons/Sword.tscn`: 现有武器场景（将被替换为通用场景）

### 设计决策
**采用：通用武器场景 + 配置资源方案**

| 方案 | 优点 | 缺点 |
|------|------|------|
| ~~每武器一个场景~~ | 直观 | 场景多，重复劳动 |
| **通用场景 + 配置** | 只维护一个场景，数据驱动 | 需要设计配置结构 |

**按键方案：Alt + 数字键**
- `Alt + 1/2/...` 装备对应槽位武器
- `Alt + 0` 卸下武器

---

## 实施步骤

### 第一步：创建武器配置资源类

**创建文件**: `Scripts/WeaponData.gd`

```gdscript
class_name WeaponData extends Resource
## 武器配置数据

@export var weapon_name: String              # 武器名称（唯一标识）
@export var display_name: String             # 显示名称
@export_file("*.gltf", "*.glb") var model_path: String  # 模型文件路径
@export var grip_position: Vector3           # 握持位置偏移
@export var grip_rotation_degrees: Vector3   # 握持旋转（欧拉角，度数）
@export var grip_scale: Vector3 = Vector3.ONE  # 握持缩放
```

---

### 第二步：创建通用武器场景

**修改文件**: `Scenes/Weapons/Sword.tscn` → 重命名为 `Weapon.tscn`

**场景结构**:
```
Weapon (Node3D)          ← 附加脚本 Weapon.gd
└── Grip (Node3D)        ← 握持调整节点
    └── Model (Node3D)   ← 模型容器（运行时动态加载）
```

**操作步骤**:
1. 打开 `Scenes/Weapons/Sword.tscn`
2. 删除 `Grip/SwordMesh` 节点
3. 在 `Grip` 下新建空的 `Node3D`，命名为 `Model`
4. 将场景另存为 `Scenes/Weapons/Weapon.tscn`
5. 删除旧的 `Sword.tscn`

---

### 第三步：创建武器场景脚本

**创建文件**: `Scripts/Weapon.gd`

```gdscript
extends Node3D
class_name Weapon
## 通用武器 - 根据配置动态加载模型

@export var weapon_data: WeaponData

@onready var _grip: Node3D = $Grip
@onready var _model_container: Node3D = $Grip/Model

func _ready() -> void:
    if weapon_data:
        _apply_config()

## 应用武器配置
func _apply_config() -> void:
    # 加载模型
    var model_scene: PackedScene = load(weapon_data.model_path)
    if not model_scene:
        push_error("无法加载武器模型: " + weapon_data.model_path)
        return

    var model_instance = model_scene.instantiate()
    _model_container.add_child(model_instance)

    # 应用握持变换
    _grip.position = weapon_data.grip_position
    _grip.rotation_degrees = weapon_data.grip_rotation_degrees
    _grip.scale = weapon_data.grip_scale

## 获取武器名称
func get_weapon_name() -> String:
    return weapon_data.weapon_name if weapon_data else ""
```

**绑定脚本**:
1. 打开 `Scenes/Weapons/Weapon.tscn`
2. 选中根节点 `Weapon`
3. 在检查器中 Script 属性，加载 `Scripts/Weapon.gd`
4. 保存场景

---

### 第四步：创建武器配置文件

**为 Sword.001 创建配置**:

1. 在 `Assets/Equipment/Weapon/Sword.001/` 文件夹右键
2. Create New → Resource
3. 选择 `WeaponData` 类型
4. 命名为 `data.tres`
5. 填写属性:
   - `weapon_name`: `sword_001`
   - `display_name`: `铁剑`
   - `model_path`: `res://Assets/Equipment/Weapon/Sword.001/scene.gltf`
   - `grip_position`: 从原 Sword.tscn 的 SwordMesh Transform 中提取
   - `grip_rotation_degrees`: 从原 Transform 中提取
   - `grip_scale`: 从原 Transform 中提取

**为 Sword.002 创建配置**:

1. 在 `Assets/Equipment/Weapon/Sword.002/` 文件夹右键
2. Create New → Resource → WeaponData
3. 命名为 `data.tres`
4. 填写属性:
   - `weapon_name`: `sword_002`
   - `display_name`: `魔剑`
   - `model_path`: `res://Assets/Equipment/Weapon/Sword.002/scene.gltf`
   - `grip_position`/`rotation`/`scale`: 需要在编辑器中调试确定

**提取原 Sword.tscn 的 Transform 值**:
原 SwordMesh 的 Transform 矩阵需要分解为位置、旋转、缩放。
可以先填入近似值，运行时再微调。

---

### 第五步：修改 WeaponMgr.gd

**完整替换** `Scripts/WeaponMgr.gd`:

```gdscript
extends Node
class_name WeaponMgr
## 武器管理器 - 处理武器装备/卸下

# --- 配置 ---
@export var weapon_attachment_path: NodePath

# --- 信号 ---
signal weapon_equipped(weapon_name: String)
signal weapon_unequipped

# --- 常量 ---
const WEAPON_SCENE := preload("res://Scenes/Weapons/Weapon.tscn")

# --- 武器配置（槽位 -> 配置资源） ---
var _weapon_configs := {
    1: preload("res://Assets/Equipment/Weapon/Sword.001/data.tres"),
    2: preload("res://Assets/Equipment/Weapon/Sword.002/data.tres"),
}

# --- 变量 ---
var _weapon_attachment: BoneAttachment3D
var _current_weapon: Weapon = null
var _current_slot: int = 0  # 0 表示无武器
var _input_cooldown := false

func _ready() -> void:
    _weapon_attachment = get_node(weapon_attachment_path)

## 装备指定槽位的武器
func equip_weapon(slot: int) -> void:
    if not _weapon_configs.has(slot):
        push_warning("武器槽位不存在: %d" % slot)
        return

    if _current_weapon:
        unequip_weapon()

    var config: WeaponData = _weapon_configs[slot]
    var weapon_instance: Weapon = WEAPON_SCENE.instantiate()
    weapon_instance.weapon_data = config
    _weapon_attachment.add_child(weapon_instance)

    _current_weapon = weapon_instance
    _current_slot = slot
    weapon_equipped.emit(config.weapon_name)

## 卸下当前武器
func unequip_weapon() -> void:
    if _current_weapon:
        _current_weapon.queue_free()
        _current_weapon = null
        _current_slot = 0
        weapon_unequipped.emit()

## 是否持有武器
func has_weapon() -> bool:
    return _current_weapon != null

## 获取当前武器槽位
func get_current_slot() -> int:
    return _current_slot

## 处理输入
func handle_input() -> void:
    if _input_cooldown:
        return

    # Alt + 数字键
    if Input.is_key_pressed(KEY_ALT):
        var slot := _get_number_key_pressed()
        if slot >= 0:
            _handle_slot_input(slot)

## 检测按下的数字键，返回 0-9，未按下返回 -1
func _get_number_key_pressed() -> int:
    if Input.is_key_pressed(KEY_0): return 0
    if Input.is_key_pressed(KEY_1): return 1
    if Input.is_key_pressed(KEY_2): return 2
    if Input.is_key_pressed(KEY_3): return 3
    if Input.is_key_pressed(KEY_4): return 4
    if Input.is_key_pressed(KEY_5): return 5
    if Input.is_key_pressed(KEY_6): return 6
    if Input.is_key_pressed(KEY_7): return 7
    if Input.is_key_pressed(KEY_8): return 8
    if Input.is_key_pressed(KEY_9): return 9
    return -1

## 处理槽位输入
func _handle_slot_input(slot: int) -> void:
    _start_cooldown()

    if slot == 0:
        unequip_weapon()
    elif slot == _current_slot:
        # 按同一槽位，卸下武器
        unequip_weapon()
    else:
        equip_weapon(slot)

## 开始输入冷却
func _start_cooldown() -> void:
    _input_cooldown = true
    await get_tree().create_timer(0.3).timeout
    if is_instance_valid(self):
        _input_cooldown = false
```

---

### 第六步：测试

1. **运行游戏**
2. **测试按键**:
   - `Alt + 1` → 装备 Sword.001
   - `Alt + 2` → 装备 Sword.002
   - `Alt + 0` → 卸下武器
   - `Alt + 1`（已装备时再按）→ 卸下武器
3. **检查武器位置**，如有偏差，修改对应 `data.tres` 的握持参数

---

## 添加新武器流程（改进后）

1. 放入模型: `Assets/Equipment/Weapon/NewWeapon/scene.gltf`
2. 创建配置: `Assets/Equipment/Weapon/NewWeapon/data.tres` (类型: WeaponData)
3. 填写配置参数
4. 在 `WeaponMgr._weapon_configs` 添加一行:
   ```gdscript
   3: preload("res://Assets/Equipment/Weapon/NewWeapon/data.tres"),
   ```

**无需创建新场景，Weapon.tscn 保持不变**

---

## 文件清单

| 操作 | 文件 |
|------|------|
| 新建 | `Scripts/WeaponData.gd` |
| 新建 | `Scripts/Weapon.gd` |
| 新建 | `Assets/Equipment/Weapon/Sword.001/data.tres` |
| 新建 | `Assets/Equipment/Weapon/Sword.002/data.tres` |
| 修改 | `Scenes/Weapons/Sword.tscn` → `Weapon.tscn` |
| 修改 | `Scripts/WeaponMgr.gd` |

