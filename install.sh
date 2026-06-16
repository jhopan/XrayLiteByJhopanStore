      0 [main] bash 19798 dofork: child -1 - forked process 10712 died unexpectedly, retry 0, exit code 0xC0000142, errno 11
/usr/bin/bash: fork: retry: Resource temporarily unavailable
#!/bin/bash

# ============================================================================
# XRAY-VLESS-LITE Installer
# Lightweight VPN Server with Xray + Nginx + VLESS
# Version: 1.0.0
# Author: Custom Build
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${CYAN}"
    echo "================================================================"
    echo "  XRAY-VLESS-LITE Installer"
    echo "  Lightweight VPN Server (Xray + Nginx + VLESS)"
    echo "  XrayLite by JhopanStore"
    echo "  Version: 1.0.0"
    echo "================================================================"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Script harus dijalankan sebagai root!"
        print_info "Gunakan: sudo bash install.sh"
        exit 1
    fi
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS"
        exit 1
    fi

    if [[ "$OS" != *"Ubuntu"* ]]; then
        print_warning "Script ini dirancang untuk Ubuntu, OS lain mungkin tidak support"
    fi
    
    print_success "OS: $OS $VER"
}

get_user_input() {
    echo ""
    echo -e "${CYAN}=== Konfigurasi ===${NC}"
    echo ""
    
    # Domain
    read -p "Domain (contoh: vpn.example.com): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        print_error "Domain tidak boleh kosong!"
        exit 1
    fi
    
    # Email
    read -p "Email untuk SSL (contoh: admin@example.com): " EMAIL
    if [ -z "$EMAIL" ]; then
        print_error "Email tidak boleh kosong!"
        exit 1
    fi
    
    # First user (optional)
    read -p "Username pertama (kosongkan jika skip): " FIRST_USER
    
    # Timezone
    echo ""
    echo "Pilih timezone untuk daily restart:"
    echo "1) WIB (UTC+7) - Jakarta"
    echo "2) WITA (UTC+8) - Makassar"
    echo "3) WIT (UTC+9) - Papua"
    read -p "Pilihan [1-3, default: 1]: " TZ_CHOICE
    TZ_CHOICE=${TZ_CHOICE:-1}
    
    case $TZ_CHOICE in
        1) RESTART_HOUR=17; TZ_NAME="WIB" ;;
        2) RESTART_HOUR=16; TZ_NAME="WITA" ;;
        3) RESTART_HOUR=15; TZ_NAME="WIT" ;;
        *) RESTART_HOUR=17; TZ_NAME="WIB" ;;
    esac
    
    # Bandwidth monitoring
    read -p "Install vnstat untuk bandwidth monitoring? [Y/n]: " INSTALL_VNSTAT
    INSTALL_VNSTAT=${INSTALL_VNSTAT:-Y}
    
    echo ""
    echo -e "${CYAN}=== Konfirmasi ===${NC}"
    echo "Domain: $DOMAIN"
    echo "Email: $EMAIL"
    echo "First User: ${FIRST_USER:-'(skip)'}"
    echo "Restart Time: 00:00 $TZ_NAME"
    echo "Vnstat: $INSTALL_VNSTAT"
    echo ""
    
    read -p "Lanjutkan? [Y/n]: " CONFIRM
    CONFIRM=${CONFIRM:-Y}
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        print_info "Installasi dibatalkan"
        exit 0
    fi
}

update_system() {
    echo ""
    print_info "Updating system packages..."
    apt-get update -qq
    apt-get upgrade -y -qq
    print_success "System updated"
}

install_dependencies() {
    echo ""
    print_info "Installing dependencies..."
    apt-get install -y -qq \
        curl \
        wget \
        unzip \
        jq \
        python3 \
        python3-pip \
        nginx \
        certbot \
        python3-certbot-nginx \
        cron
    
    print_success "Dependencies installed"
}

