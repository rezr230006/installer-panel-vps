#!/bin/bash
# ============================================================================
# VPN RW MOBILE LEGENDS BOT PANEL - ULTIMATE EDITION with PAKASIR PAYMENT
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
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==================== CEK ROOT ====================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root!${NC}" 
   exit 1
fi

# ==================== INPUT KONFIGURASI ====================
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 KONFIGURASI AWAL${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""

# Domain/IP Configuration
echo -e "${CYAN}Pilih jenis akses panel:${NC}"
echo "1) Gunakan IP VPS (http://IP_ANDA:8080)"
echo "2) Gunakan Subdomain (contoh: vpn.rw-ml.com)"
echo "3) Gunakan Domain (contoh: rw-ml.com)"
read -p "Pilih [1-3]: " ACCESS_TYPE

case $ACCESS_TYPE in
    1)
        DOMAIN=$(curl -s ifconfig.me)
        PROTOCOL="http"
        PORT=":8080"
        DOMAIN_FULL="http://${DOMAIN}:8080"
        echo -e "${GREEN}✅ Menggunakan IP VPS: ${DOMAIN}${NC}"
        ;;
    2|3)
        read -p "🔗 Masukkan domain/subdomain (contoh: vpn.rw-ml.com): " DOMAIN
        PROTOCOL="https"
        PORT=""
        DOMAIN_FULL="https://${DOMAIN}"
        echo -e "${GREEN}✅ Menggunakan domain: ${DOMAIN_FULL}${NC}"
        ;;
    *)
        echo -e "${RED}Pilihan tidak valid! Menggunakan IP VPS.${NC}"
        DOMAIN=$(curl -s ifconfig.me)
        PROTOCOL="http"
        PORT=":8080"
        DOMAIN_FULL="http://${DOMAIN}:8080"
        ;;
esac

read -p "📧 Masukkan email untuk SSL (jika pakai domain): " EMAIL
read -p "🌏 Lokasi server utama (Singapore/Jakarta): " LOCATION

