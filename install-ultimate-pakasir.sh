#!/bin/bash
# ============================================================================
# VPN RW MOBILE LEGENDS BOT PANEL - ULTIMATE EDITION with PAKASIR PAYMENT
# Support Multi Location termasuk INDIA (Bangalore)
# All-in-One Installer dengan Payment Gateway Pakasir.com
# Compatible: Ubuntu 22.04 / Debian 11
# ============================================================================

set -e

# ==================== KONFIGURASI WARNA ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ==================== BANNER ====================
clear
echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║   ██████   ██     ██    ███    ███ ██      ██████  ██████  ║"
echo "║   ██   ██  ██     ██    ████  ████ ██      ██   ██ ██   ██ ║"
echo "║   ██████   ██  █  ██    ██ ████ ██ ██      ██████  ██████  ║"
echo "║   ██   ██  ██ ███ ██    ██  ██  ██ ██      ██   ██ ██   ██ ║"
echo "║   ██   ██   ███ ███     ██      ██ ███████ ██████  ██████  ║"
echo "║                                                            ║"
echo "║         🎮 RW MOBILE LEGENDS BOT EDITION 🎮                ║"
echo "║         💰 DENGAN PAYMENT GATEWAY PAKASIR.COM 💰           ║"
echo "║         🌏 SUPPORT MULTI LOCATION (INDIA/BANGALORE) 🌏     ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==================== CEK ROOT ====================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root!${NC}" 
   exit 1
fi

# ==================== FUNGSI PILIH LOKASI SERVER ====================
choose_server_location() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🌏 PILIH LOKASI SERVER UTAMA${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Pilih lokasi server VPS Anda:"
    echo "1) 🇸🇬 Singapore (Ping terendah ke MLBB - 30ms)"
    echo "2) 🇯🇵 Japan (Ping 40-50ms)"
    echo "3) 🇺🇸 USA (Ping 180-200ms)"
    echo "4) 🇧🇷 Brazil (Ping 250-300ms)"
    echo "5) 🇮🇳 India - Bangalore (Ping 60-80ms ke Singapore)"
    echo "6) 🇮🇩 Indonesia - Jakarta (Ping 40-60ms)"
    echo "7) 🇦🇺 Australia - Sydney (Ping 100-120ms)"
    echo "8) 🇬🇧 UK - London (Ping 150-170ms)"
    echo "9) 🇩🇪 Germany - Frankfurt (Ping 160-180ms)"
    echo "10) 🇫🇷 France - Paris (Ping 170-190ms)"
    echo "11) Lainnya (isi manual)"
    echo ""
    read -p "Pilih nomor [1-11]: " LOCATION_CHOICE
    
    case $LOCATION_CHOICE in
        1)
            LOCATION="Singapore"
            COUNTRY_CODE="SG"
            CITY="Singapore"
            MLBB_PING="30-40ms"
            ;;
        2)
            LOCATION="Japan"
            COUNTRY_CODE="JP"
            CITY="Tokyo"
            MLBB_PING="40-50ms"
            ;;
        3)
            LOCATION="USA"
            COUNTRY_CODE="US"
            CITY="Washington"
            MLBB_PING="180-200ms"
            ;;
        4)
            LOCATION="Brazil"
            COUNTRY_CODE="BR"
            CITY="Sao Paulo"
            MLBB_PING="250-300ms"
            ;;
        5)
            LOCATION="India"
            COUNTRY_CODE="IN"
            CITY="Bangalore"
            MLBB_PING="60-80ms"
            ;;
        6)
            LOCATION="Indonesia"
            COUNTRY_CODE="ID"
            CITY="Jakarta"
            MLBB_PING="40-60ms"
            ;;
        7)
            LOCATION="Australia"
            COUNTRY_CODE="AU"
            CITY="Sydney"
            MLBB_PING="100-120ms"
            ;;
        8)
            LOCATION="UK"
            COUNTRY_CODE="GB"
            CITY="London"
            MLBB_PING="150-170ms"
            ;;
        9)
            LOCATION="Germany"
            COUNTRY_CODE="DE"
            CITY="Frankfurt"
            MLBB_PING="160-180ms"
            ;;
        10)
            LOCATION="France"
            COUNTRY_CODE="FR"
            CITY="Paris"
            MLBB_PING="170-190ms"
            ;;
        11)
            read -p "Masukkan nama lokasi: " LOCATION
            read -p "Masukkan country code (2 huruf, contoh: IN): " COUNTRY_CODE
            read -p "Masukkan nama kota: " CITY
            MLBB_PING="Varies"
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid, menggunakan Singapore${NC}"
            LOCATION="Singapore"
            COUNTRY_CODE="SG"
            CITY="Singapore"
            MLBB_PING="30-40ms"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✅ Lokasi dipilih: ${LOCATION} (${COUNTRY_CODE}) - ${CITY}${NC}"
    echo -e "   Estimasi ping ke MLBB: ${MLBB_PING}"
    echo ""
}

