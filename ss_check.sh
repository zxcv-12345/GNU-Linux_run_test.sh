#!/usr/bin/env bash

# ============================================================
# ss TCP 网络排查脚本
# 功能：
#   1. TCP 总体状态
#   2. TCP 拥塞控制 / qdisc
#   3. 网卡丢包与错误
#   4. TCP 连接详细分析
#   5. RTT / cwnd / 重传统计
#   6. Recv-Q / Send-Q 异常连接
#   7. 按远端 IP 统计连接
#   8. 高重传连接
#   9. 低 cwnd 连接
#  10. 自动生成诊断结论
#
# 使用：
#   chmod +x ss_check.sh
#   ./ss_check.sh
#
# ============================================================

set -u

REPORT="/tmp/ss_check_$(date +%Y%m%d_%H%M%S).log"

exec > >(tee "$REPORT") 2>&1

echo "============================================================"
echo " TCP / SS 网络排查报告"
echo " 时间: $(date '+%F %T %Z')"
echo " 主机: $(hostname)"
echo " 内核: $(uname -r)"
echo "============================================================"
echo

# ------------------------------------------------------------
# 基础信息
# ------------------------------------------------------------

echo "############################"
echo "# 1. 系统基础信息"
echo "############################"

echo "Hostname:"
hostname

echo
echo "Kernel:"
uname -a

echo
echo "OS:"
if [ -f /etc/os-release ]; then
    grep -E '^(PRETTY_NAME|VERSION)=' /etc/os-release
fi

echo


# ------------------------------------------------------------
# TCP 总体状态
# ------------------------------------------------------------

echo "############################"
echo "# 2. TCP 总体状态"
echo "############################"

ss -s

echo


# ------------------------------------------------------------
# TCP 参数
# ------------------------------------------------------------

echo "############################"
echo "# 3. TCP 核心参数"
echo "############################"

sysctl \
    net.ipv4.tcp_congestion_control \
    net.ipv4.tcp_available_congestion_control \
    net.core.default_qdisc \
    net.ipv4.tcp_rmem \
    net.ipv4.tcp_wmem \
    net.core.rmem_max \
    net.core.wmem_max \
    net.ipv4.tcp_moderate_rcvbuf \
    net.ipv4.tcp_max_tw_buckets \
    net.ipv4.tcp_slow_start_after_idle \
    net.core.somaxconn 2>/dev/null

echo


# ------------------------------------------------------------
# BBR / FQ
# ------------------------------------------------------------

echo "############################"
echo "# 4. BBR / FQ 状态"
echo "############################"

echo "BBR module:"
if lsmod 2>/dev/null | grep -q tcp_bbr; then
    echo "  [OK] tcp_bbr module loaded"
else
    echo "  [WARN] tcp_bbr module not loaded"
fi

echo
echo "FQ module:"
if lsmod 2>/dev/null | grep -q sch_fq; then
    echo "  [OK] sch_fq module loaded"
else
    echo "  [WARN] sch_fq module not loaded"
fi

echo
echo "Current congestion control:"
sysctl net.ipv4.tcp_congestion_control 2>/dev/null

echo
echo "Default qdisc:"
sysctl net.core.default_qdisc 2>/dev/null

echo
echo "Current qdisc:"
tc qdisc show 2>/dev/null

echo


# ------------------------------------------------------------
# 网卡
# ------------------------------------------------------------

echo "############################"
echo "# 5. 网络接口"
echo "############################"

ip -br addr

echo

echo "Interfaces:"
ip -br link

echo


# ------------------------------------------------------------
# 网卡错误 / 丢包
# ------------------------------------------------------------

echo "############################"
echo "# 6. 网卡 RX/TX 错误与丢包"
echo "############################"

ip -s link

echo

echo "ethtool statistics:"

for IFACE in $(ls /sys/class/net/ 2>/dev/null); do

    [ "$IFACE" = "lo" ] && continue

    echo
    echo "----- $IFACE -----"

    if command -v ethtool >/dev/null 2>&1; then
        ethtool -S "$IFACE" 2>/dev/null |
            grep -Ei \
            'drop|discard|error|miss|crc|timeout|overrun|overflow|fifo' |
            head -100
    else
        echo "ethtool not installed"
    fi

done

echo


# ------------------------------------------------------------
# TIME_WAIT
# ------------------------------------------------------------

echo "############################"
echo "# 7. TCP 状态统计"
echo "############################"

echo "TIME_WAIT:"
ss -ant state time-wait 2>/dev/null | tail -n +2 | wc -l

echo "ESTABLISHED:"
ss -ant state established 2>/dev/null | tail -n +2 | wc -l

echo "CLOSE_WAIT:"
ss -ant state close-wait 2>/dev/null | tail -n +2 | wc -l

