# Icecast KH + LiquidSoap (Ubuntu 20.04)

## Usage

Create .env file with your e-mail and global token from CloudFlare(it's free), ex.:

```
# Required
STREAM_URL="stream.site.com"
STREAM_NAME="Ultra Radio"
STREAM_DESCRIPTION="Your best radio"
STREAM_GENRE="Various"

# CloudFlare credentials
CLOUDFLARE_EMAIL="your_name@email.com"
CLOUDFLARE_TOKEN="TOKEN"

# Icacast passwords
SOURCE_PASSWD="hackme"
RELAY_PASSWD="hackme"
ADMIN_PASSWD="hackmeagain"

# IceCast & LiquidSoap users passwords
ICECAST_PW="hackme"
LIQUIDSOAP_PW="hackme"

# Optional
STREAM_FORMAT="ogg" # mp3 or ogg (default: ogg)
```

And run:

```bash
curl -sNL https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/ubuntu/install.sh | bash
```
