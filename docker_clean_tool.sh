#!/usr/bin/env bash
set -e

# 彩色输出
green(){ echo -e "\033[32m$1\033[0m"; }
yellow(){ echo -e "\033[33m$1\033[0m"; }
red(){ echo -e "\033[31m$1\033[0m"; }

pause(){
    read -rp "按回车继续..."
}

# 自动获取 Docker Root 目录
DOCKER_ROOT=$(docker info -f '{{.DockerRootDir}}' 2>/dev/null || echo "/var/lib/docker")
OVERLAY_DIR="$DOCKER_ROOT/overlay2"
LOG_DIR="$DOCKER_ROOT/containers"

menu() {
    clear
    echo "==============================="
    echo "       Docker 清理诊断"
    echo "==============================="
    echo "1. 清理悬空镜像 (dangling images)"
    echo "2. 清理所有未使用的镜像"
    echo "3. 清理所有停止的容器"
    echo "4. 清理未使用的网络"
    echo "5. 清理构建缓存卷"
    echo "6. 查询容器日志占用（支持分页）"
    echo "7. 查询 overlay2 孤立层（含大小+分页）"
    echo "8. 查找 overlay2 层对应的容器/镜像"
    echo "9. 删除所有孤立 overlay2 层（高危）"
    echo "0. 退出"
    echo "==============================="
    read -rp "请输入操作编号：" choice
}

clean_dangling_images() {
    yellow "清理悬空镜像…"
    docker image prune -f
    green "✔ 已清理悬空镜像"
}

clean_unused_images() {
    yellow "此操作将删除所有未使用镜像！"
    read -rp "确认继续? (y/n) " confirm
    if [[ "$confirm" == "y" ]]; then
        docker image prune -a -f
        green "✔ 已清理所有未使用镜像"
    else
        red "已取消"
    fi
}

clean_stopped_containers() {
    yellow "清理停止的容器…"
    docker container prune -f
    green "✔ 完成"
}

clean_unused_networks() {
    yellow "清理未使用网络…"
    docker network prune -f
    green "✔ 完成"
}

clean_build_cache() {
    yellow "清理构建缓存…"
    docker builder prune -a -f
    green "✔ 完成"
}

#############################################################
#   6. 查看日志大小（自动分页）
#############################################################
check_logs_usage() {
    tmp=$(mktemp)
    echo "容器日志占用情况（路径：$LOG_DIR）" >> "$tmp"
    echo "" >> "$tmp"

    docker ps -a --format '{{.ID}} {{.Names}}' | while read -r id name; do
        logfile="$LOG_DIR/$id/$id-json.log"
        if [[ -f "$logfile" ]]; then
            size=$(du -h "$logfile" | awk '{print $1}')
            echo "📦 $name ($id) — 日志大小：$size" >> "$tmp"
        else
            echo "📦 $name ($id) — 无日志文件" >> "$tmp"
        fi
        echo "" >> "$tmp"
    done

    less "$tmp"
    rm -f "$tmp"
}

#############################################################
#   7. overlay2 孤立层扫描（含大小 + 分页）
#############################################################
find_orphan_overlay_layers() {
    yellow "查找 overlay2 孤立层（未被容器使用的目录）并按大小排序…"

    docker_dir="/var/lib/docker/overlay2"

    if [[ ! -d "$docker_dir" ]]; then
        red "$docker_dir 不存在，请确认 Docker Root Dir。"
        return
    fi

    # 获取所有容器使用的 overlay2 层
    used_layers=$(
        docker ps -aq | while read -r cid; do
            docker inspect --format '{{json .GraphDriver.Data}}' "$cid" 2>/dev/null \
            | grep -oP '(?<=overlay2/)[a-z0-9]{12,64}' \
            | sort -u
        done
    )

    yellow "正在遍历所有 overlay2 层并计算大小..."

    tmp_file=$(mktemp)

    # 遍历所有 overlay2 子目录
    for layer in $(ls "$docker_dir"); do
        if ! echo "$used_layers" | grep -q "$layer"; then
            size=$(du -sb "$docker_dir/$layer" 2>/dev/null | awk '{print $1}')
            size_h=$(du -sh "$docker_dir/$layer" 2>/dev/null | awk '{print $1}')
            echo -e "$size\t$layer\t$size_h" >> "$tmp_file"
        fi
    done

    if [[ ! -s "$tmp_file" ]]; then
        green "没有孤立层，一切干净整洁 🍺"
        rm -f "$tmp_file"
        pause
        return
    fi

    yellow "排序结果（从大到小）："
    echo "=============================================="
    echo -e "大小(Byte)\t层目录名\t人类可读"
    echo "----------------------------------------------"

    sort -nr "$tmp_file" | while IFS=$'\t' read -r size layer size_h; do
        printf "%-12s\t%-64s\t%s\n" "$size" "$layer" "$size_h"
    done

    echo "=============================================="
    rm -f "$tmp_file"
    pause
}

#############################################################
#   8. overlay2 层 → 容器 / 镜像 关联查找（增强）
#############################################################
find_overlay_layer_mapping() {
    read -rp "输入 overlay2 层目录名（如 abc123def456）： " layer
    [[ -z "$layer" ]] && red "不能为空" && return

    tmp=$(mktemp)
    echo "Overlay2 层：$layer 对应容器/镜像：" >> "$tmp"
    echo "" >> "$tmp"

    found=0

    # 查容器
    for cid in $(docker ps -aq); do
        if docker inspect "$cid" 2>/dev/null | grep -q "$layer"; then
            name=$(docker inspect --format '{{.Name}}' "$cid" | sed 's/\///')
            echo "📦 容器：$name ($cid)" >> "$tmp"
            found=1
        fi
    done

    # 查镜像
    for img in $(docker images -q); do
        if docker inspect "$img" 2>/dev/null | grep -q "$layer"; then
            echo "🧱 镜像：$img" >> "$tmp"
            found=1
        fi
    done

    [[ "$found" -eq 0 ]] && echo "未找到任何关联，可能是孤立层。" >> "$tmp"

    less "$tmp"
    rm -f "$tmp"
}

#############################################################
#   9. 删除孤立 overlay2 层（高危）
#############################################################
delete_orphan_overlay_layers() {
    read -rp "⚠️ 确认删除所有孤立 overlay2 层？(y/n) " x
    [[ "$x" != "y" ]] && red "已取消" && return

    all_layers=$(ls "$OVERLAY_DIR")
    used_layers=$(docker inspect $(docker ps -aq 2>/dev/null) 2>/dev/null \
        | grep -oP '(?<=overlay2/)[a-zA-Z0-9]{12,64}')

    deleted=0
    for layer in $all_layers; do
        if ! echo "$used_layers" | grep -q "$layer"; then
            rm -rf "$OVERLAY_DIR/$layer"
            echo "🗑 已删除孤立层：$layer"
            deleted=1
        fi
    done

    [[ "$deleted" -eq 0 ]] && yellow "没有可删除的孤立层"
}

#############################################################
#   主控制循环
#############################################################
while true; do
    menu
    case $choice in
        1) clean_dangling_images; pause;;
        2) clean_unused_images; pause;;
        3) clean_stopped_containers; pause;;
        4) clean_unused_networks; pause;;
        5) clean_build_cache; pause;;
        6) check_logs_usage;;
        7) find_orphan_overlay_layers;;
        8) find_overlay_layer_mapping;;
        9) delete_orphan_overlay_layers; pause;;
        0) exit 0;;
        *) red "无效输入"; pause;;
    esac
done