# ==================== FUNGSI KONFIGURASI URL PANEL ====================
configure_panel_url() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🔗 KONFIGURASI URL PANEL${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Pilih jenis akses untuk panel Anda:"
    echo "1) 🌐 Menggunakan IP VPS (contoh: http://123.456.78.90:8080)"
    echo "2) 📡 Menggunakan Subdomain (contoh: https://vpn.domain.com)"
    echo "3) 🔗 Menggunakan Domain (contoh: https://domain.com)"
    echo ""
    read -p "Pilih [1-3]: " ACCESS_TYPE
    
    case $ACCESS_TYPE in
        1)
            IP_VPS=$(curl -s ifconfig.me)
            DOMAIN="$IP_VPS"
            PROTOCOL="http"
            PORT=":8080"
            DOMAIN_FULL="http://${IP_VPS}:8080"
            USE_SSL=false
            echo -e "${GREEN}✅ Menggunakan IP VPS: ${DOMAIN_FULL}${NC}"
            ;;
        2|3)
            read -p "🔗 Masukkan domain/subdomain Anda (contoh: vpn.domain.com): " DOMAIN
            PROTOCOL="https"
            PORT=""
            DOMAIN_FULL="https://${DOMAIN}"
            USE_SSL=true
            read -p "📧 Masukkan email untuk SSL certificate: " EMAIL
            echo -e "${GREEN}✅ Menggunakan domain: ${DOMAIN_FULL}${NC}"
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid! Menggunakan IP VPS.${NC}"
            IP_VPS=$(curl -s ifconfig.me)
            DOMAIN="$IP_VPS"
            PROTOCOL="http"
            PORT=":8080"
            DOMAIN_FULL="http://${IP_VPS}:8080"
            USE_SSL=false
            ;;
    esac
    echo ""
}

# ==================== FUNGSI KONFIGURASI PAKASIR ====================
configure_pakasir() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}💰 KONFIGURASI PAYMENT GATEWAY PAKASIR.COM${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "Daftar dulu di ${CYAN}https://pakasir.com${NC} lalu buat proyek"
    echo -e "Webhook URL nanti: ${GREEN}${DOMAIN_FULL}/api/payment/webhook${NC}"
    echo ""
    read -p "🔑 Masukkan PAKASIR API Key: " PAKASIR_API_KEY
    read -p "🔤 Masukkan PAKASIR Project Slug: " PAKASIR_SLUG
    read -p "💰 Kurs USD ke IDR (default: 15000): " USD_RATE
    USD_RATE=${USD_RATE:-15000}
    
    # Validate inputs
    if [ -z "$PAKASIR_API_KEY" ] || [ -z "$PAKASIR_SLUG" ]; then
        echo -e "${YELLOW}⚠️  PAKASIR API Key atau Slug kosong. Payment gateway akan dinonaktifkan sementara.${NC}"
        echo -e "   Anda bisa mengatur nanti di file konfigurasi."
        PAKASIR_ENABLED=false
    else
        PAKASIR_ENABLED=true
    fi
    echo ""
}

# ==================== FUNGSI KONFIGURASI DATABASE ====================
configure_database() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🗄️  KONFIGURASI DATABASE${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Generate random passwords
    DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    NODE_API_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    JWT_SECRET=$(openssl rand -base64 32)
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    
    echo -e "${GREEN}✅ Database credentials generated${NC}"
    echo ""
}

# ==================== FUNGSI KONFIGURASI NODE LOCAL ====================
configure_local_node() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}🖥️  KONFIGURASI NODE LOKAL${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "🚀 Install node server juga di VPS ini? (y/n): " INSTALL_NODE_LOCAL
    echo ""
}

# ==================== PILIH LOKASI SERVER ====================
choose_server_location

# ==================== KONFIGURASI URL PANEL ====================
configure_panel_url

# ==================== KONFIGURASI PAKASIR ====================
configure_pakasir

# ==================== KONFIGURASI DATABASE ====================
configure_database

# ==================== KONFIGURASI NODE LOKAL ====================
configure_local_node

