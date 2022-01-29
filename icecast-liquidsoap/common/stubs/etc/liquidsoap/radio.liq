#!/usr/bin/liquidsoap

# Log 
settings.log.file.path.set("/var/log/liquidsoap.log")
settings.log.stdout.set(true)

# Music
main = mksafe(playlist("~/playlist/main.m3u"))
eletronica = mksafe(playlist("~/playlist/eletronica.m3u"))
emergency = single("~/music/Chico Rose x 71 Digits – Somebody is Watching Me.mp3")
live = input.harbor("live",port=8080,password="hackme")

output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8000,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME",
  description = "STREAM_DESCRIPTION",
  genre = "STREAM_GENRE",
  mount = "main",
  fallback(track_sensitive=false, [live,main,emergency]))

output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8001,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME - Eletronica",
  description = "STREAM_DESCRIPTION",
  genre = "Eletronica",
  mount = "eletronica",
  fallback(track_sensitive=false, [live,eletronica,emergency]))