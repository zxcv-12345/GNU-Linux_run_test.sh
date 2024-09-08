#!/bin/bash

# 显示当前的swappiness值
current_swappiness=$(sysctl vm.swappiness | awk '{print $3}')
echo -e "\033[33m Current swappiness value: $current_swappiness \033[0m"

# 提示用户输入新的swappiness值
read -p "Enter the new swappiness value (0-100): " new_swappiness

# 检查用户输入是否为有效的数字
if [[ "$new_swappiness" =~ ^[0-9]+$ ]] && [ "$new_swappiness" -ge 0 ] && [ "$new_swappiness" -le 100 ]; then
    # 将新的swappiness值写入sysctl.conf
    if grep -q "vm.swappiness" /etc/sysctl.conf; then
        sed -i "s/^vm.swappiness=.*/vm.swappiness=$new_swappiness/" /etc/sysctl.conf
    else
        echo "vm.swappiness=$new_swappiness" >> /etc/sysctl.conf
    fi
    
    # 使配置生效
    sysctl -p

    echo -e "\033[32m Swappiness value updated to $new_swappiness and changes applied successfully. \033[0m"
else
    echo -e "\033[31m Invalid input! Please enter a number between 0 and 100. \033[0m"
fi