# ==================== RINGKASAN KONFIGURASI ====================
clear
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}📋 RINGKASAN KONFIGURASI${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "🌏 ${WHITE}LOKASI SERVER:${NC}"
echo -e "   • Lokasi     : ${GREEN}${LOCATION}${NC}"
echo -e "   • Country    : ${GREEN}${COUNTRY_CODE}${NC}"
echo -e "   • Kota       : ${GREEN}${CITY}${NC}"
echo -e "   • Ping MLBB  : ${GREEN}${MLBB_PING}${NC}"
echo ""
echo -e "🔗 ${WHITE}URL PANEL:${NC}"
echo -e "   • URL        : ${GREEN}${DOMAIN_FULL}${NC}"
echo -e "   • Protocol   : ${GREEN}${PROTOCOL}${NC}"
echo -e "   • SSL        : ${GREEN}${USE_SSL}${NC}"
echo ""
echo -e "💰 ${WHITE}PAYMENT GATEWAY:${NC}"
echo -e "   • Status     : ${GREEN}${PAKASIR_ENABLED}${NC}"
echo -e "   • API Key    : ${GREEN}${PAKASIR_API_KEY}${NC}"
echo -e "   • Slug       : ${GREEN}${PAKASIR_SLUG}${NC}"
echo -e "   • Kurs USD   : ${GREEN}Rp ${USD_RATE}${NC}"
echo -e "   • Webhook    : ${GREEN}${DOMAIN_FULL}/api/payment/webhook${NC}"
echo ""
echo -e "🗄️ ${WHITE}DATABASE:${NC}"
echo -e "   • DB Name    : ${GREEN}vpn_panel${NC}"
echo -e "   • DB User    : ${GREEN}vpn_user${NC}"
echo -e "   • DB Pass    : ${GREEN}${DB_PASSWORD}${NC}"
echo -e "   • JWT Secret : ${GREEN}${JWT_SECRET}${NC}"
echo -e "   • Node API   : ${GREEN}${NODE_API_KEY}${NC}"
echo ""
echo -e "🖥️ ${WHITE}NODE SERVER:${NC}"
echo -e "   • Install Lokal : ${GREEN}${INSTALL_NODE_LOCAL}${NC}"
echo ""
echo -e "${YELLOW}Apakah konfigurasi sudah benar? (y/n)${NC}"
read -p "Lanjutkan instalasi? " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Instalasi dibatalkan.${NC}"
    exit 0
fi

# ==================== VARIABEL GLOBAL ====================
PANEL_PORT=8080
NODE_PORT_START=8081

# ==================== MULAI INSTALASI ====================
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🚀 MEMULAI INSTALASI PANEL ULTIMATE${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""

# ==================== FUNGSI INSTALL DEPENDENCIES ====================
install_dependencies() {
    echo -e "${YELLOW}[1/15] Menginstall dependencies...${NC}"
    
    apt update && apt upgrade -y
    apt install -y curl wget git unzip zip nginx mysql-server \
        redis-server certbot python3-certbot-nginx build-essential \
        ufw nodejs npm python3 python3-pip python3-scapy \
        tcpdump nmap net-tools iptables-persistent netcat \
        htop iftop vnstat nload jq sqlite3 \
        fail2ban cron logrotate rsyslog dnsutils \
        speedtest-cli gcc g++ make
        
    # Install Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# ==================== FUNGSI INSTALL XRAY ====================
install_xray() {
    echo -e "${YELLOW}[2/15] Menginstall Xray core...${NC}"
    
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    echo -e "${GREEN}✅ Xray installed${NC}"
}

# ==================== FUNGSI SETUP FIREWALL ====================
setup_firewall() {
    echo -e "${YELLOW}[3/15] Mengkonfigurasi firewall...${NC}"
    
    ufw --force disable
    ufw --force reset
    
    ufw default deny incoming
    ufw default allow outgoing
    
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow ${PANEL_PORT}/tcp comment 'Panel API'
    ufw allow ${NODE_PORT_START}:${NODE_PORT_START}+10/tcp comment 'Node Ports'
    ufw allow 7000:8000/udp comment 'MLBB Game Ports'
    ufw allow 10001/udp comment 'MLBB Bot Server'
    ufw limit 22/tcp
    
    echo "y" | ufw enable
    
    echo -e "${GREEN}✅ Firewall configured${NC}"
}

# ==================== FUNGSI SETUP DATABASE ====================
setup_database() {
    echo -e "${YELLOW}[4/15] Mengkonfigurasi database...${NC}"
    
    # Secure MySQL installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';" 2>/dev/null || true
    mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || true
    mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    
    # Create database and user
    mysql -e "CREATE DATABASE IF NOT EXISTS vpn_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER IF NOT EXISTS 'vpn_user'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON vpn_panel.* TO 'vpn_user'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    
    systemctl restart mysql
    
    echo -e "${GREEN}✅ Database configured${NC}"
}

# ==================== FUNGSI SETUP REDIS ====================
setup_redis() {
    echo -e "${YELLOW}[5/15] Mengkonfigurasi Redis...${NC}"
    
    systemctl restart redis-server
    
    echo -e "${GREEN}✅ Redis configured${NC}"
}

# ==================== FUNGSI BUAT DIRECTORY STRUCTURE ====================
create_directories() {
    echo -e "${YELLOW}[6/15] Membuat struktur direktori...${NC}"
    
    mkdir -p /var/www/vpn-panel
    mkdir -p /var/www/vpn-panel/{backend,frontend,node-controller,mlbb-bot}
    mkdir -p /etc/vpn-panel
    mkdir -p /etc/vpn-panel/rw-ml
    mkdir -p /var/log/vpn-panel
    mkdir -p /var/log/vpn-panel/{access,error,traffic,bot,payment}
    mkdir -p /var/log/mlbb-bot
    mkdir -p /var/lib/vpn-panel/{data,cache,payments}
    
    # Save configuration
    cat > /etc/vpn-panel/config.yml << EOF
# VPN Panel Configuration
panel:
  domain: ${DOMAIN}
  protocol: ${PROTOCOL}
  port: ${PANEL_PORT}
  url: ${DOMAIN_FULL}
  location: ${LOCATION}
  country_code: ${COUNTRY_CODE}
  city: ${CITY}
  mlbb_ping: ${MLBB_PING}
  environment: production
  debug: false

database:
  host: localhost
  port: 3306
  name: vpn_panel
  user: vpn_user
  password: ${DB_PASSWORD}

redis:
  host: localhost
  port: 6379
  db: 0

node:
  api_key: ${NODE_API_KEY}
  port_range_start: ${NODE_PORT_START}
  max_nodes: 100

payment:
  enabled: ${PAKASIR_ENABLED}
  gateway: pakasir
  pakasir_api_key: ${PAKASIR_API_KEY}
  pakasir_slug: ${PAKASIR_SLUG}
  pakasir_url: https://app.pakasir.com
  usd_rate: ${USD_RATE}
  webhook_url: ${DOMAIN_FULL}/api/payment/webhook
  currencies:
    - IDR
    - USD
  methods:
    - qris
    - bni_va
    - bri_va
    - cimb_niaga_va
    - permata_va
    - paypal

mlbb:
  bot_mode: true
  matchmaking_timeout: 10
  default_difficulty: easy
  servers:
    - name: Singapore
      ip: 52.74.12.98
      ping: 30
    - name: Japan
      ip: 54.65.56.147
      ping: 45
    - name: India
      ip: 52.74.12.98  # Route via Singapore
      ping: 60-80
    - name: USA
      ip: 54.67.42.121
      ping: 180
EOF

    cat > /etc/vpn-panel/secrets.conf << EOF
DB_PASSWORD=${DB_PASSWORD}
NODE_API_KEY=${NODE_API_KEY}
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
PAKASIR_API_KEY=${PAKASIR_API_KEY}
PAKASIR_SLUG=${PAKASIR_SLUG}
EOF
    
    chmod 600 /etc/vpn-panel/secrets.conf
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# ==================== FUNGSI CREATE BACKEND ====================
create_backend() {
    echo -e "${YELLOW}[7/15] Membuat backend API...${NC}"
    
    cd /var/www/vpn-panel/backend
    
    # Create package.json
    cat > package.json << 'EOF'
{
  "name": "vpn-panel-ultimate",
  "version": "4.0.0",
  "description": "VPN Panel dengan Payment Gateway Pakasir",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "sequelize": "^6.32.1",
    "redis": "^4.6.7",
    "jsonwebtoken": "^9.0.1",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "axios": "^1.4.0",
    "socket.io": "^4.6.1",
    "node-cron": "^3.0.2",
    "qrcode": "^1.5.3",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "express-rate-limit": "^6.9.0",
    "uuid": "^9.0.0",
    "nanoid": "^5.0.1",
    "joi": "^17.10.1",
    "yaml": "^2.3.1",
    "winston": "^3.10.0"
  }
}
EOF

    npm install
    
    # Create Pakasir service
    mkdir -p services
    cat > services/pakasir.service.js << 'EOF'
const axios = require('axios');

class PakasirService {
    constructor(apiKey, projectSlug, baseUrl = 'https://app.pakasir.com') {
        this.apiKey = apiKey;
        this.projectSlug = projectSlug;
        this.baseUrl = baseUrl;
    }

    createPaymentUrl(amount, orderId, options = {}) {
        const { redirect, qrisOnly, method } = options;
        
        let url = `${this.baseUrl}/pay/${this.projectSlug}/${amount}?order_id=${orderId}`;
        
        if (redirect) {
            url += `&redirect=${encodeURIComponent(redirect)}`;
        }
        if (qrisOnly) {
            url += '&qris_only=1';
        }
        if (method === 'paypal') {
            url = `${this.baseUrl}/paypal/${this.projectSlug}/${amount}?order_id=${orderId}`;
        }
        
        return url;
    }

    async createTransaction(method, data) {
        const response = await axios.post(
            `${this.baseUrl}/api/transactioncreate/${method}`,
            {
                project: this.projectSlug,
                order_id: data.orderId,
                amount: data.amount,
                api_key: this.apiKey
            }
        );
        return response.data;
    }

    async getTransactionDetail(orderId, amount) {
        const response = await axios.get(
            `${this.baseUrl}/api/transactiondetail`,
            {
                params: {
                    project: this.projectSlug,
                    order_id: orderId,
                    amount: amount,
                    api_key: this.apiKey
                }
            }
        );
        return response.data;
    }

    generateOrderId(prefix = 'INV') {
        return `${prefix}${Date.now()}${Math.random().toString(36).substring(7)}`;
    }
}

module.exports = PakasirService;
EOF

    # Create main server file
    cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Sequelize, DataTypes, Op } = require('sequelize');
const redis = require('ioredis');
const cron = require('node-cron');
const QRCode = require('qrcode');
const { Server } = require('socket.io');
const http = require('http');
const fs = require('fs');
const yaml = require('js-yaml');
const { v4: uuidv4 } = require('uuid');
const PakasirService = require('./services/pakasir.service');

// Load configuration
const config = yaml.load(fs.readFileSync('/etc/vpn-panel/config.yml', 'utf8'));
const secrets = {};
fs.readFileSync('/etc/vpn-panel/secrets.conf', 'utf8').split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) secrets[key] = value;
});

