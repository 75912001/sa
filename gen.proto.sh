#!/bin/bash

# 获取当前脚本文件所在路径的绝对路径
currentPath=$(realpath "$(dirname "$0")")
echo "currentPath:${currentPath}"

cd "${currentPath}" || exit

# Godot 可执行文件路径
GODOT_BIN="/c/Users/Administrator/Desktop/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64.exe"

# 检查 Godot 是否存在
if [ ! -f "$GODOT_BIN" ]; then
    echo "错误: Godot 未找到: $GODOT_BIN"
    echo "请修改脚本中的 GODOT_BIN 路径"
    exit 1
fi

# 插件脚本路径
CMD_SCRIPT="addons/protobuf/protobuf_cmdln.gd"
if [ ! -f "$CMD_SCRIPT" ]; then
    echo "错误: godobuf 插件未安装: $CMD_SCRIPT"
    exit 1
fi

# 输入和输出目录
INPUT_DIR="Pb"
OUTPUT_DIR="Scripts/Pb"
mkdir -p "$OUTPUT_DIR"

echo "Input: ./$INPUT_DIR"
echo "Output: ./$OUTPUT_DIR"

# 记录生成的文件
generated_files=()

# 遍历 .proto 文件并生成
for proto_file in "$INPUT_DIR"/*.proto; do
    if [ -f "$proto_file" ]; then
        filename=$(basename "$proto_file")
        name="${filename%.*}"
        output_file="$OUTPUT_DIR/$name.gd"

        echo "Processing: $filename -> $name.gd"
        "$GODOT_BIN" --headless -s "$CMD_SCRIPT" --input="$proto_file" --output="$output_file"

        if [ $? -ne 0 ]; then
            echo "❌ 编译失败: $filename"
        else
            generated_files+=("$output_file")
        fi
    fi
done

echo "✅ 生成完成！"
echo ""

# 修复 godobuf bug 的函数
fix_godobuf_bug() {
    local file="$1"
    local fix_count=0

    # 获取所有顶级 class 名称 (兼容 Windows Git Bash)
    local classes=$(grep "^class [A-Za-z_]*:" "$file" | sed 's/^class \([A-Za-z_]*\):.*/\1/')

    for cls in $classes; do
        # 统计修复次数 (使用 head -1 确保只取一个数字)
        local count=$(grep -c -- "-> [A-Za-z_]*\.$cls:" "$file" 2>/dev/null | head -1)
        count=${count:-0}
        if [ "$count" -gt 0 ] 2>/dev/null; then
            # 修复 "-> XXX.ClassName:" 为 "-> ClassName:"
            sed -i "s/-> [A-Za-z_]*\.$cls:/-> $cls:/g" "$file"
            fix_count=$((fix_count + count))
        fi
    done

    echo "$fix_count"
}

# 添加 class_name 的函数
add_class_name() {
    local file="$1"
    local basename=$(basename "$file" .gd)
    local class_name="Pb$basename"

    # 检查第一行是否已有 class_name
    local first_line=$(head -1 "$file")
    if [[ "$first_line" == class_name* ]]; then
        echo "skip"
        return
    fi

    # 在第一行插入 class_name
    sed -i "1i class_name $class_name" "$file"
    echo "added"
}

# 提示是否修复
read -p "是否修复生成文件中的 godobuf bug? (y/n): " answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    echo ""
    echo "正在修复..."

    total_fixes=0
    class_added=0
    for file in "${generated_files[@]}"; do
        if [ -f "$file" ]; then
            fixes=$(fix_godobuf_bug "$file")
            if [ "$fixes" -gt 0 ]; then
                echo "  修复 $(basename "$file"): $fixes 处"
                total_fixes=$((total_fixes + fixes))
            fi

            # 添加 class_name
            result=$(add_class_name "$file")
            if [ "$result" = "added" ]; then
                echo "  添加 class_name: $(basename "$file")"
                class_added=$((class_added + 1))
            fi
        fi
    done

    if [ "$total_fixes" -gt 0 ] || [ "$class_added" -gt 0 ]; then
        echo ""
        echo "✅ 修复完成！共修复 $total_fixes 处，添加 $class_added 个 class_name"
    else
        echo "✅ 无需修复"
    fi
else
    echo "跳过修复"
fi

echo ""
read -n 1 -s -r -p "按任意键结束..."
echo ""
