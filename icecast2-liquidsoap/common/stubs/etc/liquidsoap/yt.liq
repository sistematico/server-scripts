set("log.file.path", "/tmp/test.dog")
set("log.level", 4)

brasset = single("youtube-dl:https://youtu.be/V7gwPsuccxg";)
lasset = single("youtube-dl:https://youtu.be/hq74Y1yUgq0";)
basset = single("youtube-dl:https://youtu.be/pC7u3UgN3s4";)

hiho = fallback(track_sensitive=true,[(brasset),(lasset),(basset)])

output.icecast(%vorbis(channels=2, samplerate=48000, quality=0.4),
    fallible=true,
    host="localhost",
    port=8000,
    password="hackme",
    mount="principal",
    description="Stream from Ersboda",
    genre="Eclectic",
    url="https://mustafejen.se/~per";,
    name="mustafejen",
    hiho
)