#!/bin/bash

# ============================================================================
# XRAY-VLESS-LITE Interactive Menu
# Version: 1.1.0 - Ultra Minimal (Optimized for Gaming + Streaming)
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Script harus dijalankan sebagai root!${NC}"
    echo -e "Gunakan: ${YELLOW}sudo menu${NC}"
    exit 1
fi

# Functions
get_system_info() {
    # OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_INFO="$NAME $VERSION_ID"
    else
        OS_INFO="Unknown"
    fi
    
    # RAM
    RAM_TOTAL=$(free -m | awk 'NR==2{printf "%s", $2}')
    RAM_USED=$(free -m | awk 'NR==2{printf "%s", $3}')
    RAM_FREE=$(free -m | awk 'NR==2{printf "%s", $4}')
    RAM_PERCENT=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    
    # CPU
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    CPU_CORES=$(nproc)
    
    # Disk
    DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')
    DISK_USED=$(df -h / | awk 'NR==2{print $3}')
    DISK_FREE=$(df -h / | awk 'NR==2{print $4}')
    DISK_PERCENT=$(df -h / | awk 'NR==2{print $5}')
    
    # Uptime
    UPTIME=$(uptime -p | cut -d' ' -f2-)
    
    # Load average
    LOAD_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
}

get_vpn_info() {
    # Domain
    if [ -f /root/.vpn-domain ]; then
        DOMAIN=$(cat /root/.vpn-domain)
    else
        DOMAIN="Not configured"
    fi
    
    # IP
    IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unknown")
    
    # Xray version
    XRAY_VERSION=$(xray version 2>/dev/null | head -1 | cut -d' ' -f2 || echo "Not installed")
    
    # Nginx version
    NGINX_VERSION=$(nginx -v 2>&1 | cut -d'/' -f2 || echo "Not installed")
    
    # Xray status
    if systemctl is-active --quiet xray; then
        XRAY_STATUS="Running"
        XRAY_COLOR="$GREEN"
    else
        XRAY_STATUS="Stopped"
        XRAY_COLOR="$RED"
    fi
    
    # Nginx status
    if systemctl is-active --quiet nginx; then
        NGINX_STATUS="Running"
        NGINX_COLOR="$GREEN"
    else
        NGINX_STATUS="Stopped"
        NGINX_COLOR="$RED"
    fi
    
    # Users count
    CONFIG_FILE='/usr/local/etc/xray/config.json'
    if [ -f "$CONFIG_FILE" ]; then
        USER_COUNT=$(python3 -c "import json; config=json.load(open('$CONFIG_FILE')); print(len(config['inbounds'][0]['settings']['clients']))" 2>/dev/null || echo "0")
    else
        USER_COUNT="0"
    fi
}

get_bandwidth_info() {
    # Check if vnstat is installed
    if command -v vnstat &> /dev/null; then
        # Today's bandwidth
        BW_TODAY_RX=$(vnstat --oneline 2>/dev/null | cut -d';' -f4 || echo "N/A")
        BW_TODAY_TX=$(vnstat --oneline 2>/dev/null | cut -d';' -f5 || echo "N/A")
        BW_TODAY_TOTAL=$(vnstat --oneline 2>/dev/null | cut -d';' -f6 || echo "N/A")
        
        # Monthly bandwidth
        BW_MONTH_RX=$(vnstat --oneline 2>/dev/null | cut -d';' -f10 || echo "N/A")
        BW_MONTH_TX=$(vnstat --oneline 2>/dev/null | cut -d';' -f11 || echo "N/A")
        BW_MONTH_TOTAL=$(vnstat --oneline 2>/dev/null | cut -d';' -f12 || echo "N/A")
        
        VNSTAT_INSTALLED=true
    else
        VNSTAT_INSTALLED=false
    fi
}

list_users() {
    echo ""
    echo -e "${CYAN}=== Active Users ===${NC}"
    echo ""
    
    CONFIG_FILE='/usr/local/etc/xray/config.json'
    if [ -f "$CONFIG_FILE" ]; then
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
    else
        echo "  (config file not found)"
    fi
    echo ""
}

