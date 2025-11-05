#!/bin/bash
set -e

# 初始化配置（若数据卷为空，复制默认配置）
if [ -z "$(ls -A /etc/freeswitch 2>/dev/null)" ]; then
    echo "初始化 Freeswitch 1.10 默认配置..."
    cp -a /usr/share/freeswitch/conf/* /etc/freeswitch/
    chown -R freeswitch:freeswitch /etc/freeswitch
fi

# 确保运行时目录权限
if [ ! -d "/var/run/freeswitch" ]; then
    mkdir -p /var/run/freeswitch
    chown -R freeswitch:freeswitch /var/run/freeswitch
fi

# 直接运行 Freeswitch（已通过 USER 指令切换为 freeswitch 用户）
exec "$@"
