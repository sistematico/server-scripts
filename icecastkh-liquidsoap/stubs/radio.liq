#!/usr/bin/liquidsoap

# Log 
set("log.file.path","/var/log/liquidsoap.log")
set("log.stdout",true)

# Input addr
set("harbor.bind_addr","0.0.0.0")

# Music
playlist = playlist("~/playlist/main.m3u")

# If something goes wrong, we'll play this
security = single("~/music/house-of-the-rising.mp3")

# An emergency file
emergency = single("/path/to/emergency/single.ogg")

# A live source
live = input.harbor("live",port=8080,password="hackme")

# Create streams
radio = fallback(track_sensitive=false, [live,playlist,emergency])

# Stream it out
output.icecast(%vorbis,
  host = "localhost", port = 8000,
  password = "SOURCE_PASSWD", mount = "stream",
  radio)