// Initialize
const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });
const pakasir = new PakasirService(secrets.PAKASIR_API_KEY, secrets.PAKASIR_SLUG);

// Database
const sequelize = new Sequelize(config.database.name, config.database.user, secrets.DB_PASSWORD, {
    host: config.database.host,
    dialect: 'mysql',
    logging: false
});

// Redis
const redisClient = new redis(config.redis);

// Models
const User = sequelize.define('User', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    username: { type: DataTypes.STRING, unique: true },
    password: DataTypes.STRING,
    email: DataTypes.STRING,
    role: { type: DataTypes.STRING, defaultValue: 'user' },
    balance: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
    totalDeposit: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
    botMode: { type: DataTypes.BOOLEAN, defaultValue: false },
    status: { type: DataTypes.STRING, defaultValue: 'active' }
});

const Invoice = sequelize.define('Invoice', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    invoiceNo: { type: DataTypes.STRING, unique: true },
    userId: DataTypes.INTEGER,
    amount: DataTypes.DECIMAL(15, 2),
    status: { type: DataTypes.STRING, defaultValue: 'pending' },
    paymentMethod: DataTypes.STRING,
    paidAt: DataTypes.DATE,
    expiredAt: DataTypes.DATE
});

const Transaction = sequelize.define('Transaction', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    userId: DataTypes.INTEGER,
    invoiceId: DataTypes.INTEGER,
    type: DataTypes.STRING,
    amount: DataTypes.DECIMAL(15, 2),
    balance: DataTypes.DECIMAL(15, 2),
    description: DataTypes.TEXT
});

const Product = sequelize.define('Product', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    name: DataTypes.STRING,
    price: DataTypes.DECIMAL(15, 2),
    duration: DataTypes.INTEGER,
    trafficLimit: DataTypes.BIGINT,
    protocol: DataTypes.STRING,
    botEnabled: DataTypes.BOOLEAN
});

sequelize.sync();

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json());
app.use(rateLimit({ windowMs: 15*60*1000, max: 100 }));

// Auth middleware
const authenticateToken = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'No token' });
    
    jwt.verify(token, secrets.JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: 'Invalid token' });
        req.user = user;
        next();
    });
};

// ==================== PAYMENT ROUTES ====================

// Get payment methods
app.get('/api/payment/methods', (req, res) => {
    res.json({
        methods: [
            { id: 'qris', name: 'QRIS', min: 1000 },
            { id: 'bni_va', name: 'BNI Virtual Account', min: 10000 },
            { id: 'bri_va', name: 'BRI Virtual Account', min: 10000 },
            { id: 'cimb_niaga_va', name: 'CIMB Niaga VA', min: 10000 },
            { id: 'permata_va', name: 'Permata Virtual Account', min: 10000 },
            { id: 'paypal', name: 'PayPal', min: 1, currency: 'USD' }
        ],
        exchange_rate: config.payment.usd_rate
    });
});

