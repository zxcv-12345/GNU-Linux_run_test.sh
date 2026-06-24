#!/usr/bin/env bash

set -o pipefail

OS_ID="unknown"
OS_LIKE=""
OS_NAME="unknown"
PACKAGE_MANAGER=""

info() {
    printf '%s\n' "$*"
}

warn() {
    printf '\033[0;33m%s\033[0m\n' "$*"
}

err() {
    printf '\033[0;31m%s\033[0m\n' "$*" >&2
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

detect_os() {
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_LIKE="${ID_LIKE:-}"
        OS_NAME="${PRETTY_NAME:-$OS_ID}"
    elif [ -f /etc/debian_version ]; then
        OS_ID="debian"
        OS_LIKE="debian"
        OS_NAME="Debian"
    elif [ -f /etc/redhat-release ]; then
        OS_ID="rhel"
        OS_LIKE="rhel fedora"
        OS_NAME="$(cat /etc/redhat-release 2>/dev/null || printf 'Red Hat family')"
    elif [ -f /etc/alpine-release ] || [ -f /etc/alpine_version ]; then
        OS_ID="alpine"
        OS_LIKE="alpine"
        OS_NAME="Alpine Linux"
    elif [ -f /etc/arch-release ]; then
        OS_ID="arch"
        OS_LIKE="arch"
        OS_NAME="Arch Linux"
    fi

    OS_ID="${OS_ID,,}"
    OS_LIKE="${OS_LIKE,,}"
}

detect_package_manager() {
    if has_cmd apt-get; then
        PACKAGE_MANAGER="apt"
    elif has_cmd dnf; then
        PACKAGE_MANAGER="dnf"
    elif has_cmd yum; then
        PACKAGE_MANAGER="yum"
    elif has_cmd zypper; then
        PACKAGE_MANAGER="zypper"
    elif has_cmd apk; then
        PACKAGE_MANAGER="apk"
    elif has_cmd pacman; then
        PACKAGE_MANAGER="pacman"
    else
        PACKAGE_MANAGER=""
        return 1
    fi
}

os_family() {
    local info_text
    info_text=" ${OS_ID} ${OS_LIKE} "

    case "$info_text" in
        *" debian "*|*" ubuntu "*|*" kali "*)
            printf 'debian'
            ;;
        *" rhel "*|*" fedora "*|*" centos "*|*" rocky "*|*" almalinux "*|*" alma "*)
            printf 'rhel'
            ;;
        *" alpine "*)
            printf 'alpine'
            ;;
        *" arch "*)
            printf 'arch'
            ;;
        *" suse "*|*" opensuse "*)
            printf 'suse'
            ;;
        *)
            printf '%s' "${PACKAGE_MANAGER:-unknown}"
            ;;
    esac
}

run_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif has_cmd sudo; then
        sudo "$@"
    else
        err "需要 root 权限，但当前用户不是 root 且未安装 sudo。"
        return 1
    fi
}

ensure_package_manager() {
    if [ -z "$PACKAGE_MANAGER" ]; then
        detect_package_manager || true
    fi

    if [ -z "$PACKAGE_MANAGER" ]; then
        err "未检测到支持的包管理器：apt-get/dnf/yum/zypper/apk/pacman。"
        return 1
    fi
}

package_update() {
    ensure_package_manager || return 1

    case "$PACKAGE_MANAGER" in
        apt)
            run_root env DEBIAN_FRONTEND=noninteractive apt-get update
            ;;
        dnf)
            run_root dnf -y makecache
            ;;
        yum)
            run_root yum -y makecache
            ;;
        zypper)
            run_root zypper --non-interactive refresh
            ;;
        apk)
            run_root apk update
            ;;
        pacman)
            run_root pacman -Syu --noconfirm
            ;;
    esac
}

package_install() {
    [ "$#" -gt 0 ] || return 0
    ensure_package_manager || return 1

    case "$PACKAGE_MANAGER" in
        apt)
            run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
            ;;
        dnf)
            run_root dnf install -y "$@"
            ;;
        yum)
            run_root yum install -y "$@"
            ;;
        zypper)
            run_root zypper --non-interactive install "$@"
            ;;
        apk)
            run_root apk add --no-cache "$@"
            ;;
        pacman)
            run_root pacman -S --noconfirm --needed "$@"
            ;;
    esac
}