echo "SYN_RECV:"
ss -ant state syn-recv 2>/dev/null | tail -n +2 | wc -l

echo "FIN_WAIT1:"
ss -ant state fin-wait-1 2>/dev/null | tail -n +2 | wc -l

echo "FIN_WAIT2:"
ss -ant state fin-wait-2 2>/dev/null | tail -n +2 | wc -l

echo


# ------------------------------------------------------------
# Recv-Q / Send-Q
# ------------------------------------------------------------

echo "############################"
echo "# 8. Recv-Q / Send-Q 最大连接"
echo "############################"

echo
echo "Top 20 Recv-Q:"
ss -nt 2>/dev/null |
    awk 'NR > 1 {print}' |
    sort -k2 -nr |
    head -20

echo
echo "Top 20 Send-Q:"
ss -nt 2>/dev/null |
    awk 'NR > 1 {print}' |
    sort -k3 -nr |
    head -20

echo


# ------------------------------------------------------------
# ss -ti 完整数据
# ------------------------------------------------------------

echo "############################"
echo "# 9. ss -ti 完整 TCP 信息"
echo "############################"

ss -ti

echo


# ------------------------------------------------------------
# 统计拥塞控制算法
# ------------------------------------------------------------

echo "############################"
echo "# 10. TCP 拥塞控制算法统计"
echo "############################"

ss -tin 2>/dev/null |
    grep -oE '\b(cubic|bbr|reno|vegas|dctcp|bbr2)\b' |
    sort |
    uniq -c |
    sort -nr

echo


# ------------------------------------------------------------
# RTT
# ------------------------------------------------------------

echo "############################"
echo "# 11. RTT 分布"
echo "############################"

ss -ti 2>/dev/null |
    grep -oE 'rtt:[0-9.]+/[0-9.]+' |
    sed 's/rtt://g' |
    head -100

echo


# ------------------------------------------------------------
# cwnd
# ------------------------------------------------------------

echo "############################"
echo "# 12. cwnd 分布"
echo "############################"

echo "cwnd <= 2:"
ss -ti 2>/dev/null |
    grep -oE 'cwnd:[0-9]+' |
    awk -F: '$2 <= 2' |
    wc -l

echo "cwnd <= 4:"
ss -ti 2>/dev/null |
    grep -oE 'cwnd:[0-9]+' |
    awk -F: '$2 <= 4' |
    wc -l

echo "cwnd <= 10:"
ss -ti 2>/dev/null |
    grep -oE 'cwnd:[0-9]+' |
    awk -F: '$2 <= 10' |
    wc -l

echo


# ------------------------------------------------------------
# 重传
# ------------------------------------------------------------

echo "############################"
echo "# 13. TCP 重传连接"
echo "############################"

echo "Connections containing retransmission:"
ss -ti 2>/dev/null |
    grep -B1 -A1 -E \
    'bytes_retrans:[1-9][0-9]*|retrans:[1-9][0-9]*/|lost:[1-9][0-9]*' |
    head -200

echo


# ------------------------------------------------------------
# 高重传连接
# ------------------------------------------------------------

echo "############################"
echo "# 14. 高重传连接"
echo "############################"

ss -ti 2>/dev/null |
    awk '
    /ESTAB/ {
        addr=$0
    }

    /bytes_retrans:/ {
        if (match($0,/bytes_retrans:[0-9]+/)) {
            x=substr($0,RSTART+14,RLENGTH-14)
            if (x > 1000000) {
                print addr
                print $0
                print
            }
        }
    }' |
    head -100

echo


# ------------------------------------------------------------
# DSACK / OoO
# ------------------------------------------------------------

echo "############################"
echo "# 15. DSACK / 乱序包"
echo "############################"

echo "DSACK:"
ss -ti 2>/dev/null |
    grep -oE 'dsack_dups:[0-9]+' |
    awk -F: '$2 > 0' |
    sort -t: -k2 -nr |
    head -30

echo
echo "Out-of-order packets:"
ss -ti 2>/dev/null |
    grep -oE 'rcv_ooopack:[0-9]+' |
    awk -F: '$2 > 0' |
    sort -t: -k2 -nr |
    head -30

echo


# ------------------------------------------------------------
# delivery rate
# ------------------------------------------------------------

echo "############################"
echo "# 16. Delivery Rate"
echo "############################"

ss -ti 2>/dev/null |
    grep -oE 'delivery_rate [0-9.]+(bps|Kbps|Mbps|Gbps)' |
    sort |
    uniq -c |
    sort -nr |
    head -50

echo


# ------------------------------------------------------------
# pacing rate
# ------------------------------------------------------------

echo "############################"
echo "# 17. Pacing Rate"
echo "############################"