install_vnstat() {
    if [[ "$INSTALL_VNSTAT" =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Installing vnstat (bandwidth monitoring)..."
        apt-get install -y -qq vnstat
        
        # Configure vnstat
        vnstat --create
        
        print_success "Vnstat installed"
        print_info "Memory usage: ~2-3 MB"
    fi
}

install_xray() {
    echo ""
    print_info "Installing Xray..."
    
    # Download and run official installer
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    # Stop Xray (will configure first)
    systemctl stop xray
    
    print_success "Xray installed"
}

configure_xray() {
    echo ""
    print_info "Configuring Xray..."
    
    # Backup default config
    cp /usr/local/etc/xray/config.json /usr/local/etc/xray/config.json.bak
    
    # Create VLESS-only config
    cat > /usr/local/etc/xray/config.json << 'EOF'
{
  "log": {
    "loglevel": "warning",
    "access": "none",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "block"
      }
    ]
  }
}
EOF
    
    print_success "Xray configured (VLESS only, warning-only logging)"
}

configure_nginx() {
    echo ""
    print_info "Configuring Nginx..."
    
    # Create Nginx config (HTTP only first)
    cat > /etc/nginx/sites-available/vpn << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location /vless {
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }
    
    location /health {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    
    location / {
        return 200 'VPN Server Running\n';
        add_header Content-Type text/plain;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/vpn /etc/nginx/sites-enabled/
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Test config
    nginx -t
    
    # Reload Nginx
    systemctl reload nginx
    
    print_success "Nginx configured (HTTP only)"
}

setup_ssl() {
    echo ""
    print_info "Setting up SSL certificate..."
    
    # Get certificate
    certbot certonly --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL"
    
    # Update Nginx config with SSL
    cat > /etc/nginx/sites-available/vpn << EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location /vless {
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
    }
    
    location /health {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
    
    location / {
        return 404;
    }
}
EOF
    
    # Reload Nginx
    nginx -t
    systemctl reload nginx
    
    print_success "SSL certificate installed"
}

create_user_script() {
    echo ""
    print_info "Creating user management script..."
    
    cat > /usr/local/bin/vpn-user << 'EOFSCRIPT'
#!/bin/bash
set -e

CONFIG_FILE='/usr/local/etc/xray/config.json'
DOMAIN_FILE='/root/.vpn-domain'

# Read domain from file
if [ -f "$DOMAIN_FILE" ]; then
    DOMAIN=$(cat "$DOMAIN_FILE")
else
    echo "Error: Domain file not found. Please reinstall or create /root/.vpn-domain"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

case "$1" in
  add)
    if [ -z "$2" ]; then
      echo -e "${RED}Usage: vpn-user add <username>${NC}"
      exit 1
    fi
    
    USERNAME="$2"
    UUID=$(cat /proc/sys/kernel/random/uuid)
    
    # Add user to Xray config
    python3 << EOF_PY
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

client = {
    'id': '$UUID',
    'email': '$USERNAME'
}

config['inbounds'][0]['settings']['clients'].append(client)

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)

print('User added to config')
EOF_PY
    
    # Restart Xray
    systemctl restart xray
    
    # Generate VLESS URL
    VLESS_URL="vless://$UUID@$DOMAIN:443?encryption=none&security=tls&sni=$DOMAIN&type=ws&host=$DOMAIN&path=%2Fvless#VPN-$USERNAME"
    
    echo -e "${GREEN}✓ User '$USERNAME' created successfully!${NC}"
    echo ""
    echo "Username: $USERNAME"
    echo "UUID: $UUID"
    echo ""
    echo -e "${YELLOW}VLESS URL:${NC}"
    echo "$VLESS_URL"
    ;;
    
  list)
    echo -e "${GREEN}Active Users:${NC}"
    python3 << EOF_PY
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

clients = config['inbounds'][0]['settings']['clients']
if not clients:
    print('  (no users)')