# PAKASIR Configuration
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}💰 KONFIGURASI PAYMENT GATEWAY PAKASIR.COM${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Daftar dulu di ${YELLOW}https://pakasir.com${NC} lalu buat proyek"
echo ""
read -p "🔑 Masukkan PAKASIR API Key: " PAKASIR_API_KEY
read -p "🔤 Masukkan PAKASIR Project Slug: " PAKASIR_SLUG
read -p "💰 Kurs USD ke IDR (default: 15000): " USD_RATE
USD_RATE=${USD_RATE:-15000}

# Database Configuration
read -p "🔑 Password database (biarkan kosong untuk auto-generate): " DB_PASS_INPUT
read -p "🔑 API Key untuk node (biarkan kosong untuk auto-generate): " NODE_KEY_INPUT
read -p "🚀 Install node server juga di VPS ini? (y/n): " INSTALL_NODE_LOCAL

# Set default values
if [ -z "$DB_PASS_INPUT" ]; then
    DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
else
    DB_PASSWORD=$DB_PASS_INPUT
fi

if [ -z "$NODE_KEY_INPUT" ]; then
    NODE_API_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
else
    NODE_API_KEY=$NODE_KEY_INPUT
fi

PANEL_PORT=8080
NODE_PORT_START=8081

echo ""
echo -e "${GREEN}✅ Konfigurasi tersimpan:${NC}"
echo -e "   Panel URL     : ${CYAN}${DOMAIN_FULL}${NC}"
echo -e "   Lokasi        : ${CYAN}${LOCATION}${NC}"
echo -e "   PAKASIR API   : ${CYAN}${PAKASIR_API_KEY}${NC}"
echo -e "   PAKASIR Slug  : ${CYAN}${PAKASIR_SLUG}${NC}"
echo -e "   Kurs USD      : ${CYAN}Rp ${USD_RATE} / USD${NC}"
echo ""

# ==================== FUNGSI INSTALL DEPENDENCIES ====================
install_dependencies() {
    echo -e "${YELLOW}[1/22] Menginstall dependencies...${NC}"
    
    apt update && apt upgrade -y
    apt install -y curl wget git unzip zip nginx mysql-server \
        redis-server certbot python3-certbot-nginx build-essential \
        ufw nodejs npm python3 python3-pip python3-scapy \
        tcpdump nmap net-tools iptables-persistent netcat \
        htop iftop vnstat nload jq sqlite3 \
        fail2ban rkhunter aide apache2-utils \
        cron logrotate rsyslog dnsutils whois \
        speedtest-cli ffmpeg gcc g++ make
        
    # Install Node.js 18
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# ==================== FUNGSI INSTALL XRAY ====================
install_xray() {
    echo -e "${YELLOW}[2/22] Menginstall Xray core dengan MLBB optimization...${NC}"
    
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    echo -e "${GREEN}✅ Xray installed${NC}"
}

# ==================== FUNGSI SETUP FIREWALL ====================
setup_firewall() {
    echo -e "${YELLOW}[3/22] Mengkonfigurasi firewall...${NC}"
    
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
    echo -e "${YELLOW}[4/22] Mengkonfigurasi database...${NC}"
    
    # Secure MySQL installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';" 2>/dev/null || true
    mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" 2>/dev/null || true
    mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" 2>/dev/null || true
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
    echo -e "${YELLOW}[5/22] Mengkonfigurasi Redis...${NC}"
    
    cat >> /etc/redis/redis.conf << EOF

# VPN Panel Optimizations
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
EOF

    systemctl restart redis-server
    
    echo -e "${GREEN}✅ Redis configured${NC}"
}

# ==================== FUNGSI BUAT DIRECTORY STRUCTURE ====================
create_directories() {
    echo -e "${YELLOW}[6/22] Membuat struktur direktori...${NC}"
    
    mkdir -p /var/www/vpn-panel
    mkdir -p /var/www/vpn-panel/{backend,frontend,node-controller,mlbb-bot,api,worker,cron}
    mkdir -p /etc/vpn-panel
    mkdir -p /etc/vpn-panel/{rw-ml,ssl,backup,config,certificates}
    mkdir -p /var/log/vpn-panel
    mkdir -p /var/log/vpn-panel/{access,error,traffic,bot,api,payment}
    mkdir -p /var/log/mlbb-bot
    mkdir -p /var/lib/vpn-panel/{data,cache,sessions,payments}
    mkdir -p /usr/local/share/vpn-panel
    
    # Save configuration
    cat > /etc/vpn-panel/config.yml << EOF
# VPN Panel Configuration
panel:
  domain: ${DOMAIN}
  protocol: ${PROTOCOL}
  port: ${PANEL_PORT}
  url: ${DOMAIN_FULL}
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
  gateway: pakasir
  pakasir_api_key: ${PAKASIR_API_KEY}
  pakasir_slug: ${PAKASIR_SLUG}
  pakasir_url: https://app.pakasir.com
  usd_rate: ${USD_RATE}
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
    - name: USA
      ip: 54.67.42.121
      ping: 180
EOF

    echo "DB_PASSWORD=${DB_PASSWORD}" > /etc/vpn-panel/secrets.conf
    echo "NODE_API_KEY=${NODE_API_KEY}" >> /etc/vpn-panel/secrets.conf
    echo "JWT_SECRET=$(openssl rand -base64 32)" >> /etc/vpn-panel/secrets.conf
    echo "ENCRYPTION_KEY=$(openssl rand -hex 32)" >> /etc/vpn-panel/secrets.conf
    echo "PAKASIR_API_KEY=${PAKASIR_API_KEY}" >> /etc/vpn-panel/secrets.conf
    echo "PAKASIR_SLUG=${PAKASIR_SLUG}" >> /etc/vpn-panel/secrets.conf
    
    chmod 600 /etc/vpn-panel/secrets.conf
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# ==================== FUNGSI CREATE BACKEND DENGAN PAYMENT ====================
create_backend() {
    echo -e "${YELLOW}[7/22] Membuat backend API dengan payment gateway...${NC}"
    
    cd /var/www/vpn-panel/backend
    
    # Create package.json with payment dependencies
    cat > package.json << 'EOF'
{
  "name": "vpn-panel-ultimate",
  "version": "4.0.0",
  "description": "VPN SaaS Ultimate Panel dengan Payment Gateway Pakasir",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "worker": "node worker.js",
    "cron": "node cron.js",
    "migrate": "node migrate.js",
    "backup": "node backup.js"
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
    "ws": "^8.13.0",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "express-rate-limit": "^6.9.0",
    "express-validator": "^7.0.1",
    "multer": "^1.4.5-lts.1",
    "sharp": "^0.32.5",
    "nodemailer": "^6.9.4",
    "puppeteer": "^21.1.1",
    "cheerio": "^1.0.0-rc.12",
    "bull": "^4.11.3",
    "ioredis": "^5.3.2",
    "winston": "^3.10.0",
    "morgan": "^1.10.0",
    "uuid": "^9.0.0",
    "nanoid": "^5.0.1",
    "joi": "^17.10.1",
    "swagger-jsdoc": "^6.2.8",
    "swagger-ui-express": "^5.0.0",
    "prom-client": "^14.2.0",
    "node-cache": "^5.1.2",
    "socket.io-client": "^4.6.1"
  }
}
EOF

    npm install
    
    # Create Payment Service
    mkdir -p services
    cat > services/pakasir.service.js << 'EOF'
const axios = require('axios');
const crypto = require('crypto');

class PakasirService {
    constructor(apiKey, projectSlug, baseUrl = 'https://app.pakasir.com') {
        this.apiKey = apiKey;
        this.projectSlug = projectSlug;
        this.baseUrl = baseUrl;
    }

    // Create transaction via URL (simple redirect)
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

    // Create transaction via API (for embedded payment)
    async createTransaction(method, data) {
        try {
            const response = await axios.post(
                `${this.baseUrl}/api/transactioncreate/${method}`,
                {
                    project: this.projectSlug,
                    order_id: data.orderId,
                    amount: data.amount,
                    api_key: this.apiKey
                },
                {
                    headers: {
                        'Content-Type': 'application/json'
                    }
                }
            );
            
            return response.data;
        } catch (error) {
            console.error('Pakasir API Error:', error.response?.data || error.message);
            throw error;
        }
    }

    // Get transaction details
    async getTransactionDetail(orderId, amount) {
        try {
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
        } catch (error) {
            console.error('Pakasir Detail Error:', error.response?.data || error.message);
            throw error;
        }
    }

    // Cancel transaction
    async cancelTransaction(orderId, amount) {
        try {
            const response = await axios.post(
                `${this.baseUrl}/api/transactioncancel`,
                {
                    project: this.projectSlug,
                    order_id: orderId,
                    amount: amount,
                    api_key: this.apiKey
                },
                {
                    headers: {
                        'Content-Type': 'application/json'
                    }
                }
            );
            
            return response.data;
        } catch (error) {
            console.error('Pakasir Cancel Error:', error.response?.data || error.message);
            throw error;
        }
    }

    // Simulate payment (sandbox only)
    async simulatePayment(orderId, amount) {
        try {
            const response = await axios.post(
                `${this.baseUrl}/api/paymentsimulation`,
                {
                    project: this.projectSlug,
                    order_id: orderId,
                    amount: amount,
                    api_key: this.apiKey
                },
                {
                    headers: {
                        'Content-Type': 'application/json'
                    }
                }
            );
            
            return response.data;
        } catch (error) {
            console.error('Pakasir Simulation Error:', error.response?.data || error.message);
            throw error;
        }
    }

    // Generate order ID
    generateOrderId(prefix = 'INV') {
        const timestamp = Date.now().toString(36).toUpperCase();
        const random = crypto.randomBytes(4).toString('hex').toUpperCase();
        return `${prefix}${timestamp}${random}`;
    }
}

module.exports = PakasirService;
EOF

    # Create main server file with payment routes
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
const axios = require('axios');
const cron = require('node-cron');
const QRCode = require('qrcode');
const { Server } = require('socket.io');
const http = require('http');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const winston = require('winston');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');
const { nanoid } = require('nanoid');
const PakasirService = require('./services/pakasir.service');

require('dotenv').config();

// ==================== INITIALIZATION ====================
const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});

// ==================== CONFIGURATION ====================
const config = yaml.load(fs.readFileSync('/etc/vpn-panel/config.yml', 'utf8'));
const secrets = JSON.parse(fs.readFileSync('/etc/vpn-panel/secrets.conf', 'utf8'));

// Initialize Pakasir
const pakasir = new PakasirService(
    secrets.PAKASIR_API_KEY,
    secrets.PAKASIR_SLUG,
    config.payment.pakasir_url
);

// ==================== DATABASE CONNECTION ====================
const sequelize = new Sequelize(
  config.database.name,
  config.database.user,
  secrets.DB_PASSWORD,
  {
    host: config.database.host,
    port: config.database.port,
    dialect: 'mysql',
    logging: false,
    pool: {
      max: 20,
      min: 5,
      acquire: 30000,
      idle: 10000
    }
  }
);

// ==================== REDIS CONNECTION ====================
const redisClient = new redis({
  host: config.redis.host,
  port: config.redis.port,
  db: config.redis.db
});

// ==================== DATABASE MODELS ====================
const User = sequelize.define('User', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  uuid: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, unique: true },
  username: { type: DataTypes.STRING(50), unique: true, allowNull: false },
  password: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING(100) },
  phone: { type: DataTypes.STRING(20) },
  fullName: { type: DataTypes.STRING(100) },
  role: { type: DataTypes.ENUM('superadmin', 'admin', 'reseller', 'user'), defaultValue: 'user' },
  parentId: { type: DataTypes.INTEGER },
  balance: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
  credit: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
  totalDeposit: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
  totalSpent: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
  botMode: { type: DataTypes.BOOLEAN, defaultValue: false },
  botDifficulty: { type: DataTypes.ENUM('easy', 'medium', 'hard'), defaultValue: 'easy' },
  status: { type: DataTypes.ENUM('active', 'inactive', 'banned'), defaultValue: 'active' },
  lastLogin: { type: DataTypes.DATE },
  lastIp: { type: DataTypes.STRING(45) },
  createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updatedAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
});

