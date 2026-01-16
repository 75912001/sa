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
    增加拿剑的 walking 动画
# 问题
    增加拿剑的 walking 动画,需要做什么步骤?
# 当前想法
# 可参考资料
    新下载的武器模型资源
        D:\sa\Assets\Equipment\Weapon\Sword.001
    原有持刀动画
        D:\sa\Assets\Animations\Library\SwordAndShield
# 任务
    非常详细的一步步指引我完成.
    给出方案. 将解决方案分步骤列出.写入 plan.md 下方的 "# 解决方案" 处.

# 解决方案

## 概述

在Godot中实现武器装备系统的核心是使用 **BoneAttachment3D** 节点，将武器模型绑定到角色骨骼的特定骨骼（右手）上。结合脚本控制，可以实现装备/卸下武器的功能。

---

## 第一步：准备武器场景

### 1.1 导入武器模型
当前武器模型位于：`Assets/Equipment/Weapon/Sword.001/scene.gltf`

在Godot编辑器中：
1. 打开文件系统面板，导航到 `Assets/Equipment/Weapon/Sword.001/`
2. 双击 `scene.gltf` 查看导入效果
3. 如果模型显示正常，Godot会自动导入

### 1.2 创建武器场景（Sword.tscn）
为了方便复用和管理，建议将武器封装为独立场景：

1. 在文件系统中右键 `Scenes/` 文件夹 → 新建文件夹 `Weapons/`
2. 将 `scene.gltf` 拖入3D视口创建节点
3. 调整武器的位置、旋转、缩放，使其：
   - 原点位于握柄位置
   - Y轴朝上（剑尖方向）
   - 根据需要调整缩放比例
4. 将场景另存为 `Scenes/Weapons/Sword.tscn`

**推荐场景结构：**
```
Sword (Node3D)
├── MeshInstance3D    # 武器网格（从gltf导入）
└── (可选) CollisionShape3D  # 如需武器碰撞检测
```

---

## 第二步：在角色骨骼上创建武器挂载点

### 2.1 理解骨骼结构
当前角色使用的是Mixamo骨骼，经过Godot重定向后的骨骼名称：
- 右手骨骼名：`RightHand`（原Mixamo名：`mixamorig_RightHand`）

### 2.2 添加 BoneAttachment3D 节点
在 `Player.tscn` 中：

1. 展开 `Player` → `XBot` → `Skeleton` → `GeneralSkeleton`
2. 右键 `GeneralSkeleton` → 添加子节点 → 搜索 `BoneAttachment3D`
3. 选中新建的 `BoneAttachment3D` 节点：
   - 重命名为 `RightHandAttachment`
   - 在检查器中，设置 `Bone Name` 属性为 `RightHand`
4. 确保 `Override Pose` 保持关闭（让骨骼动画控制位置）

**节点结构：**
```
Player (CharacterBody3D)
├── XBot
│   └── Skeleton
│       └── GeneralSkeleton (Skeleton3D)
│           └── RightHandAttachment (BoneAttachment3D)  ← 新增
│               └── (武器将挂载在此处)
├── AnimationTree
└── ...
```

---

## 第三步：创建武器管理脚本

### 3.1 设计思路
创建一个专门管理武器的脚本，负责：
- 存储当前装备的武器引用
- 实现装备武器方法
- 实现卸下武器方法
- (可选) 切换武器方法

### 3.2 脚本实现思路（WeaponManager.gd）

**核心变量：**
```
- weapon_attachment: BoneAttachment3D 引用（右手挂载点）
- current_weapon: Node3D 当前装备的武器实例
- weapon_scenes: Dictionary 预加载的武器场景资源
```

**核心方法：**

**equip_weapon(weapon_name: String) → void**
1. 如果已有武器，先卸下
2. 根据weapon_name从weapon_scenes获取场景
3. 实例化武器场景
4. 将实例添加为weapon_attachment的子节点
5. 调整武器的局部Transform（位置、旋转偏移）
6. 保存引用到current_weapon
7. 发出武器装备信号（可选）

**unequip_weapon() → void**
1. 检查current_weapon是否存在
2. 从场景树中移除武器节点
3. 释放武器实例（queue_free）
4. 清空current_weapon引用
5. 发出武器卸下信号（可选）

**has_weapon() → bool**
- 返回 current_weapon != null

### 3.3 脚本挂载位置
两种方案：

**方案A：独立脚本（推荐）**
- 创建 `Scripts/weapon_manager.gd`
- 在Player节点下添加一个Node节点命名为 `WeaponManager`
- 将脚本挂载到此节点
- 通过 `@onready var weapon_manager = $WeaponManager` 在player.gd中访问

