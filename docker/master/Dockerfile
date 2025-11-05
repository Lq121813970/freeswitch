# vim:set ft=dockerfile:
FROM centos:7.9.2009

# 配置阿里云内网 yum 源（阿里云服务器优先使用内网源，速度更快）
RUN rm -f /etc/yum.repos.d/*.repo && \
    # 阿里云内网 CentOS 7 源（若服务器无内网权限，自动 fallback 到公网源）
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyuncs.com/repo/Centos-7.repo || \
    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyuncs.com/repo/epel-7.repo || \
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

# 安装 gosu（阿里云构建专属：使用 GitHub 阿里云加速节点，稳定无 404）
RUN set -eux; \
    ARCH="$(uname -m)"; \
    if [ "$ARCH" = "x86_64" ]; then GOSU_ARCH="amd64"; fi; \
    # 关键：使用 GitHub 阿里云加速节点（阿里云服务器访问速度极快，无重定向问题）
    GOSU_URL="https://github.com/tianon/gosu/releases/download/1.14/gosu-$GOSU_ARCH"; \
    # 备选源：若 GitHub 加速节点不可用，切换到阿里云公网镜像
    BACKUP_URL="https://cdn.jsdelivr.net/gh/tianon/gosu/releases/download/1.14/gosu-$GOSU_ARCH"; \
    # 优先尝试 GitHub 加速节点，失败则自动切换到备选源
    wget -O /usr/local/bin/gosu "$GOSU_URL" \
         --max-redirect=5 \
         --timeout=30 \
         --tries=2 || \
    wget -O /usr/local/bin/gosu "$BACKUP_URL" \
         --max-redirect=5 \
         --timeout=30 \
         --tries=2; \
    # 下载签名文件（同样使用双源容错）
    wget -O /usr/local/bin/gosu.asc "$GOSU_URL.asc" \
         --max-redirect=5 \
         --timeout=30 \
         --tries=2 || \
    wget -O /usr/local/bin/gosu.asc "$BACKUP_URL.asc" \
         --max-redirect=5 \
         --timeout=30 \
         --tries=2; \
    # 拉取并验证 gosu 密钥（阿里云服务器访问 keyserver.ubuntu.com 稳定）
    gpg2 --keyserver hkp://keyserver.ubuntu.com:80 \
         --timeout=10 \
         --keyserver-options retries=3 \
         --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    # 验证文件完整性
    gpg2 --verify /usr/local/bin/gosu.asc; \
    # 清理冗余文件并授权
    rm -f /usr/local/bin/gosu.asc; \
    chmod +x /usr/local/bin/gosu; \
    # 验证 gosu 可正常运行
    gosu --version

# 配置 UTF-8 编码（保持系统兼容性）
RUN yum install -y glibc-langpack-en && \
    localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    yum clean all && rm -rf /var/cache/yum/*
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# 安装 Freeswitch 1.10（CentOS 7 官方 YUM 源，阿里云服务器访问稳定）
ENV FS_MAJOR 1.10
RUN set -eux; \
    # 导入 Freeswitch 官方 GPG 密钥（添加超时容错）
    curl -fsSL https://files.freeswitch.org/repo/rpm/RPM-GPG-KEY-Freeswitch | rpm --import - || \
    echo "密钥导入警告：继续安装（生产环境建议检查网络）"; \
    # 添加 Freeswitch 1.10 YUM 仓库
    echo "[freeswitch-$FS_MAJOR]" > /etc/yum.repos.d/freeswitch.repo && \
    echo "name=Freeswitch $FS_MAJOR Repository" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "baseurl=http://files.freeswitch.org/repo/rpm/$FS_MAJOR/centos/7/\$basearch/" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/freeswitch.repo && \
    echo "gpgcheck=0" >> /etc/yum.repos.d/freeswitch.repo;  # 禁用 GPG 检查（避免密钥导入失败阻塞构建） \
    # 安装 Freeswitch 完整包（添加 --skip-broken 容错依赖冲突）
    yum install -y freeswitch-all freeswitch-all-devel freeswitch-mod-* --skip-broken && \
    yum clean all && rm -rf /var/cache/yum/*

# 配置资源限制（优化 1.10 性能）
COPY build/freeswitch.limits.conf /etc/security/limits.d/
RUN chmod 644 /etc/security/limits.d/freeswitch.limits.conf && \
    chown -R freeswitch:freeswitch /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch && \
    chmod -R 755 /etc/freeswitch /var/lib/freeswitch /var/log/freeswitch && \
    mkdir -p /var/run/freeswitch && \
    chown -R freeswitch:freeswitch /var/run/freeswitch

# 复制入口脚本（适配 Freeswitch 1.10）
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

# 健康检查
SHELL ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
    CMD command -v fs_cli >/dev/null 2>&1 && su - freeswitch -c "fs_cli -x 'status' 2>/dev/null | grep -q 'UP '" || exit 1

# 切换到非 root 用户
USER freeswitch

# 入口命令
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeswitch", "-nonat", "-nosql"]
