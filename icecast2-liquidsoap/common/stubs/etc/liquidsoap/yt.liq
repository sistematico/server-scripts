#!/usr/bin/liquidsoap

set("log.file.path", "/var/log/liquidsoap.log")
set("log.level", 4)
set("log.stdout", true)

youtube = single("youtube-dl:V7gwPsuccxg")
emerg = single("~/music/principal/Chico Rose x 71 Digits – Somebody is Watching Me.mp3")

output.icecast(%vorbis(channels=2, samplerate=48000, quality=0.4),
    fallible=true,
    host="localhost",
    port=8000,
    password="hackme",
    mount="principal",
    name="RadioChat",
    description="",
    genre="Eclectic",
    url="https://radiochat.com.br",
    fallback(track_sensitive=false, [youtube,emerg])
)
