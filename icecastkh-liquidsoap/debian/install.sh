#!/usr/bin/env bash
#
# Arquivo: install.sh
#
# Mais um script feito com ❤️ por: 
# - "Lucas Saliés Brum" <lucas@archlinux.com.br>
# 
# Created on: 25/01/2022 10:04:47
# Updated on: 29/01/2022 05:24:04

ICECAST_VERSION="2.4.0-kh15"
LIQUIDSOAP_VERSION="2.0.2"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit
fi

[ -f .env ] && . .env || (echo ".env file not found." && exit 1)

export DEBIAN_FRONTEND=noninteractive

nginx_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/debian/icecastkh-liquidsoap/stubs/nginx.conf)"
icecast_service_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/debian/icecastkh-liquidsoap/stubs/icecast-kh.service)"
liquidsoap_service_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/debian/icecastkh-liquidsoap/stubs/liquidsoap.service)"
cron_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/debian/icecastkh-liquidsoap/stubs/cron.sh)"
icecast_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/icecast/icecast-kh.xml"
radio_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/liquidsoap/radio.liq"
youtube_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/liquidsoap/youtube.liq"

apt update -y -q &> /dev/null
apt upgrade -y -q &> /dev/null

#apt install -y -q build-essential libxml2-dev libxslt1-dev libcurl4-openssl-dev libvorbis-dev libtheora-dev libssl-dev openssl curl certbot python3-certbot-dns-cloudflare nginx youtube-dl &> /dev/null
apt install -y -q build-essential libxml2-dev libxslt1-dev libcurl4-openssl-dev libvorbis-dev libtheora-dev libssl-dev openssl curl certbot python3-certbot-dns-cloudflare nginx youtube-dl &> /dev/null

systemctl is-active --quiet liquidsoap && systemctl stop liquidsoap
systemctl is-active --quiet icecast && systemctl stop icecast
systemctl is-active --quiet nginx && systemctl stop nginx

pass=$(perl -e 'print crypt($ARGV[0], "password")' "$ICECAST_PW")

if ! id "icecast" &>/dev/null; then
    useradd -m -p "$pass" -d /home/icecast -s /bin/bash -c "Icecast System User" -U icecast
else
    usermod -m -p "$pass" -d /home/icecast -s /bin/bash -c "Icecast System User" icecast
fi

pass=$(perl -e 'print crypt($ARGV[0], "password")' "$LIQUIDSOAP_PW")

if ! id "liquidsoap" &>/dev/null; then
    useradd -m -p "$pass" -d /opt/liquidsoap -s /bin/bash -c "LiquidSoap System User" -U liquidsoap
else
    usermod -m -p "$pass" -d /opt/liquidsoap -s /bin/bash -c "LiquidSoap System User" liquidsoap
fi

mkdir -p /var/log/icecast /etc/icecast /etc/liquidsoap /opt/liquidsoap/{playlist,scripts,music} 2> /dev/null

# Icecast KH Build
if ! command -v icecast &> /dev/null
then
    curl -sL https://github.com/karlheyes/icecast-kh/archive/refs/tags/icecast-${ICECAST_VERSION}.tar.gz > /tmp/icecast-${ICECAST_VERSION}.tar.gz
    tar xzf /tmp/icecast-${ICECAST_VERSION}.tar.gz -C /tmp/

    cd /tmp/icecast-kh-icecast-${ICECAST_VERSION}

    ./configure --prefix=/usr --with-curl-config=/usr/bin/curl-config --with-openssl
    make
    make install
fi

# LiquidSoap Build
if ! command -v liquidsoap &> /dev/null
then
    curl -sL https://github.com/savonet/liquidsoap/releases/download/v${LIQUIDSOAP_VERSION}/liquidsoap-${LIQUIDSOAP_VERSION}.tar.bz2 > /tmp/liquidsoap-${LIQUIDSOAP_VERSION}.tar.bz2
    tar xjf /tmp/liquidsoap-${LIQUIDSOAP_VERSION}.tar.bz2 -C /tmp/

    cd /tmp/liquidsoap-${LIQUIDSOAP_VERSION}

    #./configure --prefix=/usr --with-curl-config=/usr/bin/curl-config --with-openssl
    ./configure --prefix=/usr
    make
    make install
