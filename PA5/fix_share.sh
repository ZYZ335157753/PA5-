#!/bin/bash

# ==============================================================================
# Script Name: fix_share.sh
# Description: Fixes missing VMware shared folders in /mnt/hgfs
# Usage: sudo ./fix_share.sh
# ==============================================================================

echo "🔍 检测并修复 VMware 共享文件夹丢失问题..."

# 1. 检查是否安装了 open-vm-tools
if ! command -v vmhgfs-fuse &> /dev/null; then
    echo "⚠️ 未找到 vmhgfs-fuse，正在尝试安装 open-vm-tools..."
    sudo apt-get update
    sudo apt-get install -y open-vm-tools open-vm-tools-desktop
fi

# 2. 确保挂载点存在
if [ ! -d "/mnt/hgfs" ]; then
    echo "📁 创建挂载点 /mnt/hgfs..."
    sudo mkdir -p /mnt/hgfs
fi

# 3. 尝试强制重新挂载
echo "🔄 正在尝试重新挂载..."
# 先尝试卸载以防万一（忽略错误）
sudo umount -f /mnt/hgfs 2>/dev/null

# 执行挂载命令
# .host:/ 表示挂载所有共享文件夹
# allow_other 允许非root用户访问
sudo /usr/bin/vmhgfs-fuse .host:/ /mnt/hgfs -o subtype=vmhgfs-fuse,allow_other

# 4. 验证结果
if [ $? -eq 0 ]; then
    echo "✅ 挂载命令执行成功！"
    echo "📂 当前 /mnt/hgfs 下的内容："
    ls -F /mnt/hgfs
    echo "-----------------------------------"
    echo "💡 如果以后重启又消失了，请再次运行此脚本。"
else
    echo "❌ 挂载失败，请检查 VMware 设置中是否已启用'共享文件夹'功能。"
fi
