FROM centos:centos7.9.2009

# 核心优化1：替换 CentOS 7 镜像源（官方源已失效）
RUN mkdir -p /etc/yum.repos.d/backup && \
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ && \
    wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo && \
    sed -i 's/mirrors.cloud.aliyuncs.com/mirrors.aliyun.com/g' /etc/yum.repos.d/CentOS-Base.repo && \
    yum clean all && yum makecache fast

# 核心优化2：合并 YUM 安装命令（减少分层，修复分隔符 &&）
RUN yum install -y \
    vim git wget lrzsz \
    yum-utils yum-plugin-ovl centos-release-scl rpmdevtools \
    autoconf automake libtool openssl-devel libtiff-devel libjpeg-devel \
    gcc-c++ sqlite-devel libcurl-devel speex-devel ldns-devel libedit-devel \
    yasm lua-devel opus-devel libatomic libuuid-devel libogg-devel libvorbis-devel \
    pcre-devel zlib-devel libxml2-devel ncurses-devel libpcap-devel \
    unixODBC unixODBC-devel mysql-connector-odbc && \
    # 安装 Freeswitch 仓库和 EPEL 源
    yum install -y https://files.freeswitch.org/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release && \
    # 安装 sngrep 依赖仓库
    echo -e "[irontec]\nname=Irontec RPMs repository\nbaseurl=http://packages.irontec.com/centos/$releasever/$basearch/\nenabled=1\ngpgcheck=1" > /etc/yum.repos.d/irontec.repo && \
    rpm --import http://packages.irontec.com/public.key && \
    yum install -y sngrep && \
    # 清理 YUM 缓存（减少镜像体积）
    yum clean all && rm -rf /var/cache/yum/*

# 优化3：按依赖顺序编译安装第三方库（避免重复安装，修复路径问题）
WORKDIR /usr/src

# 1. 安装 yasm（已通过 YUM 安装，无需源码编译，此处保留源码方式供选择）
# RUN wget https://downloads.sourceforge.net/project/yasm/yasm/1.3.0/yasm-1.3.0.tar.gz && \
#     tar zxvf yasm-1.3.0.tar.gz && cd yasm-1.3.0 && \
#     ./configure --prefix=/usr && make && make install && \
#     rm -rf ../yasm-1.3.0*  # 清理源码包

# 2. 安装 libsndfile
RUN wget http://www.nangrui.com/libsndfile-1.0.28.tar.gz && \
    tar zxvf libsndfile-1.0.28.tar.gz && cd libsndfile-1.0.28 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 && \
    make && make install && \
    cp /usr/lib64/pkgconfig/sndfile.pc /usr/lib64/pkgconfig/ && \
    ldconfig && \
    rm -rf ../libsndfile-1.0.28*

# 3. 安装 opus（YUM 已安装，此处源码安装可覆盖更新）
RUN wget https://archive.mozilla.org/pub/opus/opus-1.3.1.tar.gz && \
    tar zxvf opus-1.3.1.tar.gz && cd opus-1.3.1 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 && \
    make && make install && \
    ldconfig && \
    rm -rf ../opus-1.3.1*

# 4. 安装 lame
RUN wget https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz && \
    tar zxvf lame-3.100.tar.gz && cd lame-3.100 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    rm -rf ../lame-3.100*

# 5. 安装 mpg123
RUN wget https://downloads.sourceforge.net/project/mpg123/mpg123/1.31.3/mpg123-1.31.3.tar.bz2 && \
    tar jxvf mpg123-1.31.3.tar.bz2 && cd mpg123-1.31.3 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    rm -rf ../mpg123-1.31.3*

# 6. 安装 postgresql 13.9
RUN wget https://ftp.postgresql.org/pub/source/v13.9/postgresql-13.9.tar.gz && \
    tar zxvf postgresql-13.9.tar.gz && cd postgresql-13.9 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 && \
    make && make install && \
    ldconfig && \
    rm -rf ../postgresql-13.9*

# 7. 安装 sofia-sip
RUN wget https://github.com/freeswitch/sofia-sip/archive/refs/tags/v1.13.17.tar.gz -O sofia-sip-1.13.17.tar.gz && \
    tar zxvf sofia-sip-1.13.17.tar.gz && mv sofia-sip-1.13.17 sofia-sip && \
    cd sofia-sip && \
    ./bootstrap.sh --force && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared --with-pkgconfigdir=/usr/lib64/pkgconfig && \
    make && make install && \
    ldconfig && \
    pkg-config --modversion sofia-sip-ua && \
    rm -rf ../sofia-sip-1.13.17.tar.gz

# 8. 安装 spandsp
RUN git clone https://github.com/freeswitch/spandsp.git && \
    cd spandsp && \
    git checkout -b finecode20230705 0d2e6ac65e0e8f53d652665a743015a88bf048d4 && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf spandsp/.git  # 清理 git 缓存

# 9. 安装 libks
RUN git clone https://github.com/signalwire/libks.git && \
    cd libks && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf libks/.git

# 优化4：编译安装 Freeswitch（合并 configure，避免重复编译）
RUN git clone -b v1.11 https://github.com/signalwire/freeswitch.git && \
    cd freeswitch && \
    ./bootstrap.sh -j && \
    # 同时启用 PostgreSQL 和 ODBC 支持，避免重复 configure
    export PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/local/lib/pkgconfig && \
    ./configure \
      --enable-core-pgsql-support \
      --enable-core-odbc-support \
      --prefix=/usr/local/freeswitch \
      --libdir=/usr/lib64 && \
    make -j$(nproc) && \
    make install && \
    make cd-sounds-install && \
    make cd-moh-install && \
    # 清理编译缓存（减少镜像体积）
    cd .. && rm -rf freeswitch/.git && rm -rf /usr/src/*/.git

# 暴露 Freeswitch 默认端口（可选，根据需求调整）
EXPOSE 5060/tcp 5060/udp 5080/tcp 5080/udp 8021/tcp 16384-32768/udp

# 启动 Freeswitch（前台运行，确保容器不退出）
CMD ["/usr/local/freeswitch/bin/freeswitch", "-nonat", "-console"]