package_remove() {
    [ "$#" -gt 0 ] || return 0
    ensure_package_manager || return 1

    case "$PACKAGE_MANAGER" in
        apt)
            run_root env DEBIAN_FRONTEND=noninteractive apt-get remove -y "$@"
            ;;
        dnf)
            run_root dnf remove -y "$@"
            ;;
        yum)
            run_root yum remove -y "$@"
            ;;
        zypper)
            run_root zypper --non-interactive remove -u "$@"
            ;;
        apk)
            run_root apk del "$@"
            ;;
        pacman)
            run_root pacman -Rns --noconfirm "$@"
            ;;
    esac
}

package_autoremove() {
    ensure_package_manager || return 1

    case "$PACKAGE_MANAGER" in
        apt)
            run_root env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y --purge
            ;;
        dnf)
            run_root dnf autoremove -y
            ;;
        yum)
            run_root yum autoremove -y
            ;;
        pacman)
            local orphans
            orphans="$(pacman -Qtdq 2>/dev/null || true)"
            if [ -n "$orphans" ]; then
                # pacman prints one package name per line; word splitting is intended here.
                run_root pacman -Rns --noconfirm $orphans
            else
                info "未发现 pacman 孤儿包。"
            fi
            ;;
        zypper|apk)
            warn "当前包管理器没有安全通用的 autoremove 行为，请使用发行版推荐命令手动清理。"
            ;;
    esac
}

package_for() {
    local logical_name family
    logical_name="$1"
    family="$(os_family)"

    case "$logical_name" in
        curl|wget|screen|jq|ufw|ca-certificates)
            printf '%s' "$logical_name"
            ;;
        net-tools)
            if [ "$family" = "suse" ]; then
                printf 'net-tools-deprecated'
            else
                printf 'net-tools'
            fi
            ;;
        network-manager)
            case "$family" in
                rhel)
                    printf 'NetworkManager-tui'
                    ;;
                arch|alpine)
                    printf 'networkmanager'
                    ;;
                suse)
                    printf 'NetworkManager'
                    ;;
                *)
                    printf 'network-manager'
                    ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac
}

install_logical_package() {
    local packages
    packages="$(package_for "$1")" || {
        err "未知的软件包映射：$1"
        return 1
    }

    # package_for may return multiple whitespace separated package names.
    package_install $packages
}

remove_logical_package() {
    local packages
    packages="$(package_for "$1")" || {
        err "未知的软件包映射：$1"
        return 1
    }

    # package_for may return multiple whitespace separated package names.
    package_remove $packages
}

install_base_tools() {
    info "刷新软件源并安装 curl/wget/ca-certificates..."
    package_update && package_install curl wget ca-certificates
}

ensure_downloader() {
    if has_cmd curl || has_cmd wget; then
        return 0
    fi

    warn "未检测到 curl 或 wget，尝试安装基础下载工具。"
    install_base_tools
}

fetch_to_stdout() {
    local url
    url="$1"

    if has_cmd curl; then
        curl -fsSL --retry 3 --retry-delay 2 "$url"
    elif has_cmd wget; then
        wget -qO- "$url"
    else
        err "需要 curl 或 wget。"
        return 127
    fi
}

download_file() {
    local url output
    url="$1"
    output="$2"

    if has_cmd curl; then
        curl -fL --retry 3 --retry-delay 2 "$url" -o "$output"
    elif has_cmd wget; then
        wget -O "$output" "$url"
    else
        err "需要 curl 或 wget。"
        return 127
    fi
}

run_remote_bash() {
    local url tmp status
    url="$1"
    shift || true

    ensure_downloader || return 1
    tmp="$(mktemp "${TMPDIR:-/tmp}/toolbox.XXXXXX")" || return 1

    if download_file "$url" "$tmp"; then
        bash "$tmp" "$@"
        status=$?
    else
        status=$?
    fi

    rm -f "$tmp"
    return "$status"
}

source_remote_bash() {
    local url tmp status
    url="$1"

    ensure_downloader || return 1
    tmp="$(mktemp "${TMPDIR:-/tmp}/toolbox.XXXXXX")" || return 1

    if download_file "$url" "$tmp"; then
        # shellcheck disable=SC1090
        . "$tmp"
        status=$?
    else
        status=$?
    fi

    rm -f "$tmp"
    return "$status"
}

download_named_and_run() {
    local url output
    url="$1"
    output="$2"

    ensure_downloader || return 1
    download_file "$url" "$output" || return 1
    chmod +x "$output" 2>/dev/null || true
    bash "$output"
}

