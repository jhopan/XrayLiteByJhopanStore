# XRAY-VLESS-LITE

**XrayLite by JhopanStore**

**Lightweight VPN Server dengan Xray + Nginx + VLESS**

Setup VPN server yang super ringan, stabil, dan mudah di-manage. Perfect untuk personal use (1-5 users).

---

## ✨ **Features**

- ✅ **Super Lightweight** - Hanya ~20 MB RAM usage
- ✅ **VLESS Protocol** - Modern, efficient, hard to detect
- ✅ **Nginx Reverse Proxy** - SSL termination, security layer
- ✅ **Auto SSL** - Let's Encrypt dengan auto-renewal
- ✅ **Daily Restart** - Prevent memory leak (configurable timezone)
- ✅ **Log Rotation** - 7 days retention, compressed
- ✅ **Warning-Only Logging** - Hemat disk, hanya log issues
- ✅ **CLI User Management** - Simple commands untuk add/delete users
- ✅ **Interactive Menu** - Beautiful menu system (command: `menu`)
- ✅ **Bandwidth Monitoring** - vnstat integration (optional)
- ✅ **Auto-Recovery** - Systemd auto-restart jika crash
- ✅ **One-Command Install** - Setup dalam 5-10 menit

---

## 🚀 **Quick Install**

**One-liner installation:**

```bash
wget https://raw.githubusercontent.com/jhopan/XrayLiteByJhopanStore/main/install.sh && sudo bash install.sh
```

**Atau clone repository:**

```bash
git clone https://github.com/jhopan/XrayLiteByJhopanStore.git
cd XrayLiteByJhopanStore
sudo bash install.sh
```

**Setelah install selesai, ketik:**

```bash
menu
```

**That's it! VPN server ready dalam 5-10 menit!** 🎉

---

## 📊 **Resource Usage**

| Component | Memory | Disk |
|-----------|--------|------|
| Xray | 9 MB | 15 MB |
| Nginx | 8 MB | 10 MB |
| SSL Certs | - | 5 MB |
| Vnstat (optional) | 3 MB | 1 MB |
| **TOTAL** | **~20 MB** | **~31 MB** |

---

## 🚀 **Installation**

### **Requirements**

- Ubuntu 20.04/22.04/24.04 (recommended)
- Root access
- Domain name (pointed to VPS IP)
- Port 80 & 443 open

### **Quick Install (Recommended)**