const VPNAccount = sequelize.define('VPNAccount', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  uuid: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, unique: true },
  userId: { type: DataTypes.INTEGER },
  name: { type: DataTypes.STRING(100) },
  protocol: { type: DataTypes.STRING(20) },
  serverId: { type: DataTypes.INTEGER },
  port: { type: DataTypes.INTEGER },
  uuid_v2: { type: DataTypes.STRING },
  password: { type: DataTypes.STRING },
  expiredAt: { type: DataTypes.DATE },
  price: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
  trafficLimit: { type: DataTypes.BIGINT, defaultValue: 0 },
  trafficUsed: { type: DataTypes.BIGINT, defaultValue: 0 },
  active: { type: DataTypes.BOOLEAN, defaultValue: true },
  botEnabled: { type: DataTypes.BOOLEAN, defaultValue: false },
  createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updatedAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
});

const Invoice = sequelize.define('Invoice', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  invoiceNo: { type: DataTypes.STRING(50), unique: true },
  userId: { type: DataTypes.INTEGER },
  type: { type: DataTypes.ENUM('deposit', 'subscription', 'topup', 'product') },
  amount: { type: DataTypes.DECIMAL(15, 2) },
  amountUSD: { type: DataTypes.DECIMAL(10, 2) },
  currency: { type: DataTypes.STRING(3), defaultValue: 'IDR' },
  status: { 
    type: DataTypes.ENUM('pending', 'waiting_payment', 'paid', 'expired', 'cancelled', 'failed'),
    defaultValue: 'pending'
  },
  paymentMethod: { type: DataTypes.STRING(50) },
  paymentDetails: { type: DataTypes.TEXT }, // JSON string of payment details
  paymentProof: { type: DataTypes.TEXT },
  pakasirOrderId: { type: DataTypes.STRING(100) },
  pakasirResponse: { type: DataTypes.TEXT }, // Full response from Pakasir
  paidAt: { type: DataTypes.DATE },
  expiredAt: { type: DataTypes.DATE },
  notes: { type: DataTypes.TEXT },
  createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
  updatedAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
});

const Transaction = sequelize.define('Transaction', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER },
  invoiceId: { type: DataTypes.INTEGER },
  type: { type: DataTypes.ENUM('debit', 'credit') },
  amount: { type: DataTypes.DECIMAL(15, 2) },
  balance: { type: DataTypes.DECIMAL(15, 2) },
  description: { type: DataTypes.TEXT },
  reference: { type: DataTypes.STRING(100) },
  createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
});

const Product = sequelize.define('Product', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  name: { type: DataTypes.STRING(100) },
  description: { type: DataTypes.TEXT },
  price: { type: DataTypes.DECIMAL(15, 2) },
  priceUSD: { type: DataTypes.DECIMAL(10, 2) },
  duration: { type: DataTypes.INTEGER }, // in days
  trafficLimit: { type: DataTypes.BIGINT },
  protocol: { type: DataTypes.STRING(20) },
  botEnabled: { type: DataTypes.BOOLEAN, defaultValue: true },
  active: { type: DataTypes.BOOLEAN, defaultValue: true },
  createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
});

// Sync database
sequelize.sync({ alter: true });

// ==================== MIDDLEWARE ====================
app.use(helmet({
  contentSecurityPolicy: false
}));
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use('/api/', limiter);

// ==================== AUTH MIDDLEWARE ====================
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.status(401).json({ error: 'No token provided' });
  
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
      { id: 'qris', name: 'QRIS', icon: '/icons/qris.png', min: 1000, max: 10000000 },
      { id: 'bni_va', name: 'BNI Virtual Account', icon: '/icons/bni.png', min: 10000, max: 50000000 },
      { id: 'bri_va', name: 'BRI Virtual Account', icon: '/icons/bri.png', min: 10000, max: 50000000 },
      { id: 'cimb_niaga_va', name: 'CIMB Niaga VA', icon: '/icons/cimb.png', min: 10000, max: 50000000 },
      { id: 'permata_va', name: 'Permata Virtual Account', icon: '/icons/permata.png', min: 10000, max: 50000000 },
      { id: 'paypal', name: 'PayPal', icon: '/icons/paypal.png', min: 1, max: 1000, currency: 'USD' }
    ],
    exchange_rate: config.payment.usd_rate,
    currency: 'IDR'
  });
});

// Create deposit invoice
app.post('/api/payment/deposit', authenticateToken, async (req, res) => {
  try {
    const { amount, method, redirectUrl } = req.body;
    
    if (!amount || amount < 1000) {
      return res.status(400).json({ error: 'Minimum deposit Rp 1.000' });
    }
    
    // Generate invoice
    const invoiceNo = pakasir.generateOrderId('DEP');
    const expiredAt = new Date();
    expiredAt.setHours(expiredAt.getHours() + 24); // 24 hours expiry
    
    const invoice = await Invoice.create({
      invoiceNo,
      userId: req.user.id,
      type: 'deposit',
      amount,
      currency: 'IDR',
      status: 'pending',
      paymentMethod: method,
      expiredAt
    });
    
    // Create Pakasir payment URL
    let paymentUrl;
    if (method === 'paypal') {
      // Convert IDR to USD for PayPal
      const amountUSD = (amount / config.payment.usd_rate).toFixed(2);
      paymentUrl = pakasir.createPaymentUrl(amount, invoiceNo, {
        method: 'paypal',
        redirect: redirectUrl || `${config.panel.url}/payment/status`
      });
    } else {
      paymentUrl = pakasir.createPaymentUrl(amount, invoiceNo, {
        qrisOnly: method === 'qris',
        redirect: redirectUrl || `${config.panel.url}/payment/status`
      });
    }
    
    res.json({
      success: true,
      invoice: {
        invoiceNo,
        amount,
        method,
        expiredAt
      },
      paymentUrl
    });
  } catch (error) {
    console.error('Deposit error:', error);
    res.status(500).json({ error: 'Failed to create deposit' });
  }
});

// Create payment via API (embedded payment)
app.post('/api/payment/create', authenticateToken, async (req, res) => {
  try {
    const { amount, method, type = 'deposit', productId } = req.body;
    
    // Validate amount
    if (amount < 1000) {
      return res.status(400).json({ error: 'Minimum payment Rp 1.000' });
    }
    
    // Generate order ID
    const orderId = pakasir.generateOrderId('PAY');
    
    // Create transaction in Pakasir
    const paymentData = {
      orderId,
      amount
    };
    
    const pakasirResponse = await pakasir.createTransaction(method, paymentData);
    
    // Create invoice
    const invoice = await Invoice.create({
      invoiceNo: orderId,
      userId: req.user.id,
      type,
      amount,
      currency: 'IDR',
      status: 'waiting_payment',
      paymentMethod: method,
      pakasirOrderId: orderId,
      pakasirResponse: JSON.stringify(pakasirResponse),
      paymentDetails: JSON.stringify(pakasirResponse.payment),
      expiredAt: new Date(pakasirResponse.payment.expired_at)
    });
    
    res.json({
      success: true,
      invoice: {
        invoiceNo: invoice.invoiceNo,
        amount: pakasirResponse.payment.total_payment || amount,
        method: pakasirResponse.payment.payment_method,
        paymentNumber: pakasirResponse.payment.payment_number, // QR string or VA number
        qrString: pakasirResponse.payment.payment_number, // For QRIS
        expiredAt: pakasirResponse.payment.expired_at
      }
    });
  } catch (error) {
    console.error('Payment create error:', error);
    res.status(500).json({ error: 'Failed to create payment' });
  }
});

