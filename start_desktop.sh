#!/bin/bash

# For start XVnc and xfce4
chmod -f 777 /tmp/.X11-unix
# From: https://superuser.com/questions/806637/xauth-not-creating-xauthority-file (squashes complaints about .Xauthority)
touch ~/.Xauthority
xauth generate :0 . trusted
#/srv/TurboVNC/bin/vncserver -SecurityTypes None

# Start NoVNC. self.pem is a self-signed cert.
#if [ $? -eq 0 ] ; then
#    /srv/noVNC/utils/launch.sh --vnc localhost:5901 --cert /root/self.pem --listen 40001;
#fi

# Ustawienie strefy czasowej
if ! [[ -z "$TIME_ZONE" ]]; then
  ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime
fi

mkdir /etc/jupyter
ln -s /opt/etc/jupyterhub/jupyter_notebook_config.py /etc/jupyter/jupyter_notebook_config.py

# Jednokrotna aktualizacja liku hosts przy starcie, pozniej wywolywane systematycznie przez monit-a
/etc/monit.d/start_sync_hosts.sh

MONIT_OPT=-I
if ! [[ -z "$DEBUG" ]]; then
  MONIT_OPT="$MONIT_OPT -vvv"
fi
monit $MONIT_OPT