Lihat section **[🚀 Quick Install](#-quick-install)** di atas untuk one-liner installation.

### **Manual Installation**

Jika mau download manual:

```bash
# 1. Download installer
wget https://raw.githubusercontent.com/jhopan/XrayLiteByJhopanStore/main/install.sh

# Atau clone repository:
git clone https://github.com/jhopan/XrayLiteByJhopanStore.git
cd XrayLiteByJhopanStore

# 2. Make executable
chmod +x install.sh

# 3. Run installer
sudo bash install.sh
```

### **Interactive Setup**

Installer akan tanya:

```
Domain (contoh: vpn.example.com): vpn.yourdomain.com
Email untuk SSL (contoh: admin@example.com): admin@yourdomain.com
Username pertama (kosongkan jika skip): myuser
Pilih timezone untuk daily restart:
1) WIB (UTC+7) - Jakarta
2) WITA (UTC+8) - Makassar
3) WIT (UTC+9) - Papua
Pilihan [1-3, default: 1]: 1
Install vnstat untuk bandwidth monitoring? [Y/n]: Y
```

### **Installation Time**

~5-10 menit (tergantung network speed)

---

## 📝 **Commands Reference**

### **User Management**

```bash
# Create new user
sudo vpn-user add <username>

# Delete user
sudo vpn-user delete <username>

# List all users
sudo vpn-user list

# Show VLESS URL for user
sudo vpn-user url <username>
```

**Example:**
```bash
sudo vpn-user add john
# Output:
# ✓ User 'john' created successfully!
# 
# Username: john
# UUID: 52eec3f2-856f-4efa-907f-e6efc4587da7
# 
# VLESS URL:
# vless://52eec3f2...@vpn.example.com:443?...#VPN-john

sudo vpn-user list
# Output:
# Active Users:
#   1. john - UUID: 52eec3f2-856f-4efa-907f-e6efc4587da7
#   2. jane - UUID: 987fcdeb-51a2-43d7-9012-345678901234

sudo vpn-user delete john
# Output:
# ✓ User 'john' deleted successfully!

sudo vpn-user url jane
# Output:
# VLESS URL for 'jane':
# vless://987fcdeb...@vpn.example.com:443?...#VPN-jane
```

---

### **Service Management**

```bash
# Check Xray status
sudo systemctl status xray

# Restart Xray
sudo systemctl restart xray

# Check Nginx status
sudo systemctl status nginx

# Restart Nginx
sudo systemctl restart nginx

# Check logs
sudo tail -f /var/log/xray/error.log
sudo tail -f /var/log/nginx/error.log
```

---

### **Bandwidth Monitoring (vnstat)**

```bash
# Show bandwidth summary
vnstat

# Live monitoring (real-time)
vnstat -l

# Daily stats
vnstat -d

# Monthly stats
vnstat -m

# Yearly stats
vnstat -y

# Reset stats
sudo vnstat --cleartop
```

**Example Output:**
```
                      rx      /      tx      /     total    /   estimated
 Interface: eth0
     today:    125.4 MiB  /   89.2 MiB  /   214.6 MiB  /     280 MiB
   current:    125.4 MiB  /   89.2 MiB  /   214.6 MiB
      last:      1.2 GiB  /   890 MiB   /     2.1 GiB  /    2.5 GiB
     month:      3.5 GiB  /   2.4 GiB   /     5.9 GiB  /    8.0 GiB
```

---

### **Monitoring & Maintenance**

```bash
# Check memory usage
free -h

# Check disk usage
df -h /

# Check SSL certificate
sudo certbot certificates

# Check cron jobs
sudo crontab -l

# Check Xray config
sudo cat /usr/local/etc/xray/config.json | jq

# Test Nginx config
sudo nginx -t

# Reload Nginx (after config changes)
sudo systemctl reload nginx
```

---

## 🔧 **Configuration Files**

| File | Purpose |
|------|---------|
| `/usr/local/etc/xray/config.json` | Xray configuration |
| `/etc/nginx/sites-available/vpn` | Nginx configuration |
| `/etc/letsencrypt/live/<domain>/` | SSL certificates |
| `/usr/local/bin/vpn-user` | User management script |
| `/etc/logrotate.d/xray` | Log rotation config |
| `/root/.vpn-domain` | Domain name (used by vpn-user) |

---

## 📈 **Performance**

### **Expected Performance**

```
Speed: 50-80 Mbps (tergantung network)
Latency: 60-100ms (tergantung lokasi)
Stability: 99.9% uptime
Concurrent Users: 1-5 (personal use)
Max Users: ~50 (theoretical)
```

### **Optimization Features**

- ✅ VLESS protocol (lightweight)
- ✅ WebSocket transport (good compatibility)
- ✅ TLS encryption (secure)
- ✅ Nginx reverse proxy (efficient)
- ✅ Warning-only logging (minimal overhead)
- ✅ Daily restart (prevent memory leak)

---

## 🛡️ **Security**

### **Built-in Security**

- ✅ VLESS + TLS encryption
- ✅ UUID authentication (per user)
- ✅ Nginx reverse proxy (hide Xray)
- ✅ SSL/TLS (Let's Encrypt)
- ✅ SNI support
- ✅ Private IP blocking (geoip:private)

### **What's NOT Included (by design)**

- ❌ Firewall (UFW/iptables) - UUID auth sudah cukup secure
- ❌ Fail2ban - Low risk untuk personal use
- ❌ IP whitelist - Not needed untuk personal use
- ❌ Rate limiting - VLESS sudah efficient

**Note:** Setup ini dirancang untuk personal use dengan focus pada simplicity dan performance. Untuk production/commercial use, consider adding firewall dan additional security measures.

---

## 🔄 **Automated Maintenance**

### **Daily Restart (Cron Job)**

```
Schedule: 00:00 (timezone yang kamu pilih)
Command: systemctl restart xray
Purpose: Clear memory, prevent memory leak
Downtime: 1-3 seconds
```

### **Log Rotation**

```
Schedule: Daily
Retention: 7 days
Compression: Enabled
Purpose: Prevent disk full
```

### **SSL Auto-Renewal**

```
Schedule: Every 12 hours (certbot timer)
Renewal: 30 days before expiry
Purpose: Prevent SSL expiry
```

---

## 🐛 **Troubleshooting**

### **Issue: VPN tidak bisa connect**

```bash
# 1. Check Xray status
sudo systemctl status xray

# 2. Check Nginx status
sudo systemctl status nginx

# 3. Check error logs
sudo tail -50 /var/log/xray/error.log
sudo tail -50 /var/log/nginx/error.log

# 4. Test VLESS endpoint
curl -I https://yourdomain.com/vless
# Expected: HTTP 400 (normal, karena bukan VLESS client)

# 5. Restart services
sudo systemctl restart xray
sudo systemctl restart nginx
```

---

### **Issue: SSL certificate error**

```bash
# Check certificate
sudo certbot certificates

# Manual renewal
sudo certbot renew

# Force renewal
sudo certbot renew --force-renewal

# Check Nginx config
sudo nginx -t
```

---

### **Issue: High memory usage**

```bash
# Check memory
free -h

# Check Xray memory
sudo systemctl status xray | grep Memory

# Manual restart
sudo systemctl restart xray

# Check cron job
sudo crontab -l
# Should have: 0 17 * * * systemctl restart xray
```

---

### **Issue: Disk full**

```bash
# Check disk usage
df -h /

# Check log size
sudo du -sh /var/log/xray/

# Clear logs manually
sudo truncate -s 0 /var/log/xray/error.log

# Restart Xray
sudo systemctl restart xray

# Check logrotate
sudo logrotate -d /etc/logrotate.d/xray
```

---

## 📦 **Uninstall**

```bash
# Stop services
sudo systemctl stop xray
sudo systemctl stop nginx

# Remove packages
sudo apt-get purge -y nginx certbot python3-certbot-nginx
sudo apt-get autoremove -y

# Remove Xray
sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove

# Remove config files
sudo rm -rf /usr/local/etc/xray/
sudo rm -rf /etc/nginx/sites-available/vpn
sudo rm -rf /etc/nginx/sites-enabled/vpn
sudo rm -f /usr/local/bin/vpn-user
sudo rm -f /etc/logrotate.d/xray
sudo rm -f /root/.vpn-domain

# Remove cron jobs
sudo crontab -e
# Delete: 0 17 * * * systemctl restart xray

# Remove SSL certificates
sudo rm -rf /etc/letsencrypt/live/yourdomain.com/
sudo rm -rf /etc/letsencrypt/archive/yourdomain.com/
sudo rm -rf /etc/letsencrypt/renewal/yourdomain.com.conf

# Optional: Remove vnstat
sudo apt-get purge -y vnstat
sudo rm -rf /var/lib/vnstat/
```

---

## 🆕 **Update**

```bash
# Update Xray
sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Restart services
sudo systemctl restart xray
sudo systemctl restart nginx
```

**Note:** Installer script ini tidak auto-update. Update manual sesuai kebutuhan untuk avoid breaking changes.

---

## 📚 **FAQ**

### **Q: Berapa maksimal users yang bisa ditampung?**

**A:** Theoretical max ~50 users dengan VPS specs:
- RAM: 1 GB
- CPU: 1 core
- Network: 1 Gbps

Untuk personal use (1-5 users), setup ini sangat stabil dan efisien.

---

### **Q: Apakah bisa tambah protocol lain (VMess, Trojan)?**

**A:** Bisa, tapi tidak recommended untuk setup ini. XRAY-VLESS-LITE dirancang untuk VLESS only agar lightweight dan simple.

Jika butuh multi-protocol, consider menggunakan Marzban atau XRAY-MANTAP.

---

### **Q: Apakah ada web dashboard?**

**A:** Tidak. Setup ini CLI-only untuk minimize resource usage. Semua management lewat `vpn-user` command.

Jika butuh web dashboard, consider menggunakan Marzban.

---

### **Q: Apakah support quota tracking?**

**A:** Tidak built-in. Setup ini focus pada simplicity. Quota tracking butuh database dan monitoring, yang akan add complexity dan resource usage.

Jika butuh quota tracking, consider adding custom script atau menggunakan Marzban.

---

### **Q: Apakah bisa digunakan untuk commercial?**

**A:** Bisa, tapi tidak recommended. Setup ini dirancang untuk personal use. Untuk commercial, consider:
- Adding firewall
- Adding monitoring/alerting
- Adding backup strategy
- Adding quota management
- Using more robust solution (Marzban, etc)

---

### **Q: Bagaimana jika mau migrate ke VPS baru?**

**A:** Backup dan restore:

```bash
# Di old VPS:
sudo cp /usr/local/etc/xray/config.json ~/config.json.bak
sudo cp /etc/nginx/sites-available/vpn ~/vpn.conf.bak
sudo cp /usr/local/bin/vpn-user ~/vpn-user.bak
sudo cp /root/.vpn-domain ~/.vpn-domain.bak

# Download ke laptop
scp root@old-vps:~/config.json.bak .
scp root@old-vps:~/vpn.conf.bak .
scp root@old-vps:~/vpn-user.bak .
scp root@old-vps:~/.vpn-domain.bak .

# Di new VPS:
# 1. Run installer (dengan domain yang sama)
# 2. Upload backup files
# 3. Restore config
sudo cp config.json.bak /usr/local/etc/xray/config.json
sudo cp vpn.conf.bak /etc/nginx/sites-available/vpn
sudo cp vpn-user.bak /usr/local/bin/vpn-user
sudo cp .vpn-domain.bak /root/.vpn-domain

# 4. Restart services
sudo systemctl restart xray
sudo systemctl restart nginx

# 5. Update DNS (point ke new VPS IP)
```

---

## 🤝 **Contributing**

Feel free to fork, modify, dan improve! Setup ini open dan customizable.

**Ideas for improvement:**
- Add quota tracking
- Add expiry date
- Add subscription URLs
- Add web dashboard (optional)
- Add Telegram bot integration
- Add backup automation
- Add BBR optimization

---

## 📄 **License**

Open source, use as you wish!

---

## 🙏 **Credits**

- **Xray** - https://github.com/XTLS/Xray-core
- **Nginx** - https://nginx.org/
- **Let's Encrypt** - https://letsencrypt.org/
- **Certbot** - https://certbot.eff.org/
- **Vnstat** - https://humdi.net/vnstat/

---

## 💖 **Made With Love**

**XrayLite by JhopanStore**

Custom VPN server setup yang lightweight, stable, dan easy to manage.

Designed for personal use dengan focus pada:
- ✅ Simplicity
- ✅ Performance
- ✅ Stability
- ✅ Minimal resource usage

---

## 📞 **Support**

Jika ada issue atau pertanyaan:
1. Check troubleshooting section di atas
2. Check logs: `sudo tail -50 /var/log/xray/error.log`
3. Verify config: `sudo cat /usr/local/etc/xray/config.json | jq`
4. Test services: `sudo systemctl status xray nginx`

---

**XrayLite by JhopanStore** ❤️

*Lightweight VPN Server for Everyone*
