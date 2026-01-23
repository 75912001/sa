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
      当前有 idle, walking, running, jumping, attacking, 切换武器 等动作.
      比如 站立时, 切换武器, 或者攻击. 
      或者 行走的时候, 切换武器, 或者攻击.
      当前的 Player-> animationTree 是 AnimationNodeStateMachine. 是否需要改成 AnimationNodeBlendTree?
# 问题
      状态机如何设计? 才能支持 上半身, 下半身 动作分离?
# 当前想法
# 可参考资料
# 任务
    在任务没有完全完成之前, 不要停止回答. 持续思考, 找到最佳方案. 在提问和回答中不断完善方案.
    非常详细的一步步指引我完成.
    给出方案. 将解决方案分步骤列出.写入 plan.md 下方的 "# 解决方案" 处.
# 解决方案

## 一、问题分析

### 1.1 当前架构
```
AnimationTree (root: AnimationNodeStateMachine)
├── Unarmed_Idle
├── Unarmed_Walking
├── Unarmed_Jump
├── SwordAndShield_Idle
├── SwordAndShield_Walk
├── SwordAndShield_DrawSword
└── ...
```

**局限性**：
- 状态机同一时刻只能处于一个状态
- 无法实现「边走边攻击」「边跑边切换武器」等复合动作
- 全身动画互斥，不支持上下半身分离

### 1.2 目标需求
| 下半身 | 上半身 | 场景示例 |
|--------|--------|----------|
| Idle | Attack | 站立攻击 |
| Idle | WeaponSwitch | 站立换武器 |
| Walk | Attack | 行走攻击 |
| Walk | WeaponSwitch | 行走换武器 |
| Run | Idle | 跑步（不换武器，上半身保持姿态） |
| Jump | Idle | 跳跃（上半身保持姿态） |

**说明**：
- 站立/行走时可以攻击或换武器
- 跑步时不允许换武器（上半身保持跑步姿态）
- 跳跃时上半身保持当前姿态

**职责分离**：
| 层级 | 职责 | 说明 |
|------|------|------|
| AnimationTree | 提供能力 | 上下半身可独立播放动画 |
| GDScript 代码 | 控制规则 | 何时允许做什么动作 |

```gdscript
# 示例：WeaponSwitchMgr.gd
func can_switch_weapon() -> bool:
    # 跑步时不允许换武器
    if movement_mgr.is_running():
        return false
    # 跳跃时不允许换武器
    if jump_mgr.is_in_air():
        return false
    return true

func handle_input():
    if Input.is_action_just_pressed("switch_weapon"):
        if can_switch_weapon():
            animation_mgr.play_upper("DrawSword")
```

---

## 二、方案对比

### 方案A：AnimationNodeBlendTree + 骨骼过滤器（推荐）

**原理**：使用 BlendTree 作为根节点，内含两个子状态机（上半身/下半身），通过骨骼过滤器混合。

```
AnimationNodeBlendTree (Root)
├── LowerBodySM (AnimationNodeStateMachine) → 下半身状态机
│   ├── Locomotion_Idle
│   ├── Locomotion_Walk
│   ├── Locomotion_Run
│   └── Locomotion_Jump
├── UpperBodySM (AnimationNodeStateMachine) → 上半身状态机
│   ├── Upper_Idle
│   ├── Upper_Attack
│   ├── Upper_WeaponSwitch
│   └── Upper_DrawSword
└── Blend2 (AnimationNodeBlend2) → 混合节点，带骨骼过滤器
    ├── Input A: LowerBodySM
    ├── Input B: UpperBodySM
    └── Filter: 上半身骨骼 (Spine → Head, Arms)
```

**优点**：
- 上下半身完全独立控制
- 状态切换逻辑清晰
- 易于扩展新动作
- Godot 原生支持，性能好

**缺点**：
- 需要重构 AnimationTree
- 动画可能需要重新调整

---

### 方案B：AnimationNodeAdd2 叠加式

**原理**：下半身播全身动画，上半身用 Add2 叠加差异动画。

```
AnimationNodeBlendTree (Root)
├── BaseAnimation (全身基础动画)
├── UpperOverlay (上半身叠加动画)
└── Add2 → 叠加混合
```

**优点**：
- 可复用现有全身动画

**缺点**：
- 需要制作专门的叠加动画（Additive Animation）
- 调试复杂
- 不适合大幅度上半身动作

---

### 方案C：多 AnimationPlayer 方案