else:
    for i, client in enumerate(clients, 1):
        print(f"  {i}. {client.get('email', 'unnamed')} - UUID: {client['id']}")
EOF_PY
    ;;
    
  delete)
    if [ -z "$2" ]; then
      echo -e "${RED}Usage: vpn-user delete <username>${NC}"
      exit 1
    fi
    
    USERNAME="$2"
    
    # Remove user from Xray config
    python3 << EOF_PY
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

clients = config['inbounds'][0]['settings']['clients']
config['inbounds'][0]['settings']['clients'] = [c for c in clients if c.get('email') != '$USERNAME']

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)

print('User removed from config')
EOF_PY
    
    # Restart Xray
    systemctl restart xray
    
    echo -e "${GREEN}✓ User '$USERNAME' deleted successfully!${NC}"
    ;;
    
  url)
    if [ -z "$2" ]; then
      echo -e "${RED}Usage: vpn-user url <username>${NC}"
      exit 1
    fi
    
    USERNAME="$2"
    
    # Get user UUID
    UUID=$(python3 << EOF_PY
import json
with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

clients = config['inbounds'][0]['settings']['clients']
for client in clients:
    if client.get('email') == '$USERNAME':
        print(client['id'])
        break
EOF_PY
)
    
    if [ -z "$UUID" ]; then
      echo -e "${RED}User '$USERNAME' not found!${NC}"
      exit 1
    fi
    
    # Generate VLESS URL
    VLESS_URL="vless://$UUID@$DOMAIN:443?encryption=none&security=tls&sni=$DOMAIN&type=ws&host=$DOMAIN&path=%2Fvless#VPN-$USERNAME"
    
    echo -e "${GREEN}VLESS URL for '$USERNAME':${NC}"
    echo "$VLESS_URL"
    ;;
    
  *)
    echo "XRAY-VLESS-LITE User Management"
    echo ""
    echo "Usage: vpn-user <command> [arguments]"
    echo ""
    echo "Commands:"
    echo "  add <username>     - Create new user"
    echo "  delete <username>  - Delete user"
    echo "  list               - List all users"
    echo "  url <username>     - Show VLESS URL for user"
    echo ""
    echo "Examples:"
    echo "  vpn-user add john"
    echo "  vpn-user list"
    echo "  vpn-user delete john"
    echo "  vpn-user url john"
    exit 1
    ;;
esac
EOFSCRIPT
    
    chmod +x /usr/local/bin/vpn-user
    
    # Save domain to file
    echo "$DOMAIN" > /root/.vpn-domain
    
    print_success "User management script created"
}

create_menu_script() {
    echo ""
    print_info "Creating interactive menu..."
    
    # Download menu script from same directory
    if [ -f "menu.sh" ]; then
        cp menu.sh /usr/local/bin/menu
        chmod +x /usr/local/bin/menu
        print_success "Interactive menu created"
        print_info "Use command: menu"
    else
        print_warning "menu.sh not found, skipping menu installation"
        print_info "You can add it later manually"
    fi
}

setup_cron_jobs() {
    echo ""
    print_info "Setting up cron jobs..."
    
    # Daily restart at midnight (timezone-adjusted)
    (crontab -l 2>/dev/null | grep -v 'systemctl restart xray'; echo "0 $RESTART_HOUR * * * systemctl restart xray") | crontab -
    
    print_success "Daily restart configured (00:00 $TZ_NAME)"
}

setup_logrotate() {
    echo ""
    print_info "Setting up log rotation..."
    
    cat > /etc/logrotate.d/xray << 'EOF'
/var/log/xray/error.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 nobody nogroup
}
EOF
    
    print_success "Log rotation configured (7 days retention)"
}

start_services() {
    echo ""
    print_info "Starting services..."
    
    # Start and enable Xray
    systemctl start xray
    systemctl enable xray
    
    # Nginx already running
    systemctl reload nginx
    
    print_success "Services started"
}

