# noVNC + TurboVNC + VirtualGL
# Useful links for the software we are using:
# http://novnc.com
# https://turbovnc.org
# https://virtualgl.org

#FROM opengl/1.1-glvnd-runtime-centos7
FROM nvidia/opengl:1.1-glvnd-runtime-centos7
LABEL maintainer="seweryn.sitarski@p.lodz.pl"

EXPOSE 6445/tcp

ARG SRVDIR=/srv
ARG SOURCEFORGE=https://sourceforge.net/projects
ARG TURBOVNC_VERSION=2.2.2
ARG VIRTUALGL_VERSION=2.6.2
ARG LIBJPEG_VERSION=2.0.2
ARG WEBSOCKIFY_VERSION=0.8.0
ARG NOVNC_VERSION=1.1.0


RUN \
# Tymczasowa instalacja git-a i ansible w celu uruchomienia playbook-ow
yum -y install yum-plugin-remove-with-leaves && \
yum -y install ansible && \
# Poprawka maksymalnej grupy systemowe konieczna ze wzgledu na wymagane GID grupy sgeadmin systemu SOGE, zaszlosc historyczna
sed -ie 's/SYS_GID_MAX               999/SYS_GID_MAX               997/g' /etc/login.defs && yum -y install git && \
# Pobranie repozytorium z playbook-ami
cd /; git clone https://github.com/bockpl/boplaybooks.git; cd /boplaybooks && \
# Instalacja systemu autoryzacji AD PBIS
ansible-playbook Playbooks/install_PBIS.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Skasowanie tymczasowego srodowiska git i ansible
yum -y remove git --remove-leaves && \
yum -y remove ansible --remove-leaves && \
cd /; rm -rf /boplaybooks

# Szukanie zalznosci w yum
# yum whatprovides '*/libICE.so.6*'

# Instalacja dodatku yum pozwalajacego usuwac pakiet z zaleznosciami
RUN yum -y install yum-plugin-remove-with-leaves && \
yum clean all && \
rm -rf /var/cache/yum

# Instalacja/kompilacja noVNC
RUN yum install -y \
        wget \
        make \
        gcc && \
    wget https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz && \
    tar -xzf v${NOVNC_VERSION}.tar.gz -C ${SRVDIR} && \
    wget https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz && \
    tar -xzf v${WEBSOCKIFY_VERSION}.tar.gz -C ${SRVDIR} && \
    mv ${SRVDIR}/noVNC-${NOVNC_VERSION} ${SRVDIR}/noVNC && \
    chmod -R a+w ${SRVDIR}/noVNC && \
    mv ${SRVDIR}/websockify-${WEBSOCKIFY_VERSION} ${SRVDIR}/websockify && \
    cd ${SRVDIR}/websockify && make && \
    cd ${SRVDIR}/noVNC/utils && \
    ln -s ${SRVDIR}/websockify && \
    yum remove -y --remove-leaves \
        wget \
        make \
        gcc && \
    yum clean all && \
    rm -rf /var/cache/yum

#yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \

# Instalacja srodowiska XFCE oraz dodatkowych bibliotek wsparcia grafiki
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum groups install -y Xfce && \
    yum install -y \
        mesa-demos-8.3.0-10.el7.x86_64 \
        libICE-1.0.9-9.el7.x86_64 \
        libSM-1.2.2-2.el7.x86_64 \
        libX11-1.6.5-2.el7.x86_64 \
        libglvnd-glx-1.0.1-0.8.git5baa1e5.el7.x86_64 \
        mesa-libGLU-9.0.0-4.el7.x86_64 \
        libXv-1.0.11-1.el7.x86_64 \
        libXtst-1.2.3-1.el7.x86_64 && \
    yum clean all && \
    rm -rf /var/cache/yum

# Instalacja i wtepna konfiguracja TurboVNC i VirtualGL
RUN cd /tmp && \
    yum install -y perl wget && \
    wget ${SOURCEFORGE}/turbovnc/files/${TURBOVNC_VERSION}/turbovnc-${TURBOVNC_VERSION}.x86_64.rpm && \
    wget ${SOURCEFORGE}/libjpeg-turbo/files/${LIBJPEG_VERSION}/libjpeg-turbo-official-${LIBJPEG_VERSION}.x86_64.rpm && \
    wget ${SOURCEFORGE}/virtualgl/files/${VIRTUALGL_VERSION}/VirtualGL-${VIRTUALGL_VERSION}.x86_64.rpm && \
    rpm -i *.rpm && \
    mv /opt/* ${SRVDIR}/ && \
    rm -f /tmp/*.rpm && \
    sed -i 's/$host:/unix:/g' ${SRVDIR}/TurboVNC/bin/vncserver

ENV PATH ${PATH}:${SRVDIR}/VirtualGL/bin:${SRVDIR}/TurboVNC/bin

COPY xorg.conf /etc/X11/xorg.conf
COPY index.html ${SRVDIR}/noVNC/index.html

# Install desktop background
COPY ./background.png /usr/share/backgrounds/images/default.png

# Expose whatever port NoVNC will serve from. In our case it will be 40001, see ./start_desktop.sh
EXPOSE 40001
ENV DISPLAY :1

RUN mkdir -p /root/.vnc
COPY ./xstartup.turbovnc /root/.vnc/xstartup.turbovnc
RUN chmod a+x /root/.vnc/xstartup.turbovnc

COPY self.pem /root/self.pem
COPY start_desktop.sh /usr/local/bin/start_desktop.sh

CMD /usr/local/bin/start_desktop.sh
