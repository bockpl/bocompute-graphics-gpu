#!/bin/bash

# Start SSH process:
cp /opt/software/Blueocean/Configs/ssh/id_rsa /root/.ssh/
cp /opt/software/Blueocean/Configs/ssh/authorized_keys /root/.ssh/
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa
chmod 600 /root/.ssh/authorized_keys
/usr/sbin/sshd -D &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start SSH sshd process: $status"
  exit $status
fi

# Start PBIS process
(/opt/pbis/sbin/lwsmd --syslog& echo $! > /run/lwsmd.pid)
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start PBIS lwsmd process: $status"
  exit $status
fi

# Podlaczenie do domeny:
sleep 5; domainjoin-cli join --disable ssh adm.p.lodz.pl blueocean $(cat /opt/software/Blueocean/Configs/bo_password)

# Start SOGE process
sleep 5; source /etc/profile.d/sge.sh; /etc/init.d/sgeexecd.blueocean-v15 start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start SOGE sge_execd process: $status"
  exit $status
fi

# Start XVnc and xfce4
chmod -f 777 /tmp/.X11-unix
# From: https://superuser.com/questions/806637/xauth-not-creating-xauthority-file (squashes complaints about .Xauthority)
touch ~/.Xauthority
xauth generate :0 . trusted
/srv/TurboVNC/bin/vncserver -SecurityTypes None

# Start NoVNC. self.pem is a self-signed cert.
if [ $? -eq 0 ] ; then
    /srv/noVNC/utils/launch.sh --vnc localhost:5901 --cert /root/self.pem --listen 40001;
fi

sleep 3600