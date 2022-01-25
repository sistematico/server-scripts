# Icecast KH + LiquidSoap (Debian 10)

## Usage

Create .env file with your e-mail and global token from CloudFlare(it's free), ex.:

```
STREAM_URL="stream.site.com"
CLOUDFLARE_EMAIL="your_name@email.com"
CLOUDFLARE_TOKEN="TOKEN"

```

And run:

```bash
curl -s https://raw.githubusercontent.com/sistematico/server-scripts/main/icecastkh-liquidsoap/install.sh | bash
```
