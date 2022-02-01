set("log.file.path", "/tmp/test.dog")
set("log.level", 4)

brasset = mksafe(single("youtube-dl:https://youtu.be/V7gwPsuccxg"))
lasset = mksafe(single("youtube-dl:https://youtu.be/hq74Y1yUgq0"))
basset = mksafe(single("youtube-dl:https://youtu.be/pC7u3UgN3s4"))

youtube = fallback(track_sensitive=true,[brasset,lasset,basset])
emergency = single("~/music/eletronica/Chico Rose x 71 Digits – Somebody is Watching Me.mp3")

#fallible=true,

output.icecast(%vorbis
    (channels=2, samplerate=44100, quality=0.3),
    host="localhost",
    port=8000,
    password="hackme",
    mount="principal",
    name="RadioChat",
    description="",
    genre="Eclectic",
    url="https://radiochat.com.br",
    fallback(track_sensitive=false,[youtube,emergency])
)