download_named_only() {
    local url output
    url="$1"
    output="$2"

    ensure_downloader || return 1
    download_file "$url" "$output" && info "已下载：$output"
}

require_debian_family() {
    if [ "$(os_family)" != "debian" ]; then
        warn "此功能只建议在 Debian/Ubuntu/Kali 系发行版使用，当前系统为：$OS_NAME。"
        return 1
    fi
}

require_systemd() {
    if ! has_cmd journalctl; then
        warn "未检测到 systemd/journalctl，此功能不适用于当前系统。"
        return 1
    fi
}

valid_port() {
    case "$1" in
        ''|*[!0-9]*)
            return 1
            ;;
        *)
            [ "$1" -ge 1 ] && [ "$1" -le 65535 ]
            ;;
    esac
}

list_installed_kernels() {
    case "$PACKAGE_MANAGER" in
        apt)
            if has_cmd dpkg; then
                dpkg --list 'linux-image*' 2>/dev/null | awk '/^ii/{print $2 "\t" $3}'
            else
                warn "未检测到 dpkg。"
            fi
            ;;
        dnf|yum|zypper)
            if has_cmd rpm; then
                rpm -qa 'kernel*' | sort
            else
                warn "未检测到 rpm。"
            fi
            ;;
        apk)
            apk info 2>/dev/null | grep -E '^linux-' || true
            ;;
        pacman)
            pacman -Q 2>/dev/null | awk '/^linux($|-| )/{print $1 "\t" $2}'
            ;;
        *)
            warn "当前系统未配置可识别的内核包查询方式。"
            ;;
    esac
}

show_top_files() {
    du -ak . 2>/dev/null | sort -rn | head -n 5 | awk '{
        size=$1
        $1=""
        sub(/^ /, "")
        printf "%.1f MiB\t%s\n", size / 1024, $0
    }'
}

change_dns() {
    local new_dns tmp backup

    read -r -p "请输入新的 DNS 服务器地址: " new_dns
    if [ -z "$new_dns" ]; then
        warn "DNS 地址不能为空。"
        return 1
    fi

    if [ -L /etc/resolv.conf ]; then
        warn "/etc/resolv.conf 是符号链接，systemd-resolved 或 NetworkManager 可能会覆盖本次修改。"
    fi

    tmp="$(mktemp "${TMPDIR:-/tmp}/resolv.XXXXXX")" || return 1
    backup="/etc/resolv.conf.toolbox.$(date +%Y%m%d%H%M%S).bak"

    if [ -e /etc/resolv.conf ]; then
        awk -v dns="$new_dns" '
            /^[[:space:]]*nameserver[[:space:]]/ { next }
            { print }
            END { print "nameserver " dns }
        ' /etc/resolv.conf >"$tmp"
        run_root cp /etc/resolv.conf "$backup" || {
            rm -f "$tmp"
            return 1
        }
    else
        printf 'nameserver %s\n' "$new_dns" >"$tmp"
    fi

    run_root cp "$tmp" /etc/resolv.conf
    rm -f "$tmp"
    info "DNS 已修改为 $new_dns，原文件备份位置：$backup"
}

allow_cloudflare_ufw() {
    local response ipv4_cidrs ipv6_cidrs choice port ip

    if ! has_cmd ufw; then
        warn "未检测到 ufw，请先安装 ufw。"
        return 1
    fi

    if ! has_cmd jq; then
        warn "此功能需要 jq，正在尝试安装。"
        install_logical_package jq || return 1
    fi

    ensure_downloader || return 1
    response="$(fetch_to_stdout "https://api.cloudflare.com/client/v4/ips")" || return 1
    ipv4_cidrs="$(printf '%s' "$response" | jq -r '.result.ipv4_cidrs[]')"
    ipv6_cidrs="$(printf '%s' "$response" | jq -r '.result.ipv6_cidrs[]')"

    cat <<'MENU'
1. IPv4 - 放行 Cloudflare CDN IPv4
2. IPv6 - 放行 Cloudflare CDN IPv6
0. 返回上级菜单
MENU
    read -r -p "请输入 IP 协议对应的编号: " choice

    case "$choice" in
        1)
            read -r -p "请输入 IPv4 端口号: " port
            valid_port "$port" || {
                warn "端口号无效。"
                return 1
            }
            for ip in $ipv4_cidrs; do
                run_root ufw allow from "$ip" to any port "$port" proto tcp
            done
            ;;
        2)
            read -r -p "请输入 IPv6 端口号: " port
            valid_port "$port" || {
                warn "端口号无效。"
                return 1
            }
            for ip in $ipv6_cidrs; do
                run_root ufw allow from "$ip" to any port "$port" proto tcp
            done
            ;;
        0)
            return 0
            ;;
        *)
            warn "无效选项。"
            return 1
            ;;
    esac
}

