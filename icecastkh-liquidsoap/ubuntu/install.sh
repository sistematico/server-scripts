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

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LGRAY='\033[0;37m'
DGRAY='\033[1;30m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LBLUE='\033[1;34m'
LPURPLE='\033[1;35m'
LCYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit
fi

if [ -f .env ]; then
    . .env
else
    echo ".env file not found."
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

printf "${PURPLE}************************************************\n"
printf "${GREEN} ___                       _           \n"
printf "${GREEN}|_ _|___ ___  ___ __ _ ___| |_     _   \n"
printf "${GREEN} | |/ __/ _ \/ __/ _\` / __| __|  _| |_ \n"
printf "${GREEN} | | (_|  __/ (_| (_| \__ \ |_  |_   _|\n"
printf "${GREEN}|___\___\___|\___\__,_|___/\__|   |_|  \n"
printf "\n"                                     
printf "${RED} _     _             _     _ ____                    \n"
printf "${RED}| |   (_) __ _ _   _(_) __| / ___|  ___   __ _ _ __  \n"
printf "${RED}| |   | |/ _\` | | | | |/ _\` \___ \ / _ \ / _\` | '_ \ \n"
printf "${RED}| |___| | (_| | |_| | | (_| |___) | (_) | (_| | |_) |\n"
printf "${RED}|_____|_|\__, |\__,_|_|\__,_|____/ \___/ \__,_| .__/ \n"
printf "${RED}            |_|                               |_|    \n"
printf "\n"
printf "${YELLOW} ___           _        _ _           \n"
printf "${YELLOW}|_ _|_ __  ___| |_ __ _| | | ___ _ __ \n"
printf "${YELLOW} | || '_ \/ __| __/ _\` | | |/ _ \ '__|\n"
printf "${YELLOW} | || | | \__ \ || (_| | | |  __/ |   \n"
printf "${YELLOW}|___|_| |_|___/\__\__,_|_|_|\___|_|   \n"
printf "${PURPLE}************************************************${NC}\n"                                     


nginx_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/nginx/sites-available/nginx.conf)"
icecast_service_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/systemd/system/icecast-kh.service)"
liquidsoap_service_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/systemd/system/liquidsoap.service)"
cron_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/opt/liquidsoap/scripts/cron.sh)"
icecast_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/icecast2/icecast-kh.xml"
radio_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/liquidsoap/radio.liq"
youtube_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/common/stubs/etc/liquidsoap/youtube.liq"

printf "${PURPLE}*${NC} Updating & Upgrading system...\n"
apt update -y -q &> /dev/null
apt upgrade -y -q &> /dev/null

printf "${PURPLE}*${NC} Installing required dependencies...\n"
apt install -y -q build-essential pkg-config opam \
                libpcre3-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev \ 
                libvorbis-dev libmp3lame-dev libmad0-dev libtheora-dev \ 
                libssl-dev openssl curl certbot python3-certbot-dns-cloudflare nginx youtube-dl \ 
                libavcodec-dev libavdevice-dev libavfilter-dev libavformat-dev libavutil-dev libswresample-dev libswscale-dev &> /dev/null

opam init -qy 1> /dev/null 2> /dev/null
eval $(opam env) 2> /dev/null
opam install sedlex pcre menhir menhirLib dtools duppy mm ssl camomile vorbis lame mad cry ffmpeg -y 1> /dev/null 2> /dev/null
opam update -y 1> /dev/null 2> /dev/null
opam upgrade -y 1> /dev/null 2> /dev/null

printf "${PURPLE}*${NC} Disabling and stopping old systemd units...\n"
systemctl is-active --quiet liquidsoap && systemctl stop liquidsoap
systemctl is-active --quiet icecast && systemctl stop icecast
systemctl is-active --quiet icecast-kh && systemctl stop icecast-kh
systemctl is-active --quiet nginx && systemctl stop nginx

printf "${PURPLE}*${NC} Creating icecast user...\n"
pass=$(perl -e 'print crypt($ARGV[0], "password")' "$ICECAST_PW")

