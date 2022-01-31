#!/usr/bin/env bash
#
# Arquivo: install.sh
#
# Mais um script feito com ❤️ por: 
# - "Lucas Saliés Brum" <lucas@archlinux.com.br>
# 
# Created on: 25/01/2022 10:04:47
# Updated on: 29/01/2022 11:44:58

# https://downloads.xiph.org/releases/icecast/icecast-2.4.4.tar.gz
ICECAST_VERSION="2.4.4"
ICECAST_PATH="/usr/share/icecast"

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

printf "${PURPLE}***********************************************************************************************\n"
printf "${GREEN} ___                       _             _     _             _     _ ____                       \n"
printf "${GREEN}|_ _|___ ___  ___ __ _ ___| |_     _    | |   (_) __ _ _   _(_) __| / ___|  ___   __ _ _ __     \n"
printf "${GREEN} | |/ __/ _ \/ __/ _\` / __| __|  _| |_  | |   | |/ _\` | | | | |/ _\` \___ \ / _ \ / _\` | '_ \ \n"
printf "${GREEN} | | (_|  __/ (_| (_| \__ \ |_  |_   _| | |___| | (_| | |_| | | (_| |___) | (_) | (_| | |_) |   \n"
printf "${GREEN}|___\___\___|\___\__,_|___/\__|   |_|   |_____|_|\__, |\__,_|_|\__,_|____/ \___/ \__,_| .__/    \n"
printf "${GREEN}                                                    |_|                               |_|       \n"
printf "${YELLOW} ___           _        _ _           \n"
printf "${YELLOW}|_ _|_ __  ___| |_ __ _| | | ___ _ __ \n"
printf "${YELLOW} | || '_ \/ __| __/ _\` | | |/ _ \ '__|\n"
printf "${YELLOW} | || | | \__ \ || (_| | | |  __/ |   \n"
printf "${YELLOW}|___|_| |_|___/\__\__,_|_|_|\___|_|   \n"
printf "${PURPLE}***********************************************************************************************${NC}\n"
printf "\n"

nginx_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/icecast2-liquidsoap/common/stubs/etc/nginx/sites-available/nginx.conf)"
icecast_service_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/icecast2-liquidsoap/common/stubs/etc/systemd/system/icecast2.service)"
liquidsoap_service_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/icecast2-liquidsoap/common/stubs/etc/systemd/system/liquidsoap.service)"
cron_tpl="$(curl -s -L https://raw.githubusercontent.com/sistematico/server-scripts/main/icecast2-liquidsoap/common/stubs/opt/liquidsoap/scripts/cron.sh)"
icecast_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecast2-liquidsoap/common/stubs/etc/icecast2/icecast.xml"
radio_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecast2-liquidsoap/common/stubs/etc/liquidsoap/radio.liq"
youtube_tpl="https://raw.githubusercontent.com/sistematico/server-scripts/main/icecast2-liquidsoap/common/stubs/etc/liquidsoap/youtube.liq"

