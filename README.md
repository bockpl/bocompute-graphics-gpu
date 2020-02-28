# bocompute-graphics-gpu
Kontener obliczeniowy z możliwością wyświetlania grafiki.

Przykładowe uruchomienie bez wsparcia GPU:
docker run -dt --name bo60 -h bo60 -v /srv/blueocean/opt:/opt -v /srv/blueocean/home:/home -v /etc/aliases:/etc/aliases -v /etc/msmtprc:/etc/msmtprc --net cluster_network --ip 10.0.0.60 bockpl/bocompute-graphics-gpu

Przykładowe uruchomienie ze wsparciem GPU:
docker run -dt --rm --name bo225 **--gpus all** -h bo225 --shm-size 2g -v **/tmp/.X11-unix/X1:/tmp/.X11-unix/X1** -v /srv/blueocean/opt:/opt -v /srv/blueocean/home:/home --net cluster_network --ip 10.0.0.225 bockpl/bocompute-graphics-gpu

