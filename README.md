# bocompute-graphics-gpu
Kontener obliczeniowy z możliwością wyświetlania grafiki 3D i obliczeń na GPU.

Przykładowe uruchomienie:
docker run -dt --name bocompute-gpu **--runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=all -e NVIDIA_DRIVER_CAPABILITIES=all** -h bo60 -v /srv/blueocean/opt:/opt -v /srv/blueocean/home:/home -v /etc/aliases:/etc/aliases -v /etc/msmtprc:/etc/msmtprc -p 6445:6445 --net cluster_network --ip 10.0.0.60  bocompute-gpu:develop

Globalne pliki konfiguracyjne dla środowiska graficznego i Jupyter Notebook znają się w katalogu **/opt/python/python3.6.7/etc/jupyter**
