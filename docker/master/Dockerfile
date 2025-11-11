FROM registry.cn-hangzhou.aliyuncs.com/nangrui/centos:centos7.9.2009

WORKDIR /usr/src

# 步骤 1：安装基础工具 + 配置国内源（先换源，避免后续下载超时）
RUN sed -i 's|^baseurl=.*|baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/|' /etc/yum.repos.d/CentOS-Base.repo \
    && sed -i 's|^mirrorlist=.*|#mirrorlist=|' /etc/yum.repos.d/CentOS-Base.repo \
    && yum install -y vim git wget lrzsz \
    && yum clean all && yum makecache fast

# 步骤 2：安装 Freeswitch 官方源 + EPEL 源（提供核心依赖）
RUN yum install -y https://files.freeswitch.org/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release \
    && yum clean all && yum makecache fast

# 步骤 3：安装 YUM 工具和编译基础依赖（无冲突包，成功率高）
RUN yum install -y yum-utils yum-plugin-ovl centos-release-scl rpmdevtools \
    autoconf automake libtool openssl-devel libtiff-devel libjpeg-turbo-devel \
    gcc-c++ sqlite-devel libcurl-devel speex-devel ldns-devel libedit-devel \
    yasm lua-devel opus-devel ncurses-devel libpcap-devel pcre-devel \
    postgresql-devel libshout-devel lame-devel libmpg123-devel \
    unixODBC unixODBC-devel mysql-connector-odbc

# 步骤 4：配置 Irontec 源（仅用于安装 sngrep，无兼容性问题）
RUN echo -e "[irontec]\nname=Irontec RPMs repository\nbaseurl=http://packages.irontec.com/centos/$releasever/$basearch/\nenabled=1\ngpgcheck=1\ngpgkey=http://packages.irontec.com/public.key\n" > /etc/yum.repos.d/irontec.repo \
    && yum clean all && yum makecache fast

# 步骤 5：安装 sngrep + libopus-devel（从 EPEL 源获取，移除 linuxtech 源）
RUN yum install -y sngrep libopus-devel

# 后续步骤不变（拉取源码、编译安装）
RUN git clone https://github.com/freeswitch/sofia-sip.git \
    && git clone https://github.com/freeswitch/spandsp.git \
    && git clone -b v1.11 https://github.com/signalwire/freeswitch.git

RUN cd sofia-sip && ./bootstrap.sh && ./configure && make -j $(nproc) && make install && make clean

RUN cd spandsp && git checkout -b finecode20230705 0d2e6ac65e0e8f53d652665a743015a88bf048d4 \
    && ./bootstrap.sh && ./configure && make -j $(nproc) && make install && make clean

RUN wget http://www.nangrui.com/libsndfile-1.0.28.tar.gz \
    && tar zxvf libsndfile-1.0.28.tar.gz \
    && cd libsndfile-1.0.28 && ./configure && make -j $(nproc) && make install && make clean \
    && cp /usr/local/lib/pkgconfig/sndfile.pc /usr/lib64/pkgconfig \
    && rm -rf libsndfile-1.0.28.tar.gz libsndfile-1.0.28

RUN cd freeswitch && ./bootstrap.sh -j $(nproc) \
    && export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    && ./configure --enable-core-pgsql-support --enable-core-odbc-support \
    && make -j $(nproc) && make install && make -j $(nproc) cd-sounds-install && make -j $(nproc) cd-moh-install \
    && make clean

EXPOSE 5060/tcp 5060/udp 5061/tcp 5061/udp 8021/tcp

CMD ["/usr/local/freeswitch/bin/freeswitch"]
