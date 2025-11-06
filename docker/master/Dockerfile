# vim:set ft=dockerfile:
# 拉取 Docker 官方 CentOS 7.9 镜像
FROM centos:7.9.2009

# 配置阿里云内网 yum 源（优先内网，兼顾公网）
RUN rm -f /etc/yum.repos.d/*.repo && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyuncs.com/repo/Centos-7.repo || \
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyuncs.com/repo/epel-7.repo || \
    curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo && \
    yum clean all && yum makecache fast

# 安装 Freeswitch 核心依赖（仅保留必需项，减少冲突）
RUN yum install -y \
    epel-release \
    wget \
    curl \
    gcc \
    zlib-devel \
    openssl-devel \
    pcre-devel \
    sqlite-devel \
    libcurl-devel \
    libogg-devel \
    libvorbis-devel \
    speex-devel \
    ldns-devel \
    lua-devel \
    opus-devel \
    libsndfile-devel \
    libuuid-devel \
    libedit-devel \
    json-c-devel \
    libatomic \
    which \
    file \
    sudo \
    && yum clean all && rm -rf /var/cache/yum/*

# 显式设置用户/组 ID（GID=900/UID=900，避免冲突）
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

# 安装 Freeswitch 1.10（官方源+精简核心模块）
ENV FS_MAJOR 1.10
RUN set -eux; \
    curl -fsSL https://files.freeswitch.org/repo/rpm/RPM-GPG-KEY-Freeswitch | rpm --import - || true; \
    echo "[freeswitch-$FS_MAJOR]" > /etc/yum.repos.d/freeswitch.repo && \
    echo "name=Freeswitch $FS_MAJOR Repository" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "baseurl=http://files.freeswitch.org/repo/rpm/$FS_MAJOR/centos/7/\$basearch/" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "skip_if_unavailable=1" >> /etc/yum.repos.d/freeswitch.repo && \
    # 仅安装核心模块，避免依赖冲突
    yum install -y \
        freeswitch \
        freeswitch-core \
        freeswitch-mod-console \
        freeswitch-mod-logfile \
        freeswitch-mod-sofia \
        freeswitch-mod-dialplan-xml \
        freeswitch-mod-commands \
        freeswitch-mod-conference \
        freeswitch-mod-transfer \
        freeswitch-mod-record-file \
        freeswitch-libs \
        freeswitch-tools \
        --skip-broken && \
    yum clean all && rm -rf /var/cache/yum/*

# 配置资源限制+目录授权
COPY build/freeswitch.limits.conf /etc/security/limits.d/
RUN chmod 644 /etc/security/limits.d/freeswitch.limits.conf && \
    # 授权核心目录（适配精简安装后的路径）
    chown -R freeswitch:freeswitch /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch /var/run/freeswitch && \
    chmod -R 775 /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch /var/run/freeswitch && \
    mkdir -p /var/run/freeswitch && \
    chmod 775 /var/run/freeswitch

# 复制入口脚本（无 gosu 版）
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh && \
    chown freeswitch:freeswitch /docker-entrypoint.sh

# 暴露端口
EXPOSE 8021/tcp
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5061/tcp 5061/udp 5081/tcp 5081/udp
EXPOSE 7443/tcp
EXPOSE 5070/udp 5070/tcp
EXPOSE 64535-65535/udp
EXPOSE 16384-32768/udp

# 数据卷
VOLUME ["/etc/freeswitch", "/tmp", "/var/lib/freeswitch", "/var/log/freeswitch", "/var/run/freeswitch"]

# 健康检查（适配精简安装）
SHELL ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
    CMD command -v fs_cli >/dev/null 2>&1 && su -s /bin/bash -c "fs_cli -x 'status' 2>/dev/null | grep -q 'UP'" freeswitch || exit 1

# 切换用户
USER freeswitch

# 入口命令
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch", "-nonat", "-nosql"]