if ! id "icecast" &>/dev/null; then
    useradd -m -p "$pass" -d /home/icecast -s /bin/bash -c "Icecast System User" -U icecast
else
    usermod -m -p "$pass" -d /home/icecast -s /bin/bash -c "Icecast System User" icecast
fi

printf "${PURPLE}*${NC} Creating liquidsoap user...\n"
pass=$(perl -e 'print crypt($ARGV[0], "password")' "$LIQUIDSOAP_PW")

if ! id "liquidsoap" &>/dev/null; then
    useradd -m -p "$pass" -d /opt/liquidsoap -s /bin/bash -c "LiquidSoap System User" -U liquidsoap
else
    usermod -m -p "$pass" -d /opt/liquidsoap -s /bin/bash -c "LiquidSoap System User" liquidsoap
fi

mkdir -p /var/log/icecast /etc/icecast /etc/liquidsoap /opt/liquidsoap/{playlist,scripts,music} 2> /dev/null

printf "${PURPLE}*${NC} Installing icecast-kh from sources...\n"
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

printf "${PURPLE}*${NC} Installing liquidsoap from sources...\n"
# LiquidSoap Build
if ! command -v liquidsoap &> /dev/null
then
    curl -sL https://github.com/savonet/liquidsoap/releases/download/v${LIQUIDSOAP_VERSION}/liquidsoap-${LIQUIDSOAP_VERSION}.tar.bz2 > /tmp/liquidsoap-${LIQUIDSOAP_VERSION}.tar.bz2
    tar xjf /tmp/liquidsoap-${LIQUIDSOAP_VERSION}.tar.bz2 -C /tmp/

    cd /tmp/liquidsoap-${LIQUIDSOAP_VERSION}

    ./configure --prefix=/usr
    make
    make install
fi

printf "${PURPLE}*${NC} Creating certs...\n"
cat >/etc/cloudflare.ini <<-EOL
dns_cloudflare_email = ${CLOUDFLARE_EMAIL}
dns_cloudflare_api_key = ${CLOUDFLARE_TOKEN}
EOL

chmod 600 /etc/cloudflare.ini

if [ ! -f /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem ] && [ ! -f /etc/letsencrypt/live/${STREAM_URL}/privkey.pem ]; then
    certbot certonly -n -m "${CLOUDFLARE_EMAIL}" --agree-tos --dns-cloudflare --dns-cloudflare-credentials /etc/cloudflare.ini --webroot-path="/usr/share/icecast/web" -d "${STREAM_URL}"
fi

if [ -f /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${STREAM_URL}/privkey.pem ]; then
    cat /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem /etc/letsencrypt/live/${STREAM_URL}/privkey.pem > /usr/share/icecast/icecast.pem
    
    chmod 600 /usr/share/icecast/icecast.pem
else
    echo "Error in certificates generation. Check your STREAM_URL in .env file."
    exit 1
fi

