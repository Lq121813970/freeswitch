#!/bin/bash
set -e

# 初始化配置（精简安装的默认配置路径）
if [ -z "$(ls -A /etc/freeswitch 2>/dev/null)" ]; then
    echo "初始化 Freeswitch 1.10 核心配置..."
    # 精简安装的默认配置路径为 /usr/share/freeswitch/conf/minimal
    cp -a /usr/share/freeswitch/conf/minimal/* /etc/freeswitch/
    chown -R freeswitch:freeswitch /etc/freeswitch
fi

# 确保运行时目录权限
if [ ! -d "/var/run/freeswitch" ]; then
    mkdir -p /var/run/freeswitch
    chown -R freeswitch:freeswitch /var/run/freeswitch
fi

# 启动 Freeswitch
exec "$@"
