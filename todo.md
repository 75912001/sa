状态              左               右             
idle 


状态机
角色同一时刻, 只能处于一个状态
当前状态有
	idle
	walking
	jumping(只包括起跳和落地. 空中可以攻击)
	attacking
	running
	被击中
	倒地

	move

idle
move
jump
attack

one state active at a time 


stateMachine Brain
1. runs the current state every frame
2. Switches states when told to



State Machine

StateMachine brain
BaseState
IdleState
WalkingState
JumpingState
AttackingState
RunningState
HurtState
DownState



手拿武器.
	增加拿剑的 walking 动画
	是否需要使用对应的动画? 比如拿剑, 使用拿剑的walking动画, idle动画等.

手拿盾牌


可以没有剑鞘
但是要有动作




多次按攻击，有多个连续的动作，上一个动作未完成，就可以接下去

2.8
9.3
2.8
10.4
1.7

攻击向前一步


跳跃的前摇很短，可以移动
落地就可再次跳跃






草地

# 阻挡与碰撞
## 树木/石头： 在图片的位置放一个 StaticBody3D + CylinderShape3D (圆柱体)。
## 原理： Godot 的物理引擎会自动处理 3D 碰撞，角色再也不会出现“头穿过树干”或者“脚踩在树顶”的视觉错误（Z-Fighting），因为它们在 Z 轴（或 Godot 3D 的 Y 轴）上有真实的距离。


问题:
怎么消除走路时候, 持续按住前进的"滑行"感?   分析原因,给出解决方案


左右移动的速度, 比 上下 移动的速度 更快一些


跳跃动作有点搞笑. 前摇时间, 落地时间 ...
