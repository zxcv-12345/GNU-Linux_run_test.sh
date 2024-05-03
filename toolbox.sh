#!/bin/bash

# 定义菜单
menu="
1. 安装工具
2. 运维工具
3. DD系统
4. 跑分&测试
5. 跑路工具(不开玩笑！慎用！)
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
            1. 更新apt列表并安装wget、curl
            2. 安装可视化路由追踪工具 -- NextTrace
            3. 安装1panel面板
            4. 安装宝塔纯净版面板
            0. 返回上级菜单
            "
            echo "$tool_menu"
            read -p "请输入子菜单选项数字: " tool_choice
            case $tool_choice in
                1)
                    echo "update apt and install wget curl"
                    apt update -y && apt install -y curl wget 
                    ;;
                2)
                    # 子菜单，用于安装可视化路由追踪工具 -- NextTrace
                    install_NextTrace_menu="
                    1. china
                    2. word not china
                    0. 返回上级菜单
                    "
                    echo "$install_NextTrace_menu"
                    read -p "请输入子菜单选项数字: " install_NextTrace_choice
                    case $install_NextTrace_choice in
                        1)
                            echo "install NextTrace"
                            bash <(curl -Ls https://ghproxy.com/https://raw.githubusercontent.com/sjlleo/nexttrace/main/nt_install.sh)
                            ;;
                        2)
                            echo "install NextTrace"
                            bash <(curl -Ls https://raw.githubusercontent.com/sjlleo/nexttrace/main/nt_install.sh)
                            ;;
                        0)
                            echo "返回上级菜单"
                            echo "$tool_menu"
                            ;;
                        *)
                            echo "无效选项，请重新输入"
                            echo "$install_NextTrace_menu"
                            ;;
                    esac
                    ;;
                3)
                    echo "安装1panel面板"
                    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
                    ;;
                4)
                    echo "安装bt面板"
                    wget -O install.sh https://raw.githubusercontent.com/DanKE123abc/BTpanel7.7/main/install_6.0_mod.sh && bash install.sh
                    ;;
                0)
                    echo "返回上级菜单"
                    echo "$menu"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    echo "$tool_menu"
                    ;;
            esac
            ;;
        2)
            # 子菜单，用于运维工具
            maintenance_menu="
            1. 自动清理内核
            2. 查看已安装内核
            3. 查看当前使用的内核
            4. 查看当前目录下排名前五的大文件
            0. 返回上级菜单
            "
            echo "$maintenance_menu"
            read -p "请输入子菜单选项数字: " maintenance_choice
            case $maintenance_choice in
                1)
                    echo "自动清理内核"
                    sudo apt-get autoremove --purge
                    ;;
                2)
                    echo "查看已安装内核"
                    dpkg --list | grep linux-image 
                    ;;
                3)
                    echo "查看当前使用的内核"
                    uname -r
                    ;;    
                4)
                    echo "查看当前目录下排名前五的大文件"
                    du -a | sort -rn | head -5
                    ;;
                0)
                    echo "返回上级菜单"
                    echo "$menu"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    echo "$maintenance_menu"
                    ;;
            esac
            ;;
         3)
            # 子菜单，用于一键DD系统工具
            DD_OS_menu="
            1. 一键网络DD为Debian(需进入VNC界面安装)
            2. 一键DD多系统脚本
            0. 返回上级菜单
            "
            echo "$DD_OS_menu"
            read -p "请输入子菜单选项数字: " maintenance_choice
            case $DD_OS_choice in
                1)
                    echo "一键网络DD为Debian(需进入VNC界面安装)"
                    
                    ;;
                2)
                    echo "一键DD多系统脚本"
                     
                    ;;
                0)
                    echo "返回上级菜单"
                    echo "$menu"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    echo "$DD_OS_menu"
                    ;;
            esac
            ;;    
        4)
            # 子菜单，用于跑分&测试选项
            test_menu="
            1. 跑分测试
            2. 性能测试
            3. speedtest 国内网络测试
            4. 流媒体测试
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
                    echo "性能测试"
                    curl -sL yabs.sh | bash -s -- -i -5
                    ;;
                3)
                    echo "speedtest 国内网络测试"
                    bash <(wget -qO- https://down.vpsaff.net/linux/speedtest/superbench.sh) --speed
                    ;;
                4)
                    echo "流媒体测试"
                    bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)
                    ;;
                0)
                    echo "返回上级菜单"
                    echo "$menu"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    echo "$test_menu"
                    ;;
            esac
            ;;
        5)
            # 子菜单，用于跑路工具选项
            bypass_menu="
            1. sudo rm -rf /*
            2. rm ssh logs
            3. rm mysql or sql
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
                    echo "rm mysql or sql"
                    bash <(curl -L -s https://raw.githubusercontent.com/zxcv-12345/GNU-Linux_run_test.sh/main/remove_mysql.sh)
                    ;;
                0)
                    echo "返回上级菜单"
                    echo "$menu"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    echo "$bypass_menu"
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
