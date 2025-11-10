#!/bin/bash
set -e

# 初始化最小配置（适配 EPEL 安装的默认路径）
if [ -z "$(ls -A /etc/freeswitch 2>/dev/null)" ]; then
    echo "初始化 Freeswitch 最小配置..."
    # EPEL 安装的默认配置路径
    if [ -d "/usr/share/freeswitch/conf/minimal" ]; then
        cp -a /usr/share/freeswitch/conf/minimal/* /etc/freeswitch/
    else
        # 兜底：复制基础配置文件
        cp -a /usr/share/freeswitch/conf/* /etc/freeswitch/ 2>/dev/null || true
    fi
    chown -R freeswitch:freeswitch /etc/freeswitch
fi

# 确保运行时目录可写
chmod 777 /var/run/freeswitch 2>/dev/null || true

# 启动 Freeswitch（强制前台运行，容器不退出）
exec freeswitch -nonat -nosql -c
