#!/usr/bin/liquidsoap

# Log 
set("log.file.path", "/var/log/liquidsoap.log")
set("log.stdout", true)

# Youtube
#dance = mksafe(playlist("youtube-pl:PLp0YhNoP_vanDpHF6dCZkgsxSiAyska8V"))
#dance = playlist("youtube-pl:PLp0YhNoP_vanDpHF6dCZkgsxSiAyska8V")
#"ffmpeg2wav:youtube-dl:https$(colon)//youtube.com/watch?v=-IYXYB0r-Ww"
dance = mksafe(playlist("youtube-pl:https$(colon)//youtube.com/watch?v=-IYXYB0r-Ww"))
emerg = single("~/music/principal/Chico Rose x 71 Digits – Somebody is Watching Me.mp3")
live = input.harbor("live",port=8080,password="hackme")

output.icecast(%STREAM_FORMAT,
  host = "localhost", 
  port = 8000,
  user = "source",
  password = "SOURCE_PASSWD",
  name = "STREAM_NAME",
  description = "STREAM_DESCRIPTION",
  genre = "Dance",
  mount = "dance",
  fallback(track_sensitive=false, [live,dance,emerg]))