ss -ti 2>/dev/null |
    grep -oE 'pacing_rate [0-9.]+(bps|Kbps|Mbps|Gbps)' |
    sort |
    uniq -c |
    sort -nr |
    head -50

echo


# ------------------------------------------------------------
# 远端 IP 连接数
# ------------------------------------------------------------

echo "############################"
echo "# 18. 远端 IP 连接数 TOP 30"
echo "############################"

ss -nt 2>/dev/null |
    tail -n +2 |
    awk '{print $5}' |
    sed -E 's/\[[^]]+\]:[0-9]+/IPV6/g; s/:[0-9]+$//' |
    sort |
    uniq -c |
    sort -nr |
    head -30

echo


# ------------------------------------------------------------
# 端口统计
# ------------------------------------------------------------

echo "############################"
echo "# 19. 本地端口连接统计"
echo "############################"

ss -nt 2>/dev/null |
    tail -n +2 |
    awk '{print $4}' |
    sed -E 's/\[[^]]+\]:/IPv6:/; s/.*://' |
    sort |
    uniq -c |
    sort -nr |
    head -30

echo


# ------------------------------------------------------------
# Socket memory
# ------------------------------------------------------------

echo "############################"
echo "# 20. Socket Memory"
echo "############################"

ss -m 2>/dev/null | head -100

echo


# ------------------------------------------------------------
# TCP 内核统计
# ------------------------------------------------------------

echo "############################"
echo "# 21. TCP Kernel Statistics"
echo "############################"

nstat -az 2>/dev/null |
    grep -Ei \
    'Tcp|Retrans|Listen|Abort|Timeout|Reset|Failed|Drop|OutOf|Prune' |
    head -100

echo


# ------------------------------------------------------------
# 路由
# ------------------------------------------------------------

echo "############################"
echo "# 22. 默认路由"
echo "############################"

ip route

echo
ip -6 route 2>/dev/null

echo


# ------------------------------------------------------------
# MTU
# ------------------------------------------------------------

echo "############################"
echo "# 23. MTU"
echo "############################"

for IFACE in $(ls /sys/class/net/ 2>/dev/null); do
    echo -n "$IFACE: "
    ip link show "$IFACE" 2>/dev/null |
        grep -oE 'mtu [0-9]+' |
        head -1
done

echo


# ------------------------------------------------------------
# 自动诊断
# ------------------------------------------------------------

echo "############################"
echo "# 24. 自动诊断"
echo "############################"

echo

TW=$(ss -ant state time-wait 2>/dev/null | tail -n +2 | wc -l)
CWND2=$(ss -ti 2>/dev/null | grep -oE 'cwnd:[0-9]+' | awk -F: '$2 <= 2' | wc -l)
CWND4=$(ss -ti 2>/dev/null | grep -oE 'cwnd:[0-9]+' | awk -F: '$2 <= 4' | wc -l)
RETRANS=$(ss -ti 2>/dev/null | grep -cE 'bytes_retrans:[1-9][0-9]*')
OOO=$(ss -ti 2>/dev/null | grep -cE 'rcv_ooopack:[1-9][0-9]*')
DSACK=$(ss -ti 2>/dev/null | grep -cE 'dsack_dups:[1-9][0-9]*')

echo "TIME_WAIT connections : $TW"
echo "cwnd <= 2             : $CWND2"
echo "cwnd <= 4             : $CWND4"
echo "connections retrans   : $RETRANS"
echo "connections OoO       : $OOO"
echo "connections DSACK     : $DSACK"

echo

if [ "$TW" -gt 1000 ]; then
    echo "[WARN] TIME_WAIT 数量较高"
else
    echo "[ OK ] TIME_WAIT 没有明显压力"
fi

if [ "$CWND2" -gt 5 ]; then
    echo "[WARN] 大量 TCP 连接 cwnd <= 2，建议检查丢包/拥塞"
else
    echo "[ OK ] cwnd <= 2 的连接数量正常"
fi

if [ "$CWND4" -gt 10 ]; then
    echo "[WARN] 大量 TCP 连接 cwnd <= 4"
else
    echo "[ OK ] cwnd <= 4 的连接数量没有明显异常"
fi

if [ "$RETRANS" -gt 10 ]; then
    echo "[WARN] 检测到较多存在重传的 TCP 连接"
else
    echo "[ OK ] TCP 重传连接数量正常"
fi

if [ "$OOO" -gt 10 ]; then
    echo "[WARN] 检测到大量 TCP 乱序包"
fi

if [ "$DSACK" -gt 10 ]; then
    echo "[WARN] 检测到较多 DSACK，可能存在重复/乱序传输"
fi

echo

echo "============================================================"
echo " 排查完成"
echo " 报告保存至:"
echo " $REPORT"
echo "============================================================"
