extends Node
# 动画-管理器
class_name AnimationMgr

@export var animation_tree_path: NodePath

var animation_tree: AnimationTree
var state_machine: AnimationNodeStateMachinePlayback

var current_animation_name := "" # 当前动画

func _ready() -> void:
	animation_tree = get_node(animation_tree_path)
	if animation_tree: # 激活 AnimationTree
		animation_tree.active = true
	state_machine = animation_tree.get("parameters/playback")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func play(animation_name: String) -> void:
	if current_animation_name != animation_name:
		current_animation_name = animation_name
		state_machine.travel(animation_name)