change_mirror_menu() {
    local choice

    cat <<'MENU'
1. Chinese Mainland(中国大陆地区)
2. World(Not Chinese Mainland)
0. 返回上级菜单
MENU
    read -r -p "请输入对应的编号: " choice

    case "$choice" in
        1)
            run_remote_bash "https://linuxmirrors.cn/main.sh"
            ;;
        2)
            run_remote_bash "https://raw.githubusercontent.com/SuperManito/LinuxMirrors/main/ChangeMirrors.sh" --abroad
            ;;
        0)
            return 0
            ;;
        *)
            warn "无效选项。"
            ;;
    esac
}

swap_menu() {
    local choice

    cat <<'MENU'
1. 一键增加/开启 swap
2. 一键修改 swap 内存交换优先级
0. 返回上级菜单
MENU
    read -r -p "请输入对应的编号: " choice

    case "$choice" in
        1)
            require_debian_family && run_remote_bash "https://raw.githubusercontent.com/zxcv-12345/GNU-Linux_run_test.sh/main/add_swap_debian.sh"
            ;;
        2)
            require_debian_family && run_remote_bash "https://raw.githubusercontent.com/zxcv-12345/GNU-Linux_run_test.sh/main/amend_swap_debian_priority.sh"
            ;;
        0)
            return 0
            ;;
        *)
            warn "无效选项。"
            ;;
    esac
}

show_bbr_status() {
    info "当前 TCP 拥塞控制："
    sysctl net.ipv4.tcp_congestion_control 2>/dev/null || true
    sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null || true

    if has_cmd modinfo; then
        modinfo tcp_bbr 2>/dev/null || warn "tcp_bbr 模块信息不可用，可能已内建进内核或当前内核未提供。"
    else
        warn "未检测到 modinfo，如需查看模块详情可安装 kmod。"
    fi
}

install_nexttrace_menu() {
    local choice

    cat <<'MENU'
1. Chinese Mainland(中国大陆地区)
2. World(Not Chinese Mainland)
0. 返回上级菜单
MENU
    read -r -p "请输入子菜单选项数字: " choice

    case "$choice" in
        1)
            run_remote_bash "https://ghproxy.com/https://raw.githubusercontent.com/sjlleo/nexttrace/main/nt_install.sh"
            ;;
        2)
            run_remote_bash "https://raw.githubusercontent.com/sjlleo/nexttrace/main/nt_install.sh"
            ;;
        0)
            return 0
            ;;
        *)
            warn "无效选项。"
            ;;
    esac
}

install_tools_menu() {
    local choice

    while true; do
        cat <<'MENU'
1. 安装 net-tools
2. 安装可视化路由追踪工具 NextTrace
3. 安装 1Panel
4. 安装宝塔纯净版
5. 安装 caddy
6. 安装 ufw
7. 安装 nmtui/NetworkManager TUI
8. 安装 screen
9. 安装 bbr3
0. 返回上级菜单
MENU
        read -r -p "请输入子菜单选项数字: " choice

        case "$choice" in
            1)
                install_logical_package net-tools
                ;;
            2)
                install_nexttrace_menu
                ;;
            3)
                run_remote_bash "https://resource.fit2cloud.com/1panel/package/quick_start.sh"
                ;;
            4)
                run_remote_bash "https://raw.githubusercontent.com/DanKE123abc/BTpanel7.7/main/install_6.0_mod.sh"
                ;;
            5)
                run_remote_bash "https://raw.githubusercontent.com/AsenHu/Note/main/archive/CaddyCDN.sh"
                ;;
            6)
                install_logical_package ufw
                ;;
            7)
                install_logical_package network-manager
                ;;
            8)
                install_logical_package screen
                ;;
            9)
                require_debian_family && run_remote_bash "https://raw.githubusercontent.com/zxcv-12345/GNU-Linux_run_test.sh/main/bbr3fordebian.sh"
                ;;
            0)
                return 0
                ;;
            *)
                warn "无效选项，请重新输入。"
                ;;
        esac
    done
}

