FROM registry.cn-hangzhou.aliyuncs.com/nangrui/centos:centos7.9.2009

# 配置工作目录
WORKDIR /usr/src

# 修复依赖安装：替换 $$ 为 &&、明确包名、添加国内源加速
RUN yum install -y vim git wget lrzsz \
    && yum install -y https://files.freeswitch.org/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release \
    && yum install -y yum-utils yum-plugin-ovl centos-release-scl rpmdevtools \
    && yum install -y autoconf automake libtool openssl-devel libtiff-devel libjpeg-turbo-devel \
    gcc-c++ sqlite-devel libcurl-devel speex-devel ldns-devel libedit-devel yasm lua-devel opus-devel \
    ncurses-devel libpcap-devel pcre-devel postgresql-devel libshout-devel lame-devel libmpg123-devel \
    unixODBC unixODBC-devel mysql-connector-odbc \
    # 配置第三方源（LinuxTECH + Irontec）
    && echo -e "[linuxtech]\nname=LinuxTECH\nbaseurl=http://pkgrepo.linuxtech.net/el6/release/\nenabled=1\ngpgcheck=1\ngpgkey=http://pkgrepo.linuxtech.net/el6/release/RPM-GPG-KEY-LinuxTECH.NET\n" > /etc/yum.repos.d/linuxtech.repo \
    && echo -e "[irontec]\nname=Irontec RPMs repository\nbaseurl=http://packages.irontec.com/centos/$releasever/$basearch/\nenabled=1\ngpgcheck=1\ngpgkey=http://packages.irontec.com/public.key\n" > /etc/yum.repos.d/irontec.repo \
    # 安装剩余依赖
    && yum install -y libopus-devel sngrep \
    # 国内源加速（阿里云 CentOS 7 源）
    && sed -i 's|^baseurl=.*|baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/|' /etc/yum.repos.d/CentOS-Base.repo \
    && sed -i 's|^mirrorlist=.*|#mirrorlist=|' /etc/yum.repos.d/CentOS-Base.repo \
    && yum clean all && yum makecache fast

# 拉取源码
RUN git clone https://github.com/freeswitch/sofia-sip.git \
    && git clone https://github.com/freeswitch/spandsp.git \
    && git clone -b v1.11 https://github.com/signalwire/freeswitch.git

# 编译安装 sofia-sip
RUN cd sofia-sip && ./bootstrap.sh && ./configure && make -j $(nproc) && make install && make clean

# 编译安装 spandsp（锁定特定 commit）
RUN cd spandsp && git checkout -b finecode20230705 0d2e6ac65e0e8f53d652665a743015a88bf048d4 \
    && ./bootstrap.sh && ./configure && make -j $(nproc) && make install && make clean

# 编译安装 libsndfile
RUN wget http://www.nangrui.com/libsndfile-1.0.28.tar.gz \
    && tar zxvf libsndfile-1.0.28.tar.gz \
    && cd libsndfile-1.0.28 && ./configure && make -j $(nproc) && make install && make clean \
    && cp /usr/local/lib/pkgconfig/sndfile.pc /usr/lib64/pkgconfig \
    && rm -rf libsndfile-1.0.28.tar.gz libsndfile-1.0.28

# 编译安装 Freeswitch（启用 PostgreSQL + ODBC 支持）
RUN cd freeswitch && ./bootstrap.sh -j $(nproc) \
    && export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    && ./configure --enable-core-pgsql-support --enable-core-odbc-support \
    && make -j $(nproc) && make install && make -j $(nproc) cd-sounds-install && make -j $(nproc) cd-moh-install \
    && make clean

# 暴露端口
EXPOSE 5060/tcp 5060/udp 5061/tcp 5061/udp 8021/tcp

# 启动命令
CMD ["/usr/local/freeswitch/bin/freeswitch"]