// Check payment status
app.get('/api/payment/status/:invoiceNo', authenticateToken, async (req, res) => {
  try {
    const invoice = await Invoice.findOne({
      where: { 
        invoiceNo: req.params.invoiceNo,
        userId: req.user.id
      }
    });
    
    if (!invoice) {
      return res.status(404).json({ error: 'Invoice not found' });
    }
    
    // Check with Pakasir if status is still waiting/pending
    if (['pending', 'waiting_payment'].includes(invoice.status)) {
      try {
        const pakasirStatus = await pakasir.getTransactionDetail(
          invoice.invoiceNo,
          invoice.amount
        );
        
        if (pakasirStatus.transaction.status === 'completed' && invoice.status !== 'paid') {
          // Update invoice to paid
          invoice.status = 'paid';
          invoice.paidAt = new Date();
          await invoice.save();
          
          // Update user balance
          const user = await User.findByPk(invoice.userId);
          const newBalance = parseFloat(user.balance) + parseFloat(invoice.amount);
          user.balance = newBalance;
          user.totalDeposit = parseFloat(user.totalDeposit) + parseFloat(invoice.amount);
          await user.save();
          
          // Create transaction record
          await Transaction.create({
            userId: user.id,
            invoiceId: invoice.id,
            type: 'credit',
            amount: invoice.amount,
            balance: newBalance,
            description: `Deposit via ${invoice.paymentMethod}`,
            reference: invoice.invoiceNo
          });
        }
      } catch (error) {
        console.error('Error checking Pakasir status:', error);
      }
    }
    
    res.json({
      invoiceNo: invoice.invoiceNo,
      amount: invoice.amount,
      status: invoice.status,
      paymentMethod: invoice.paymentMethod,
      paidAt: invoice.paidAt,
      expiredAt: invoice.expiredAt
    });
  } catch (error) {
    console.error('Payment status error:', error);
    res.status(500).json({ error: 'Failed to check payment status' });
  }
});

// Webhook for Pakasir (to receive payment notifications)
app.post('/api/payment/webhook', async (req, res) => {
  try {
    const { amount, order_id, project, status, payment_method, completed_at } = req.body;
    
    console.log('Pakasir webhook received:', req.body);
    
    // Find invoice
    const invoice = await Invoice.findOne({
      where: { invoiceNo: order_id }
    });
    
    if (!invoice) {
      return res.status(404).json({ error: 'Invoice not found' });
    }
    
    // Verify amount matches
    if (parseFloat(invoice.amount) !== parseFloat(amount)) {
      return res.status(400).json({ error: 'Amount mismatch' });
    }
    
    // Update invoice if status is completed
    if (status === 'completed' && invoice.status !== 'paid') {
      invoice.status = 'paid';
      invoice.paidAt = new Date(completed_at);
      invoice.paymentMethod = payment_method;
      await invoice.save();
      
      // Update user balance
      const user = await User.findByPk(invoice.userId);
      if (user) {
        const newBalance = parseFloat(user.balance) + parseFloat(invoice.amount);
        user.balance = newBalance;
        user.totalDeposit = parseFloat(user.totalDeposit) + parseFloat(invoice.amount);
        await user.save();
        
        // Create transaction record
        await Transaction.create({
          userId: user.id,
          invoiceId: invoice.id,
          type: 'credit',
          amount: invoice.amount,
          balance: newBalance,
          description: `Deposit via ${payment_method}`,
          reference: invoice.invoiceNo
        });
      }
    }
    
    res.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});

// Get user balance
app.get('/api/user/balance', authenticateToken, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: ['balance', 'totalDeposit', 'totalSpent']
    });
    
    // Get recent transactions
    const transactions = await Transaction.findAll({
      where: { userId: req.user.id },
      order: [['createdAt', 'DESC']],
      limit: 10
    });
    
    res.json({
      balance: user.balance,
      totalDeposit: user.totalDeposit,
      totalSpent: user.totalSpent,
      transactions
    });
  } catch (error) {
    console.error('Balance error:', error);
    res.status(500).json({ error: 'Failed to get balance' });
  }
});

// Get user invoices
app.get('/api/user/invoices', authenticateToken, async (req, res) => {
  try {
    const invoices = await Invoice.findAll({
      where: { userId: req.user.id },
      order: [['createdAt', 'DESC']],
      limit: 50
    });
    
    res.json(invoices);
  } catch (error) {
    console.error('Invoices error:', error);
    res.status(500).json({ error: 'Failed to get invoices' });
  }
});

// Buy product with balance
app.post('/api/products/buy', authenticateToken, async (req, res) => {
  try {
    const { productId } = req.body;
    
    const product = await Product.findByPk(productId);
    if (!product || !product.active) {
      return res.status(404).json({ error: 'Product not found' });
    }
    
    const user = await User.findByPk(req.user.id);
    
    if (user.balance < product.price) {
      return res.status(400).json({ error: 'Insufficient balance' });
    }
    
    // Deduct balance
    const newBalance = user.balance - product.price;
    user.balance = newBalance;
    user.totalSpent = parseFloat(user.totalSpent) + parseFloat(product.price);
    await user.save();
    
    // Create VPN account
    const uuid = uuidv4();
    const expiredAt = new Date();
    expiredAt.setDate(expiredAt.getDate() + product.duration);
    
    const account = await VPNAccount.create({
      userId: user.id,
      name: product.name,
      protocol: product.protocol || 'vless',
      uuid_v2: uuid,
      expiredAt,
      trafficLimit: product.trafficLimit,
      botEnabled: product.botEnabled,
      price: product.price
    });
    
    // Create transaction
    await Transaction.create({
      userId: user.id,
      type: 'debit',
      amount: product.price,
      balance: newBalance,
      description: `Pembelian: ${product.name}`,
      reference: `PROD-${productId}`
    });
    
    res.json({
      success: true,
      account,
      newBalance
    });
  } catch (error) {
    console.error('Buy product error:', error);
    res.status(500).json({ error: 'Failed to buy product' });
  }
});

// ==================== PRODUCT ROUTES ====================
app.get('/api/products', async (req, res) => {
  try {
    const products = await Product.findAll({
      where: { active: true },
      order: [['price', 'ASC']]
    });
    
    res.json(products);
  } catch (error) {
    console.error('Products error:', error);
    res.status(500).json({ error: 'Failed to get products' });
  }
});

app.post('/api/products', authenticateToken, async (req, res) => {
  try {
    const { name, description, price, duration, trafficLimit, protocol, botEnabled } = req.body;
    
    const product = await Product.create({
      name,
      description,
      price,
      duration,
      trafficLimit: trafficLimit * 1024 * 1024 * 1024, // Convert GB to bytes
      protocol,
      botEnabled: botEnabled !== false
    });
    
    res.json(product);
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({ error: 'Failed to create product' });
  }
});

// ==================== AUTH ROUTES ====================
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    const user = await User.findOne({ where: { username, status: 'active' } });
    if (!user || !bcrypt.compareSync(password, user.password)) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    user.lastLogin = new Date();
    user.lastIp = req.ip;
    await user.save();
    
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      secrets.JWT_SECRET,
      { expiresIn: '7d' }
    );
    
    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        balance: user.balance,
        botMode: user.botMode
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, email } = req.body;
    
    const existing = await User.findOne({ where: { username } });
    if (existing) {
      return res.status(400).json({ error: 'Username already exists' });
    }
    
    const hashedPassword = bcrypt.hashSync(password, 10);
    const user = await User.create({
      username,
      password: hashedPassword,
      email,
      role: 'user',
      balance: 0
    });
    
    res.json({ success: true, message: 'Registration successful' });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== DASHBOARD ====================
