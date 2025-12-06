#!/bin/bash

DOMAIN="fingrow.info"
SSL_DIR="./nginx/ssl"
EMAIL="admin@$DOMAIN"

mkdir -p $SSL_DIR

# Check if port 80 is open
echo "Checking port 80 accessibility..."
if ! curl -s -I http://$DOMAIN &> /dev/null; then
    echo "ERROR: Cannot reach http://$DOMAIN on port 80"
    echo ""
    echo "Please ensure:"
    echo "1. Domain $DOMAIN points to this server's IP: $(curl -s ifconfig.me)"
    echo "2. Port 80 is open in firewall (ufw allow 80 or iptables)"
    echo "3. No other service is using port 80"
    echo ""
    echo "If using cloud provider, allow port 80 in security groups/firewall rules."
    exit 1
fi

echo "Port 80 is accessible for $DOMAIN"

# Install certbot if not exists
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    apt-get update && apt-get install -y certbot
fi

# Generate certificate
echo "Generating SSL certificate..."
certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email $EMAIL

# Check if certs were created
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "ERROR: Certificate generation failed"
    echo "Check logs at: /var/log/letsencrypt/letsencrypt.log"
    exit 1
fi

# Copy certs to nginx ssl folder
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem $SSL_DIR/cert.pem
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem $SSL_DIR/key.pem

chmod 644 $SSL_DIR/cert.pem
chmod 600 $SSL_DIR/key.pem

echo ""
echo "✅ SSL certificates generated for $DOMAIN"
echo "Certificates saved to:"
echo "  - $SSL_DIR/cert.pem"
echo "  - $SSL_DIR/key.pem"
echo ""
echo "Add to crontab for auto-renewal:"
echo "0 12 * * * /usr/bin/certbot renew --quiet && docker compose restart nginx"

