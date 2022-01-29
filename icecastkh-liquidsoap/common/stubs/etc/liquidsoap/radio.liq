#!/usr/bin/liquidsoap

# Log 
settings.log.file.path.set("/var/log/liquidsoap.log")
settings.log.stdout.set(true)

# Input addr
#set("harbor.bind_addr","0.0.0.0")

# Music
main = playlist("~/playlist/main.m3u")
eletronica = playlist("~/playlist/eletronica.m3u")

# If something goes wrong, we'll play this
emergency = single("~/music/Chico Rose x 71 Digits – Somebody is Watching Me.mp3")

# A live source
live = input.harbor(
  "live",
  port = 8080,
  password = "hackme"
)

# Create streams
# radio = fallback(track_sensitive=false, [live,main,emergency])

# Stream it out
output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8000,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME",
  description = "STREAM_DESCRIPTION",
  genre = "STREAM_GENRE",
  mount = "main.STREAM_EXT",
  fallback(track_sensitive=false, [live,main,emergency]))

output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8001,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME - Eletronica",
  description = "STREAM_DESCRIPTION",
  genre = "Eletronica",
  mount = "eletronica.STREAM_EXT",
  fallback(track_sensitive=false, [live,eletronica,emergency]))