create_first_user() {
    if [ -n "$FIRST_USER" ]; then
        echo ""
        print_info "Creating first user: $FIRST_USER"
        vpn-user add "$FIRST_USER"
    fi
}

show_summary() {
    echo ""
    echo -e "${CYAN}"
    echo "================================================================"
    echo "  Installation Complete!"
    echo "  XrayLite by JhopanStore"
    echo "================================================================"
    echo -e "${NC}"
    echo ""
    echo -e "${GREEN}✓ Xray installed (VLESS only)${NC}"
    echo -e "${GREEN}✓ Nginx configured (reverse proxy)${NC}"
    echo -e "${GREEN}✓ SSL certificate installed${NC}"
    echo -e "${GREEN}✓ User management script ready${NC}"
    echo -e "${GREEN}✓ Interactive menu installed${NC}"
    echo -e "${GREEN}✓ Daily restart configured (00:00 $TZ_NAME)${NC}"
    echo -e "${GREEN}✓ Log rotation configured (7 days)${NC}"
    
    if [[ "$INSTALL_VNSTAT" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓ Vnstat installed (bandwidth monitoring)${NC}"
    fi
    
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║  🎯 TIP: Ketik 'menu' untuk akses menu interaktif!           ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}=== Quick Commands ===${NC}"
    echo ""
    echo -e "  ${GREEN}menu${NC}                      # Open interactive menu"
    echo ""
    echo -e "${CYAN}=== Manual Commands ===${NC}"
    echo ""
    echo "User Management:"
    echo "  vpn-user add <username>     # Create new user"
    echo "  vpn-user delete <username>  # Delete user"
    echo "  vpn-user list               # List all users"
    echo "  vpn-user url <username>     # Show VLESS URL"
    echo ""
    echo "Service Management:"
    echo "  systemctl status xray       # Check Xray status"
    echo "  systemctl restart xray      # Restart Xray"
    echo "  systemctl status nginx      # Check Nginx status"
    echo "  systemctl restart nginx     # Restart Nginx"
    echo ""
    
    if [[ "$INSTALL_VNSTAT" =~ ^[Yy]$ ]]; then
        echo "Bandwidth Monitoring:"
        echo "  vnstat                      # Show bandwidth stats"
        echo "  vnstat -l                   # Live monitoring"
        echo "  vnstat -d                   # Daily stats"
        echo "  vnstat -m                   # Monthly stats"
        echo ""
    fi
    
    echo -e "${CYAN}=== Server Info ===${NC}"
    echo ""
    echo "Domain: $DOMAIN"
    echo "IP: $(curl -s ifconfig.me)"
    echo "Xray Version: $(xray version | head -1)"
    echo "Nginx Version: $(nginx -v 2>&1 | cut -d/ -f2)"
    echo ""
    
    if [ -n "$FIRST_USER" ]; then
        echo -e "${YELLOW}First user '$FIRST_USER' sudah dibuat!${NC}"
        echo "Gunakan 'vpn-user url $FIRST_USER' untuk lihat VLESS URL"
    else
        echo -e "${YELLOW}Belum ada user. Buat user pertama dengan:${NC}"
        echo "  vpn-user add <username>"
        echo "  atau"
        echo "  menu (lalu pilih opsi 1)"
    fi
    
    echo ""
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}  Thank you for using XrayLite by JhopanStore!${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
}

# Main installation flow
main() {
    print_header
    check_root
    check_os
    get_user_input
    
    echo ""
    echo -e "${CYAN}=== Starting Installation ===${NC}"
    echo ""
    
    update_system
    install_dependencies
    install_vnstat
    install_xray
    configure_xray
    configure_nginx
    setup_ssl
    create_user_script
    create_menu_script
    setup_cron_jobs
    setup_logrotate
    start_services
    create_first_user
    show_summary
}

# Run main function
main "$@"