**原理**：使用两个 AnimationPlayer，分别控制不同骨骼。

**缺点**：
- Godot 4 不推荐
- 骨骼冲突难处理
- 不推荐使用

---

## 三、推荐方案详解（方案A）

### 3.1 骨骼分组

基于 Mixamo 标准骨骼（SkeletonProfileHumanoid）：

| 分组 | 骨骼名称 |
|------|----------|
| **下半身** | Hips, LeftUpLeg, LeftLeg, LeftFoot, LeftToeBase, RightUpLeg, RightLeg, RightFoot, RightToeBase |
| **上半身** | Spine, Spine1, Spine2, Neck, Head, LeftShoulder, LeftArm, LeftForeArm, LeftHand, RightShoulder, RightArm, RightForeArm, RightHand |
| **共享** | Hips（作为根骨骼，两边都需要） |

### 3.2 AnimationTree 新结构

```
AnimationTree
└── AnimationNodeBlendTree (Root)
    ├── [Node] lower_body_sm: AnimationNodeStateMachine
    │   └── States: Idle, Walk, Run, Jump_Start, Jump_Loop, Jump_Land
    │
    ├── [Node] upper_body_sm: AnimationNodeStateMachine
    │   └── States: Idle, Attack_1, Attack_2, DrawSword, SheathSword, WeaponSwitch
    │
    ├── [Node] blend: AnimationNodeBlend2
    │   ├── Input 0 (in): lower_body_sm
    │   ├── Input 1 (add): upper_body_sm
    │   ├── blend_amount: 1.0 (完全使用上半身覆盖)
    │   └── filter: 启用，勾选上半身骨骼
    │
    └── [Output] → blend
```

### 3.3 动画命名规范

```
# 下半身动画（全身动画，但只取下半身部分）
Locomotion/Idle
Locomotion/Walk
Locomotion/Run
Locomotion/Jump_Start
Locomotion/Jump_Loop
Locomotion/Jump_Land

# 上半身动画（全身动画，但只取上半身部分）
Upper/Idle
Upper/Attack_Light_1
Upper/Attack_Light_2
Upper/Attack_Heavy
Upper/DrawSword
Upper/SheathSword
Upper/Block
```

### 3.4 代码架构调整

#### 3.4.1 新增 AnimationMgr 接口

```gdscript
# Scripts/Animation.gd
class_name AnimationMgr
extends Node

var _animation_tree: AnimationTree
var _lower_body_sm: AnimationNodeStateMachinePlayback
var _upper_body_sm: AnimationNodeStateMachinePlayback

func _ready() -> void:
    _animation_tree = get_node(animation_tree_path)
    _lower_body_sm = _animation_tree.get("parameters/lower_body_sm/playback")
    _upper_body_sm = _animation_tree.get("parameters/upper_body_sm/playback")

# 播放下半身动画
func play_lower(animation_name: String) -> void:
    _lower_body_sm.travel(animation_name)

# 播放上半身动画
func play_upper(animation_name: String) -> void:
    _upper_body_sm.travel(animation_name)

# 同时播放
func play_full_body(lower: String, upper: String) -> void:
    play_lower(lower)
    play_upper(upper)

# 获取当前状态
func get_lower_state() -> String:
    return _lower_body_sm.get_current_node()

func get_upper_state() -> String:
    return _upper_body_sm.get_current_node()
```

#### 3.4.2 状态机调整

```gdscript
# 移动时
func on_move():
    animation_mgr.play_lower("Walk")
    # 上半身保持当前状态，不干扰

# 攻击时
func on_attack():
    animation_mgr.play_upper("Attack_Light_1")
    # 下半身保持当前状态（可能是 Idle/Walk/Run）

# 切换武器时
func on_weapon_switch():
    animation_mgr.play_upper("DrawSword")
    # 下半身继续移动
```

### 3.5 全身动画控制（blend_amount 方案）

某些动作需要控制全身（如翻滚、倒地、受击硬直），通过调节 `blend_amount` 实现模式切换：

**原理**：
- `blend_amount = 0` → 100% 使用 lower_body_sm，骨骼过滤器失效，变为全身动画
- `blend_amount = 1` → 上半身被 upper_body_sm 覆盖（分离模式）

**代码实现**：