remove_tools_menu() {
    local choice

    while true; do
        cat <<'MENU'
1. 卸载 NextTrace 工具
2. 卸载 ufw
3. 卸载 1Panel
4. 卸载宝塔纯净版
5. 卸载 screen
6. 卸载 nmtui/NetworkManager TUI
0. 返回上级菜单
MENU
        read -r -p "请输入菜单编号: " choice

        case "$choice" in
            1)
                run_root rm -f -- /usr/local/bin/nexttrace
                ;;
            2)
                remove_logical_package ufw
                ;;
            3)
                if has_cmd 1pctl; then
                    run_root 1pctl uninstall
                else
                    warn "未检测到 1pctl。"
                fi
                ;;
            4)
                run_remote_bash "https://raw.githubusercontent.com/DanKE123abc/BTpanel7.7/main/bt-uninstall.sh"
                ;;
            5)
                remove_logical_package screen
                ;;
            6)
                remove_logical_package network-manager
                ;;
            0)
                return 0
                ;;
            *)
                warn "无效选项，请重新输入。"
                ;;
        esac
    done
}

maintenance_menu() {
    local choice

    while true; do
        cat <<'MENU'
1. 自动清理无用软件包
2. 查看已安装内核
3. 查看当前使用的内核
4. 查看当前目录下排名前五的大文件
5. Debian 系统开局初始化
6. ufw 防火墙放行 Cloudflare CDN IP
7. 一键更换包管理器源
8. 修改 DNS
9. 修改 systemd journal 日志大小并释放磁盘空间
10. Swap 交换内存增删与优先级修改
11. 开启当前 bash 会话 vi 模式
12. 查看 bbr 类型
0. 返回上级菜单
MENU
        read -r -p "请输入子菜单选项数字: " choice

        case "$choice" in
            1)
                package_autoremove
                ;;
            2)
                list_installed_kernels
                ;;
            3)
                uname -r
                ;;
            4)
                show_top_files
                ;;
            5)
                require_debian_family && run_remote_bash "https://raw.githubusercontent.com/AsenHu/Note/main/debianBBR3.sh"
                ;;
            6)
                allow_cloudflare_ufw
                ;;
            7)
                change_mirror_menu
                ;;
            8)
                change_dns
                ;;
            9)
                require_systemd && run_remote_bash "https://raw.githubusercontent.com/spiritLHLS/one-click-installation-script/main/repair_scripts/resize_journal.sh"
                ;;
            10)
                swap_menu
                ;;
            11)
                set -o vi
                info "当前 bash 会话已开启 vi 模式。"
                ;;
            12)
                show_bbr_status
                ;;
            0)
                return 0
                ;;
            *)
                warn "无效选项，请重新输入。"
                ;;
        esac
    done
}

os_reinstall_menu() {
    local choice

    while true; do
        cat <<'MENU'
1. 一键网络 DD 为 Debian(需进入 VNC 界面安装)
2. 下载一键 DD 多系统脚本
3. 下载一键 DD 多系统脚本 CN
4. 一键 DD 基于 LXC 虚拟化
5. 一键 DD 基于 OpenVZ/LXC 虚拟化
6. 一键 DD 基于 OpenVZ/LXC 虚拟化(磁盘小于 1G)
0. 返回上级菜单
MENU
        read -r -p "请输入子菜单选项数字: " choice

        case "$choice" in
            1)
                run_remote_bash "https://raw.githubusercontent.com/AsenHu/Note/main/mini.sh"
                ;;
            2)
                download_named_only "https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh" "reinstall.sh"
                ;;
            3)
                download_named_only "https://mirror.ghproxy.com/https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh" "reinstall.sh"
                ;;
            4)
                run_remote_bash "https://raw.githubusercontent.com/AsenHu/Note/main/LXCuidd.sh"
                ;;
            5)
                download_named_and_run "https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh" "OsMutation.sh"
                ;;
            6)
                download_named_and_run "https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutationTight.sh" "OsMutation.sh"
                ;;
            0)
                return 0
                ;;
            *)
                warn "无效选项，请重新输入。"
                ;;
        esac
    done
}

