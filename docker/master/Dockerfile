FROM registry.cn-hangzhou.aliyuncs.com/nangrui/centos:centos7.9.2009
RUN yum install vim git wget lrzsz -y \
	$$ yum install -y https://files.freeswitch.org/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm epel-release \
	$$ yum install yum-utils \
	$$ yum install -y yum-plugin-ovl centos-release-scl rpmdevtools \
	$$ yum install autoconf automake libtool openssl* libtiff* libjpeg* -y \
	$$ yum install gcc-c++ -y \
	$$ yum install sqlite-devel -y \
	$$ yum install libcurl-devel -y \
	$$ yum install speex-devel -y \
	$$ yum install ldns-devel -y \
	$$ yum install libedit-devel -y \
	$$ yum install yasm -y \
	$$ yum install lua-devel -y \
	$$ yum install opus-devel -y 

RUN git clone https://github.com/freeswitch/sofia-sip.git /usr/src/sofia-sip
RUN git clone https://github.com/freeswitch/spandsp.git /usr/src/spandsp
RUN git clone -b v1.11 https://github.com/signalwire/freeswitch.git /usr/src/freeswitch

RUN cd /usr/src/sofia-sip && ./bootstrap.sh && ./configure && make && make install

RUN cd /usr/src/spandsp && git checkout -b finecode20230705 0d2e6ac65e0e8f53d652665a743015a88bf048d4 && ./bootstrap.sh && ./configure && make && make install

RUN cd /usr/src/freeswitch && ./bootstrap.sh -j
RUN touch /etc/yum.repos.d/linuxtech.repo
RUN echo -e "[linuxtech]\nname=LinuxTECH\nbaseurl=http://pkgrepo.linuxtech.net/el6/release/\nenabled=1\ngpgcheck=1\ngpgkey=http://pkgrepo.linuxtech.net/el6/release/RPM-GPG-KEY-LinuxTECH.NET\n" > /etc/yum.repos.d/linuxtech.repo
RUN yum install libopus-devel  -y
COPY ./build/modules.conf /usr/src/freeswitch/modules.conf
RUN cd /usr/src/freeswitch && ./bootstrap.sh -j
RUN yum install postgresql-devel -y
RUN cd /usr/src && wget http://www.nangrui.com/libsndfile-1.0.28.tar.gz
RUN cd /usr/src && tar zxvf libsndfile-1.0.28.tar.gz
RUN cd /usr/src/libsndfile-1.0.28 && ./configure
RUN cd /usr/src/libsndfile-1.0.28 && make && make install 
RUN cp /usr/local/lib/pkgconfig/sndfile.pc /usr/lib64/pkgconfig
RUN yum install yasm -y
RUN yum install libshout-devel lame-devel libmpg123-devel -y
RUN cd /usr/src/freeswitch && export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig && ./configure --enable-core-pgsql-support && make && make -j install && make -j cd-sounds-install && make -j cd-moh-install
RUN yum install ncurses-devel make libpcap-devel pcre-devel openssl-devel git gcc autoconf automake  -y
RUN echo -e "[irontec]\nname=Irontec RPMs repository\n" > /etc/yum.repos.d/irontec.repo
RUN echo 'baseurl=http://packages.irontec.com/centos/$releasever/$basearch/' >> /etc/yum.repos.d/irontec.repo
RUN rpm --import http://packages.irontec.com/public.key
RUN yum install sngrep -y
RUN yum install -y unixODBC unixODBC-devel mysql-connector-odbc
RUN cd /usr/src/freeswitch && export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig && ./configure --enable-core-odbc-support && make && make install
COPY ./build/conf /usr/local/freeswitch/conf
CMD ["/usr/local/freeswitch/bin/freeswitch"]