fi

cat >/etc/cloudflare.ini <<-EOL
dns_cloudflare_email = ${CLOUDFLARE_EMAIL}
dns_cloudflare_api_key = ${CLOUDFLARE_TOKEN}
EOL

chmod 600 /etc/cloudflare.ini

if [ ! -f /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem ] && [ ! -f /etc/letsencrypt/live/${STREAM_URL}/privkey.pem ]; then
    certbot certonly -n -m "${CLOUDFLARE_EMAIL}" --agree-tos --dns-cloudflare --dns-cloudflare-credentials /etc/cloudflare.ini --webroot-path="/usr/local/share/icecast/web" -d "${STREAM_URL}"
fi

if [ -f /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${STREAM_URL}/privkey.pem ]; then
    cat /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem /etc/letsencrypt/live/${STREAM_URL}/privkey.pem > /usr/local/share/icecast/icecast.pem
    
    chmod 600 /usr/local/share/icecast/icecast.pem
else
    echo "Error in certificates generation. Check your STREAM_URL in .env file."
    exit 1
fi

[ -L /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default

printf "$nginx_tpl" | sed -e "s|STREAM_URL|$STREAM_URL|" > /etc/nginx/sites-available/${STREAM_URL}

ln -sf /etc/nginx/sites-available/${STREAM_URL} /etc/nginx/sites-enabled/${STREAM_URL}

[ ! -d /etc/tmpfiles.d ] && mkdir /etc/tmpfiles.d

cat >/etc/tmpfiles.d/liquidsoap.conf <<EOL
f /run/liquidsoap.pid 0644 liquidsoap liquidsoap
EOL

printf "$icecast_service_tpl" > /etc/systemd/system/icecast-kh.service
printf "$liquidsoap_service_tpl" > /etc/systemd/system/liquidsoap.service

curl -sL "$icecast_tpl" | sed -e "s|SOURCE_PASSWD|$SOURCE_PASSWD|" -e "s|RELAY_PASSWD|$RELAY_PASSWD|" -e "s|ADMIN_PASSWD|$ADMIN_PASSWD|" > /etc/icecast/icecast.xml
curl -sL "$radio_tpl" | sed -e "s|SOURCE_PASSWD|$SOURCE_PASSWD|" > /etc/liquidsoap/radio.liq

printf "$cron_tpl" > /opt/liquidsoap/scripts/cron.sh

curl -sLo /opt/liquidsoap/music/1949-Hitz.mp3 'https://ia800609.us.archive.org/25/items/1949Hitz1/1949%20Hitz%20%23%201.mp3'
curl -sLo /opt/liquidsoap/music/house-of-the-rising.mp3 'https://ia601601.us.archive.org/14/items/78_house-of-the-rising-sun_josh-white-and-his-guitar_gbia0001628b/_78_house-of-the-rising-sun_josh-white-and-his-guitar_gbia0001628b_01_3.8_CT_EQ.mp3'

if ! grep --quiet liquidsoap /etc/crontab; then
    echo '*/2 * * * * liquidsoap /bin/bash /opt/liquidsoap/scripts/cron.sh main 2>&1' >> /etc/crontab
fi

[ ! -d /usr/share/liquidsoap/1.4.1 ] && mkdir /usr/share/liquidsoap/1.4.1

/bin/bash /opt/liquidsoap/scripts/cron.sh main

touch /var/log/icecast.log /var/log/liquidsoap.log

chown -R icecast:icecast /var/log/icecast /usr/local/share/icecast /etc/icecast /var/log/icecast.log
chown -R liquidsoap:liquidsoap /etc/liquidsoap /opt/liquidsoap /var/log/liquidsoap.log

[ ! -d /usr/share/liquidsoap/libs ] && mkdir -p /usr/share/liquidsoap/libs
ln -fs /usr/share/liquidsoap/libs /usr/share/liquidsoap/1.4.1

systemctl daemon-reload
systemctl enable icecast liquidsoap
systemctl restart nginx cron
systemctl start icecast-kh liquidsoap
