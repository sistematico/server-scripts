#!/usr/bin/liquidsoap

# Log 
set("log.file.path", "/var/log/liquidsoap.log")
set("log.stdout", true)

# Music
main = mksafe(playlist(reload_mode="watch", "~/playlist/principal.m3u"))
eletronica = mksafe(playlist(reload_mode="watch", "~/playlist/eletronica.m3u"))
rock = mksafe(playlist(reload_mode="watch", "~/playlist/rock.m3u"))

emergency = single("~/music/eletronica/Chico Rose x 71 Digits – Somebody is Watching Me.mp3")
live = input.harbor("live",port=8080,password="hackme")

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