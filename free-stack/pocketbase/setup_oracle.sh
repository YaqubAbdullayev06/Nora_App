#!/bin/bash
# ══════════════════════════════════════════════════════════════
# PocketBase Setup for Oracle Cloud Free Tier
# 4 ARM OCPUs + 24GB RAM — FREE FOREVER
# ══════════════════════════════════════════════════════════════
#
# PREREQUISITES:
#   1. Sign up at https://cloud.oracle.com (free tier)
#   2. Create an ARM instance (VM.Standard.A1.Flex)
#      - 4 OCPUs, 24GB RAM (always free, not trial)
#      - Ubuntu 22.04 or Oracle Linux 8
#   3. SSH into your instance:
#      ssh -i ~/.ssh/your_key.pem ubuntu@YOUR_PUBLIC_IP
#
# USAGE:
#   chmod +x setup_oracle.sh
#   ./setup_oracle.sh
#
# ══════════════════════════════════════════════════════════════

set -e

# ─── Colors ───
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  PocketBase Setup for Oracle Cloud Free Tier  ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""

# ─── 1. System Update ───
echo -e "${YELLOW}[1/7] Updating system...${NC}"
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

# ─── 2. Install Dependencies ───
echo -e "${YELLOW}[2/7] Installing dependencies...${NC}"
sudo apt-get install -y -qq curl wget unzip nginx certbot python3-certbot-nginx

# ─── 3. Download PocketBase ───
echo -e "${YELLOW}[3/7] Downloading PocketBase...${NC}"
POCKETBASE_VERSION="0.22.0"
cd /tmp
wget -q "https://github.com/pocketbase/pocketbase/releases/download/v${POCKETBASE_VERSION}/pocketbase_${POCKETBASE_VERSION}_linux_arm64.zip"
unzip -o "pocketbase_${POCKETBASE_VERSION}_linux_arm64.zip"
sudo mv pocketbase /usr/local/bin/
sudo chmod +x /usr/local/bin/pocketbase
rm -f "pocketbase_${POCKETBASE_VERSION}_linux_arm64.zip"

echo -e "${GREEN}  PocketBase $(pocketbase --version) installed${NC}"

# ─── 4. Create Data Directory ───
echo -e "${YELLOW}[4/7] Creating data directory...${NC}"
sudo mkdir -p /opt/pocketbase/data
sudo mkdir -p /opt/pocketbase/backups
sudo chown -R ubuntu:ubuntu /opt/pocketbase

# ─── 5. Create Systemd Service ───
echo -e "${YELLOW}[5/7] Creating systemd service...${NC}"
sudo tee /etc/systemd/system/pocketbase.service > /dev/null <<EOF
[Unit]
Description=PocketBase
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/pocketbase
ExecStart=/usr/local/bin/pocketbase serve --http=127.0.0.1:8090 --dir=/opt/pocketbase/data
Restart=always
RestartSec=5
Environment=POCKETBASE_ADMIN_EMAIL=nora@example.com
Environment=POCKETBASE_ADMIN_PASSWORD=CHANGE_ME_NOW

[Install]
WantedBy=multi-user.target
EOF

# ─── 6. Start PocketBase ───
echo -e "${YELLOW}[6/7] Starting PocketBase...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable pocketbase
sudo systemctl start pocketbase

sleep 3

if systemctl is-active --quiet pocketbase; then
    echo -e "${GREEN}  PocketBase is running on http://127.0.0.1:8090${NC}"
else
    echo -e "${RED}  PocketBase failed to start. Check: sudo journalctl -u pocketbase${NC}"
    exit 1
fi

# ─── 7. Configure Nginx Reverse Proxy ───
echo -e "${YELLOW}[7/7] Configuring Nginx...${NC}"

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me)

sudo tee /etc/nginx/sites-available/pocketbase > /dev/null <<EOF
server {
    listen 80;
    server_name ${PUBLIC_IP};

    # Redirect HTTP to HTTPS (after certbot)
    # return 301 https://\$host\$request_uri;

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket support (for real-time subscriptions)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # PocketBase admin UI
    location /_/ {
        proxy_pass http://127.0.0.1:8090/_/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/pocketbase /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

# ─── Done ───
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  PocketBase is ready!                        ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  Admin UI:  http://${PUBLIC_IP}/_/"
echo -e "  API Base:  http://${PUBLIC_IP}/api/"
echo ""
echo -e "${YELLOW}  NEXT STEPS:${NC}"
echo -e "  1. Open http://${PUBLIC_IP}/_/ in your browser"
echo -e "  2. Create admin account (first signup = admin)"
echo -e "  3. Create collections (users, sessions, content, etc.)"
echo -e "  4. Update your app's .env with:"
echo -e "     DATABASE_URL=http://${PUBLIC_IP}/api/"
echo ""
echo -e "${YELLOW}  SECURITY:${NC}"
echo -e "  - Change admin password after first login"
echo -e "  - Set up SSL: sudo certbot --nginx -d ${PUBLIC_IP}"
echo -e "  - Configure firewall: sudo ufw allow 80,443"
echo ""
echo -e "${YELLOW}  BACKUPS:${NC}"
echo -e "  - Auto-backup: sudo crontab -e"
echo -e "  - Add: 0 2 * * * /usr/local/bin/pocketbase backup /opt/pocketbase/backups/"
echo ""
