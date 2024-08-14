#!/bin/bash

if [[ -z $(cat /etc/os-release | grep -Ei 'debian|ubuntu') ]]; then
  echo "本脚本仅支持Debian/Ubuntu系统。"
  exit 1
fi

if [[ $(uname -m) != "x86_64" ]]; then
  echo "本脚本仅支持x86_64架构的CPU。"
  exit 1
fi

echo "正在更新系统并安装必要组件..."
apt update -y && apt install -y wget gnupg

echo "正在注册XanMod的PGP密钥..."
wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

echo "正在添加XanMod存储库..."
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

echo "检测适合的XanMod内核版本..."
wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh

echo "请选择适合的XanMod内核版本:"
echo "1. 更老的机型如大西洋 (linux-xanmod-x64v1)"
echo "2. 老机型如CC，搬瓦工，RN (linux-xanmod-x64v2)"
echo "3. 大众机型且DD过系统的 (linux-xanmod-x64v3)"
echo "4. 新机型莱卡云，谷歌云，微软云，甲骨文云，V.PS，Vultr，do，linode等 (linux-xanmod-x64v4)"
read -p "请输入选项 [1-4]: " choice

case $choice in
  1)
    kernel_version="linux-xanmod-x64v1"
    ;;
  2)
    kernel_version="linux-xanmod-x64v2"
    ;;
  3)
    kernel_version="linux-xanmod-x64v3"
    ;;
  4)
    kernel_version="linux-xanmod-x64v4"
    ;;
  *)
    echo "无效的选项。"
    exit 1
    ;;
esac

echo "正在安装内核版本 $kernel_version..."
apt update -y && apt install -y $kernel_version

echo "启用BBR3..."
cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF

sysctl -p

echo "系统将在5秒后重启..."
sleep 5
reboot