vps_benchmark_menu() {
    local choice

    cat <<'MENU'
VPS 融合怪服务器测评
1. 交互式(需要预先安装 curl)
2. 短链(bash 使用 wget)
0. 返回上级菜单
MENU
    read -r -p "请输入对应的编号: " choice

    case "$choice" in
        1)
            run_remote_bash "https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh"
            ;;
        2)
            run_remote_bash "https://bash.spiritlhl.net/ecs"
            ;;
        0)
            return 0
            ;;
        *)
            warn "无效选项。"
            ;;
    esac
}

ip_check_menu() {
    local choice

    cat <<'MENU'
一键 IP 检测脚本
1. 双栈测试
2. 仅 IPv4
3. 仅 IPv6
0. 返回上级菜单
MENU
    read -r -p "请输入对应的编号: " choice

    case "$choice" in
        1)
            run_remote_bash "https://IP.Check.Place"
            ;;
        2)
            run_remote_bash "https://IP.Check.Place" -v4
            ;;
        3)
            run_remote_bash "https://IP.Check.Place" -v6
            ;;
        0)
            return 0
            ;;
        *)
            warn "无效选项。"
            ;;
    esac
}

test_menu() {
    local choice

    while true; do
        cat <<'MENU'
1. 跑分测速
2. 性能测试
3. 国内网络速度测试
4. 流媒体测试
5. VPS 融合怪服务器测评脚本
6. IP 检测脚本
0. 返回上级菜单
MENU
        read -r -p "请输入子菜单选项数字: " choice

        case "$choice" in
            1)
                run_remote_bash "https://down.vpsaff.net/linux/speedtest/superbench.sh" -f Speedtest
                ;;
            2)
                run_remote_bash "https://yabs.sh" -i -5
                ;;
            3)
                run_remote_bash "https://res.yserver.ink/taier.sh"
                ;;
            4)
                run_remote_bash "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh"
                ;;
            5)
                vps_benchmark_menu
                ;;
            6)
                ip_check_menu
                ;;
            0)
                return 0
                ;;
            *)
                warn "无效选项，请重新输入。"
                ;;
        esac
    done
}

environment_menu() {
    local choice

    while true; do
        cat <<'MENU'
1. 一键安装 Go 最新版脚本
2. 一键安装/卸载 Python 脚本
0. 返回上级菜单
MENU
        read -r -p "请输入子菜单选项数字: " choice

        case "$choice" in
            1)
                source_remote_bash "https://go-install.netlify.app/install.sh"
                ;;
            2)
                run_remote_bash "https://raw.githubusercontent.com/zxcv-12345/GNU-Linux_run_test.sh/main/love_python&kill_python.sh"
                ;;
            0)
                return 0
                ;;
            *)
                warn "无效选项，请重新输入。"
                ;;
        esac
    done
}

show_main_menu() {
    cat <<'MENU'
1. 安装工具
2. 卸载工具
3. 运维工具
4. 一键 DD 系统
5. 跑分&测试
6. 环境一键安装
0. 退出
MENU
}

main_menu() {
    local choice invalid_choice_count
    invalid_choice_count=0

    while true; do
        show_main_menu
        read -r -p "请输入选项编号: " choice

        case "$choice" in
            1)
                install_tools_menu
                ;;
            2)
                remove_tools_menu
                ;;
            3)
                maintenance_menu
                ;;
            4)
                os_reinstall_menu
                ;;
            5)
                test_menu
                ;;
            6)
                environment_menu
                ;;
            0)
                info "退出脚本。"
                exit 0
                ;;
            *)
                invalid_choice_count=$((invalid_choice_count + 1))
                if [ "$invalid_choice_count" -ge 3 ]; then
                    err "无效选项输入次数过多，即将退出脚本。"
                    exit 1
                fi
                warn "无效选项，请重新输入。"
                ;;
        esac
    done
}

main() {
    local pre_update

    detect_os
    detect_package_manager || true

    info "当前系统：$OS_NAME"
    if [ -n "$PACKAGE_MANAGER" ]; then
        info "检测到包管理器：$PACKAGE_MANAGER"
    else
        warn "未检测到受支持的包管理器，安装/卸载类功能将不可用。"
    fi

    read -r -p "是否预先刷新软件源并安装 curl/wget(y/n): " pre_update
    case "$pre_update" in
        y|Y)
            install_base_tools
            ;;
        n|N|'')
            ;;
        *)
            warn "未识别输入，跳过预先更新。"
            ;;
    esac

    main_menu
}

main "$@"