show_menu() {
    clear
    
    # Header
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    XRAY-VLESS-LITE Menu                        ║"
    echo "║              Lightweight VPN Server Management                 ║"
    echo "║                  XrayLite by JhopanStore                       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # System Information
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    System Information                          ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BLUE}OS:${NC}           $OS_INFO"
    echo -e "  ${BLUE}Uptime:${NC}       $UPTIME"
    echo -e "  ${BLUE}Load Avg:${NC}     $LOAD_AVG"
    echo ""
    echo -e "  ${BLUE}RAM:${NC}          ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PERCENT}% used)"
    echo -e "  ${BLUE}CPU:${NC}          ${CPU_USAGE}% (${CPU_CORES} cores)"
    echo -e "  ${BLUE}Disk:${NC}         ${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT} used)"
    echo ""
    
    # Bandwidth Information
    if [ "$VNSTAT_INSTALLED" = true ]; then
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║                    Bandwidth Usage                             ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${BLUE}Today:${NC}        ↓ ${BW_TODAY_RX}  ↑ ${BW_TODAY_TX}  = ${BW_TODAY_TOTAL}"
        echo -e "  ${BLUE}This Month:${NC}   ↓ ${BW_MONTH_RX}  ↑ ${BW_MONTH_TX}  = ${BW_MONTH_TOTAL}"
        echo ""
    fi
    
    # VPN Information
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    VPN Information                             ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BLUE}Domain:${NC}       $DOMAIN"
    echo -e "  ${BLUE}IP Address:${NC}   $IP"
    echo -e "  ${BLUE}Xray:${NC}         ${XRAY_COLOR}${XRAY_STATUS}${NC} (v${XRAY_VERSION})"
    echo -e "  ${BLUE}Nginx:${NC}        ${NGINX_COLOR}${NGINX_STATUS}${NC} (v${NGINX_VERSION})"
    echo -e "  ${BLUE}Total Users:${NC}  $USER_COUNT"
    echo ""
    
    # Users List
    list_users
    
    # Menu Options
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Menu Options                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Tambah akun baru"
    echo -e "  ${GREEN}2.${NC} Hapus akun"
    echo -e "  ${GREEN}3.${NC} Lihat VLESS URL"
    echo -e "  ${GREEN}4.${NC} Restart Xray"
    echo -e "  ${GREEN}5.${NC} Restart Nginx"
    echo -e "  ${GREEN}6.${NC} Restart semua services"
    echo -e "  ${GREEN}7.${NC} Cek bandwidth (vnstat)"
    echo -e "  ${GREEN}8.${NC} Cek logs"
    echo -e "  ${GREEN}9.${NC} Update system"
    echo -e "  ${GREEN}10.${NC} Test speed (speedtest)"
    echo -e "  ${RED}0.${NC} Keluar"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

