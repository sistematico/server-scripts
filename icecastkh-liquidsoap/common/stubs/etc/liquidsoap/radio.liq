#!/usr/bin/liquidsoap

# Log 
settings.log.file.path.set("/var/log/liquidsoap.log")
settings.log.stdout.set(true)

# Input addr
#set("harbor.bind_addr","0.0.0.0")

# Music
principal = mksafe(playlist("~/playlist/principal.m3u"))
eletronica = mksafe(playlist("~/playlist/eletronica.m3u"))
rock = mksafe(playlist("~/playlist/rock.m3u"))

# If something goes wrong, we'll play this
emergency = single("~/music/Chico Rose x 71 Digits – Somebody is Watching Me.mp3")

# A live source
live = input.harbor("live", port = 8080, password = "hackme")

# Stream it out
output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8000,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME",
  description = "STREAM_DESCRIPTION",
  genre = "Varios",
  mount = "principal",
  fallback(track_sensitive=false, [live,principal,emergency]))

output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8002,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME",
  description = "STREAM_DESCRIPTION",
  genre = "Eletronica",
  mount = "eletronica",
  fallback(track_sensitive=false, [live,eletronica,emergency]))

output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8004,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME",
  description = "STREAM_DESCRIPTION",
  genre = "Rock",
  mount = "rock",
  fallback(track_sensitive=false, [live,rock,emergency]))