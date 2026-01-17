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
      切换武器时,没有拔剑的动作,直接切换
# 问题
      切换武器时,动作不自然,需要增加拔剑动作.
      Unarmed -> Sword
      Sword -> Sword
# 当前想法
      Unarmed -> Sword : 空手->持剑
         播放拔剑动作
            D:\sa\Assets\Animations\Library\Unarmed\DrawSword.res 空手,去握剑柄
         播放拔剑动作
            D:\sa\Assets\Animations\Library\SwordAndShield\DrawSword.res 拔剑动作,动画播放开始时装备武器
      Sword -> Sword : 持剑->持剑
         播放收剑动作
         D:\sa\Assets\Animations\Library\SwordAndShield\SheathSword.1.res 收剑动作,动画播放结束时-卸下武器
         播放拔剑动作
         D:\sa\Assets\Animations\Library\SwordAndShield\DrawSword.res 拔剑动作,动画播放开始时-装备武器
      Sword -> Unarmed : 持剑->空手
         播放收剑动作
         D:\sa\Assets\Animations\Library\SwordAndShield\SheathSword.1.res 收剑动作,动画播放结束时-卸下武器
         恢复空手状态
         D:\sa\Assets\Animations\Library\SwordAndShield\SheathSword.2.res
# 可参考资料
# 任务
    非常详细的一步步指引我完成.
    给出方案. 将解决方案分步骤列出.写入 plan.md 下方的 "# 解决方案" 处.
# 解决方案

