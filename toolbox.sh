#!/bin/bash

# 主菜单
menu="
1. 安装工具
2. 卸载工具
3. 运维工具
4. 一键DD系统
5. 跑分&测试
6. 跑路工具集(不开玩笑！慎用！)
0. 退出
"

# 选项无效计数器
invalid_choice_count=0

# 循环头
while true; do
    # 选项输入
    echo "$menu"
    read -p "请输入选项编号: " choice

    case $choice in
        1)
            # 子菜单，用于工具安装选项
            tool_menu="
            1. 更新软件包列表并安装wget、curl、net-tools
            2. 安装可视化路由追踪工具 -- NextTrace
            3. 安装1panel面板
            4. 安装宝塔纯净版面板
            5. 安装caddy(使用go本地编译并安装)
            6. 安装ufw
            0. 返回上级菜单
            "
            echo "$tool_menu"
            read -p "请输入子菜单选项数字: " tool_choice
            case $tool_choice in
                1)
                    echo "update apt and install wget curl"
                    apt update -y && apt install -y curl wget net-tools
                    ;;
                2)
                    # 子菜单，用于安装可视化路由追踪工具 -- NextTrace
                    install_NextTrace_menu="
                    1. Chinese Mainland(中国大陆地区)
                    2. World(Not Chinese Mainland)
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
                5)
                    echo "安装caddy"
                    bash <(wget -qO- https://raw.githubusercontent.com/AsenHu/Note/main/archive/CaddyCDN.sh)
                    ;;
                6)
                    echo "安装ufw"
                    apt install ufw -y
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
            # 子菜单,用于卸载工具
            remove_menu="
            1. 卸载Nexttrace工具
            "
            echo "$remove_menu"
            read -p "请输入菜单编号: " remove_choice
            case $remove_choice in
                1)
                    echo "卸载Nexttrace tool"
                    rm /usr/local/bin/nexttrace
                    ;;
                0)
                    echo "返回上级菜单"
                    echo "$menu"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    echo "$remove_menu"
                    ;;
            esac
            ;;
        3)
            # 子菜单，用于运维工具
            maintenance_menu="
            1. 自动清理内核
            2. 查看已安装内核
            3. 查看当前使用的内核
            4. 查看当前目录下排名前五的大文件
            5. 系统开局初始化
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
                5)
                    echo "系统开局初始化: 可以方便的设置密钥，端口，防火墙，换内核，开 bbr3 这些操作，通常搭配 '一键网络DD为Debian' 使用.建议阅读代码看看它到底会做什么再用."
                    bash <(curl https://raw.githubusercontent.com/AsenHu/Note/main/debianBBR3.sh -L -q --retry 5 --retry-delay 10 --retry-max-time 60)
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
         4)
            # 子菜单，用于一键DD系统工具
            OS_menu="
            1. 一键网络DD为Debian(需进入VNC界面安装)
            2. 一键DD多系统脚本
            3. 一键DD多系统脚本CN
            4. 一键DD基于LXC虚拟化
            5. 一键DD基于openVZ、LXC虚拟化
            6. 一键DD基于openVZ、LXC虚拟化(磁盘较小的vps'<1G')
            0. 返回上级菜单
            "
            echo "$OS_menu"
            read -p "请输入子菜单选项数字: " OS_choice
            case $OS_choice in
                1)
                    echo "一键网络DD为Debian(需进入VNC界面安装)"
                    bash <(curl https://raw.githubusercontent.com/AsenHu/Note/main/mini.sh -L -q --retry 5 --retry-delay 10 --retry-max-time 60)
                    ;;
                2)
                    echo "一键DD多系统脚本"
                    curl -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
                    ;;
                3)
                    echo "一键DD多系统脚本CN"
                    curl -O https://mirror.ghproxy.com/https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
                    ;;
                4)
                    echo "DD基于LXC虚拟化的cloud vps"
                    bash <(curl 'https://raw.githubusercontent.com/AsenHu/Note/main/LXCuidd.sh' -L -q --retry 5 --retry-delay 10 --retry-max-time 60)
                    ;;
                5)
                    echo "DD基于openVZ&LXC虚拟化的cloud vps"
                    wget -qO OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
                    ;;
                6)
                    echo "DD硬盘小于1GB且基于openVZ&LXC虚拟化的cloud vps"
                    wget -qO OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutationTight.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
                    ;;
                0)
                    echo "返回上级菜单"
                    echo "$menu"
                    ;;
                *)
                    echo "无效选项，请重新输入"
                    echo "$OS_menu"
                    ;;
            esac
            ;;    
        5)
            # 子菜单，用于跑分&测试选项
            test_menu="
            1. 跑分测试
            2. 性能测试
            3. speedtest 国内网络测试
            4. 流媒体测试
            5. VPS融合怪服务器测评脚本
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
                5)
                    echo "VPS融合怪服务器测评"
                    bash <(wget -qO- bash.spiritlhl.net/ecs)
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
        6)
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
            echo "$menu"
            echo "无效选项，请重新输入"
            ;;
    esac
done
