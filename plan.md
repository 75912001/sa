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
| Walk | Attack | 行走攻击 |
| Run | WeaponSwitch | 跑步中切换武器 |
| Jump | Idle | 跳跃（上半身保持姿态） |

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

---

## 四、实施步骤

### 步骤 1：准备动画资源
1. 将现有动画复制到新目录结构：
   ```
   Assets/Animations/Library/
   ├── Locomotion/    # 下半身/移动动画
   │   ├── Idle.res
   │   ├── Walk.res
   │   └── Jump.res
   └── Upper/         # 上半身动画
       ├── Idle.res
       ├── Attack.res
       └── DrawSword.res
   ```
2. 注意：可以复用同一个动画文件，骨骼过滤器会自动只取需要的部分

### 步骤 2：重构 AnimationTree（在 Godot 编辑器中）
1. 打开 `Player.tscn`
2. 选中 `AnimationTree` 节点
3. 将 `tree_root` 从 `AnimationNodeStateMachine` 改为 `AnimationNodeBlendTree`
4. 在 BlendTree 中添加节点：
   - 添加 `AnimationNodeStateMachine`，命名为 `lower_body_sm`
   - 添加 `AnimationNodeStateMachine`，命名为 `upper_body_sm`
   - 添加 `AnimationNodeBlend2`，命名为 `blend`
5. 连接节点：
   - `lower_body_sm` → `blend` (Input 0)
   - `upper_body_sm` → `blend` (Input 1)
   - `blend` → `Output`

### 步骤 3：配置骨骼过滤器
1. 选中 `blend` 节点
2. 在 Inspector 中启用 `Filter`
3. 点击 `Edit Filters`
4. 勾选上半身骨骼：
   - Spine, Spine1, Spine2
   - Neck, Head
   - LeftShoulder, LeftArm, LeftForeArm, LeftHand, LeftHandThumb1-4, LeftHandIndex1-4...
   - RightShoulder, RightArm, RightForeArm, RightHand...
5. 设置 `blend_amount` 为 `1.0`

### 步骤 4：配置子状态机
1. 双击 `lower_body_sm` 进入编辑
2. 添加状态：Idle, Walk, Run, Jump
3. 配置状态转换
4. 同理配置 `upper_body_sm`

### 步骤 5：更新 Animation.gd
按 3.4.1 节代码修改

### 步骤 6：更新 Player.gd 和各 Manager
- MovementMgr：调用 `play_lower()`
- WeaponSwitchMgr：调用 `play_upper()`
- AttackMgr（新增）：调用 `play_upper()`

### 步骤 7：测试验证
1. 站立时攻击 → 上半身攻击，下半身 Idle
2. 行走时攻击 → 上半身攻击，下半身 Walk
3. 行走时切换武器 → 上半身 DrawSword，下半身 Walk
4. 跳跃时 → 下半身 Jump，上半身保持

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
| 代码复杂度 | 简单 | 中等 |
| 动画控制 | play(anim) | play_lower(anim) / play_upper(anim) |

**核心改动**：
1. AnimationTree 根节点改为 `AnimationNodeBlendTree`
2. 添加两个子 `AnimationNodeStateMachine`
3. 使用 `AnimationNodeBlend2` + 骨骼过滤器混合
4. Animation.gd 提供分层播放接口
