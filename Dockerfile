FROM bockpl/bocompute:v2.1.0
LABEL maintainer="pawel.adamczyk.1@p.lodz.pl"

ARG SRVDIR=/srv
ARG SOURCEFORGE=https://sourceforge.net/projects
ARG TURBOVNC_VERSION=2.2.4
ARG VIRTUALGL_VERSION=2.6.3
ARG LIBJPEG_VERSION=2.0.2
ARG WEBSOCKIFY_VERSION=0.9.0
ARG NOVNC_VERSION=1.1.0

# Zmiana konfiguracji yum-a, dolaczanie stron MAN
RUN sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

# Szukanie zalznosci w yum
# yum whatprovides '*/libICE.so.6*'

# Instalacja/kompilacja noVNC
RUN cd /tmp && \
    yum install -y \
        wget \
        make \
        gcc && \
    wget https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz && \
    tar -xzf v${NOVNC_VERSION}.tar.gz -C ${SRVDIR} && \
#    wget https://github.com/novnc/websockify/archive/v${WEBSOCKIFY_VERSION}.tar.gz && \
#    tar -xzf v${WEBSOCKIFY_VERSION}.tar.gz -C ${SRVDIR} && \
    mv ${SRVDIR}/noVNC-${NOVNC_VERSION} ${SRVDIR}/noVNC && \
    chmod -R a+w ${SRVDIR}/noVNC && \
 #   mv ${SRVDIR}/websockify-${WEBSOCKIFY_VERSION} ${SRVDIR}/websockify && \
 #   cd ${SRVDIR}/websockify && make && \
 #   cd ${SRVDIR}/noVNC/utils && \
 #   ln -s ${SRVDIR}/websockify && \
 #  rm -f v${WEBSOCKIFY_VERSION}.tar.gz && \
    rm -f v${NOVNC_VERSION}.tar.gz && \
    yum clean all && \
    rm -rf /var/cache/yum

#yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \

# Instalacja srodowiska XFCE oraz dodatkowych bibliotek wsparcia grafiki
#
# Poprawka zwiazana z bledem xfce-polkit, usuniecie uruchamiania xfce-polkit przy starciesesji
# W celu poprawnego uruchomienia min xfdesktop dodano link i biblioteke libpng12
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum groups install -y Xfce && \
    yum remove -y xfce4-power-manager && \
    rm -rf /etc/xdg/autostart/xfce-polkit.desktop && \
    ln -s /usr/lib64/libbz2.so.1.0.6 /usr/lib64/libbz2.so.1.0 && \
    yum install -y libpng12 && \
    yum clean all && \
    rm -rf /var/cache/yum

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
        libXtst-1.2.3-1.el7.x86_64 \
        docker \
        singularity \
        git && \
     yum clean all && \
     rm -rf /var/cache/yum

# INstalacja elementow alphafold2
RUN pip3 install absl-py==0.13.0
RUN pip3 install docker==5.0.0

# Instalacja i wtepna konfiguracja TurboVNC i VirtualGL
RUN cd /tmp && \
    yum install -y perl && \
    yum install -y wget && \
    wget --no-check-certificate ${SOURCEFORGE}/turbovnc/files/${TURBOVNC_VERSION}/turbovnc-${TURBOVNC_VERSION}.x86_64.rpm && \
    wget --no-check-certificate ${SOURCEFORGE}/libjpeg-turbo/files/${LIBJPEG_VERSION}/libjpeg-turbo-official-${LIBJPEG_VERSION}.x86_64.rpm && \
    wget --no-check-certificate ${SOURCEFORGE}/virtualgl/files/${VIRTUALGL_VERSION}/VirtualGL-${VIRTUALGL_VERSION}.x86_64.rpm && \
    rpm -i *.rpm && \
    mv /opt/* ${SRVDIR}/ && \
    cp ${SRVDIR}/TurboVNC/bin/vncserver ${SRVDIR}/TurboVNC/bin/vncserver.org && \
    rm -f /tmp/*.rpm && \
    yum clean all && \
    rm -rf /var/cache/yum

# Czyszczenie srodowiska ze zbednych plikow i pakietow
RUN sed -i '/<Filename>exo-mail-reader.desktop<\/Filename>/d' /etc/xdg/menus/xfce-applications.menu && \
    rm -rf /usr/share/applications/exo-mail-reader.desktop && \
    rm -rf /usr/share/applications/tvncviewer.desktop && \
    yum erase -y pavucontrol && \
    yum clean all && \
    rm -rf /var/cache/yum

ENV PATH ${PATH}:${SRVDIR}/VirtualGL/bin:${SRVDIR}/TurboVNC/bin


# Poprawiony plik index.html w noVNC, dodaje sciezke proxowania dla klienta noVNC
ADD index.html ${SRVDIR}/noVNC/index.html

# Konfiguracja środowiska X
ADD Xcfg/xorg.conf /etc/X11/xorg.conf
ADD Xcfg/background.png /usr/share/backgrounds/images/default.png
ADD Xcfg/*.desktop /usr/share/applications/
ADD Xcfg/bo.menu /etc/xdg/menus/applications-merged/
ADD Xcfg/*.directory /usr/share/desktop-directories/


RUN mkdir -p /root/.vnc
# Ustawienie strony domowej w przegladarce na uci.p.lodz.pl
ARG HOME_PAGE="\1https:\/\/uci\.p\.lodz\.pl\/uslugi\/klaster-obliczeniowy\2"
ARG FF_CFG_FILE=/usr/lib64/firefox/defaults/preferences/all-redhat.js
RUN sed -i -E 's/(pref\("startup\.homepage_override_url",.*").*("\);)/'"${HOME_PAGE}"'/g' ${FF_CFG_FILE} && \
    sed -i -E 's/(pref\("startup\.homepage_welcome_url",.*").*("\);)/'"${HOME_PAGE}"'/g' ${FF_CFG_FILE} && \
    sed -i -E 's/(pref\("browser\.startup\.homepage",.*"data:text\/plain,browser\.startup\.homepage=).*("\);)/'"${HOME_PAGE}"'/g' ${FF_CFG_FILE}

ADD self.pem /tmp/self.pem
ADD start_desktop.sh /usr/local/bin/start_desktop.sh

CMD /usr/local/bin/start_desktop.sh
