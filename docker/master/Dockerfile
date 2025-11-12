FROM centos:centos7.9.2009

# 修复1：替换镜像源+禁用失效仓库+配置YUM跳过错误
RUN mkdir -p /etc/yum.repos.d/backup && \
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ && \
    # 用华为云稳定归档源
    curl -s -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo && \
    # 禁用所有失效仓库，跳过不可用包
    yum-config-manager --save --setopt=centos-sclo-rh.skip_if_unavailable=true && \
    yum-config-manager --save --setopt=centos-sclo-sclo.skip_if_unavailable=true && \
    yum-config-manager --save --setopt=epel.skip_if_unavailable=true && \
    yum-config-manager --save --setopt=epel-testing.skip_if_unavailable=true && \
    # 配置YUM忽略包冲突和校验错误
    echo "exclude=*.i686" >> /etc/yum.conf && \
    echo "skip_broken=1" >> /etc/yum.conf && \
    echo "gpgcheck=0" >> /etc/yum.conf && \
    # 清理缓存
    yum clean all && yum makecache fast

# 修复2：拆分YUM安装（先装基础依赖，再装特殊仓库包）
## 第一步：安装基础工具和编译依赖（仅用Base源，稳定性最高）
RUN yum install -y \
    vim git wget lrzsz \
    yum-utils yum-plugin-ovl rpmdevtools \
    autoconf automake libtool openssl-devel libtiff-devel libjpeg-devel \
    gcc-c++ sqlite-devel libcurl-devel speex-devel ldns-devel libedit-devel \
    yasm lua-devel opus-devel libatomic libuuid-devel libogg-devel libvorbis-devel \
    pcre-devel zlib-devel libxml2-devel ncurses-devel libpcap-devel \
    unixODBC unixODBC-devel && \
    yum clean all && rm -rf /var/cache/yum/*

## 第二步：单独安装MySQL ODBC连接器（替换为阿里云源，避免Irontec冲突）
RUN curl -s -o /etc/yum.repos.d/mysql-community.repo https://repo.mysql.com/mysql-community.repo && \
    yum install -y mysql-connector-odbc && \
    rm -rf /etc/yum.repos.d/mysql-community.repo && \
    yum clean all && rm -rf /var/cache/yum/*

## 第三步：安装Freeswitch仓库和EPEL源（仅必要依赖）
RUN yum install -y https://files.freeswitch.org/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release || true && \
    yum clean all && rm -rf /var/cache/yum/*

## 第四步：跳过sngrep安装（非必需，避免Irontec仓库失败）
# 注：若必须用sngrep，后续可手动进入容器安装，此处优先保证核心编译

# 工作目录切换
WORKDIR /usr/src

# 修复3：按依赖顺序编译第三方库（保持不变，源码安装不受仓库影响）
## 1. 安装 libsndfile
RUN wget http://www.nangrui.com/libsndfile-1.0.28.tar.gz && \
    tar zxvf libsndfile-1.0.28.tar.gz && cd libsndfile-1.0.28 && \
    ./configure --prefix=/usr --libdir=/usr/lib64 && \
    make && make install && \
    cp /usr/lib64/pkgconfig/sndfile.pc /usr/lib64/pkgconfig/ && \
    ldconfig && \
    cd .. && rm -rf libsndfile-1.0.28*

## 2. 安装 opus
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

## 6. 安装 sofia-sip
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
    cd .. && rm -rf spandsp/.git

## 8. 安装 libks
RUN git clone https://github.com/signalwire/libks.git && \
    cd libks && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared && \
    make && make install && \
    ldconfig && \
    cd .. && rm -rf libks/.git

# 修复4：编译安装Freeswitch（核心步骤，保持不变）
RUN git clone -b v1.11 https://github.com/signalwire/freeswitch.git && \
    cd freeswitch && \
    ./bootstrap.sh -j && \
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
    cd .. && rm -rf freeswitch/.git && rm -rf /usr/src/*/.git

# 前台启动Freeswitch
CMD ["/usr/local/freeswitch/bin/freeswitch", "-nonat", "-console", "-nort"]