// Create deposit
app.post('/api/payment/deposit', authenticateToken, async (req, res) => {
    try {
        const { amount, method, redirectUrl } = req.body;
        
        if (amount < 1000) {
            return res.status(400).json({ error: 'Minimum deposit Rp 1.000' });
        }
        
        const invoiceNo = pakasir.generateOrderId('DEP');
        const expiredAt = new Date();
        expiredAt.setHours(expiredAt.getHours() + 24);
        
        const invoice = await Invoice.create({
            invoiceNo,
            userId: req.user.id,
            amount,
            status: 'pending',
            paymentMethod: method,
            expiredAt
        });
        
        const paymentUrl = pakasir.createPaymentUrl(amount, invoiceNo, {
            method: method === 'paypal' ? 'paypal' : null,
            redirect: redirectUrl || `${config.panel.url}/payment/status`
        });
        
        res.json({ success: true, invoice, paymentUrl });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Webhook for Pakasir
app.post('/api/payment/webhook', async (req, res) => {
    try {
        const { amount, order_id, status, payment_method, completed_at } = req.body;
        
        const invoice = await Invoice.findOne({ where: { invoiceNo: order_id } });
        
        if (invoice && status === 'completed' && invoice.status !== 'paid') {
            invoice.status = 'paid';
            invoice.paidAt = new Date(completed_at);
            invoice.paymentMethod = payment_method;
            await invoice.save();
            
            const user = await User.findByPk(invoice.userId);
            if (user) {
                const newBalance = parseFloat(user.balance) + parseFloat(invoice.amount);
                user.balance = newBalance;
                user.totalDeposit = parseFloat(user.totalDeposit) + parseFloat(invoice.amount);
                await user.save();
                
                await Transaction.create({
                    userId: user.id,
                    invoiceId: invoice.id,
                    type: 'credit',
                    amount: invoice.amount,
                    balance: newBalance,
                    description: `Deposit via ${payment_method}`
                });
            }
        }
        
        res.json({ received: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Check payment status
app.get('/api/payment/status/:invoiceNo', authenticateToken, async (req, res) => {
    const invoice = await Invoice.findOne({
        where: { invoiceNo: req.params.invoiceNo, userId: req.user.id }
    });
    res.json(invoice);
});

// Get user balance
app.get('/api/user/balance', authenticateToken, async (req, res) => {
    const user = await User.findByPk(req.user.id);
    const transactions = await Transaction.findAll({
        where: { userId: req.user.id },
        order: [['createdAt', 'DESC']],
        limit: 10
    });
    
    res.json({
        balance: user.balance,
        totalDeposit: user.totalDeposit,
        transactions
    });
});

// Get products
app.get('/api/products', async (req, res) => {
    const products = await Product.findAll({ where: { active: true } });
    res.json(products);
});

// Buy product
app.post('/api/products/buy', authenticateToken, async (req, res) => {
    const { productId } = req.body;
    
    const product = await Product.findByPk(productId);
    const user = await User.findByPk(req.user.id);
    
    if (user.balance < product.price) {
        return res.status(400).json({ error: 'Insufficient balance' });
    }
    
    const newBalance = user.balance - product.price;
    user.balance = newBalance;
    user.totalSpent = (user.totalSpent || 0) + product.price;
    await user.save();
    
    await Transaction.create({
        userId: user.id,
        type: 'debit',
        amount: product.price,
        balance: newBalance,
        description: `Pembelian: ${product.name}`
    });
    
    res.json({ success: true, newBalance });
});

// Auth routes
app.post('/api/auth/login', async (req, res) => {
    const { username, password } = req.body;
    
    const user = await User.findOne({ where: { username } });
    if (!user || !bcrypt.compareSync(password, user.password)) {
        return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const token = jwt.sign(
        { id: user.id, username: user.username, role: user.role },
        secrets.JWT_SECRET,
        { expiresIn: '7d' }
    );
    
    res.json({ token, user: { id: user.id, username: user.username, balance: user.balance } });
});

app.post('/api/auth/register', async (req, res) => {
    const { username, password, email } = req.body;
    
    const existing = await User.findOne({ where: { username } });
    if (existing) {
        return res.status(400).json({ error: 'Username exists' });
    }
    
    const hashedPassword = bcrypt.hashSync(password, 10);
    await User.create({
        username,
        password: hashedPassword,
        email,
        role: 'user',
        balance: 0
    });
    
    res.json({ success: true });
});

// Dashboard
app.get('/api/dashboard', authenticateToken, async (req, res) => {
    const user = await User.findByPk(req.user.id);
    res.json({
        balance: user.balance,
        location: config.panel.location,
        country: config.panel.country_code,
        mlbb_ping: config.panel.mlbb_ping
    });
});

// MLBB Bot routes
app.post('/api/mlbb/bot/enable', authenticateToken, async (req, res) => {
    const { difficulty = 'easy' } = req.body;
    await User.update({ botMode: true, botDifficulty: difficulty }, {
        where: { id: req.user.id }
    });
    res.json({ success: true });
});

app.post('/api/mlbb/bot/disable', authenticateToken, async (req, res) => {
    await User.update({ botMode: false }, { where: { id: req.user.id } });
    res.json({ success: true });
});

// Start server
const PORT = config.panel.port || 8080;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Panel running on ${config.panel.url}`);
    console.log(`Location: ${config.panel.location} (${config.panel.country_code})`);
});

// Create default products
setTimeout(async () => {
    const count = await Product.count();
    if (count === 0) {
        await Product.create({
            name: '1 Bulan - Basic',
            price: 50000,
            duration: 30,
            trafficLimit: 100 * 1e9,
            protocol: 'vless',
            botEnabled: true
        });
        await Product.create({
            name: '3 Bulan - Premium',
            price: 120000,
            duration: 90,
            trafficLimit: 300 * 1e9,
            protocol: 'vless',
            botEnabled: true
        });
    }
}, 5000);
EOF

    echo -e "${GREEN}✅ Backend created${NC}"
}

# ==================== FUNGSI CREATE FRONTEND ====================
create_frontend() {
    echo -e "${YELLOW}[8/15] Membuat frontend...${NC}"
    
    cd /var/www/vpn-panel/frontend
    
    # Create React app
    npx create-react-app . --template typescript
    
    # Install dependencies
    npm install @mui/material @emotion/react @emotion/styled @mui/icons-material \
        axios react-router-dom react-qr-code react-copy-to-clipboard \
        react-toastify framer-motion
    
    # Create App.tsx
    cat > src/App.tsx << 'EOF'
import React, { useEffect, useState } from 'react';
import {
  ThemeProvider, createTheme, CssBaseline, Box, AppBar,
  Toolbar, Typography, IconButton, Badge, Avatar, Menu,
  MenuItem, Paper, Grid, Card, CardContent, Button,
  Dialog, DialogTitle, DialogContent, DialogActions,
  TextField, InputAdornment, Chip, Table, TableBody,
  TableCell, TableContainer, TableHead, TableRow,
  FormControl, InputLabel, Select, Alert
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Payment as PaymentIcon,
  AccountBalance as BalanceIcon,
  History as HistoryIcon,
  ShoppingCart as CartIcon,
  QrCode as QrCodeIcon,
  ContentCopy as CopyIcon,
  SportsEsports as GameIcon,
  BugReport as BotIcon,
  DarkMode as DarkModeIcon,
  LightMode as LightModeIcon,
  ExitToApp as LogoutIcon
} from '@mui/icons-material';
import { QRCodeSVG } from 'qrcode.react';
import { CopyToClipboard } from 'react-copy-to-clipboard';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import axios from 'axios';

const theme = createTheme({
  palette: { mode: 'dark', primary: { main: '#ff4d4d' } }
});

function App() {
  const [user, setUser] = useState(null);
  const [balance, setBalance] = useState(0);
  const [products, setProducts] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [paymentMethods, setPaymentMethods] = useState([]);
  const [openDeposit, setOpenDeposit] = useState(false);
  const [amount, setAmount] = useState(50000);
  const [method, setMethod] = useState('qris');
  const [currentInvoice, setCurrentInvoice] = useState(null);
  const [anchorEl, setAnchorEl] = useState(null);
  const [location, setLocation] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) window.location.href = '/login';
    
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const token = localStorage.getItem('token');
      const headers = { Authorization: `Bearer ${token}` };
      
      const [balanceRes, productsRes, methodsRes] = await Promise.all([
        axios.get('/api/user/balance', { headers }),
        axios.get('/api/products'),
        axios.get('/api/payment/methods')
      ]);
      
      setBalance(balanceRes.data.balance);
      setTransactions(balanceRes.data.transactions);
      setProducts(productsRes.data);
      setPaymentMethods(methodsRes.data.methods);
    } catch (error) {
      console.error(error);
    }
  };

  const handleDeposit = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post('/api/payment/deposit', {
        amount,
        method,
        redirectUrl: window.location.origin + '/callback'
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      window.location.href = res.data.paymentUrl;
    } catch (error) {
      toast.error(error.response?.data?.error || 'Failed');
    }
  };

  const handleBuy = async (productId) => {
    try {
      const token = localStorage.getItem('token');
      await axios.post('/api/products/buy', { productId }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      toast.success('Purchase successful!');
      fetchData();
    } catch (error) {
      toast.error(error.response?.data?.error || 'Failed');
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    window.location.href = '/login';
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <ToastContainer theme="dark" />
      
      <Box sx={{ display: 'flex' }}>
        <AppBar position="fixed">
          <Toolbar>
            <Typography variant="h6" sx={{ flexGrow: 1, display: 'flex', alignItems: 'center' }}>
              <GameIcon sx={{ mr: 1 }} /> RW MLBB VPN
            </Typography>
            
            <Chip 
              icon={<BotIcon />} 
              label="Bot Mode Ready" 
              size="small" 
              color="primary"
              variant="outlined"
              sx={{ mr: 2 }}
            />
            
            <IconButton color="inherit" onClick={() => setOpenDeposit(true)}>
              <BalanceIcon />
            </IconButton>
            
            <IconButton color="inherit" onClick={(e) => setAnchorEl(e.currentTarget)}>
              <Avatar sx={{ bgcolor: 'primary.main' }}>
                {user?.username?.charAt(0).toUpperCase()}
              </Avatar>
            </IconButton>
            
            <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={() => setAnchorEl(null)}>
              <MenuItem>
                <BalanceIcon sx={{ mr: 1 }} /> Rp {balance?.toLocaleString()}
              </MenuItem>
              <MenuItem onClick={handleLogout}>
                <LogoutIcon sx={{ mr: 1 }} /> Logout
              </MenuItem>
            </Menu>
          </Toolbar>
        </AppBar>
        
        <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8 }}>
          {/* Balance Card */}
          <Grid container spacing={3} sx={{ mb: 4 }}>
            <Grid item xs={12} md={4}>
              <Card>
                <CardContent>
                  <Typography color="text.secondary">Your Balance</Typography>
                  <Typography variant="h3" color="primary.main">
                    Rp {balance?.toLocaleString()}
                  </Typography>
                  <Button 
                    variant="contained" 
                    startIcon={<PaymentIcon />}
                    onClick={() => setOpenDeposit(true)}
                    sx={{ mt: 2 }}
                  >
                    Deposit
                  </Button>
                </CardContent>
              </Card>
            </Grid>
            
            <Grid item xs={12} md={8}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Recent Transactions
                  </Typography>
                  <TableContainer>
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Date</TableCell>
                          <TableCell>Description</TableCell>
                          <TableCell align="right">Amount</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {transactions.map((tx) => (
                          <TableRow key={tx.id}>
                            <TableCell>{new Date(tx.createdAt).toLocaleDateString()}</TableCell>
                            <TableCell>{tx.description}</TableCell>
                            <TableCell align="right" sx={{
                              color: tx.type === 'credit' ? 'success.main' : 'error.main'
                            }}>
                              {tx.type === 'credit' ? '+' : '-'} Rp {parseFloat(tx.amount).toLocaleString()}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
          
          {/* Products */}
          <Typography variant="h5" sx={{ mb: 3 }}>
            VPN Packages
          </Typography>
          
          <Grid container spacing={3}>
            {products.map((product) => (
              <Grid item xs={12} md={4} key={product.id}>
                <Card>
                  <CardContent>
                    <Typography variant="h5">{product.name}</Typography>
                    <Typography variant="h4" color="primary.main" sx={{ my: 2 }}>
                      Rp {parseFloat(product.price).toLocaleString()}
                    </Typography>
                    <Box sx={{ my: 2 }}>
                      <Chip label={`${product.duration} Days`} size="small" sx={{ mr: 1 }} />
                      <Chip label={`${product.trafficLimit / 1e9} GB`} size="small" />
                    </Box>
                    <Button 
                      fullWidth 
                      variant="contained"
                      disabled={balance < product.price}
                      onClick={() => handleBuy(product.id)}
                    >
                      {balance < product.price ? 'Insufficient Balance' : 'Buy Now'}
                    </Button>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      </Box>
      
      {/* Deposit Dialog */}
      <Dialog open={openDeposit} onClose={() => setOpenDeposit(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Deposit Balance</DialogTitle>
        <DialogContent>
          <FormControl fullWidth margin="normal">
            <InputLabel>Payment Method</InputLabel>
            <Select value={method} onChange={(e) => setMethod(e.target.value)} label="Payment Method">
              {paymentMethods.map((m) => (
                <MenuItem key={m.id} value={m.id}>{m.name}</MenuItem>
              ))}
            </Select>
          </FormControl>
          
          <TextField
            fullWidth
            label="Amount"
            type="number"
            margin="normal"
            value={amount}
            onChange={(e) => setAmount(parseInt(e.target.value))}
            InputProps={{
              startAdornment: <InputAdornment position="start">Rp</InputAdornment>
            }}
          />
          
          <Box sx={{ mt: 2, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
            {[10000, 25000, 50000, 100000].map((amt) => (
              <Chip
                key={amt}
                label={`Rp ${amt.toLocaleString()}`}
                onClick={() => setAmount(amt)}
                color={amount === amt ? 'primary' : 'default'}
              />
            ))}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDeposit(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleDeposit}>Pay Now</Button>
        </DialogActions>
      </Dialog>
    </ThemeProvider>
  );
}

export default App;
EOF

    # Create Login page
    cat > src/Login.tsx << 'EOF'
import React, { useState } from 'react';
import { Container, Paper, Typography, TextField, Button, Box, Alert } from '@mui/material';
import { Gamepad as GameIcon } from '@mui/icons-material';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

function Login() {
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const res = await axios.post('/api/auth/login', { username, password });
      localStorage.setItem('token', res.data.token);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed');
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', alignItems: 'center', 
      background: 'linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%)' }}>
      <Container maxWidth="sm">
        <Paper sx={{ p: 4 }}>
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <GameIcon sx={{ fontSize: 60, color: '#ff4d4d' }} />
            <Typography variant="h4">RW MLBB VPN</Typography>
          </Box>
          
          {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}
          
          <form onSubmit={handleSubmit}>
            <TextField fullWidth label="Username" margin="normal"
              value={username} onChange={(e) => setUsername(e.target.value)} required />
            <TextField fullWidth label="Password" type="password" margin="normal"
              value={password} onChange={(e) => setPassword(e.target.value)} required />
            <Button type="submit" fullWidth variant="contained" size="large" sx={{ mt: 3 }}>
              Login
            </Button>
          </form>
        </Paper>
      </Container>
    </Box>
  );
}

export default Login;
EOF

    # Build frontend
    npm run build
    
    echo -e "${GREEN}✅ Frontend created${NC}"
}

# ==================== FUNGSI SETUP NGINX ====================
setup_nginx() {
    echo -e "${YELLOW}[9/15] Mengkonfigurasi Nginx...${NC}"
    
    if [ "$USE_SSL" = false ]; then
        # IP-based configuration
        cat > /etc/nginx/sites-available/vpn-panel << EOF
server {
    listen 80;
    server_name _;
    
    location / {
        root /var/www/vpn-panel/frontend/build;
        try_files \$uri /index.html;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:${PANEL_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    else
        # Domain-based configuration
        cat > /etc/nginx/sites-available/vpn-panel << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
    location / {
        root /var/www/vpn-panel/frontend/build;
        try_files \$uri /index.html;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:${PANEL_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    fi

    ln -sf /etc/nginx/sites-available/vpn-panel /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t && systemctl reload nginx
    
    echo -e "${GREEN}✅ Nginx configured${NC}"
}

# ==================== FUNGSI SETUP SSL ====================
setup_ssl() {
    if [ "$USE_SSL" = true ]; then
        echo -e "${YELLOW}[10/15] Mengkonfigurasi SSL...${NC}"
        
        apt install -y certbot python3-certbot-nginx
        
        certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${EMAIL} || {
            echo -e "${YELLOW}⚠️ SSL setup failed, using HTTP${NC}"
        }
        
        echo -e "${GREEN}✅ SSL configured${NC}"
    fi
}

# ==================== FUNGSI SETUP SERVICES ====================
setup_services() {
    echo -e "${YELLOW}[11/15] Membuat systemd services...${NC}"
    
    cat > /etc/systemd/system/vpn-panel-backend.service << EOF
[Unit]
Description=RW MLBB VPN Panel
After=network.target mysql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/vpn-panel/backend
ExecStart=/usr/bin/node server.js
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable vpn-panel-backend
    systemctl start vpn-panel-backend
    
    echo -e "${GREEN}✅ Services created${NC}"
}

# ==================== FUNGSI SETUP DATABASE TABLES ====================
setup_database_tables() {
    echo -e "${YELLOW}[12/15] Membuat database tables...${NC}"
    
    cd /var/www/vpn-panel/backend
    
    node -e "
    const bcrypt = require('bcryptjs');
    const { Sequelize } = require('sequelize');
    const sequelize = new Sequelize('vpn_panel', 'vpn_user', '${DB_PASSWORD}', {
        host: 'localhost',
        dialect: 'mysql'
    });
    
    const User = sequelize.define('User', {
        username: { type: Sequelize.STRING, unique: true },
        password: Sequelize.STRING,
        email: Sequelize.STRING,
        role: { type: Sequelize.STRING, defaultValue: 'user' },
        balance: { type: Sequelize.DECIMAL(15, 2), defaultValue: 0 },
        status: { type: Sequelize.STRING, defaultValue: 'active' }
    });
    
    (async () => {
        await sequelize.sync();
        
        const [user, created] = await User.findOrCreate({
            where: { username: 'admin' },
            defaults: {
                username: 'admin',
                password: bcrypt.hashSync('admin123', 10),
                email: 'admin@${DOMAIN}',
                role: 'superadmin',
                balance: 1000000
            }
        });
        
        console.log(created ? 'Admin created' : 'Admin exists');
        process.exit();
    })();
    "
    
    echo -e "${GREEN}✅ Database tables created${NC}"
}

# ==================== FUNGSI CREATE NODE INSTALLER ====================
create_node_installer() {
    echo -e "${YELLOW}[13/15] Membuat node installer script...${NC}"
    
    cat > /var/www/vpn-panel/install-node.sh << 'EOF'
#!/bin/bash
set -e
echo "RW MLBB VPN Node Installer"

read -p "Panel URL (${DOMAIN_FULL}): " PANEL_URL
PANEL_URL=${PANEL_URL:-${DOMAIN_FULL}}

read -p "Node API Key (${NODE_API_KEY}): " NODE_API_KEY
NODE_API_KEY=${NODE_API_KEY:-${NODE_API_KEY}}

read -p "Node Name: " NODE_NAME
read -p "Location: " LOCATION
read -p "Country Code: " COUNTRY_CODE

apt update && apt install -y curl nodejs npm ufw
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 8081/tcp
ufw --force enable

mkdir -p /opt/vpn-node
cd /opt/vpn-node

cat > node-controller.js << 'NODEEOF'
const express = require('express');
const os = require('os');
const app = express();
app.use(express.json());

const API_KEY = process.env.NODE_API_KEY;

app.use((req, res, next) => {
    if (req.headers['x-api-key'] !== API_KEY) return res.status(401).json({ error: 'Unauthorized' });
    next();
});

app.get('/status', (req, res) => {
    res.json({ cpu: os.loadavg()[0], ram: ((os.totalmem() - os.freemem()) / os.totalmem()) * 100 });
});

app.listen(8081, () => console.log('Node controller running'));
NODEEOF

npm init -y
npm install express

cat > /etc/systemd/system/vpn-node.service << EOF
[Unit]
Description=VPN Node Controller
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/vpn-node
ExecStart=/usr/bin/node node-controller.js
Environment=NODE_API_KEY=${NODE_API_KEY}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vpn-node
systemctl start vpn-node

curl -X POST ${PANEL_URL}/api/servers \
    -H "Content-Type: application/json" \
    -H "X-API-Key: ${NODE_API_KEY}" \
    -d "{\"name\":\"${NODE_NAME}\",\"location\":\"${LOCATION}\",\"countryCode\":\"${COUNTRY_CODE}\",\"ip\":\"$(curl -s ifconfig.me)\",\"apiKey\":\"${NODE_API_KEY}\"}"

echo "Node installed successfully!"
EOF

    chmod +x /var/www/vpn-panel/install-node.sh
    echo -e "${GREEN}✅ Node installer created${NC}"
}

# ==================== FUNGSI SHOW SUMMARY ====================
show_summary() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         INSTALASI SELESAI! 🎉                              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "🔗 Panel URL      : ${CYAN}${DOMAIN_FULL}${NC}"
    echo -e "👤 Admin Login    : ${YELLOW}admin / admin123${NC}"
    echo -e "🌏 Lokasi Server  : ${YELLOW}${LOCATION} (${COUNTRY_CODE})${NC}"
    echo -e "📌 Webhook URL    : ${CYAN}${DOMAIN_FULL}/api/payment/webhook${NC}"
    echo -e "🔑 Node API Key   : ${YELLOW}${NODE_API_KEY}${NC}"
    echo ""
    echo -e "📲 Install node: curl -s ${DOMAIN_FULL}/install-node.sh | bash"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
}

# ==================== EKSEKUSI FUNGSI ====================
install_dependencies
install_xray
setup_firewall
setup_database
setup_redis
create_directories
create_backend
create_frontend
setup_nginx
setup_ssl
setup_services
setup_database_tables
create_node_installer
show_summary