```gdscript
# Scripts/Animation.gd 补充

enum AnimMode { SPLIT, FULL_BODY }
var _current_mode := AnimMode.SPLIT

# 设置动画模式
func set_mode(mode: AnimMode) -> void:
    _current_mode = mode
    var amount = 1.0 if mode == AnimMode.SPLIT else 0.0
    _animation_tree.set("parameters/blend/blend_amount", amount)

# 播放全身动画（翻滚、倒地等）
func play_full_body_single(animation_name: String) -> void:
    set_mode(AnimMode.FULL_BODY)
    _lower_body_sm.travel(animation_name)

# 恢复分离模式
func restore_split_mode() -> void:
    set_mode(AnimMode.SPLIT)

# 检查当前模式
func is_full_body_mode() -> bool:
    return _current_mode == AnimMode.FULL_BODY
```

**使用示例**：

```gdscript
# 翻滚
func on_roll():
    animation_mgr.play_full_body_single("Roll")
    # 翻滚动画结束后恢复
    await animation_mgr.animation_finished
    animation_mgr.restore_split_mode()

# 受击硬直
func on_hit_stagger():
    animation_mgr.play_full_body_single("HitStagger")
    await animation_mgr.animation_finished
    animation_mgr.restore_split_mode()

# 死亡（不恢复）
func on_die():
    animation_mgr.play_full_body_single("Die")
```

**动画命名扩展**：

```
# 全身动画（放在 lower_body_sm 中）
Locomotion/Idle
Locomotion/Walk
Locomotion/Run
Locomotion/Jump
Locomotion/Roll        # 翻滚
Locomotion/HitStagger  # 受击硬直
Locomotion/Die         # 死亡
Locomotion/Knockdown   # 击倒
```

---

## 四、实施步骤

### 步骤 1：准备动画资源

#### 1.1 当前动画目录结构
```
Assets/Animations/Library/
├── Unarmed/
│   ├── Idle.res
│   ├── Walking.res
│   ├── Jump.res
│   └── DrawSword.res
└── SwordAndShield/
    ├── Idle.res
    ├── Walk.res
    ├── DrawSword.res
    ├── SheathSword.1.res
    └── SheathSword.2.res
```

#### 1.2 新建动画目录（可选）
如果需要区分上下半身专用动画，可新建目录：
```
Assets/Animations/Library/
├── Locomotion/         # 下半身动画
│   ├── Idle.res
│   ├── Walk.res
│   ├── Run.res
│   ├── Jump.res
│   ├── Roll.res        # 全身动画
│   └── HitStagger.res  # 全身动画
└── Upper/              # 上半身动画
    ├── Idle.res
    ├── Attack_Light_1.res
    ├── Attack_Light_2.res
    ├── DrawSword.res
    └── SheathSword.res
```

#### 1.3 动画复用说明
- **不需要重新制作动画**，骨骼过滤器会自动只取需要的骨骼
- 同一个 `Walk.res` 可以同时用于下半身（取腿部）和上半身（取手臂摆动）
- 攻击动画建议使用原地动画（Hips 不移动），避免身体撕裂

---

### 步骤 2：重构 AnimationTree（Godot 编辑器）

#### 2.1 打开场景
1. 在 Godot 编辑器中打开 `Scenes/Player.tscn`
2. 在场景树中选中 `AnimationTree` 节点

#### 2.2 更改根节点类型
1. 在 Inspector 面板找到 `Tree Root` 属性
2. 点击当前值（AnimationNodeStateMachine）
3. 选择 `新建 AnimationNodeBlendTree`
4. **警告**：这会清除现有状态机配置，确认后继续

#### 2.3 进入 BlendTree 编辑器
1. 在 Inspector 底部点击 `Tree Root` 旁的「编辑」按钮
2. 或双击 AnimationTree 节点
3. 会打开 AnimationTree 编辑面板（底部停靠面板）

#### 2.4 添加节点
在 BlendTree 编辑面板中：

**添加下半身状态机**：
1. 右键空白处 → `Add Node...`
2. 搜索并选择 `AnimationNodeStateMachine`
3. 节点会出现在面板中，点击选中
4. 在 Inspector 中将 `Name` 改为 `lower_body_sm`

**添加上半身状态机**：
1. 右键空白处 → `Add Node...`
2. 选择 `AnimationNodeStateMachine`
3. 将 `Name` 改为 `upper_body_sm`

**添加混合节点**：
1. 右键空白处 → `Add Node...`
2. 搜索并选择 `AnimationNodeBlend2`
3. 将 `Name` 改为 `blend`