add_user() {
    echo ""
    echo -e "${CYAN}=== Tambah Akun Baru ===${NC}"
    echo ""
    read -p "Username: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}Error: Username tidak boleh kosong!${NC}"
        return
    fi
    
    echo ""
    echo -e "${BLUE}Creating user: $USERNAME${NC}"
    echo ""
    
    # Call vpn-user add
    vpn-user add "$USERNAME"
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

delete_user() {
    echo ""
    echo -e "${CYAN}=== Hapus Akun ===${NC}"
    echo ""
    
    # List users first
    list_users
    
    read -p "Username yang mau dihapus: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}Error: Username tidak boleh kosong!${NC}"
        return
    fi
    
    echo ""
    read -p "Yakin mau hapus user '$USERNAME'? [y/N]: " CONFIRM
    
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}Deleting user: $USERNAME${NC}"
        echo ""
        
        # Call vpn-user delete
        vpn-user delete "$USERNAME"
    else
        echo -e "${YELLOW}Cancelled${NC}"
    fi
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

show_url() {
    echo ""
    echo -e "${CYAN}=== Lihat VLESS URL ===${NC}"
    echo ""
    
    # List users first
    list_users
    
    read -p "Username: " USERNAME
    
    if [ -z "$USERNAME" ]; then
        echo -e "${RED}Error: Username tidak boleh kosong!${NC}"
        return
    fi
    
    echo ""
    
    # Call vpn-user url (will show Direct + CloudFront URLs)
    vpn-user url "$USERNAME"
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

restart_xray() {
    echo ""
    echo -e "${BLUE}Restarting Xray...${NC}"
    systemctl restart xray
    sleep 2
    
    if systemctl is-active --quiet xray; then
        echo -e "${GREEN}✓ Xray restarted successfully${NC}"
    else
        echo -e "${RED}✗ Xray failed to restart${NC}"
    fi
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

restart_nginx() {
    echo ""
    echo -e "${BLUE}Restarting Nginx...${NC}"
    systemctl restart nginx
    sleep 2
    
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✓ Nginx restarted successfully${NC}"
    else
        echo -e "${RED}✗ Nginx failed to restart${NC}"
    fi
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

restart_all() {
    echo ""
    echo -e "${BLUE}Restarting all services...${NC}"
    
    systemctl restart xray
    sleep 1
    systemctl restart nginx
    sleep 1
    
    echo ""
    
    if systemctl is-active --quiet xray && systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✓ All services restarted successfully${NC}"
    else
        echo -e "${RED}✗ Some services failed to restart${NC}"
    fi
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

check_bandwidth() {
    echo ""
    echo -e "${CYAN}=== Bandwidth Monitoring ===${NC}"
    echo ""
    
    if [ "$VNSTAT_INSTALLED" = true ]; then
        echo -e "${BLUE}Summary:${NC}"
        vnstat
        echo ""
        echo -e "${BLUE}Daily Stats:${NC}"
        vnstat -d | head -15
        echo ""
        echo -e "${BLUE}Monthly Stats:${NC}"
        vnstat -m | head -15
    else
        echo -e "${RED}vnstat tidak terinstall!${NC}"
        echo ""
        echo -e "Install dengan: ${YELLOW}sudo apt install vnstat${NC}"
    fi
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

check_logs() {
    echo ""
    echo -e "${CYAN}=== Logs ===${NC}"
    echo ""
    echo -e "${BLUE}1.${NC} Xray error log (last 20 lines)"
    echo -e "${BLUE}2.${NC} Nginx error log (last 20 lines)"
    echo -e "${BLUE}3.${NC} Nginx access log (last 20 lines)"
    echo -e "${BLUE}4.${NC} Systemd journal (Xray, last 20 lines)"
    echo -e "${BLUE}0.${NC} Kembali"
    echo ""
    read -p "Pilihan [0-4]: " LOG_CHOICE
    
    case $LOG_CHOICE in
        1)
            echo ""
            echo -e "${BLUE}Xray Error Log:${NC}"
            sudo tail -20 /var/log/xray/error.log
            ;;
        2)
            echo ""
            echo -e "${BLUE}Nginx Error Log:${NC}"
            sudo tail -20 /var/log/nginx/error.log
            ;;
        3)
            echo ""
            echo -e "${BLUE}Nginx Access Log:${NC}"
            sudo tail -20 /var/log/nginx/access.log
            ;;
        4)
            echo ""
            echo -e "${BLUE}Systemd Journal (Xray):${NC}"
            sudo journalctl -u xray --no-pager -n 20
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            ;;
    esac
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

update_system() {
    echo ""
    echo -e "${BLUE}Updating system packages...${NC}"
    echo ""
    
    apt-get update -qq
    apt-get upgrade -y
    
    echo ""
    echo -e "${GREEN}✓ System updated${NC}"
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

test_speed() {
    echo ""
    echo -e "${BLUE}Testing internet speed...${NC}"
    echo ""
    
    # Check if speedtest-cli is installed
    if ! command -v speedtest &> /dev/null; then
        echo -e "${RED}speedtest-cli tidak terinstall!${NC}"
        echo -e "${YELLOW}Install dengan: pip3 install speedtest-cli${NC}"
        echo ""
        read -p "Tekan ENTER untuk kembali ke menu..."
        return
    fi
    
    # Run speedtest
    speedtest --simple
    
    echo ""
    read -p "Tekan ENTER untuk kembali ke menu..."
}

# Main loop
while true; do
    # Get fresh data
    get_system_info
    get_vpn_info
    get_bandwidth_info
    
    # Show menu
    show_menu
    
    # Get user input
    read -p "Pilihan [0-9]: " CHOICE
    
    case $CHOICE in
        1)
            add_user
            ;;
        2)
            delete_user
            ;;
        3)
            show_url
            ;;
        4)
            restart_xray
            ;;
        5)
            restart_nginx
            ;;
        6)
            restart_all
            ;;
        7)
            check_bandwidth
            ;;
        8)
            check_logs
            ;;
        9)
            update_system
            ;;
        10)
            test_speed
            ;;
        0)
            echo ""
            echo -e "${GREEN}Terima kasih! Sampai jumpa!${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1
            ;;
    esac
done
