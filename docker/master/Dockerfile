# 拉取 Docker 官方 CentOS 7.9 镜像
FROM centos:7.9.2009

# 配置阿里云内网 yum 源（优先内网，确保依赖包拉取稳定）
RUN rm -f /etc/yum.repos.d/*.repo && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyuncs.com/repo/Centos-7.repo || \
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyuncs.com/repo/epel-7.repo || \
    curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo && \
    yum clean all && yum makecache fast

# 安装最精简的基础依赖（仅保留必需项）
RUN yum install -y \
    epel-release \
    wget \
    curl \
    zlib-devel \
    openssl-devel \
    pcre-devel \
    sqlite-devel \
    libcurl-devel \
    libogg-devel \
    libvorbis-devel \
    speex-devel \
    lua-devel \
    opus-devel \
    libsndfile-devel \
    libuuid-devel \
    which \
    sudo \
    --skip-broken && \
    yum clean all && rm -rf /var/cache/yum/*

# 显式设置用户/组 ID（避免权限冲突）
RUN groupadd -r freeswitch --gid=900 && \
    useradd -r -g freeswitch --uid=900 -m -d /home/freeswitch freeswitch && \
    echo "freeswitch ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/freeswitch && \
    chmod 440 /etc/sudoers.d/freeswitch

# 配置 UTF-8 编码（CentOS 7 兼容方案）
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    locale -a | grep en_US.utf8 && \
    yum clean all && rm -rf /var/cache/yum/*
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# 安装 Freeswitch（语法修正：参数与安装包同列，无换行拆分）
ENV FS_MAJOR 1.10
RUN set -eux; \
    yum install -y freeswitch freeswitch-core freeswitch-mod-sofia freeswitch-mod-dialplan-xml freeswitch-mod-commands freeswitch-libs --nogpgcheck --skip-broken --nobest; \
    yum clean all && rm -rf /var/cache/yum/*

# 配置资源限制+目录授权（适配最小安装路径）
COPY build/freeswitch.limits.conf /etc/security/limits.d/
RUN chmod 644 /etc/security/limits.d/freeswitch.limits.conf && \
    # 强制授权所有相关目录，避免权限问题
    chown -R freeswitch:freeswitch /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch /var/run/freeswitch && \
    chmod -R 777 /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch /var/run/freeswitch && \
    mkdir -p /var/run/freeswitch && \
    chmod 777 /var/run/freeswitch

# 复制入口脚本（最小安装适配版）
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh && \
    chown freeswitch:freeswitch /docker-entrypoint.sh

# 暴露核心端口（仅保留必需端口，减少冲突）
EXPOSE 8021/tcp  # FS CLI 管理端口
EXPOSE 5060/tcp 5060/udp  # SIP 标准端口
EXPOSE 5080/tcp 5080/udp  # SIP 备用端口
EXPOSE 16384-32768/udp    # RTP 媒体端口

# 数据卷（仅保留核心配置和日志目录）
VOLUME ["/etc/freeswitch", "/var/log/freeswitch"]

# 简化健康检查（适配最小安装）
SHELL ["/bin/bash"]
HEALTHCHECK --interval=20s --timeout=10s --retries=2 \
    CMD su -s /bin/bash -c "fs_cli -x 'status' 2>/dev/null | grep -q 'UP'" freeswitch || exit 1

# 直接用 freeswitch 用户启动
USER freeswitch

# 入口命令（简化启动参数）
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch", "-nonat", "-nosql", "-c"]  # -c 强制前台运行，适配容器
