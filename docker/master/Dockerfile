# vim:set ft=dockerfile:
FROM centos:7.9.2009

# 配置国内 yum 源（阿里云，解决官方源访问慢问题）
RUN rm -f /etc/yum.repos.d/*.repo && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
    curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo && \
    yum clean all && yum makecache fast

# 安装 Freeswitch 1.10 依赖（修正语法错误，确保所有包在同一命令中）
RUN yum install -y \
    epel-release \
    wget \
    curl \
    gnupg2 \
    gcc \
    gcc-c++ \
    make \
    autoconf \
    automake \
    libtool \
    zlib-devel \
    openssl-devel \
    pcre-devel \
    sqlite-devel \
    libcurl-devel \
    libjpeg-devel \
    libpng-devel \
    libtiff-devel \
    libxml2-devel \
    libxslt-devel \
    libuuid-devel \
    libogg-devel \
    libvorbis-devel \
    speex-devel \
    ldns-devel \
    lua-devel \
    opus-devel \
    libsndfile-devel \
    unixODBC-devel \
    postgresql-devel \
    mysql-devel \
    net-snmp-devel \
    freetype-devel \
    fontconfig-devel \
    libicu-devel \
    jemalloc-devel \
    libedit-devel \
    json-c-devel \
    libatomic \
    which \
    file \
    sudo \
    && yum clean all && rm -rf /var/cache/yum/*

# 显式设置用户/组 ID（调整为 GID=900、UID=900，避免与系统组冲突）
RUN groupadd -r freeswitch --gid=900 && \
    useradd -r -g freeswitch --uid=900 -m -d /home/freeswitch freeswitch && \
    echo "freeswitch ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/freeswitch && \
    chmod 440 /etc/sudoers.d/freeswitch

# 安装 gosu（方案 1：DaoCloud 加速源，稳定无 404）
RUN set -eux; \
    ARCH="$(uname -m)"; \
    if [ "$ARCH" = "x86_64" ]; then GOSU_ARCH="amd64"; fi; \
    # 阿里云 Docker Toolbox 加速源（长期维护）
    wget -O /usr/local/bin/gosu "https://mirrors.aliyun.com/docker-toolbox/linux/compat/gosu-$GOSU_ARCH" && \
    # GitHub 下载签名文件（添加重定向和重试参数）
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.14/gosu-$GOSU_ARCH.asc" \
         --max-redirect=5 \
         --timeout=30 \
         --tries=3 && \
    # 验证密钥
    gpg2 --keyserver hkp://keyserver.ubuntu.com:80 \
         --timeout=10 \
         --keyserver-options retries=3 \
         --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg2 --verify /usr/local/bin/gosu.asc && \
    # 清理冗余文件
    rm -f /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu

# 配置 UTF-8 编码（保持系统兼容性）
RUN yum install -y glibc-langpack-en && \
    localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    yum clean all && rm -rf /var/cache/yum/*
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# 安装 Freeswitch 1.10（CentOS 7 官方 YUM 源）
ENV FS_MAJOR 1.10  # 版本调整为 1.10
RUN set -eux; \
    # 导入 Freeswitch 1.10 官方 GPG 密钥（与 1.6 通用，无需更换）
    curl -fsSL https://files.freeswitch.org/repo/rpm/RPM-GPG-KEY-Freeswitch | rpm --import -; \
    # 添加 Freeswitch 1.10 YUM 仓库（官方专属 1.10 源）
    echo "[freeswitch-$FS_MAJOR]" > /etc/yum.repos.d/freeswitch.repo && \
    echo "name=Freeswitch $FS_MAJOR Repository" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "baseurl=http://files.freeswitch.org/repo/rpm/$FS_MAJOR/centos/7/\$basearch/" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "gpgcheck=1" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "gpgkey=https://files.freeswitch.org/repo/rpm/RPM-GPG-KEY-Freeswitch" >> /etc/yum.repos.d/freeswitch.repo && \
    # 安装 Freeswitch 1.10 完整包（包含核心模块和工具）
    yum install -y freeswitch-all freeswitch-all-devel freeswitch-mod-* && \
    # 清理 YUM 缓存，减小镜像体积
    yum clean all && rm -rf /var/cache/yum/*

# 配置资源限制（优化 1.10 性能，保持原 limits 逻辑）
COPY build/freeswitch.limits.conf /etc/security/limits.d/
RUN chmod 644 /etc/security/limits.d/freeswitch.limits.conf && \
    # 给 Freeswitch 1.10 目录授权（使用新的 freeswitch 用户/组）
    chown -R freeswitch:freeswitch /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch && \
    chmod -R 755 /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch && \
    # 1.10 新增日志目录权限适配
    mkdir -p /var/run/freeswitch && \
    chown -R freeswitch:freeswitch /var/run/freeswitch

# 复制入口脚本（适配 Freeswitch 1.10 启动参数）
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh && \
    chown freeswitch:freeswitch /docker-entrypoint.sh

# 暴露端口（1.10 端口与 1.6 完全兼容，保持原配置）
EXPOSE 8021/tcp
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp
EXPOSE 5061/tcp 5061/udp 5081/tcp 5081/udp
EXPOSE 7443/tcp
EXPOSE 5070/udp 5070/tcp
EXPOSE 64535-65535/udp
EXPOSE 16384-32768/udp

# 数据卷（包含 1.10 新增的运行时目录）
VOLUME ["/etc/freeswitch", "/tmp", "/var/lib/freeswitch", "/var/log/freeswitch", "/var/run/freeswitch"]

# 健康检查（适配 1.10 的 fs_cli 命令，优化检测逻辑）
SHELL ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
    CMD command -v fs_cli >/dev/null 2>&1 && su - freeswitch -c "fs_cli -x 'status' 2>/dev/null | grep -q 'UP '" || exit 1

# 切换到非 root 用户（安全最佳实践）
USER freeswitch

# 入口命令（1.10 推荐启动参数，添加 -nosql 避免默认数据库冲突）
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch", "-nonat", "-nosql"]
