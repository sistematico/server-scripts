#!/usr/bin/liquidsoap

# Log 
set("log.file.path","/var/log/liquidsoap.log")
set("log.stdout",true)

# Input addr
set("harbor.bind_addr","0.0.0.0")

# Music
playlist = playlist("~/playlist/main.m3u")

# If something goes wrong, we'll play this
emergency = single("~/music/house-of-the-rising.mp3")

# A live source
live = input.harbor("live",port=8080,password="hackme")

# Create streams
radio = fallback(track_sensitive=false, [live,playlist,emergency])

# Stream it out
output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8000,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME",
  description = "STREAM_DESCRIPTION",
  genre = "Various",
  mount = "stream",
  radio)