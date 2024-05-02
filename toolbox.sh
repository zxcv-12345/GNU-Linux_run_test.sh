#!/bin/bash

# 定义菜单
menu="
1. 安装工具
2. 跑分测试
3. speedtest 国内网络测试
4. 跑路工具(不开玩笑！慎用！)
0. 退出
"

# 显示菜单
echo "$menu"

# 循环，直到用户选择退出
while true; do
    # 提示用户输入选项
    read -p "请输入选项数字: " choice

    case $choice in
        1)
            echo "安装工具"
            # 在这里添加工具1的命令
            ;;
        2)
            echo "跑分测试"
            bash <(wget -qO- https://down.vpsaff.net/linux/speedtest/superbench.sh) -f Speedtest
            ;;
        3)
            echo "speedtest 国内网络测试"
            bash <(wget -qO- https://down.vpsaff.net/linux/speedtest/superbench.sh) --speed
            ;;
        4)
            echo "跑路工具(不开玩笑！慎用！)"
            # 在这里添加工具4的命令
            ;;
        0)
            # 退出
            echo "退出脚本"
            exit 0
            ;;
        *)
            echo "无效选项，请重新输入"
            ;;
    esac
done