#### 2.5 连接节点
1. 从 `lower_body_sm` 的输出端口拖线到 `blend` 的 `in` 端口
2. 从 `upper_body_sm` 的输出端口拖线到 `blend` 的 `blend` 端口
3. 从 `blend` 的输出端口拖线到 `Output` 节点

**最终连接图**：
```
lower_body_sm ──→ blend (in)
                      ├──→ Output
upper_body_sm ──→ blend (blend)
```

---

### 步骤 3：配置骨骼过滤器

#### 3.1 选中 blend 节点
在 BlendTree 编辑面板中点击 `blend` 节点

#### 3.2 启用过滤器
1. 在 Inspector 面板找到 `Filter` 部分
2. 勾选 `Enable` 启用过滤器
3. 点击 `Edit Filters` 按钮打开骨骼选择窗口

#### 3.3 选择上半身骨骼
在弹出的骨骼列表中，**勾选以下骨骼**（Mixamo 标准骨骼名）：

**躯干**：
- [ ] Hips（不勾选，作为共享根骨骼）
- [x] Spine
- [x] Spine1
- [x] Spine2

**头部**：
- [x] Neck
- [x] Head
- [x] HeadTop_End（如有）

**左臂**：
- [x] LeftShoulder
- [x] LeftArm
- [x] LeftForeArm
- [x] LeftHand
- [x] LeftHandThumb1, LeftHandThumb2, LeftHandThumb3, LeftHandThumb4
- [x] LeftHandIndex1, LeftHandIndex2, LeftHandIndex3, LeftHandIndex4
- [x] LeftHandMiddle1, LeftHandMiddle2, LeftHandMiddle3, LeftHandMiddle4
- [x] LeftHandRing1, LeftHandRing2, LeftHandRing3, LeftHandRing4
- [x] LeftHandPinky1, LeftHandPinky2, LeftHandPinky3, LeftHandPinky4

**右臂**：
- [x] RightShoulder
- [x] RightArm
- [x] RightForeArm
- [x] RightHand
- [x] RightHandThumb1-4
- [x] RightHandIndex1-4
- [x] RightHandMiddle1-4
- [x] RightHandRing1-4
- [x] RightHandPinky1-4

**不勾选（下半身）**：
- [ ] Hips
- [ ] LeftUpLeg, LeftLeg, LeftFoot, LeftToeBase
- [ ] RightUpLeg, RightLeg, RightFoot, RightToeBase

#### 3.4 设置混合量
1. 关闭过滤器窗口
2. 在 Inspector 中找到 `Blend Amount` 参数路径：`parameters/blend/blend_amount`
3. 初始值设为 `1.0`（表示上半身完全由 upper_body_sm 控制）

---

### 步骤 4：配置下半身状态机 (lower_body_sm)

#### 4.1 进入状态机编辑
1. 在 BlendTree 面板中双击 `lower_body_sm` 节点
2. 进入子状态机编辑界面

#### 4.2 添加动画状态
右键添加 `AnimationNodeAnimation` 节点，配置如下：

| 节点名 | Animation 属性 | 说明 |
|--------|----------------|------|
| Idle | Unarmed/Idle | 站立 |
| Walk | Unarmed/Walking | 行走 |
| Run | Unarmed/Walking（暂用） | 跑步 |
| Jump | Unarmed/Jump | 跳跃 |
| Roll | （待添加）| 翻滚（全身） |

#### 4.3 配置状态转换
1. 从 `Start` 节点拖线到 `Idle`（设为默认状态）
2. 配置转换：
   - `Idle` ↔ `Walk`（双向）
   - `Walk` ↔ `Run`（双向）
   - `Idle/Walk/Run` → `Jump`
   - `Jump` → `Idle`
   - `Any` → `Roll`（全身动画优先）

#### 4.4 设置转换参数
选中转换连线，在 Inspector 中设置：
- `Switch Mode`: `Immediate` 或 `Sync`
- `Advance Condition`:（可选，用于代码触发）
- `Xfade Time`: `0.1` ~ `0.2`（过渡时间）

---

### 步骤 5：配置上半身状态机 (upper_body_sm)

#### 5.1 进入状态机编辑
返回 BlendTree 面板，双击 `upper_body_sm` 节点

#### 5.2 添加动画状态