**方案B：集成到player.gd**
- 直接在player.gd中添加武器管理代码
- 适合简单项目，但耦合度高

---

## 第四步：调整武器Transform偏移

### 4.1 为什么需要调整
BoneAttachment3D会将子节点放置在骨骼的精确位置，但：
- 武器模型的原点可能不在握柄中心
- 握持角度需要微调
- 不同武器可能需要不同偏移

### 4.2 调整方法

**方法1：在武器场景中调整（推荐）**
1. 打开 `Sword.tscn`
2. 添加一个空的Node3D作为根节点
3. 将武器网格作为子节点
4. 调整子节点的Transform使原点对齐握柄

**方法2：在代码中调整**
```
# 装备武器后设置偏移
weapon_instance.position = Vector3(0, 0, 0.1)  # 位置偏移
weapon_instance.rotation_degrees = Vector3(-90, 0, 0)  # 角度偏移
```

### 4.3 调试技巧
1. 在编辑器中手动将武器场景拖入 `RightHandAttachment` 下
2. 播放持剑Idle动画（SwordAndShield/Idle.004）
3. 实时调整Transform直到握持姿势自然
4. 记录最终的Position和Rotation值
5. 将这些值写入代码或保存到武器场景

---

## 第五步：集成动画系统

### 5.1 当前动画状态
项目已有：
- Unarmed动画：Idle, Walking, Jump
- SwordAndShield动画：Idle.004

### 5.2 动画切换逻辑
在player.gd中，根据是否装备武器播放对应动画：

**思路：**
```
var is_armed: bool = false  # 是否持有武器

# 修改动画播放逻辑
if is_armed:
    if horizontal_speed > 0.1:
        play_anim("SwordAndShield_Walking")  # 需要添加
    else:
        play_anim("SwordAndShield_Idle_004")
else:
    # 原有的Unarmed动画逻辑
```

### 5.3 需要补充的动画
- SwordAndShield_Walking（持剑行走）
- SwordAndShield_Jump（持剑跳跃）

可从Mixamo下载对应动画，按现有流程导入。

---

## 第六步：添加输入控制

### 6.1 装备/卸下武器按键
建议使用 `E` 键或数字键切换：

**在player.gd中添加输入检测：**
```
# _physics_process 或 _input 中
if Input.is_action_just_pressed("equip_weapon"):  # 需要在项目设置中添加
    if weapon_manager.has_weapon():
        weapon_manager.unequip_weapon()
        is_armed = false
    else:
        weapon_manager.equip_weapon("sword")
        is_armed = true
```

### 6.2 配置Input Map
在 项目 → 项目设置 → 输入映射 中：
1. 添加动作 `equip_weapon`
2. 绑定按键 `E`

---

## 总结：实施步骤清单

| 步骤 | 任务 | 位置 |
|------|------|------|
| 1 | 创建 `Scenes/Weapons/` 文件夹 | 文件系统 |
| 2 | 导入并保存武器场景 `Sword.tscn` | Scenes/Weapons/ |
| 3 | 在Player骨骼下添加 `BoneAttachment3D` | Player.tscn |
| 4 | 创建 `weapon_manager.gd` 脚本 | Scripts/ |
| 5 | 在Player中添加WeaponManager节点 | Player.tscn |
| 6 | 修改player.gd集成武器状态 | Scripts/player.gd |
| 7 | 调整武器Transform偏移 | Sword.tscn 或代码 |
| 8 | 添加Input Map配置 | 项目设置 |
| 9 | 补充持剑动画（Walking, Jump） | 动画库 |

---

## 备选方案对比

### 方案A：BoneAttachment3D（推荐）
**优点：**
- Godot原生支持，无需额外代码
- 武器自动跟随骨骼动画
- 性能好

**缺点：**
- 需要知道骨骼名称

### 方案B：手动Transform跟随
**思路：** 每帧在代码中读取骨骼全局Transform并应用到武器

**优点：**
- 更灵活的控制

**缺点：**
- 需要每帧更新，性能稍差
- 代码复杂度高
- 可能有一帧延迟

### 方案C：将武器合并到角色模型
**思路：** 在Blender中将武器绑定到骨骼，导出为带武器的模型

**优点：**
- 无需运行时处理

**缺点：**
- 不灵活，无法运行时切换武器
- 需要为每种武器组合导出单独模型

**结论：方案A（BoneAttachment3D）是Godot中武器装备的标准做法，推荐使用。**
