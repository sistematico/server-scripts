#!/usr/bin/liquidsoap

# Log dir
# set("log.file.path","/tmp/<script>.log")
set("log.file.path","/var/log/liquidsoap.log")
set("log.stdout",true)

# Music
main = playlist("~/playlist/main.m3u")

# Some jingles
# jingles = playlist("~/playlist/jingles.m3u")

# If something goes wrong, we'll play this
security = single("~/music/house-of-the-rising.mp3")

# Start building the feed with music
radio = main

# Now add some jingles
# radio = random(weights = [1, 4],[jingles, radio])

# And finally the security
radio = fallback(track_sensitive = false, [radio, security])

# Stream it out
output.icecast(%vorbis,
  host = "localhost", port = 8000,
  password = "SOURCE_PASSWD", mount = "stream",
  radio)