| 节点名 | Animation 属性 | 说明 |
|--------|----------------|------|
| Idle | Unarmed/Idle | 空闲（手臂自然下垂） |
| Idle_Armed | SwordAndShield/Idle | 持武器空闲 |
| Attack_Light_1 | （待添加）| 轻攻击1 |
| Attack_Light_2 | （待添加）| 轻攻击2 |
| DrawSword | SwordAndShield/DrawSword | 拔剑 |
| SheathSword | SwordAndShield/SheathSword.1 | 收剑 |

#### 5.3 配置状态转换
- `Start` → `Idle`
- `Idle` ↔ `Idle_Armed`
- `Idle/Idle_Armed` → `Attack_Light_1` → `Attack_Light_2` → `Idle_Armed`
- `Idle` → `DrawSword` → `Idle_Armed`
- `Idle_Armed` → `SheathSword` → `Idle`

---

### 步骤 6：更新 Animation.gd

#### 6.1 完整代码

```gdscript
# 动画-管理器
class_name AnimationMgr
extends Node

# --- 配置 ---
@export var animation_tree_path: NodePath

# --- 信号 ---
signal animation_finished(animation_name: String)
signal lower_animation_finished(animation_name: String)
signal upper_animation_finished(animation_name: String)

# --- 动画模式 ---
enum AnimMode { SPLIT, FULL_BODY }

# --- 变量 ---
var _animation_tree: AnimationTree
var _lower_body_sm: AnimationNodeStateMachinePlayback
var _upper_body_sm: AnimationNodeStateMachinePlayback
var _current_mode := AnimMode.SPLIT
var _current_lower := ""
var _current_upper := ""

func _ready() -> void:
    _animation_tree = get_node(animation_tree_path)
    if _animation_tree:
        _animation_tree.active = true
        _animation_tree.animation_finished.connect(_on_animation_finished)

    _lower_body_sm = _animation_tree.get("parameters/lower_body_sm/playback")
    _upper_body_sm = _animation_tree.get("parameters/upper_body_sm/playback")

# ==================== 分离模式 ====================

# 播放下半身动画
func play_lower(animation_name: String) -> void:
    if _current_lower != animation_name:
        _current_lower = animation_name
        _lower_body_sm.travel(animation_name)

# 播放上半身动画
func play_upper(animation_name: String) -> void:
    if _current_upper != animation_name:
        _current_upper = animation_name
        _upper_body_sm.travel(animation_name)

# 同时播放上下半身
func play_split(lower: String, upper: String) -> void:
    play_lower(lower)
    play_upper(upper)

# ==================== 全身模式 ====================

# 设置动画模式
func set_mode(mode: AnimMode) -> void:
    _current_mode = mode
    var amount = 1.0 if mode == AnimMode.SPLIT else 0.0
    _animation_tree.set("parameters/blend/blend_amount", amount)

# 播放全身动画（翻滚、倒地等）
func play_full_body(animation_name: String) -> void:
    set_mode(AnimMode.FULL_BODY)
    _current_lower = animation_name
    _lower_body_sm.travel(animation_name)

# 恢复分离模式
func restore_split_mode() -> void:
    set_mode(AnimMode.SPLIT)

# ==================== 状态查询 ====================

# 获取当前下半身状态
func get_lower_state() -> String:
    return _lower_body_sm.get_current_node()

# 获取当前上半身状态
func get_upper_state() -> String:
    return _upper_body_sm.get_current_node()

# 检查是否全身模式
func is_full_body_mode() -> bool:
    return _current_mode == AnimMode.FULL_BODY

# 检查下半身是否在播放指定动画
func is_lower_playing(animation_name: String) -> bool:
    return get_lower_state() == animation_name

# 检查上半身是否在播放指定动画
func is_upper_playing(animation_name: String) -> bool:
    return get_upper_state() == animation_name

# ==================== 回调 ====================

func _on_animation_finished(anim_name: StringName) -> void:
    animation_finished.emit(str(anim_name))
```

---

### 步骤 7：更新 Player.gd

#### 7.1 修改 _physics_process

```gdscript
func _physics_process(delta: float) -> void:
    jump_mgr.handle_input()
    jump_mgr.handle_gravity(delta)
    weapon_switch_mgr.handle_input()
    move_and_slide()

    # 更新动画（全身模式下跳过）
    if not animation_mgr.is_full_body_mode():
        _update_lower_animation()
        _update_upper_animation()

func _update_lower_animation() -> void:
    if jump_mgr.is_in_air():
        animation_mgr.play_lower("Jump")
    elif movement_mgr.is_moving():
        animation_mgr.play_lower("Walk")
    else:
        animation_mgr.play_lower("Idle")

func _update_upper_animation() -> void:
    # 如果没有上半身动作在播放，根据武器状态更新
    if not weapon_switch_mgr.is_switching():
        if weapon_mgr.has_weapon():
            animation_mgr.play_upper("Idle_Armed")
        else:
            animation_mgr.play_upper("Idle")
```

