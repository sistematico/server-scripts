#!/usr/bin/env bash

ICECAST_USER_PASSWD="hackme"
LIQUIDSOAP_USER_PASSWD="hackme"
ICECAST_VERSION="2.4.0-kh15"

[ -f .env ] && . .env || echo "Arquivo .env não encontrado." && exit 1

export DEBIAN_FRONTEND=noninteractive

nginx_tpl="$(curl -s -L https://gist.githubusercontent.com/sistematico/e5b59bea8e80752fe1aee8be38a104ca/raw/98e5b26994dd7493527ac62c61ccec06917fe151/nginx.tpl)"
icecast_tpl="$(curl -s -L https://gist.githubusercontent.com/sistematico/e5b59bea8e80752fe1aee8be38a104ca/raw/83a6a5c8c0135cf3033b84c398cf12c76a999df3/icecast.xml)"

apt update -y -q &> /dev/null
apt upgrade -y -q &> /dev/null

apt install -y -q build-essential libxml2-dev libxslt1-dev libcurl4-openssl-dev libvorbis-dev libtheora-dev libssl-dev openssl curl icecast2 liquidsoap certbot python3-certbot-dns-cloudflare nginx &> /dev/null

systemctl is-active --quiet liquidsoap && systemctl stop liquidsoap
systemctl is-active --quiet icecast && systemctl stop icecast
systemctl is-active --quiet nginx && systemctl stop nginx

pass=$(perl -e 'print crypt($ARGV[0], "password")' "$ICECAST_USER_PASSWD")

if ! id "icecast" &>/dev/null; then
    useradd -m -p "$pass" -d /home/icecast -s /bin/bash -c "Icecast System User" -U icecast
else
    usermod -m -p "$pass" -d /home/icecast -s /bin/bash -c "Icecast System User" icecast
fi

pass=$(perl -e 'print crypt($ARGV[0], "password")' "$LIQUIDSOAP_USER_PASSWD")

if ! id "liquidsoap" &>/dev/null; then
    useradd -m -p "$pass" -d /home/liquidsoap -s /bin/bash -c "LiquidSoap System User" -U liquidsoap
else
    usermod -m -p "$pass" -d /home/liquidsoap -s /bin/bash -c "LiquidSoap System User" liquidsoap
fi

mkdir -p /var/log/icecast /etc/icecast /etc/liquidsoap /opt/liquidsoap/{playlist,scripts,music} 2> /dev/null

if ! command -v icecast &> /dev/null
then
    curl -sL https://github.com/karlheyes/icecast-kh/archive/refs/tags/icecast-${ICECAST_VERSION}.tar.gz > /tmp/icecast-${ICECAST_VERSION}.tar.gz
    tar xzf /tmp/icecast-${ICECAST_VERSION}.tar.gz -C /tmp/

    cd /tmp/icecast-kh-icecast-${ICECAST_VERSION}

    ./configure --with-curl-config=/usr/bin/curl-config --with-openssl
    make
    sudo make install
fi

cat >/etc/cloudflare.ini <<-EOL
dns_cloudflare_email = ${EMAIL}
dns_cloudflare_api_key = ${CLOUDFLARE_TOKEN}
EOL

chmod 600 /etc/cloudflare.ini

if [ ! -f /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem ] && [ ! -f /etc/letsencrypt/live/${STREAM_URL}/privkey.pem ]; then
    certbot certonly -n -m "${EMAIL}" --agree-tos --dns-cloudflare --dns-cloudflare-credentials /etc/cloudflare.ini --webroot-path="/usr/local/share/icecast/web" -d "${STREAM_URL}"
fi

if [ -f /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem ] && [ -f /etc/letsencrypt/live/${STREAM_URL}/privkey.pem ]; then
    cat /etc/letsencrypt/live/${STREAM_URL}/fullchain.pem /etc/letsencrypt/live/${STREAM_URL}/privkey.pem > /usr/local/share/icecast/icecast.pem
    
    chmod 600 /usr/local/share/icecast/icecast.pem
else
    exit 1
fi

