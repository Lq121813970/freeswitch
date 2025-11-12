FROM centos:centos7.9.2009

# 修复核心：用 curl 下载镜像源（无需提前安装 wget），避免 exit code 127
RUN mkdir -p /etc/yum.repos.d/backup && \
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ && \
    # 基础镜像自带 curl，用 curl 下载更稳妥
    curl -s -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
    # 替换失效的镜像地址
    sed -i 's/mirrors.cloud.aliyuncs.com/mirrors.aliyun.com/g' /etc/yum.repos.d/CentOS-Base.repo && \
    # 清理缓存并生成新缓存
    yum clean all && yum makecache fast

# 后续的 YUM 安装命令不变（已合并依赖，包含 wget）
RUN yum install -y \
    vim git wget lrzsz \
    yum-utils yum-plugin-ovl centos-release-scl rpmdevtools \
    autoconf automake libtool openssl-devel libtiff-devel libjpeg-devel \
    gcc-c++ sqlite-devel libcurl-devel speex-devel ldns-devel libedit-devel \
    yasm lua-devel opus-devel libatomic libuuid-devel libogg-devel libvorbis-devel \
    pcre-devel zlib-devel libxml2-devel ncurses-devel libpcap-devel \
    unixODBC unixODBC-devel mysql-connector-odbc && \
    yum install -y https://files.freeswitch.org/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release && \
    echo -e "[irontec]\nname=Irontec RPMs repository\nbaseurl=http://packages.irontec.com/centos/$releasever/$basearch/\nenabled=1\ngpgcheck=1" > /etc/yum.repos.d/irontec.repo && \
    rpm --import http://packages.irontec.com/public.key && \
    yum install -y sngrep && \
    yum clean all && rm -rf /var/cache/yum/*

# 后续的编译安装步骤不变...
