#!/bin/bash

# 获取系统信息
current_swap=$(free -m | awk '/Swap/ {print $2}') # 获取当前swap大小（MB）
disk_size=$(df --total -m | grep 'total' | awk '{print $2}') # 获取总硬盘容量（MB）
mem_size=$(free -m | awk '/Mem/ {print $2}') # 获取当前内存大小（MB）

# 计算建议的swap大小范围（1.5到2倍内存大小）
min_suggested_swap=$(echo "$mem_size * 1.5" | bc) # 计算内存的1.5倍swap
max_suggested_swap=$(echo "$mem_size * 2" | bc)   # 计算内存的2倍swap

# 确保推荐的swap大小不会超过硬盘的三分之一
max_allowed_swap=$(echo "$disk_size / 3" | bc)    # 硬盘大小的三分之一
if (( $(echo "$max_suggested_swap > $max_allowed_swap" | bc -l) )); then
    max_suggested_swap=$max_allowed_swap
fi

# 显示当前的swap、硬盘容量、内存和建议的swap范围
echo -e "\n\033[32m Current system details: \033[0m"
echo -e "------------------------------------"
echo -e "Current Swap Size (MB): $current_swap"
echo -e "Disk Size (MB): $disk_size"
echo -e "Memory Size (MB): $mem_size"
echo -e "Suggested Swap Size Range (MB): ${min_suggested_swap}MB ~ ${max_suggested_swap}MB (based on memory)"
echo -e "------------------------------------"

# 用户输入swap大小或默认使用建议值
read -p "Enter the size of swap to add (e.g., 512M or press Enter for suggested value: $min_suggested_swap MB): " swap_size

# 如果用户未输入，使用建议的最小swap大小
if [ -z "$swap_size" ]; then
    swap_size=$(printf "%.0f" $min_suggested_swap) # 将推荐的swap值四舍五入为整数
    echo -e "\033[33m Using suggested swap size: ${swap_size}MB \033[0m"
fi

# 如果用户输入0，则移除swap
if [ "$swap_size" == "0" ]; then
    swapoff /SwapDir/swap
    rm -f /SwapDir/swap
    sed -i '/\/SwapDir\/swap/d' /etc/fstab
    echo -e "\033[31m Swap space removed successfully! \033[0m"
else
    # 创建新的swap空间
    mkdir -p /SwapDir
    dd if=/dev/zero of=/SwapDir/swap bs=1M count=$swap_size
    chmod 0600 /SwapDir/swap
    mkswap /SwapDir/swap
    swapon /SwapDir/swap
    
    # 备份并更新fstab
    cp /etc/fstab /etc/fstab.bak
    sed -i '/\/SwapDir\/swap/d' /etc/fstab
    echo "/SwapDir/swap swap swap defaults 0 0" >> /etc/fstab
    
    echo -e "\033[31m Swap space added successfully! \033[0m"
fi

# 显示更新后的swap情况
echo -e "\033[33m Your system swap is now: \033[0m"
free -h