printf "${RED}*${NC} Disabling snap system...\n"
bash <(curl -sL https://raw.githubusercontent.com/sistematico/server-scripts/main/common/snap-disable.sh)

printf "${PURPLE}*${NC} Disabling and stopping old systemd units...\n"
systemctl --now disable iptables &> /dev/null
systemctl --now disable liquidsoap &> /dev/null
systemctl --now disable icecast2 &> /dev/null
systemctl --now disable icecast &> /dev/null
systemctl --now disable icecast-kh &> /dev/null

printf "${BLUE}*${NC} Updating & Upgrading system...\n"
apt update -y -q 1> /dev/null 2> /dev/null
apt upgrade -y -q 1> /dev/null 2> /dev/null

printf "${GREEN}*${NC} Installing required dependencies...\n"
apt install -y -q \
    build-essential \
    libxml2-dev \
    libxslt1-dev \
    libssl-dev \
    libvorbis-dev \
    unzip \
    bubblewrap \
    certbot \
    python3-certbot-dns-cloudflare \
    openssl \
    curl \
    cron \
    nginx \
    youtube-dl \
    debianutils \
    pkg-config \
    libcurl4-gnutls-dev \
    libmad0-dev \
    libmp3lame-dev \
    libogg-dev \
    libpcre3-dev \
    libsamplerate0-dev \
    libtag1-dev \
    libvorbis-dev \
    zlib1g-dev &> /dev/null

printf "${BLUE}*${NC} Building icecast...\n"
curl -sL https://downloads.xiph.org/releases/icecast/icecast-${ICECAST_VERSION}.tar.gz > /tmp/icecast-${ICECAST_VERSION}.tar.gz
tar xzf /tmp/icecast-${ICECAST_VERSION}.tar.gz -C /tmp/
cd /tmp/icecast-${ICECAST_VERSION}
#./configure --prefix=/usr --with-curl-config=/usr/bin/curl-config --with-openssl
./configure --prefix=/usr --with-openssl 1> /dev/null 2> /dev/null
make 1> /dev/null 2> /dev/null
make install 1> /dev/null 2> /dev/null

printf "${YELLOW}*${NC} Creating icecast user...\n"

pass=$(perl -e 'print crypt($ARGV[0], "password")' "$ICECAST_PW")
if ! id "icecast" &>/dev/null; then
    useradd -m -p "$pass" -d /home/icecast -s /bin/bash -c "Icecast System User" icecast
else
    usermod -m -p "$pass" -d /home/icecast -s /bin/bash -c "Icecast System User" icecast
fi

printf "${YELLOW}*${NC} Creating liquidsoap user...\n"

pass=$(perl -e 'print crypt($ARGV[0], "password")' "$LIQUIDSOAP_PW")
if ! id "icecast" &>/dev/null; then
    useradd -m -p "$pass" -d /opt/liquidsoap -s /bin/bash -c "Liquidsoap System User" liquidsoap
else
    usermod -m -p "$pass" -d /opt/liquidsoap -s /bin/bash -c "Icecast System User" liquidsoap
fi

mkdir -p /etc/icecast2 /etc/liquidsoap /opt/liquidsoap/{playlist,scripts} /opt/liquidsoap/music/{principal,eletronica,rock} 2> /dev/null

if ! grep --quiet 'opam-init' /opt/liquidsoap/.bash_profile; then
    echo 'test -r /opt/liquidsoap/.opam/opam-init/init.sh && . /opt/liquidsoap/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true' >> /opt/liquidsoap/.bash_profile
fi

chown -R liquidsoap:liquidsoap /etc/liquidsoap /opt/liquidsoap /var/log/liquidsoap.log /usr/share/liquidsoap 2> /dev/null

printf "${BLUE}*${NC} Building opam...\n"
curl -sL https://github.com/ocaml/opam/releases/download/2.1.2/opam-2.1.2-x86_64-linux > /tmp/opam-2.1.2-x86_64-linux
install /tmp/opam-2.1.2-x86_64-linux /usr/local/bin/opam

#if [ $(liquidsoap --version 2> /dev/null | head -n1) != "Liquidsoap 2.0.2" ]; then
    printf "${GREEN}*${NC} Installing liquidsoap through opam...\n"

    #export OPAMROOTISOK=true

    #opam init -qy 1> /dev/null 2> /dev/null
    sudo -H -u liquidsoap bash -c 'opam init -qy 1> /dev/null 2> /dev/null'

    #opam switch create 4.10.0 1> /dev/null 2> /dev/null
    sudo -H -u liquidsoap bash -c 'opam switch create 4.10.0 1> /dev/null 2> /dev/null'

    #eval $(opam env --switch=4.10.0) 1> /dev/null 2> /dev/null
    sudo -H -u liquidsoap bash -c 'eval $(opam env --switch=4.10.0) 1> /dev/null 2> /dev/null'

    #opam depext taglib mad lame vorbis cry samplerate ocurl liquidsoap -y 1> /dev/null 2> /dev/null
    sudo -H -u liquidsoap bash -c 'opam depext taglib mad lame vorbis cry samplerate ocurl liquidsoap -y 1> /dev/null 2> /dev/null'

    #opam install taglib mad lame vorbis cry samplerate ocurl liquidsoap -y 1> /dev/null 2> /dev/null
    sudo -H -u liquidsoap bash -c 'opam install taglib mad lame vorbis cry samplerate ocurl liquidsoap -y 1> /dev/null 2> /dev/null'

# else
#     printf "${YELLOW}*${NC} Liquidsoap already installed...\n"
# fi

curl -sL https://raw.githubusercontent.com/sistematico/server-scripts/main/icecast2-liquidsoap/common/stubs/usr/local/bin/startliquidsoap > /usr/local/bin/startliquidsoap
chmod +x /usr/local/bin/startliquidsoap

printf "${BLUE}*${NC} Creating certs...\n"
if [ ! -f /etc/cloudflare.ini ]; then
cat >/etc/cloudflare.ini <<-EOL
dns_cloudflare_email = ${CLOUDFLARE_EMAIL}
dns_cloudflare_api_key = ${CLOUDFLARE_TOKEN}
EOL
fi

chmod 600 /etc/cloudflare.ini

if [ ! -f /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem ] && [ ! -f /etc/letsencrypt/live/${STREAM_URL}/privkey.pem ]; then
    certbot certonly -n -m "${CLOUDFLARE_EMAIL}" --agree-tos --dns-cloudflare --dns-cloudflare-credentials /etc/cloudflare.ini --webroot-path="$ICECAST_PATH/web" -d "${STREAM_URL}"
fi

if [ -f /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${STREAM_URL}/privkey.pem ]; then
    cat /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem /etc/letsencrypt/live/${STREAM_URL}/privkey.pem > $ICECAST_PATH/icecast.pem
    
    chmod 600 $ICECAST_PATH/icecast.pem
else
    echo "Error in certificates generation. Check your STREAM_URL in .env file."
    exit 1
fi

[ -L /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default

if [ ! -f /etc/nginx/sites-available/${STREAM_URL} ]; then
    printf "${BLUE}*${NC} Creating nginx proxy...\n"
    printf "$nginx_tpl" | sed -e "s|STREAM_URL|$STREAM_URL|" > /etc/nginx/sites-available/${STREAM_URL}
fi

[ ! -L /etc/nginx/sites-enabled/${STREAM_URL} ] && ln -sf /etc/nginx/sites-available/${STREAM_URL} /etc/nginx/sites-enabled/${STREAM_URL}

[ ! -d /etc/tmpfiles.d ] && mkdir /etc/tmpfiles.d

cat >/etc/tmpfiles.d/liquidsoap.conf <<EOL
f /run/liquidsoap.pid 0644 liquidsoap liquidsoap
EOL

cat >/etc/tmpfiles.d/icecast.conf <<EOL
f /run/icecast2.pid 0644 icecast icecast
EOL

systemd-tmpfiles --create --remove # --boot

printf "${BLUE}*${NC} Creating systemd units...\n"
printf "$icecast_service_tpl" > /etc/systemd/system/icecast2.service
printf "$liquidsoap_service_tpl" > /etc/systemd/system/liquidsoap.service

[ "$STREAM_FORMAT" == "vorbis" ] && STREAM_EXT="ogg" || STREAM_EXT="mp3"

printf "${BLUE}*${NC} Configuring Icecast...\n"
curl -sL "$icecast_tpl" | sed -e "s|SOURCE_PASSWD|$SOURCE_PASSWD|" -e "s|RELAY_PASSWD|$RELAY_PASSWD|" -e "s|ADMIN_PASSWD|$ADMIN_PASSWD|" > /etc/icecast2/icecast.xml

printf "${BLUE}*${NC} Configuring LiquidSoap...\n"
curl -sL "$radio_tpl" | \
    sed -e "s|SOURCE_PASSWD|$SOURCE_PASSWD|" \
    -e "s|STREAM_FORMAT|$STREAM_FORMAT|g" \
    -e "s|STREAM_EXT|$STREAM_EXT|g" \
    -e "s|STREAM_NAME|$STREAM_NAME|g" \
    -e "s|STREAM_DESCRIPTION|$STREAM_DESCRIPTION|g" \
    -e "s|STREAM_GENRE|$STREAM_GENRE|g" > /etc/liquidsoap/radio.liq

curl -sL "$youtube_tpl" | \
    sed -e "s|SOURCE_PASSWD|$SOURCE_PASSWD|" \
    -e "s|STREAM_FORMAT|$STREAM_FORMAT|g" \
    -e "s|STREAM_EXT|$STREAM_EXT|g" \
    -e "s|STREAM_NAME|$STREAM_NAME|g" \
    -e "s|STREAM_DESCRIPTION|$STREAM_DESCRIPTION|g" \
    -e "s|STREAM_GENRE|$STREAM_GENRE|g" > /etc/liquidsoap/youtube.liq

printf "${BLUE}*${NC} Installing cron script...\n"
printf "$cron_tpl" > /opt/liquidsoap/scripts/cron.sh

printf "${PURPLE}*${NC} Downloading samples...\n"
[ ! -f '/opt/liquidsoap/music/principal/Chico Rose x 71 Digits – Somebody is Watching Me.mp3' ] && \
    curl -sLo '/opt/liquidsoap/music/principal/Chico Rose x 71 Digits – Somebody is Watching Me.mp3' 'https://drive.google.com/uc?export=download&id=1y0xNhh7xljd2453Q-vCZshfw7ncjJ3eW'

[ ! -f '/opt/liquidsoap/music/principal/DubDogz - Baila Conmigo.mp3' ] && \
    curl -sLo '/opt/liquidsoap/music/principal/DubDogz - Baila Conmigo.mp3' 'https://drive.google.com/uc?export=download&id=1JeJA3LiEZdvi-Mg-UAVCxluv0oAGWvPR'

[ ! -f '/opt/liquidsoap/music/principal/Lil Peep & XXXTENTACION - Falling Down.mp3' ] && \
    curl -sLo '/opt/liquidsoap/music/principal/Lil Peep & XXXTENTACION - Falling Down.mp3' 'https://drive.google.com/uc?export=download&id=1yMjB1A6YUdXA4RkiL-eYaPVhXGG9KLdo'

[ ! -f '/opt/liquidsoap/music/eletronica/Lykke Li - I Follow Rivers.mp3' ] && \
    curl -sLo '/opt/liquidsoap/music/eletronica/Lykke Li - I Follow Rivers.mp3' 'https://drive.google.com/uc?export=download&id=186I-JL5ncUdg6TC8ootbeDJ12jHEJHFj'

[ ! -f '/opt/liquidsoap/music/eletronica/Rag n Bone Man - Giant.mp3' ] && \
    curl -sLo '/opt/liquidsoap/music/eletronica/Rag n Bone Man - Giant.mp3' 'https://drive.google.com/uc?export=download&id=1AT8vukswiyQoiEDd4xlq9tCxE4ejpk39'

[ ! -f '/opt/liquidsoap/music/eletronica/Vintage Culture, Bruno Be feat Manimal - Human at Burning Man.mp3' ] && \
    curl -sLo '/opt/liquidsoap/music/eletronica/Vintage Culture, Bruno Be feat Manimal - Human at Burning Man.mp3' 'https://drive.google.com/uc?export=download&id=1I4uN5yauNETAjRyqnt4sBX6JLKfYpY9c'

[ ! -f '/opt/liquidsoap/music/rock/Pearl Jam - Alive.mp3' ] && \
    curl -sLo '/opt/liquidsoap/music/rock/Pearl Jam - Alive.mp3' 'https://drive.google.com/uc?export=download&id=1y2UftqxcP8a4SF1KlQBgxo5v3WnLYMTd'

[ ! -f '/opt/liquidsoap/music/rock/Nirvana - Lithium.mp3' ] && \
    curl -sLo '/opt/liquidsoap/music/rock/Nirvana - Lithium.mp3' 'https://drive.google.com/uc?export=download&id=1f_xtIxDzKUQArgTB9pwgucZ1khfUjelO'

if ! grep --quiet 'cron.sh principal' /etc/crontab; then
    echo '*/2 * * * * liquidsoap /bin/bash /opt/liquidsoap/scripts/cron.sh principal 2>&1' >> /etc/crontab
fi

if ! grep --quiet 'cron.sh eletronica' /etc/crontab; then
    echo '*/2 * * * * liquidsoap /bin/bash /opt/liquidsoap/scripts/cron.sh eletronica 2>&1' >> /etc/crontab
fi

if ! grep --quiet 'cron.sh rock' /etc/crontab; then
    echo '*/2 * * * * liquidsoap /bin/bash /opt/liquidsoap/scripts/cron.sh rock 2>&1' >> /etc/crontab
fi

[ ! -d /usr/share/liquidsoap/1.4.1 ] && mkdir /usr/share/liquidsoap/1.4.1

printf "${BLUE}*${NC} Running first cron job(playlists)...\n"
/bin/bash /opt/liquidsoap/scripts/cron.sh principal
/bin/bash /opt/liquidsoap/scripts/cron.sh eletronica
/bin/bash /opt/liquidsoap/scripts/cron.sh rock

touch /var/log/liquidsoap.log /var/log/icecast.log

printf "${YELLOW}*${NC} Fixing permissions...\n"
chown -R icecast:icecast /var/log/icecast2 $ICECAST_PATH /etc/icecast2 /var/log/icecast.log
chown -R liquidsoap:liquidsoap /etc/liquidsoap /opt/liquidsoap /var/log/liquidsoap.log /usr/share/liquidsoap

[ ! -d /usr/share/liquidsoap/libs ] && mkdir -p /usr/share/liquidsoap/libs
ln -fs /usr/share/liquidsoap/libs /usr/share/liquidsoap/1.4.1 2> /dev/null

systemctl daemon-reload 
printf "${BLUE}*${NC} Enabling & starting services...\n"
systemctl enable icecast liquidsoap &> /dev/null
systemctl restart nginx cron icecast liquidsoap