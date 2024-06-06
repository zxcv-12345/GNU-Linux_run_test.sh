#!/bin/bash

# 判断系统环境并选择合适的包管理器
if [ -f /etc/redhat-release ]; then
    echo "当前环境为 CentOS"
    OS="centos"
    package_manager_command="yum"
    echo "update source and install wget curl"
    $package_manager_command update -y && $package_manager_command install -y curl wget
    echo "已完成 wget 和 curl 的安装，继续后续操作..."
elif [ -f /etc/debian_version ]; then
    echo "当前环境为 Debian"
    OS="debian"
    package_manager_command="apt"
    echo "update source and install wget curl"
    $package_manager_command update -y && $package_manager_command install -y curl wget
    echo "已完成 wget 和 curl 的安装，继续后续操作..."
elif [ -f /etc/alpine_version ]; then
    echo "当前环境为 Alpine"
    OS="alpine"
    package_manager_command="apk"
    echo "update source and install wget curl"
    $package_manager_command update -y && $package_manager_command install -y curl wget
    echo "已完成 wget 和 curl 的安装，继续后续操作..."
else
    echo -e "\e[0;31m无法识别当前环境！\e[0m"
    exit 1
fi

# This toolbox.sh body.
# 主菜单
menu="
1. 安装工具
2. 卸载工具
3. 运维工具
4. 一键DD系统
5. 跑分&测试
\e[0;31m6. 跑路工具集(不开玩笑！慎用！)\e[0m
7. 环境一键安装
0. 退出

P.S.:众多脚本需要用到curl与wget命令
     跑脚本前最好先在“安装工具”里面
     先install这两个基础命令！！！
"

# 选项无效计数器
invalid_choice_count=0

# 循环头
while true; do
    # 选项输入
    echo -e "$menu"
    read -p "请输入选项编号: " choice

    case $choice in
        1)
            # 子菜单，用于工具安装选项
            tool_menu="
            1. 更新软件包列表并安装net-tools
            2. 安装可视化路由追踪工具 -- NextTrace
            3. 安装1panel
            4. 安装宝塔纯净版
            5. 安装caddy(使用go本地编译并安装)
            6. 安装ufw--Debian系防火墙
            7. 安装nmtui--图形化界面管理网卡&配置
            8. 安装screen--后台虚拟终端
            0. 返回上级菜单
            "
            echo "$tool_menu"
            read -p "请输入子菜单选项数字: " tool_choice
            case $tool_choice in
                1)
                    echo "install net-tools"
                    $package_manager_command install -y net-tools
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
                    $package_manager_command install ufw -y
                    ;;
                8)
                    echo "安装screen"
                    $package_manager_command install screen -y
                    ;;
                0)
                    echo "返回上级菜单"
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
            2. 卸载ufw
            3. 卸载1panel
            4. 卸载宝塔纯净版
            0. 返回上级菜单
            "
            echo "$remove_menu"
            read -p "请输入菜单编号: " remove_choice
            case $remove_choice in
                1)
                    echo "卸载Nexttrace tool"
                    rm /usr/local/bin/nexttrace
                    ;;
                2)
                    echo "卸载ufw"
                    $package_manager_command remove ufw -y
                    ;;
                3)
                    echo "卸载1panel"
                    1pctl uninstall
                    ;;
                4)
                    echo "卸载宝塔纯净版"
                    wget -O bt-uninstall.sh https://raw.githubusercontent.com/DanKE123abc/BTpanel7.7/main/bt-uninstall.sh && bash bt-uninstall.sh
                    ;;
                0)
                    echo "返回上级菜单"
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
            5. Debian系统开局初始化
            6. 防火墙放行Cloudfare CDN IP
            7. 一键更换包管理器源
            8. 修改DNS
            0. 返回上级菜单
            "
            echo "$maintenance_menu"
            read -p "请输入子菜单选项数字: " maintenance_choice
            case $maintenance_choice in
                1)
                    echo "自动清理内核"
                    sudo $package_manager_command autoremove --purge
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
                6)
                    # 子菜单，用于防火墙放行Cloudfare CDN IP
                    Cloudfare_CDN_IP_menu="
                    1. IPv4 - 放行Cloudfare CDN IPv4
                    2. IPv6 - 放行Cloudfare CDN IPv6
                    0. 返回上级菜单
                    "
                    echo "$Cloudfare_CDN_IP_menu"
                    read -p "请输入IP协议对应的编号: " Cloudfare_CDN_IP_choice
                    case $Cloudfare_CDN_IP_choice in
                        1)
                            echo "IPv4"
                            read -p "请输入IPv4端口号: " port
                            sudo ufw allow from 173.245.48.0/20 to any port $port proto tcp
                            sudo ufw allow from 103.21.244.0/22 to any port $port proto tcp
                            sudo ufw allow from 103.22.200.0/22 to any port $port proto tcp
                            sudo ufw allow from 103.31.4.0/22 to any port $port proto tcp
                            sudo ufw allow from 141.101.64.0/18 to any port $port proto tcp
                            sudo ufw allow from 108.162.192.0/18 to any port $port proto tcp
                            sudo ufw allow from 190.93.240.0/20 to any port $port proto tcp
                            sudo ufw allow from 188.114.96.0/20 to any port $port proto tcp
                            sudo ufw allow from 197.234.240.0/22 to any port $port proto tcp
                            sudo ufw allow from 198.41.128.0/17 to any port $port proto tcp
                            sudo ufw allow from 162.158.0.0/15 to any port $port proto tcp
                            sudo ufw allow from 104.16.0.0/13 to any port $port proto tcp
                            sudo ufw allow from 104.24.0.0/14 to any port $port proto tcp
                            sudo ufw allow from 172.64.0.0/13 to any port $port proto tcp
                            sudo ufw allow from 131.0.72.0/22 to any port $port proto tcp
                            ;;
                        2)
                            echo "IPv6"
                            read -p "请输入IPv6端口号: " port
                            sudo ufw allow from 2400:cb00::/32 to any port $port proto tcp
                            sudo ufw allow from 2606:4700::/32 to any port $port proto tcp
                            sudo ufw allow from 2803:f800::/32 to any port $port proto tcp
                            sudo ufw allow from 2405:b500::/32 to any port $port proto tcp
                            sudo ufw allow from 2405:8100::/32 to any port $port proto tcp
                            sudo ufw allow from 2a06:98c0::/29 to any port $port proto tcp
                            sudo ufw allow from 2c0f:f248::/32 to any port $port proto tcp
                            ;;
                        0)
                            echo "返回上级菜单"
                            echo "$maintenance_menu"
                            ;;
                        *)
                            echo "无效选项，请重新输入"
                            echo "$Cloudfare_CDN_IP_menu"
                            ;;
                    esac
                    ;;
                7)
                    # 子菜单，用于apt、yum、apk等包管理器源的一键替换
                    package_manager_menu="
                    1. Chinese Mainland(中国大陆地区)
                    2. World(Not Chinese Mainland)
                    0. 返回上级菜单
                    "
                    echo "$package_manager_menu"
                    read -p "请输入对应的编号: " package_manager_choice
                    case $package_manager_choice in
                        1)
                            echo "Chinese Mainland"
                            bash <(curl -sSL https://linuxmirrors.cn/main.sh)
                            ;;
                        2)
                            echo "World(Not Chinese Mainland)"
                            bash <(curl -sSL https://raw.githubusercontent.com/SuperManito/LinuxMirrors/main/ChangeMirrors.sh) --abroad
                            ;;
                        0)
                            echo "返回上级菜单"
                            echo "$maintenance_menu"
                            ;;
                        *)
                            echo "无效选项，请重新输入"
                            echo "$package_manager_menu"
                            ;;
                    esac
                    ;;
                8)
                    echo "更换DNS"
                    read -p "请输入新的DNS服务器地址: " new_dns
                    sed -i '/^[^#]/s/^/# /' /etc/resolv.conf
                    last_non_comment_line=$(awk '!/^#/ && NF {line=$0} END{print NR}' /etc/resolv.conf)
                    sed -i "${last_non_comment_line}a\\
                    nameserver ${new_dns}
                    " /etc/resolv.conf
                    echo "DNS 已修改为 $new_dns"
                    ;;
                0)
                    echo "返回上级菜单"
                    echo -e "$menu"
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
                    echo -e "$menu"
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
                    # 子菜单，用于apt、yum、apk等包管理器源的一键替换
                    vps_paofen_menu="
                    "VPS融合怪服务器测评"
                    1. 交互式(需要预先安装curl)
                    2. 短链(bash使用wget) P.S：无法使用情况下请用交互式！！！
                    0. 返回上级菜单
                    "
                    echo "$vps_paofen_menu"
                    read -p "请输入对应的编号: " vps_paofen_choice
                    case $vps_paofen_choice in
                        1)
                            echo "交互式"
                            curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
                            ;;
                        2)
                            echo "短链"
                            bash <(wget -qO- bash.spiritlhl.net/ecs)
                            ;;
                        0)
                            echo "返回上级菜单"
                            echo "$maintenance_menu"
                            ;;
                        *)
                            echo "无效选项，请重新输入"
                            echo "$vps_paofen_menu"
                            ;;
                    esac
                    ;;
                0)
                    echo "返回上级菜单"
                    echo -e "$menu"
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
            \e[0;31m1. sudo rm -rf /* \e[0m
            \e[0;31m2. rm ssh logs\e[0m
            \e[0;31m3. rm mysql or sql\e[0m
            0. 返回上级菜单
            "
            read -p "请输入 'kill root' 以继续: " confirm
            if [ "$confirm" == "kill root" ]; then
                confirmed_count=0
                while [ $confirmed_count -lt 3 ]; do
                    read -p "确认进入跑路工具集(y/n): " confirm
                    if [ "$confirm" == "y" ]; then
                        ((confirmed_count++))
                        echo "确认次数: $confirmed_count"
                        if [ $confirmed_count -eq 3 ]; then
                            echo "确认成功！进入跑路工具集..."
                            sleep 1
                            clear
                            echo -e "$bypass_menu"
                            while true; do
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
                                        break
                                        ;;
                                    *)
                                        echo "无效选项，请重新输入"
                                        ;;
                                esac
                            done
                            break
                        fi
                    elif [ "$confirm" == "n" ]; then
                        echo -e "\e[0;31m已退出跑路工具集！\e[0m"
                        break
                    else
                        confirmed_count=0
                        echo "输入无效，请输入 'y' 或 'n'"
                    fi
                done
            else
                echo -e "\e[0;31m输入有误，确认为误触跑路工具集！\e[0m"
            fi
            ;;
        7)
            # 子菜单，各种运行环境一键安装
            # 一键安装go最新版：https://github.com/Jrohy/go-install
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
            ;;
    esac
done