[ -L /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default

printf "${PURPLE}*${NC} Creating nginx proxy...\n"
printf "$nginx_tpl" | sed -e "s|STREAM_URL|$STREAM_URL|" > /etc/nginx/sites-available/${STREAM_URL}

ln -sf /etc/nginx/sites-available/${STREAM_URL} /etc/nginx/sites-enabled/${STREAM_URL}

[ ! -d /etc/tmpfiles.d ] && mkdir /etc/tmpfiles.d

cat >/etc/tmpfiles.d/liquidsoap.conf <<EOL
f /run/liquidsoap.pid 0644 liquidsoap liquidsoap
EOL

printf "${PURPLE}*${NC} Creating systemd units...\n"
printf "$icecast_service_tpl" > /etc/systemd/system/icecast-kh.service
printf "$liquidsoap_service_tpl" > /etc/systemd/system/liquidsoap.service

curl -sL "$icecast_tpl" | sed -e "s|SOURCE_PASSWD|$SOURCE_PASSWD|" -e "s|RELAY_PASSWD|$RELAY_PASSWD|" -e "s|ADMIN_PASSWD|$ADMIN_PASSWD|" > /etc/icecast/icecast.xml
curl -sL "$radio_tpl" | sed -e "s|SOURCE_PASSWD|$SOURCE_PASSWD|" -e "s|STREAM_FORMAT|$STREAM_FORMAT|" -e "s|STREAM_NAME|$STREAM_NAME|" -e "s|STREAM_DESCRIPTION|$STREAM_DESCRIPTION|" -e "s|STREAM_GENRE|$STREAM_GENRE|" > /etc/liquidsoap/radio.liq

printf "$cron_tpl" > /opt/liquidsoap/scripts/cron.sh

printf "${PURPLE}*${NC} Downloading samples...\n"
[ ! -f '/opt/liquidsoap/music/Chico Rose x 71 Digits – Somebody is Watching Me.mp3' ] && \ 
    curl -sLo '/opt/liquidsoap/music/Chico Rose x 71 Digits – Somebody is Watching Me.mp3' 'https://drive.google.com/uc?export=download&id=1y0xNhh7xljd2453Q-vCZshfw7ncjJ3eW'

[ ! -f '/opt/liquidsoap/music/DubDogz - Baila Conmigo.mp3' ] && \ 
    curl -sLo '/opt/liquidsoap/music/DubDogz - Baila Conmigo.mp3' 'https://drive.google.com/uc?export=download&id=1JeJA3LiEZdvi-Mg-UAVCxluv0oAGWvPR'

[ ! -f '/opt/liquidsoap/music/Lil Peep & XXXTENTACION - Falling Down.mp3' ] && \ 
    curl -sLo '/opt/liquidsoap/music/Lil Peep & XXXTENTACION - Falling Down.mp3' 'https://drive.google.com/uc?export=download&id=1yMjB1A6YUdXA4RkiL-eYaPVhXGG9KLdo'

[ ! -f '/opt/liquidsoap/music/Lykke Li - I Follow Rivers.mp3' ] && \ 
    curl -sLo '/opt/liquidsoap/music/Lykke Li - I Follow Rivers.mp3' 'https://drive.google.com/uc?export=download&id=186I-JL5ncUdg6TC8ootbeDJ12jHEJHFj'

[ ! -f '/opt/liquidsoap/music/Rag n Bone Man - Giant.mp3' ] && \ 
    curl -sLo '/opt/liquidsoap/music/Rag n Bone Man - Giant.mp3' 'https://drive.google.com/uc?export=download&id=1AT8vukswiyQoiEDd4xlq9tCxE4ejpk39'

[ ! -f '/opt/liquidsoap/music/Vintage Culture, Bruno Be feat Manimal - Human at Burning Man.mp3' ] && \ 
    curl -sLo '/opt/liquidsoap/music/Vintage Culture, Bruno Be feat Manimal - Human at Burning Man.mp3' 'https://drive.google.com/uc?export=download&id=1I4uN5yauNETAjRyqnt4sBX6JLKfYpY9c'

if ! grep --quiet liquidsoap /etc/crontab; then
    echo '*/2 * * * * liquidsoap /bin/bash /opt/liquidsoap/scripts/cron.sh main 2>&1' >> /etc/crontab
fi

[ ! -d /usr/share/liquidsoap/1.4.1 ] && mkdir /usr/share/liquidsoap/1.4.1

printf "${PURPLE}*${NC} Running first cron job(playlists)...\n"
/bin/bash /opt/liquidsoap/scripts/cron.sh main

touch /var/log/icecast.log /var/log/liquidsoap.log

printf "${PURPLE}*${NC} Fixing permissions...\n"
chown -R icecast:icecast /var/log/icecast /usr/share/icecast /etc/icecast /var/log/icecast.log
chown -R liquidsoap:liquidsoap /etc/liquidsoap /opt/liquidsoap /var/log/liquidsoap.log

[ ! -d /usr/share/liquidsoap/libs ] && mkdir -p /usr/share/liquidsoap/libs
ln -fs /usr/share/liquidsoap/libs /usr/share/liquidsoap/1.4.1

systemctl daemon-reload
systemctl enable icecast liquidsoap
systemctl restart nginx cron
systemctl start icecast-kh liquidsoap
