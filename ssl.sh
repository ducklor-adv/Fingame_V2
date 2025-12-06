#!/bin/bash

DOMAIN="fingrow.info"
SSL_DIR="./nginx/ssl"

mkdir -p $SSL_DIR

# Install certbot if not exists
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install certbot
    else
        apt-get update && apt-get install -y certbot
    fi
fi

# Generate certificate
certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN

# Copy certs to nginx ssl folder
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $SSL_DIR/cert.pem
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $SSL_DIR/key.pem

chmod 644 $SSL_DIR/cert.pem
chmod 600 $SSL_DIR/key.pem

echo "SSL certificates generated for $DOMAIN"