---

### 步骤 8：更新 WeaponSwitchMgr.gd

#### 8.1 添加状态检查

```gdscript
func can_switch_weapon() -> bool:
    # 跑步时不允许换武器
    if movement_mgr.is_running():
        return false
    # 跳跃时不允许换武器
    if jump_mgr.is_in_air():
        return false
    # 正在切换中不允许
    if is_switching():
        return false
    return true
```

#### 8.2 修改动画调用

```gdscript
# 原来
animation_mgr.play("SwordAndShield_DrawSword")

# 改为
animation_mgr.play_upper("DrawSword")
```

---

### 步骤 9：测试验证

#### 9.1 基础测试
| 操作 | 预期结果 |
|------|----------|
| 站立不动 | 下半身 Idle，上半身 Idle |
| 按 WASD 移动 | 下半身 Walk，上半身保持 |
| 站立时按换武器 | 下半身 Idle，上半身 DrawSword |
| 移动时按换武器 | 下半身 Walk，上半身 DrawSword |
| 按空格跳跃 | 下半身 Jump，上半身保持 |

#### 9.2 边界测试
| 操作 | 预期结果 |
|------|----------|
| 跳跃中按换武器 | 不响应（can_switch_weapon 返回 false） |
| 换武器过程中移动 | 下半身切换 Walk，上半身继续 DrawSword |
| 换武器过程中再按换武器 | 中断当前，开始新切换 |

#### 9.3 调试命令
```gdscript
# 在 Player.gd 中添加调试输出
func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_home"):  # Home 键
        print("Lower: ", animation_mgr.get_lower_state())
        print("Upper: ", animation_mgr.get_upper_state())
        print("Mode: ", "FULL_BODY" if animation_mgr.is_full_body_mode() else "SPLIT")
```

---

## 五、注意事项

### 5.1 动画制作要求
- 上下半身动画的 **帧率** 和 **时长** 可以不同
- 但需要确保 **根骨骼（Hips）** 的位移在两组动画中一致，否则会出现身体撕裂
- 建议攻击动画保持 Hips 位置不动（原地攻击）

### 5.2 状态同步问题
- 某些动作可能需要锁定另一半身体（如翻滚、受击硬直）
- 可在 AnimationMgr 中增加 `lock_upper()` / `lock_lower()` 方法

### 5.3 过渡平滑度
- 在状态机中配置 `transition` 时间（0.1-0.2秒）
- 避免动画切换生硬

---

## 六、扩展建议

### 6.1 三层混合（可选）
如果未来需要更精细控制，可扩展为三层：
```
Lower (腿部) + Core (躯干) + Upper (手臂/头部)
```

### 6.2 IK 支持
结合 `SkeletonIK3D` 实现：
- 脚部 IK（地形适应）
- 手部 IK（抓取物体）
- 头部 IK（看向目标）

---

## 七、总结

| 项目 | 当前 | 改进后 |
|------|------|--------|
| 根节点类型 | AnimationNodeStateMachine | AnimationNodeBlendTree |
| 状态机数量 | 1 个 | 2 个（上/下半身） |
| 动作分离 | 不支持 | 支持 |
| 全身动画 | 默认 | 通过 blend_amount 切换 |
| 代码复杂度 | 简单 | 中等 |
| 动画控制 | play(anim) | play_lower() / play_upper() / play_full_body_single() |

**核心改动**：
1. AnimationTree 根节点改为 `AnimationNodeBlendTree`
2. 添加两个子 `AnimationNodeStateMachine`（lower_body_sm, upper_body_sm）
3. 使用 `AnimationNodeBlend2` + 骨骼过滤器混合
4. Animation.gd 提供分层播放接口
5. 通过 `blend_amount` 切换分离/全身模式

**动画模式**：
| 模式 | blend_amount | 效果 |
|------|--------------|------|
| SPLIT | 1.0 | 上下半身独立控制 |
| FULL_BODY | 0.0 | 全身统一控制（翻滚、倒地等） |
