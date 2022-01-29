# Icecast KH + LiquidSoap (Ubuntu 20.04)

## Usage

Create .env file with your e-mail and global token from CloudFlare(it's free), ex.:

```
STREAM_URL="stream.site.com"
CLOUDFLARE_EMAIL="your_name@email.com"
CLOUDFLARE_TOKEN="TOKEN"
```

And run:

```bash
curl -sNL https://raw.githubusercontent.com/sistematico/server-scripts/main/ubuntu/icecastkh-liquidsoap/install.sh | bash
```