[ -L /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default
printf "$nginx_tpl" | sed -e "s|STREAM_URL|$STREAM_URL|" > /etc/nginx/sites-available/${STREAM_URL}
ln -sf /etc/nginx/sites-available/${STREAM_URL} /etc/nginx/sites-enabled/${STREAM_URL}

[ ! -d /etc/tmpfiles.d ] && mkdir /etc/tmpfiles.d

cat >/etc/tmpfiles.d/liquidsoap.conf <<EOL
#d /run/liquidsoap 0755 liquidsoap liquidsoap
#f /run/liquidsoap/liquidsoap.pid 0644 liquidsoap liquidsoap
f /run/liquidsoap.pid 0644 liquidsoap liquidsoap
EOL

cat >/etc/systemd/system/icecast.service <<EOL
[Unit]
Description=Icecast-KH daemon
Documentation=https://github.com/karlheyes/icecast-kh

[Service]
Type=simple
Restart=always
User=icecast
ExecStart=/usr/local/bin/icecast -b -c /etc/icecast/icecast.xml
PIDFile=/run/icecast.pid
KillMode=process
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL

cat >/etc/systemd/system/liquidsoap.service <<EOL
[Unit]
Description=Liquidsoap daemon
After=network.target icecast.service
Documentation=http://liquidsoap.fm/

[Service]
Type=forking
User=liquidsoap
PIDFile=/run/liquidsoap.pid
ExecStart=/usr/bin/liquidsoap /etc/liquidsoap/radio.liq
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOL

printf "$icecast_tpl" > /etc/icecast/icecast.xml

cat >/etc/liquidsoap/radio.liq <<-EOL
#!/usr/bin/liquidsoap

# logging
set("log.file.path", "/var/log/liquidsoap.log")
set("log.stdout", true)

#set("init.daemon.pidfile.path", "/run/liquidsoap.pid")

output.icecast(%mp3,
  host="localhost",port=8000,password="hackme",
  mount="stream", mksafe(playlist(reload_mode="watch","/opt/liquidsoap/playlist/main.m3u")))
EOL

cat >/opt/liquidsoap/scripts/cron.sh <<'EOL'
#!/usr/bin/env bash

if [ $1 ]; then
    playlist="/opt/liquidsoap/playlist/${1}.m3u"
    music="/opt/liquidsoap/music"
    
    [ ! -f $playlist ] && find $music -type f -iname "*.mp3" > $playlist

    if [ $(find $music -type f -iname "*.mp3" | wc -l) -ne $(cat $playlist | wc -l) ]; then
        find ${music} -type f -iname "*.mp3" > $playlist
    fi
fi
EOL

curl -sLo /opt/liquidsoap/music/1949-Hitz.mp3 'https://ia800609.us.archive.org/25/items/1949Hitz1/1949%20Hitz%20%23%201.mp3'
curl -sLo /opt/liquidsoap/music/house-of-the-rising.mp3 'https://ia601601.us.archive.org/14/items/78_house-of-the-rising-sun_josh-white-and-his-guitar_gbia0001628b/_78_house-of-the-rising-sun_josh-white-and-his-guitar_gbia0001628b_01_3.8_CT_EQ.mp3'

if ! grep --quiet liquidsoap /etc/crontab; then
    echo '*/2 * * * * liquidsoap /bin/bash /opt/liquidsoap/scripts/cron.sh main 2>&1' >> /etc/crontab
fi

if [ ! -d /usr/share/liquidsoap/1.4.1 ]; then
    mkdir /usr/share/liquidsoap/1.4.1
fi

/bin/bash /opt/liquidsoap/scripts/cron.sh main

touch /var/log/icecast.log /var/log/liquidsoap.log

chown -R icecast:icecast /var/log/icecast /usr/local/share/icecast /etc/icecast /var/log/icecast.log
chown -R liquidsoap:liquidsoap /etc/liquidsoap /opt/liquidsoap /var/log/liquidsoap.log

[ ! -d /usr/share/liquidsoap/libs ] && mkdir -p /usr/share/liquidsoap/libs
ln -fs /usr/share/liquidsoap/libs /usr/share/liquidsoap/1.4.1

systemctl daemon-reload
systemctl enable icecast liquidsoap
systemctl restart nginx cron
systemctl start icecast liquidsoap