# vim:set ft=dockerfile:
# 拉取 Docker 官方 CentOS 7.9 镜像（无需认证）
FROM centos:7.9.2009

# 配置阿里云内网 yum 源（确保编译依赖拉取稳定）
RUN rm -f /etc/yum.repos.d/*.repo && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyuncs.com/repo/Centos-7.repo || \
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyuncs.com/repo/epel-7.repo || \
    curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo && \
    yum clean all && yum makecache fast

# 安装源码编译必需依赖（CentOS 7 官方源均有，无冲突）
RUN yum install -y \
    epel-release \
    wget \
    curl \
    gcc \
    gcc-c++ \
    make \
    autoconf \
    automake \
    libtool \
    git \
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

# 源码编译安装 Freeswitch 1.10（官方稳定版，无 RPM 依赖）
ENV FS_VERSION 1.10.10
RUN set -eux; \
    # 下载官方源码（阿里云访问 GitHub 稳定）
    cd /tmp && \
    wget -q https://github.com/signalwire/freeswitch/archive/v${FS_VERSION}.tar.gz && \
    tar -zxf v${FS_VERSION}.tar.gz && \
    cd freeswitch-${FS_VERSION} && \
    # 初始化编译环境（适配 CentOS 7）
    ./bootstrap.sh -j$(nproc) && \
    # 配置编译参数（仅启用核心模块，减少依赖）
    ./configure \
        --prefix=/usr/local/freeswitch \
        --sysconfdir=/etc/freeswitch \
        --localstatedir=/var/lib/freeswitch \
        --logdir=/var/log/freeswitch \
        --with-lua \
        --with-openssl \
        --with-opus \
        --with-sndfile \
        --disable-debug \
        --disable-dependency-tracking \
        --enable-core-odbc-support=no \
        --enable-core-pgsql-support=no \
        --enable-core-mysql-support=no \
        --enable-modules=core,endpoints,dialplans,applications,formats,codecs,loggers \
        --enable-mod-console \
        --enable-mod-logfile \
        --enable-mod-sofia \
        --enable-mod-dialplan-xml \
        --enable-mod-commands \
        --enable-mod-conference \
        --enable-mod-transfer \
        --enable-mod-record-file && \
    # 编译安装（并行编译，加速构建）
    make -j$(nproc) && \
    make install && \
    # 清理源码，减小镜像体积
    cd / && rm -rf /tmp/* && \
    # 配置环境变量，让系统识别 fs_cli 等命令
    echo "export PATH=/usr/local/freeswitch/bin:\$PATH" >> /etc/profile && \
    source /etc/profile

# 配置资源限制+目录授权（适配源码编译路径）
COPY build/freeswitch.limits.conf /etc/security/limits.d/
RUN chmod 644 /etc/security/limits.d/freeswitch.limits.conf && \
    # 授权所有相关目录
    chown -R freeswitch:freeswitch /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch /var/run/freeswitch /usr/local/freeswitch && \
    chmod -R 777 /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch /var/run/freeswitch /usr/local/freeswitch && \
    mkdir -p /var/run/freeswitch && \
    chmod 777 /var/run/freeswitch

# 复制入口脚本（源码编译适配版）
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh && \
    chown freeswitch:freeswitch /docker-entrypoint.sh

# 暴露核心端口（语法合规）
# FS CLI 管理端口
EXPOSE 8021/tcp
# SIP 标准端口
EXPOSE 5060/tcp 5060/udp
# SIP 备用端口
EXPOSE 5080/tcp 5080/udp
# RTP 媒体端口
EXPOSE 16384-32768/udp

# 数据卷（核心配置和日志目录）
VOLUME ["/etc/freeswitch", "/var/log/freeswitch"]

# 健康检查（适配源码编译路径）
SHELL ["/bin/bash"]
HEALTHCHECK --interval=20s --timeout=10s --retries=2 \
    CMD /usr/local/freeswitch/bin/fs_cli -x 'status' 2>/dev/null | grep -q 'UP' || exit 1

# 切换用户
USER freeswitch

# 入口命令（适配源码编译的启动路径）
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/freeswitch/bin/freeswitch", "-nonat", "-nosql", "-c"]
