#!/bin/bash

# 检查是否已安装MySQL并列出相关组件
echo "检查是否已安装MySQL并列出相关组件："
rpm -qa | grep mysql
echo ""

# 检查MySQL服务状态并关闭
echo "检查MySQL服务状态并关闭："
systemctl status mysqld
if [ $? -eq 0 ]; then
    echo "MySQL服务已开启，正在关闭..."
    systemctl stop mysqld
    echo "MySQL服务已关闭。"
fi
echo ""

# 查找含有MySQL的目录并删除
echo "查找含有MySQL的目录并删除："
find / -name mysql | while read line; do
    echo "删除目录: $line"
    rm -rf "$line"
done
echo ""

# 单独删除/etc/my.cnf
echo "删除/etc/my.cnf"
rm -rf /etc/my.cnf
echo ""

# 查找MySQL安装的组件服务并卸载
echo "查找MySQL安装的组件服务并卸载："
rpm -qa | grep -i mysql | while read package; do
    echo "卸载组件: $package"
    rpm -ev "$package"
done
echo ""

# 检查是否成功卸载MySQL相关组件
echo "检查是否成功卸载MySQL相关组件："
rpm -qa | grep -i mysql
echo ""

# 检查MySQL服务是否能够启动（如果返回Unit not found，则说明卸载成功）
echo "尝试启动MySQL服务："
systemctl start mysql
if [ $? -ne 0 ]; then
    echo "提示：Failed to start mysql.service: Unit not found。MySQL已成功卸载。"
else
    echo "MySQL服务已启动，可能仍然残留部分组件，请手动检查。"
fi
