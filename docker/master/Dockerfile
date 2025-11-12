FROM centos:centos7.9.2009

# 修复1：替换 CentOS 7 镜像源（用 curl 避免依赖 wget，基础镜像自带 curl）
RUN mkdir -p /etc/yum.repos.d/backup && \
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ && \
    # 用华为云 CentOS 7 归档源（稳定性更高）
    curl -s -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo && \
    # 禁用所有可能失效的仓库，避免安装卡住
    yum-config-manager --save --setopt=centos-sclo-rh.skip_if_unavailable=true && \
    yum-config-manager --save --setopt=centos-sclo-sclo.skip_if_unavailable=true && \
    yum-config-manager --save --setopt=epel-testing.skip_if_unavailable=true && \
    # 清理缓存并生成新缓存
    yum clean all && yum makecache fast

# 修复2：安装基础工具和编译依赖（卸载无用的 centos-release-scl，避免失效仓库）
RUN yum remove -y centos-release-scl && \
    yum install -y \
    vim git wget lrzsz \
    yum-utils yum-plugin-ovl rpmdevtools \
    autoconf automake libtool openssl-devel libtiff-devel libjpeg-devel \
    gcc-c++ sqlite-devel libcurl-devel speex-devel ldns-devel libedit-devel \
    yasm lua-devel opus-devel libatomic libuuid-devel libogg-devel libvorbis-devel \
    pcre-devel zlib-devel libxml2-devel ncurses-devel libpcap-devel \
    unixODBC unixODBC-devel mysql-connector-odbc && \
    # 安装 Freeswitch 仓库和 EPEL 源（提供额外依赖）
    yum install -y https://files.freeswitch.org/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release && \
    # 配置 irontec 仓库（用于安装 sngrep）
    echo -e "[irontec]\nname=Irontec RPMs repository\nbaseurl=http://packages.irontec.com/centos/$releasever/$basearch/\nenabled=1\ngpgcheck=1" > /etc/yum.repos.d/irontec.repo && \
    rpm --import http://packages.irontec.com/public.key && \
    yum install -y sngrep && \
    # 清理 YUM 缓存，减少镜像体积
    yum clean all && rm -rf /var/cache/yum/*

# 工作目录切换到 /usr/src（统一管理源码）
WORKDIR /usr/src

# 修复3：按依赖顺序编译安装第三方库（清理源码包，减少镜像体积）
## 1. 安装 libsndfile
RUN wget http://www.nangrui.com/libsndfile-1.0.28.tar.gz && \
    tar zxvf libsndfile-1.0.28.tar.gz && cd libsndfile-1.0.28 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 && \
    make && make install && \
    cp /usr/lib64/pkgconfig/sndfile.pc /usr/lib64/pkgconfig/ && \
    ldconfig && \
    cd .. && rm -rf libsndfile-1.0.28*

## 2. 安装 opus（源码覆盖更新，确保版本兼容）
RUN wget https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz && \
    tar zxvf opus-1.3.1.tar.gz && cd opus-1.3.1 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf opus-1.3.1*

## 3. 安装 lame
RUN wget https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz && \
    tar zxvf lame-3.100.tar.gz && cd lame-3.100 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf lame-3.100*

## 4. 安装 mpg123
RUN wget https://downloads.sourceforge.net/project/mpg123/mpg123/1.31.3/mpg123-1.31.3.tar.bz2 && \
    tar jxvf mpg123-1.31.3.tar.bz2 && cd mpg123-1.31.3 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf mpg123-1.31.3*

## 5. 安装 postgresql 13.9
RUN wget https://ftp.postgresql.org/pub/source/v13.9/postgresql-13.9.tar.gz && \
    tar zxvf postgresql-13.9.tar.gz && cd postgresql-13.9 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf postgresql-13.9*

## 6. 安装 sofia-sip（Freeswitch 核心依赖）
RUN wget https://github.com/freeswitch/sofia-sip/archive/refs/tags/v1.13.17.tar.gz -O sofia-sip-1.13.17.tar.gz && \
    tar zxvf sofia-sip-1.13.17.tar.gz && mv sofia-sip-1.13.17 sofia-sip && \
    cd sofia-sip && \
    ./bootstrap.sh --force && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared --with-pkgconfigdir=/usr/lib64/pkgconfig && \
    make && make install && \
    ldconfig && \
    pkg-config --modversion sofia-sip-ua && \
    cd .. && rm -rf sofia-sip-1.13.17.tar.gz

## 7. 安装 spandsp
RUN git clone https://github.com/freeswitch/spandsp.git && \
    cd spandsp && \
    git checkout -b finecode20230705 0d2e6ac65e0e8f53d652665a743015a88bf048d4 && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf spandsp/.git  # 清理 git 缓存

## 8. 安装 libks
RUN git clone https://github.com/signalwire/libks.git && \
    cd libks && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf libks/.git

# 修复4：编译安装 Freeswitch（合并 configure，避免重复编译）
RUN git clone -b v1.11 https://github.com/signalwire/freeswitch.git && \
    cd freeswitch && \
    ./bootstrap.sh -j && \
    # 同时启用 PostgreSQL 和 ODBC 支持，指定 pkgconfig 路径
    export PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/local/lib/pkgconfig && \
    ./configure \
      --enable-core-pgsql-support \
      --enable-core-odbc-support \
      --prefix=/usr/local/freeswitch \
      --libdir=/usr/lib64 && \
    # 多核编译（加速构建）
    make -j$(nproc) && \
    make install && \
    # 安装声音文件和背景音乐
    make cd-sounds-install && \
    make cd-moh-install && \
    # 清理编译缓存，减少镜像体积
    cd .. && rm -rf freeswitch/.git && rm -rf /usr/src/*/.git

# 修复5：前台启动 Freeswitch，确保容器不退出
CMD ["/usr/local/freeswitch/bin/freeswitch", "-nonat", "-console", "-nort"]