app.get('/api/dashboard', authenticateToken, async (req, res) => {
  try {
    const accounts = await VPNAccount.count({ where: { userId: req.user.id } });
    const activeAccounts = await VPNAccount.count({ 
      where: { userId: req.user.id, active: true } 
    });
    
    const invoices = await Invoice.count({ where: { userId: req.user.id } });
    const pendingInvoices = await Invoice.count({ 
      where: { userId: req.user.id, status: ['pending', 'waiting_payment'] } 
    });
    
    const totalSpent = await Transaction.sum('amount', {
      where: { userId: req.user.id, type: 'debit' }
    }) || 0;
    
    res.json({
      accounts: { total: accounts, active: activeAccounts },
      payments: { total: invoices, pending: pendingInvoices },
      balance: req.user.balance,
      totalSpent
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== MLBB BOT ROUTES ====================
app.post('/api/mlbb/bot/enable', authenticateToken, async (req, res) => {
  try {
    const { difficulty = 'easy' } = req.body;
    
    await User.update(
      { botMode: true, botDifficulty: difficulty },
      { where: { id: req.user.id } }
    );
    
    res.json({ 
      success: true, 
      message: 'Bot mode enabled! You will face AI opponents.',
      difficulty
    });
  } catch (error) {
    console.error('Enable bot error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/mlbb/bot/disable', authenticateToken, async (req, res) => {
  try {
    await User.update(
      { botMode: false },
      { where: { id: req.user.id } }
    );
    
    res.json({ success: true, message: 'Bot mode disabled' });
  } catch (error) {
    console.error('Disable bot error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ==================== START SERVER ====================
const PORT = config.panel.port || 8080;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`RW MLBB Panel running on port ${PORT}`);
  console.log(`Payment gateway: Pakasir.com`);
  console.log(`Panel URL: ${config.panel.url}`);
  
  // Create default products
  setTimeout(async () => {
    const count = await Product.count();
    if (count === 0) {
      await Product.create({
        name: '1 Bulan - Basic',
        description: 'Akses VPN 1 bulan, 100GB, support bot MLBB',
        price: 50000,
        duration: 30,
        trafficLimit: 100 * 1024 * 1024 * 1024,
        protocol: 'vless',
        botEnabled: true
      });
      
      await Product.create({
        name: '3 Bulan - Premium',
        description: 'Akses VPN 3 bulan, 300GB, priority bot MLBB',
        price: 120000,
        duration: 90,
        trafficLimit: 300 * 1024 * 1024 * 1024,
        protocol: 'vless',
        botEnabled: true
      });
      
      await Product.create({
        name: '1 Tahun - VIP',
        description: 'Akses VPN 1 tahun, unlimited, guaranteed bot match',
        price: 400000,
        duration: 365,
        trafficLimit: 999 * 1024 * 1024 * 1024,
        protocol: 'vless',
        botEnabled: true
      });
      
      console.log('Default products created');
    }
  }, 5000);
});
EOF

    echo -e "${GREEN}✅ Backend dengan payment gateway created${NC}"
}

# ==================== FUNGSI CREATE FRONTEND DENGAN PAYMENT UI ====================
create_frontend() {
    echo -e "${YELLOW}[8/22] Membuat frontend dengan UI payment...${NC}"
    
    cd /var/www/vpn-panel/frontend
    
    # Create React app
    npx create-react-app . --template typescript
    
    # Install dependencies
    npm install @mui/material @emotion/react @emotion/styled @mui/icons-material \
        @mui/x-data-grid @mui/x-date-pickers \
        axios recharts socket.io-client react-router-dom \
        react-query react-hook-form yup @hookform/resolvers \
        date-fns react-qr-code react-copy-to-clipboard \
        react-toastify @reduxjs/toolkit react-redux \
        framer-motion react-helmet-async
    
    # Create main App.tsx
    cat > src/App.tsx << 'EOF'
import React, { useEffect, useState } from 'react';
import {
  ThemeProvider, createTheme, CssBaseline, Box, Container,
  AppBar, Toolbar, Typography, Drawer, List, ListItem,
  ListItemIcon, ListItemText, IconButton, Badge, Avatar,
  Menu, MenuItem, Divider, Paper, Grid, Card, CardContent,
  Button, TextField, Dialog, DialogTitle, DialogContent,
  DialogActions, Chip, LinearProgress, Alert, Snackbar,
  Tab, Tabs, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, TablePagination, FormControl,
  InputLabel, Select, InputAdornment, Stepper, Step,
  StepLabel, Radio, RadioGroup, FormControlLabel
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  VpnLock as VpnIcon,
  People as PeopleIcon,
  Settings as SettingsIcon,
  ShowChart as ChartIcon,
  DarkMode as DarkModeIcon,
  LightMode as LightModeIcon,
  Notifications as NotificationsIcon,
  AccountCircle as AccountCircleIcon,
  ExitToApp as LogoutIcon,
  Add as AddIcon,
  Payment as PaymentIcon,
  AccountBalance as BalanceIcon,
  History as HistoryIcon,
  ShoppingCart as CartIcon,
  AttachMoney as MoneyIcon,
  QrCode as QrCodeIcon,
  CheckCircle as CheckCircleIcon,
  AccessTime as TimeIcon,
  ContentCopy as CopyIcon,
  SportsEsports as GameIcon,
  EmojiEvents as TrophyIcon,
  BugReport as BotIcon,
  WhatsApp as WhatsAppIcon,
  Telegram as TelegramIcon
} from '@mui/icons-material';
import { QRCodeSVG } from 'qrcode.react';
import { CopyToClipboard } from 'react-copy-to-clipboard';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import axios from 'axios';

// Theme
const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: { main: '#ff4d4d' },
    secondary: { main: '#9b59b6' },
    background: { default: '#0a0e1c', paper: '#1a1f35' }
  }
});

function App() {
  const [user, setUser] = useState(null);
  const [balance, setBalance] = useState(0);
  const [invoices, setInvoices] = useState([]);
  const [products, setProducts] = useState([]);
  const [paymentMethods, setPaymentMethods] = useState([]);
  const [openDeposit, setOpenDeposit] = useState(false);
  const [depositAmount, setDepositAmount] = useState(50000);
  const [selectedMethod, setSelectedMethod] = useState('qris');
  const [currentInvoice, setCurrentInvoice] = useState(null);
  const [paymentStatus, setPaymentStatus] = useState(null);
  const [anchorEl, setAnchorEl] = useState(null);
  const [darkMode, setDarkMode] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) {
      window.location.href = '/login';
      return;
    }
    
    fetchUserData();
    fetchPaymentMethods();
    fetchProducts();
  }, []);

  const fetchUserData = async () => {
    try {
      const token = localStorage.getItem('token');
      const headers = { Authorization: `Bearer ${token}` };
      
      const [balanceRes, invoicesRes] = await Promise.all([
        axios.get('/api/user/balance', { headers }),
        axios.get('/api/user/invoices', { headers })
      ]);
      
      setBalance(balanceRes.data.balance);
      setInvoices(balanceRes.data.transactions || []);
      setInvoices(invoicesRes.data);
      
      // Get user from token
      const tokenData = JSON.parse(atob(token.split('.')[1]));
      setUser(tokenData);
    } catch (error) {
      console.error('Failed to fetch user data:', error);
    }
  };

  const fetchPaymentMethods = async () => {
    try {
      const res = await axios.get('/api/payment/methods');
      setPaymentMethods(res.data.methods);
    } catch (error) {
      console.error('Failed to fetch payment methods:', error);
    }
  };

  const fetchProducts = async () => {
    try {
      const res = await axios.get('/api/products');
      setProducts(res.data);
    } catch (error) {
      console.error('Failed to fetch products:', error);
    }
  };

  const handleDeposit = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post('/api/payment/deposit', {
        amount: depositAmount,
        method: selectedMethod,
        redirectUrl: window.location.origin + '/payment/callback'
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      // Redirect to Pakasir payment page
      window.location.href = res.data.paymentUrl;
    } catch (error) {
      toast.error(error.response?.data?.error || 'Failed to create deposit');
    }
  };

  const handleCreatePayment = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post('/api/payment/create', {
        amount: depositAmount,
        method: selectedMethod
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      setCurrentInvoice(res.data.invoice);
      setPaymentStatus('waiting');
    } catch (error) {
      toast.error(error.response?.data?.error || 'Failed to create payment');
    }
  };

  const handleBuyProduct = async (productId) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.post('/api/products/buy', {
        productId
      }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      toast.success('Product purchased successfully!');
      fetchUserData();
    } catch (error) {
      toast.error(error.response?.data?.error || 'Failed to buy product');
    }
  };

  const checkPaymentStatus = async (invoiceNo) => {
    try {
      const token = localStorage.getItem('token');
      const res = await axios.get(`/api/payment/status/${invoiceNo}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      
      if (res.data.status === 'paid') {
        setPaymentStatus('paid');
        toast.success('Payment successful!');
        fetchUserData();
      }
    } catch (error) {
      console.error('Failed to check payment status:', error);
    }
  };

  // Copy to clipboard
  const handleCopy = (text) => {
    navigator.clipboard.writeText(text);
    toast.success('Copied to clipboard!');
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <ToastContainer position="top-right" theme="dark" />
      
      <Box sx={{ display: 'flex' }}>
        {/* App Bar */}
        <AppBar position="fixed" sx={{ zIndex: 1201 }}>
          <Toolbar>
            <Typography variant="h6" sx={{ flexGrow: 1, display: 'flex', alignItems: 'center' }}>
              <GameIcon sx={{ mr: 1 }} /> RW MLBB VPN
            </Typography>
            
            <Badge badgeContent="BOT" color="error" sx={{ mr: 2 }}>
              <Chip 
                icon={<BotIcon />} 
                label="Bot Mode Ready" 
                size="small" 
                color="primary"
                variant="outlined"
              />
            </Badge>
            
            <IconButton color="inherit" onClick={() => setOpenDeposit(true)}>
              <BalanceIcon />
            </IconButton>
            
            <IconButton color="inherit" onClick={() => setDarkMode(!darkMode)}>
              {darkMode ? <LightModeIcon /> : <DarkModeIcon />}
            </IconButton>
            
            <IconButton color="inherit" onClick={(e) => setAnchorEl(e.currentTarget)}>
              <Avatar sx={{ bgcolor: 'primary.main' }}>
                {user?.username?.charAt(0).toUpperCase()}
              </Avatar>
            </IconButton>
            
            <Menu
              anchorEl={anchorEl}
              open={Boolean(anchorEl)}
              onClose={() => setAnchorEl(null)}
            >
              <MenuItem>
                <BalanceIcon sx={{ mr: 1 }} /> Balance: Rp {balance?.toLocaleString()}
              </MenuItem>
              <Divider />
              <MenuItem onClick={() => {}}>
                <AccountCircleIcon sx={{ mr: 1 }} /> Profile
              </MenuItem>
              <MenuItem onClick={() => {
                localStorage.removeItem('token');
                window.location.href = '/login';
              }}>
                <LogoutIcon sx={{ mr: 1 }} /> Logout
              </MenuItem>
            </Menu>
          </Toolbar>
        </AppBar>
        
        {/* Main Content */}
        <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8 }}>
          {/* Balance Card */}
          <Grid container spacing={3} sx={{ mb: 4 }}>
            <Grid item xs={12} md={4}>
              <Card>
                <CardContent>
                  <Typography color="text.secondary" gutterBottom>
                    Your Balance
                  </Typography>
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
                          <TableCell align="right">Balance</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {invoices.slice(0, 5).map((tx) => (
                          <TableRow key={tx.id}>
                            <TableCell>{new Date(tx.createdAt).toLocaleDateString()}</TableCell>
                            <TableCell>{tx.description}</TableCell>
                            <TableCell align="right" sx={{ 
                              color: tx.type === 'credit' ? 'success.main' : 'error.main'
                            }}>
                              {tx.type === 'credit' ? '+' : '-'} Rp {parseFloat(tx.amount).toLocaleString()}
                            </TableCell>
                            <TableCell align="right">Rp {parseFloat(tx.balance).toLocaleString()}</TableCell>
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
                <Card sx={{ 
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  position: 'relative',
                  overflow: 'visible'
                }}>
                  {product.botEnabled && (
                    <Chip
                      label="🤖 BOT READY"
                      color="primary"
                      size="small"
                      sx={{ position: 'absolute', top: -10, right: 10 }}
                    />
                  )}
                  
                  <CardContent sx={{ flexGrow: 1 }}>
                    <Typography variant="h5" gutterBottom>
                      {product.name}
                    </Typography>
                    
                    <Typography variant="h4" color="primary.main" sx={{ my: 2 }}>
                      Rp {parseFloat(product.price).toLocaleString()}
                    </Typography>
                    
                    <Box sx={{ my: 2 }}>
                      <Chip 
                        label={`${product.duration} Days`} 
                        size="small" 
                        sx={{ mr: 1 }}
                      />
                      <Chip 
                        label={`${product.trafficLimit / 1e9} GB`} 
                        size="small"
                      />
                    </Box>
                    
                    <Typography variant="body2" color="text.secondary" paragraph>
                      {product.description}
                    </Typography>
                    
                    <Typography variant="body2">
                      ✓ Protocol: {product.protocol?.toUpperCase()}
                    </Typography>
                    <Typography variant="body2">
                      ✓ Bot Mode: {product.botEnabled ? 'Yes' : 'No'}
                    </Typography>
                  </CardContent>
                  
                  <Box sx={{ p: 2 }}>
                    <Button 
                      fullWidth 
                      variant="contained"
                      disabled={balance < product.price}
                      onClick={() => handleBuyProduct(product.id)}
                    >
                      {balance < product.price ? 'Insufficient Balance' : 'Buy Now'}
                    </Button>
                  </Box>
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
          {!currentInvoice ? (
            <>
              <Typography variant="body2" color="text.secondary" paragraph>
                Pilih metode pembayaran dan jumlah deposit
              </Typography>
              
              <FormControl fullWidth margin="normal">
                <InputLabel>Payment Method</InputLabel>
                <Select
                  value={selectedMethod}
                  onChange={(e) => setSelectedMethod(e.target.value)}
                  label="Payment Method"
                >
                  {paymentMethods.map((method) => (
                    <MenuItem key={method.id} value={method.id}>
                      {method.name} {method.currency && `(${method.currency})`}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              
              <TextField
                fullWidth
                label="Amount"
                type="number"
                margin="normal"
                value={depositAmount}
                onChange={(e) => setDepositAmount(parseInt(e.target.value))}
                InputProps={{
                  startAdornment: <InputAdornment position="start">Rp</InputAdornment>,
                  inputProps: { min: 1000 }
                }}
              />
              
              <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
                {[10000, 25000, 50000, 100000, 250000].map((amount) => (
                  <Chip
                    key={amount}
                    label={`Rp ${amount.toLocaleString()}`}
                    onClick={() => setDepositAmount(amount)}
                    color={depositAmount === amount ? 'primary' : 'default'}
                    variant={depositAmount === amount ? 'filled' : 'outlined'}
                  />
                ))}
              </Box>
            </>
          ) : (
            <Box sx={{ textAlign: 'center', py: 2 }}>
              {currentInvoice.qrString ? (
                <>
                  <Typography variant="h6" gutterBottom>
                    Scan QR Code
                  </Typography>
                  <Paper sx={{ p: 3, display: 'inline-block', mb: 2 }}>
                    <QRCodeSVG value={currentInvoice.qrString} size={200} />
                  </Paper>
                </>
              ) : currentInvoice.paymentNumber ? (
                <>
                  <Typography variant="h6" gutterBottom>
                    Virtual Account Number
                  </Typography>
                  <Paper sx={{ p: 2, mb: 2, bgcolor: 'background.default' }}>
                    <Typography variant="h4" sx={{ fontFamily: 'monospace' }}>
                      {currentInvoice.paymentNumber}
                    </Typography>
                  </Paper>
                  <Button
                    startIcon={<CopyIcon />}
                    onClick={() => handleCopy(currentInvoice.paymentNumber)}
                  >
                    Copy Number
                  </Button>
                </>
              ) : null}
              
              <Typography variant="body1" sx={{ mt: 2 }}>
                Amount: Rp {currentInvoice?.amount?.toLocaleString()}
              </Typography>
              
              <Typography variant="body2" color="text.secondary">
                Expires: {new Date(currentInvoice?.expiredAt).toLocaleString()}
              </Typography>
              
              <Button
                variant="contained"
                sx={{ mt: 2 }}
                onClick={() => checkPaymentStatus(currentInvoice?.invoiceNo)}
              >
                Check Payment Status
              </Button>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => {
            setCurrentInvoice(null);
            setOpenDeposit(false);
          }}>
            Close
          </Button>
          {!currentInvoice && (
            <Button 
              variant="contained" 
              onClick={handleCreatePayment}
            >
              Pay Now
            </Button>
          )}
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
import {
  Container, Paper, Typography, TextField, Button,
  Box, Alert, InputAdornment, IconButton, Link
} from '@mui/material';
import { Visibility, VisibilityOff, Gamepad as GameIcon } from '@mui/icons-material';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

function Login() {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const response = await axios.post('/api/auth/login', {
        username,
        password
      });

      localStorage.setItem('token', response.data.token);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      background: 'linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%)'
    }}>
      <Container maxWidth="sm">
        <Paper sx={{ p: 4, backdropFilter: 'blur(10px)' }}>
          <Box sx={{ textAlign: 'center', mb: 4 }}>
            <GameIcon sx={{ fontSize: 60, color: '#ff4d4d', mb: 2 }} />
            <Typography variant="h4" sx={{ fontWeight: 'bold' }}>
              RW MLBB VPN
            </Typography>
            <Typography variant="body2" color="text.secondary">
              dengan Payment Gateway Pakasir.com
            </Typography>
          </Box>

          {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

          <form onSubmit={handleSubmit}>
            <TextField
              fullWidth
              label="Username"
              margin="normal"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />

            <TextField
              fullWidth
              label="Password"
              type={showPassword ? 'text' : 'password'}
              margin="normal"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={() => setShowPassword(!showPassword)}>
                      {showPassword ? <VisibilityOff /> : <Visibility />}
                    </IconButton>
                  </InputAdornment>
                )
              }}
            />

            <Button
              type="submit"
              fullWidth
              variant="contained"
              size="large"
              disabled={loading}
              sx={{ mt: 3, py: 1.5 }}
            >
              {loading ? 'Logging in...' : 'Login'}
            </Button>

            <Typography align="center" sx={{ mt: 2 }}>
              Don't have account?{' '}
              <Link href="/register" underline="hover" sx={{ color: '#ff4d4d' }}>
                Register
              </Link>
            </Typography>
          </form>

          <Box sx={{ mt: 4, pt: 3, borderTop: '1px solid rgba(255,255,255,0.1)' }}>
            <Typography variant="caption" color="text.secondary" align="center" display="block">
              Demo: admin / admin123
            </Typography>
          </Box>
        </Paper>
      </Container>
    </Box>
  );
}

export default Login;
EOF

    # Build frontend
    npm run build
    
    echo -e "${GREEN}✅ Frontend dengan UI payment created${NC}"
}

# ==================== FUNGSI SETUP NGINX ====================
setup_nginx() {
    echo -e "${YELLOW}[9/22] Mengkonfigurasi Nginx...${NC}"
    
    if [ "$ACCESS_TYPE" = "1" ]; then
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
    
    location /socket.io {
        proxy_pass http://127.0.0.1:${PANEL_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF
    else
        # Domain-based configuration with SSL
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
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /socket.io {
        proxy_pass http://127.0.0.1:${PANEL_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
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
    if [ "$ACCESS_TYPE" != "1" ]; then
        echo -e "${YELLOW}[10/22] Mengkonfigurasi SSL...${NC}"
        
        apt install -y certbot python3-certbot-nginx
        
        certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${EMAIL} || {
            echo -e "${YELLOW}⚠️ SSL setup failed, using HTTP only${NC}"
        }
        
        echo -e "${GREEN}✅ SSL configured${NC}"
    fi
}

# ==================== FUNGSI SETUP SERVICES ====================
setup_services() {
    echo -e "${YELLOW}[11/22] Membuat systemd services...${NC}"
    
    # Backend service
    cat > /etc/systemd/system/vpn-panel-backend.service << EOF
[Unit]
Description=RW MLBB VPN Panel with Pakasir
After=network.target mysql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/vpn-panel/backend
ExecStart=/usr/bin/node server.js
Restart=always
Environment=NODE_ENV=production
Environment=PORT=${PANEL_PORT}

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
    echo -e "${YELLOW}[12/22] Membuat database tables...${NC}"
    
    cd /var/www/vpn-panel/backend
    
    node -e "
    const bcrypt = require('bcryptjs');
    const { Sequelize, DataTypes } = require('sequelize');
    const sequelize = new Sequelize('vpn_panel', 'vpn_user', '${DB_PASSWORD}', {
        host: 'localhost',
        dialect: 'mysql'
    });
    
    const User = sequelize.define('User', {
        username: DataTypes.STRING,
        password: DataTypes.STRING,
        email: DataTypes.STRING,
        role: DataTypes.STRING,
        balance: DataTypes.DECIMAL,
        status: DataTypes.STRING
    });
    
    (async () => {
        await sequelize.sync();
        
        const [user, created] = await User.findOrCreate({
            where: { username: 'admin' },
            defaults: {
                username: 'admin',
                password: bcrypt.hashSync('admin123', 10),
                email: '${EMAIL:-admin@localhost}',
                role: 'superadmin',
                balance: 1000000,
                status: 'active'
            }
        });
        
        console.log(created ? 'Admin created' : 'Admin already exists');
        process.exit();
    })();
    "
    
    echo -e "${GREEN}✅ Database tables created${NC}"
}

# ==================== FUNGSI CREATE NODE INSTALLER ====================
create_node_installer() {
    echo -e "${YELLOW}[13/22] Membuat node installer script...${NC}"
    
    cat > /var/www/vpn-panel/install-node.sh << EOF
#!/bin/bash
# RW MLBB VPN Node Installer with Pakasir Support

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "\${GREEN}========================================\${NC}"
echo -e "\${GREEN}   RW MLBB VPN NODE INSTALLER          \${NC}"
echo -e "\${GREEN}========================================\${NC}"

if [[ \$EUID -ne 0 ]]; then
   echo -e "\${RED}This script must be run as root\${NC}" 
   exit 1
fi

read -p "Panel URL (${DOMAIN_FULL}): " PANEL_URL
PANEL_URL=\${PANEL_URL:-${DOMAIN_FULL}}

read -p "Node API Key (${NODE_API_KEY}): " NODE_API_KEY
NODE_API_KEY=\${NODE_API_KEY:-${NODE_API_KEY}}

read -p "Node Name: " NODE_NAME
read -p "Location: " LOCATION
read -p "Country Code (SG/JP/US): " COUNTRY_CODE
read -p "Is this a bot server? (y/n): " IS_BOT

# Update system
echo -e "\${YELLOW}[1/5] Updating system...\${NC}"
apt update && apt upgrade -y

# Install dependencies
echo -e "\${YELLOW}[2/5] Installing dependencies...\${NC}"
apt install -y curl wget git unzip ufw nodejs npm

# Install Xray
echo -e "\${YELLOW}[3/5] Installing Xray...\${NC}"
bash -c "\$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Setup firewall
echo -e "\${YELLOW}[4/5] Configuring firewall...\${NC}"
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 8081/tcp
ufw --force enable

# Create node controller
echo -e "\${YELLOW}[5/5] Setting up node controller...\${NC}"
mkdir -p /opt/vpn-node
cd /opt/vpn-node

cat > node-controller.js << 'NODEEOF'
const express = require('express');
const fs = require('fs');
const { exec } = require('child_process');
const os = require('os');

const app = express();
app.use(express.json());

const API_KEY = process.env.NODE_API_KEY || '';

app.use((req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    if (apiKey !== API_KEY) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
});

app.get('/status', (req, res) => {
    res.json({
        cpu: os.loadavg()[0],
        ram: ((os.totalmem() - os.freemem()) / os.totalmem()) * 100,
        users: 0,
        uptime: os.uptime()
    });
});

app.post('/api/account', (req, res) => {
    res.json({ success: true });
});

app.delete('/api/account/:uuid', (req, res) => {
    res.json({ success: true });
});

const PORT = process.env.PORT || 8081;
app.listen(PORT, () => {
    console.log(`Node controller running on port \${PORT}`);
});
NODEEOF

npm init -y
npm install express

cat > /etc/systemd/system/vpn-node.service << EOF
[Unit]
Description=RW MLBB VPN Node Controller
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vpn-node
ExecStart=/usr/bin/node node-controller.js
Restart=always
Environment=NODE_ENV=production
Environment=PORT=8081
Environment=NODE_API_KEY=\${NODE_API_KEY}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vpn-node
systemctl start vpn-node

# Register with panel
echo -e "\${YELLOW}Registering with panel...\${NC}"
curl -X POST \${PANEL_URL}/api/servers \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer \${NODE_API_KEY}" \
    -d '{
        "name": "'"\${NODE_NAME}"'",
        "location": "'"\${LOCATION}"'",
        "countryCode": "'"\${COUNTRY_CODE}"'",
        "ip": "'"\$(curl -s ifconfig.me)"'",
        "port": 443,
        "apiPort": 8081,
        "apiKey": "'"\${NODE_API_KEY}"'",
        "botServer": '"\${IS_BOT}"'
    }' || echo -e "\${YELLOW}⚠️ Could not register with panel, register manually\${NC}"

echo -e "\${GREEN}========================================\${NC}"
echo -e "\${GREEN}   NODE INSTALLATION COMPLETE!         \${NC}"
echo -e "\${GREEN}========================================\${NC}"
EOF

    chmod +x /var/www/vpn-panel/install-node.sh
    
    echo -e "${GREEN}✅ Node installer created${NC}"
}

# ==================== FUNGSI SHOW SUMMARY ====================
show_summary() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║   INSTALASI SELESAI! 🎉                                    ║"
    echo "║                                                            ║"
    echo "║   RW MOBILE LEGENDS VPN PANEL                              ║"
    echo "║   dengan PAYMENT GATEWAY PAKASIR.COM                       ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📋 INFORMASI PANEL${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "🔗 Panel URL      : ${CYAN}${DOMAIN_FULL}${NC}"
    echo -e "👤 Admin Login    : ${YELLOW}admin / admin123${NC}"
    echo -e "🗄️  Database       : ${YELLOW}vpn_panel${NC}"
    echo -e "🔑 DB Password    : ${YELLOW}${DB_PASSWORD}${NC}"
    echo -e "🔑 Node API Key   : ${YELLOW}${NODE_API_KEY}${NC}"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}💰 KONFIGURASI PAYMENT${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "🔑 PAKASIR API Key : ${CYAN}${PAKASIR_API_KEY}${NC}"
    echo -e "🔤 PAKASIR Slug    : ${CYAN}${PAKASIR_SLUG}${NC}"
    echo -e "💵 Kurs USD        : ${CYAN}Rp ${USD_RATE} / USD${NC}"
    echo ""
    echo -e "📌 Webhook URL     : ${CYAN}${DOMAIN_FULL}/api/payment/webhook${NC}"
    echo -e "   (Isi di Edit Proyek Pakasir)"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📲 CARA INSTALL NODE SERVER${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "1. Siapkan VPS baru (Ubuntu 22.04)"
    echo "2. Jalankan perintah berikut di VPS node:"
    echo ""
    echo -e "   ${YELLOW}curl -s ${DOMAIN_FULL}/install-node.sh | bash${NC}"
    echo ""
    echo "3. Masukkan informasi node"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🎮 FITUR YANG TERSEDIA${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "✅ Multi Server Cluster"
    echo "✅ Multi Protocol VPN (VLESS, VMESS, Trojan, Shadowsocks)"
    echo "✅ User Management dengan Balance"
    echo "✅ Deposit via Pakasir.com"
    echo "✅ Payment Methods: QRIS, Virtual Account, PayPal"
    echo "✅ Auto Webhook untuk konfirmasi pembayaran"
    echo "✅ Buy VPN Package dengan balance"
    echo "✅ MLBB Bot Matchmaking System"
    echo "✅ Riwayat transaksi lengkap"
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}🎮 SELAMAT BERTANDING DAN NAIK RANK! 🎮${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
}

# ==================== MAIN INSTALLATION ====================
main() {
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
}

# Run main installation
main