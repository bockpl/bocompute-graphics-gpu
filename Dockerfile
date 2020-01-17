# noVNC + TurboVNC + VirtualGL
# Useful links for the software we are using:
# http://novnc.com
# https://turbovnc.org
# https://virtualgl.org

FROM nvidia/opengl:1.1-glvnd-runtime-centos7
LABEL maintainer="seweryn.sitarski@p.lodz.pl"

ARG SRVDIR=/srv
ARG SOURCEFORGE=https://sourceforge.net/projects
ARG TURBOVNC_VERSION=2.2.2
ARG VIRTUALGL_VERSION=2.6.2
ARG LIBJPEG_VERSION=2.0.2
ARG WEBSOCKIFY_VERSION=0.8.0
ARG NOVNC_VERSION=1.1.0

# Zmiana konfiguracji yum-a, dolaczanie stron MAN
RUN sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

# SGE
ADD soge/sgeexecd.blueocean-v15 /etc/init.d/
ADD soge/sge.sh /etc/profile.d/
ADD soge/module.sh /etc/profile.d/

ADD soge/jemalloc-3.6.0-1.el7.x86_64.rpm /tmp/jemalloc-3.6.0-1.el7.x86_64.rpm

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
# Instalacja wymagan dla systemu kolejkowego SOGE
ansible-playbook Playbooks/install_dep_SOGE.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja systemu Monit
ansible-playbook Playbooks/install_Monit.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla podsystemu Module
ansible-playbook Playbooks/install_dep_Module.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla oprogramowania Augustus
ansible-playbook Playbooks/install_dep_Augustus.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla oprogramownia Ansys v19.2
ansible-playbook Playbooks/install_dep_Ansys19.2.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla oprogramowania Games
ansible-playbook Playbooks/install_dep_Games.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla srodowiska MPI
ansible-playbook Playbooks/install_dep_MPI.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla srodowiska TensorBoard
ansible-playbook Playbooks/install_dep_TensorBoard.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja wymagan dla oprogramowanie MatLab
ansible-playbook Playbooks/install_dep_MatLab.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Instalacja narzedzi do interaktywnej wpracy w konsoli dla uzytkownikow klastra
ansible-playbook Playbooks/install_boaccess_tools.yml --connection=local --extra-vars "var_host=127.0.0.1" && \
# Skasowanie tymczasowego srodowiska git i ansible
yum -y remove git --remove-leaves && \
yum -y remove ansible --remove-leaves && \
cd /; rm -rf /boplaybooks

# Dodanie konfiguracji monit-a
ADD monit/monitrc /etc/
ADD monit/sshd.conf /etc/monit.d/
ADD monit/pbis.conf /etc/monit.d/
ADD monit/sge_exec.conf /etc/monit.d/
ADD monit/sync_hosts.conf /etc/monit.d/
ADD monit/start_sshd.sh /etc/monit.d/
ADD monit/start_pbis.sh /etc/monit.d/
ADD monit/start_sync_hosts.sh /etc/monit.d/

# Zmiana uprawnien konfiguracji monit-a
RUN chmod 700 /etc/monitrc

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
#
# Poprawka zwiazana z bledem xfce-polkit, usuniecie uruchamiania xfce-polkit przy starciesesji
# W celu poprawnego uruchomienia min xfdesktop dodano link i biblioteke libpng12
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum groups install -y Xfce && \
    rm -rf /etc/xdg/autostart/xfce-polkit.desktop && \
    ln -s /usr/lib64/libbz2.so.1.0.6 /usr/lib64/libbz2.so.1.0 && \
    yum install -y libpng12

# Dodatowe pakiety środowiska graficznego
RUN  yum install -y \
        mousepad \
	eog \
        firefox \
	mozilla-ublock-origin \
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

# Czyszczenie srodowiska ze zbednych plikow i pakietow
RUN    sed -i '/<Filename>exo-mail-reader.desktop<\/Filename>/d' /etc/xdg/menus/xfce-applications.menu && \
    rm -rf /usr/share/applications/exo-mail-reader.desktop && \
    rm -rf /usr/share/applications/tvncviewer.desktop && \
    yum erase -y pavucontrol && \
    yum clean all && \
    rm -rf /var/cache/yum

ENV PATH ${PATH}:${SRVDIR}/VirtualGL/bin:${SRVDIR}/TurboVNC/bin

# Konfiguracja środowiska X
COPY xorg.conf /etc/X11/xorg.conf
COPY index.html ${SRVDIR}/noVNC/index.html

ADD Xcfg/background.png /usr/share/backgrounds/images/default.png
ADD Xcfg/*.desktop /usr/share/applications/
ADD Xcfg/bo.menu /etc/xdg/menus/applications-merged/
ADD Xcfg/*.directory /usr/share/desktop-directories/


RUN mkdir -p /root/.vnc

COPY self.pem /tmp/self.pem
COPY start_desktop.sh /usr/local/bin/start_desktop.sh

ENV TIME_ZONE Europe/Warsaw

CMD /usr/local/bin/start_desktop.sh
