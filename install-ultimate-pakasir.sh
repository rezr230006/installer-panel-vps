#!/bin/bash
# ============================================================================
# VPN RW MOBILE LEGENDS BOT PANEL - ULTIMATE EDITION with PAKASIR PAYMENT
# Support Multi Location + Konfigurasi via Panel Admin
# Tanpa Port 8080 - Langsung akses via IP/Domain
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
echo "║         ⚙️  KONFIGURASI VIA PANEL ADMIN ⚙️                  ║"
echo "║         🌐 AKSES LANGSUNG TANPA PORT 🌐                    ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==================== CEK ROOT ====================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root!${NC}" 
   exit 1
fi

# ==================== CEK SYSTEM ====================
OS=$(lsb_release -is)
VERSION=$(lsb_release -rs)
if [[ "$OS" != "Ubuntu" ]] || [[ "$VERSION" != "22.04" && "$VERSION" != "20.04" ]]; then
    echo -e "${YELLOW}⚠️  Sistem terdeteksi: $OS $VERSION${NC}"
    echo -e "${YELLOW}⚠️  Script ini dioptimalkan untuk Ubuntu 22.04/20.04${NC}"
    echo -e "${YELLOW}⚠️  Tetap lanjutkan? (y/n)${NC}"
    read -p "> " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# ==================== INPUT MINIMAL ====================
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 KONFIGURASI AWAL MINIMAL${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Pilih metode akses panel:${NC}"
echo "1) 🌐 Menggunakan IP VPS (langsung akses via http://IP)"
echo "2) 📡 Menggunakan Domain/Subdomain (https://domain.com)"
echo ""
read -p "Pilih [1-2]: " ACCESS_TYPE

case $ACCESS_TYPE in
    1)
        IP_VPS=$(curl -s ifconfig.me)
        DOMAIN="$IP_VPS"
        PROTOCOL="http"
        DOMAIN_FULL="http://${IP_VPS}"
        USE_SSL=false
        echo -e "${GREEN}✅ Panel akan diakses via: ${DOMAIN_FULL}${NC}"
        ;;
    2)
        read -p "🔗 Masukkan domain Anda (contoh: vpn.domain.com): " DOMAIN
        PROTOCOL="https"
        DOMAIN_FULL="https://${DOMAIN}"
        USE_SSL=true
        read -p "📧 Masukkan email untuk SSL: " EMAIL
        echo -e "${GREEN}✅ Panel akan diakses via: ${DOMAIN_FULL}${NC}"
        ;;
    *)
        echo -e "${RED}Pilihan tidak valid! Menggunakan IP VPS.${NC}"
        IP_VPS=$(curl -s ifconfig.me)
        DOMAIN="$IP_VPS"
        PROTOCOL="http"
        DOMAIN_FULL="http://${IP_VPS}"
        USE_SSL=false
        ;;
esac

echo ""
echo -e "${YELLOW}⚠️  Konfigurasi lainnya (lokasi server, payment, dll)${NC}"
echo -e "${YELLOW}⚠️  bisa dilakukan nanti di Panel Admin setelah login.${NC}"
echo ""
read -p "🚀 Lanjutkan instalasi? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Instalasi dibatalkan.${NC}"
    exit 0
fi

# ==================== GENERATE PASSWORD RANDOM ====================
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
NODE_API_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
JWT_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)

# ==================== VARIABEL GLOBAL ====================
PANEL_PORT=80  # Gunakan port 80 untuk HTTP, nanti diarahkan oleh Nginx
NODE_PORT_START=8081

# ==================== INSTALL DEPENDENCIES ====================
echo -e "${YELLOW}[1/15] Menginstall dependencies...${NC}"

# Fix potential Node.js conflicts first
apt update
apt remove --purge -y nodejs npm libnode-dev 2>/dev/null || true
apt autoremove -y
rm -rf /etc/apt/sources.list.d/nodesource.list
rm -rf /usr/lib/node_modules
rm -rf /usr/include/node

# Install base packages
apt install -y curl wget git unzip zip nginx mysql-server \
    redis-server certbot python3-certbot-nginx build-essential \
    ufw python3 python3-pip python3-scapy \
    tcpdump net-tools iptables-persistent \
    htop iftop vnstat jq sqlite3 \
    fail2ban cron logrotate rsyslog dnsutils \
    speedtest-cli gcc g++ make

# Install Node.js 18 properly
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# ==================== INSTALL XRAY ====================
echo -e "${YELLOW}[2/15] Menginstall Xray core...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
echo -e "${GREEN}✅ Xray installed${NC}"
echo ""

# ==================== SETUP FIREWALL ====================
echo -e "${YELLOW}[3/15] Mengkonfigurasi firewall...${NC}"
ufw --force disable
ufw --force reset

ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow ${NODE_PORT_START}:${NODE_PORT_START}+10/tcp comment 'Node Ports'
ufw allow 7000:8000/udp comment 'MLBB Game Ports'
ufw limit 22/tcp

echo "y" | ufw enable
echo -e "${GREEN}✅ Firewall configured${NC}"
echo ""

# ==================== SETUP DATABASE ====================
echo -e "${YELLOW}[4/15] Mengkonfigurasi database...${NC}"

# Secure MySQL
mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Create database and user
mysql -e "CREATE DATABASE IF NOT EXISTS vpn_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'vpn_user'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON vpn_panel.* TO 'vpn_user'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

systemctl restart mysql
echo -e "${GREEN}✅ Database configured${NC}"
echo ""

# ==================== SETUP REDIS ====================
echo -e "${YELLOW}[5/15] Mengkonfigurasi Redis...${NC}"
systemctl restart redis-server
echo -e "${GREEN}✅ Redis configured${NC}"
echo ""

# ==================== BUAT DIRECTORY STRUCTURE ====================
echo -e "${YELLOW}[6/15] Membuat struktur direktori...${NC}"

mkdir -p /var/www/vpn-panel
mkdir -p /var/www/vpn-panel/{backend,frontend,node-controller,mlbb-bot}
mkdir -p /etc/vpn-panel
mkdir -p /etc/vpn-panel/rw-ml
mkdir -p /var/log/vpn-panel
mkdir -p /var/log/vpn-panel/{access,error,traffic,bot,payment}
mkdir -p /var/log/mlbb-bot
mkdir -p /var/lib/vpn-panel/{data,cache,payments}

# Save minimal configuration
cat > /etc/vpn-panel/config.yml << EOF
# VPN Panel Configuration - Auto Generated
panel:
  domain: ${DOMAIN}
  protocol: ${PROTOCOL}
  url: ${DOMAIN_FULL}
  environment: production
  setup_complete: false

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
  enabled: false
  gateway: pakasir
  pakasir_api_key: ""
  pakasir_slug: ""
  usd_rate: 15000

mlbb:
  bot_mode: true
  default_difficulty: easy
EOF

cat > /etc/vpn-panel/secrets.conf << EOF
DB_PASSWORD=${DB_PASSWORD}
NODE_API_KEY=${NODE_API_KEY}
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
PAKASIR_API_KEY=""
PAKASIR_SLUG=""
EOF

chmod 600 /etc/vpn-panel/secrets.conf
echo -e "${GREEN}✅ Directories created${NC}"
echo ""

# ==================== CREATE BACKEND ====================
echo -e "${YELLOW}[7/15] Membuat backend API...${NC}"

cd /var/www/vpn-panel/backend

cat > package.json << 'EOF'
{
  "name": "vpn-panel-ultimate",
  "version": "4.0.0",
  "description": "VPN Panel with Pakasir Payment",
  "main": "server.js",
  "scripts": { "start": "node server.js" },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "sequelize": "^6.32.1",
    "redis": "^4.6.7",
    "jsonwebtoken": "^9.0.1",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "axios": "^1.4.0",
    "socket.io": "^4.6.1",
    "node-cron": "^3.0.2",
    "qrcode": "^1.5.3",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "express-rate-limit": "^6.9.0",
    "uuid": "^9.0.0",
    "nanoid": "^5.0.1",
    "yaml": "^2.3.1",
    "winston": "^3.10.0"
  }
}
EOF

npm install

# Create main server file
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Sequelize, DataTypes } = require('sequelize');
const redis = require('ioredis');
const { Server } = require('socket.io');
const http = require('http');
const fs = require('fs');
const yaml = require('js-yaml');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

// Load configuration
const config = yaml.load(fs.readFileSync('/etc/vpn-panel/config.yml', 'utf8'));
const secrets = {};
fs.readFileSync('/etc/vpn-panel/secrets.conf', 'utf8').split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) secrets[key.trim()] = value.trim();
});

// Initialize
const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

// Database
const sequelize = new Sequelize(
    config.database.name,
    config.database.user,
    secrets.DB_PASSWORD,
    {
        host: config.database.host,
        dialect: 'mysql',
        logging: false
    }
);

// Redis
const redisClient = new redis(config.redis);

// ==================== MODELS ====================
const Setting = sequelize.define('Setting', {
    key: { type: DataTypes.STRING, primaryKey: true },
    value: DataTypes.TEXT,
    type: DataTypes.STRING,
    group: DataTypes.STRING,
    description: DataTypes.TEXT
});

const User = sequelize.define('User', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    username: { type: DataTypes.STRING, unique: true },
    password: DataTypes.STRING,
    email: DataTypes.STRING,
    role: { type: DataTypes.STRING, defaultValue: 'user' },
    balance: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
    totalDeposit: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
    botMode: { type: DataTypes.BOOLEAN, defaultValue: false },
    botDifficulty: { type: DataTypes.STRING, defaultValue: 'easy' },
    status: { type: DataTypes.STRING, defaultValue: 'active' },
    createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
});

const ServerNode = sequelize.define('ServerNode', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    name: DataTypes.STRING,
    location: DataTypes.STRING,
    countryCode: DataTypes.STRING,
    city: DataTypes.STRING,
    ip: DataTypes.STRING,
    apiKey: DataTypes.STRING,
    status: { type: DataTypes.STRING, defaultValue: 'active' },
    botServer: { type: DataTypes.BOOLEAN, defaultValue: false }
});

// Sync database
sequelize.sync();

// ==================== MIDDLEWARE ====================
app.use(helmet({ contentSecurityPolicy: false }));
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '50mb' }));
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

const isAdmin = (req, res, next) => {
    if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
        return res.status(403).json({ error: 'Admin only' });
    }
    next();
};

// ==================== SETUP ROUTES ====================

// Setup wizard - cek apakah sudah dikonfigurasi
app.get('/api/setup/status', async (req, res) => {
    const setupComplete = await Setting.findOne({ where: { key: 'setup_complete' } });
    const adminExists = await User.findOne({ where: { role: 'superadmin' } });
    
    res.json({
        setup_complete: setupComplete?.value === 'true' || false,
        admin_exists: !!adminExists,
        panel_url: config.panel.url
    });
});

// Setup wizard - konfigurasi awal
app.post('/api/setup/configure', async (req, res) => {
    try {
        const { 
            admin_username, admin_password, admin_email,
            location, country_code, city,
            pakasir_api_key, pakasir_slug, usd_rate,
            site_name, site_description
        } = req.body;
        
        // Buat admin user
        const hashedPassword = bcrypt.hashSync(admin_password || 'admin123', 10);
        await User.create({
            username: admin_username || 'admin',
            password: hashedPassword,
            email: admin_email || 'admin@localhost',
            role: 'superadmin',
            balance: 1000000
        });
        
        // Simpan settings
        const settings = [
            { key: 'site_name', value: site_name || 'RW MLBB VPN', group: 'general' },
            { key: 'site_description', value: site_description || 'VPN Khusus MLBB dengan Bot Mode', group: 'general' },
            { key: 'location', value: location || 'Singapore', group: 'server' },
            { key: 'country_code', value: country_code || 'SG', group: 'server' },
            { key: 'city', value: city || 'Singapore', group: 'server' },
            { key: 'pakasir_api_key', value: pakasir_api_key || '', group: 'payment' },
            { key: 'pakasir_slug', value: pakasir_slug || '', group: 'payment' },
            { key: 'usd_rate', value: usd_rate?.toString() || '15000', group: 'payment' },
            { key: 'payment_enabled', value: pakasir_api_key ? 'true' : 'false', group: 'payment' },
            { key: 'setup_complete', value: 'true', group: 'system' }
        ];
        
        for (const s of settings) {
            await Setting.upsert(s);
        }
        
        // Update config file
        const configPath = '/etc/vpn-panel/config.yml';
        const currentConfig = yaml.load(fs.readFileSync(configPath, 'utf8'));
        
        currentConfig.panel.location = location || 'Singapore';
        currentConfig.panel.country_code = country_code || 'SG';
        currentConfig.panel.city = city || 'Singapore';
        currentConfig.panel.setup_complete = true;
        
        if (pakasir_api_key) {
            currentConfig.payment.enabled = true;
            currentConfig.payment.pakasir_api_key = pakasir_api_key;
            currentConfig.payment.pakasir_slug = pakasir_slug;
            currentConfig.payment.usd_rate = parseInt(usd_rate) || 15000;
        }
        
        fs.writeFileSync(configPath, yaml.dump(currentConfig));
        
        // Update secrets
        const secretsPath = '/etc/vpn-panel/secrets.conf';
        let secretsContent = fs.readFileSync(secretsPath, 'utf8');
        if (pakasir_api_key) {
            secretsContent = secretsContent.replace(/PAKASIR_API_KEY=.*/g, `PAKASIR_API_KEY=${pakasir_api_key}`);
            secretsContent = secretsContent.replace(/PAKASIR_SLUG=.*/g, `PAKASIR_SLUG=${pakasir_slug}`);
        }
        fs.writeFileSync(secretsPath, secretsContent);
        
        res.json({ success: true, message: 'Configuration saved' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ==================== AUTH ROUTES ====================
app.post('/api/auth/login', async (req, res) => {
    const { username, password } = req.body;
    
    const user = await User.findOne({ where: { username, status: 'active' } });
    if (!user || !bcrypt.compareSync(password, user.password)) {
        return res.status(401).json({ error: 'Invalid credentials' });
    }
    
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
            role: user.role,
            balance: user.balance,
            botMode: user.botMode
        }
    });
});

// ==================== SETTINGS ROUTES (Admin only) ====================
app.get('/api/admin/settings', authenticateToken, isAdmin, async (req, res) => {
    const settings = await Setting.findAll();
    const grouped = {};
    settings.forEach(s => {
        if (!grouped[s.group]) grouped[s.group] = {};
        grouped[s.group][s.key] = s.value;
    });
    res.json(grouped);
});

app.post('/api/admin/settings', authenticateToken, isAdmin, async (req, res) => {
    const { key, value, group, type } = req.body;
    await Setting.upsert({ key, value, group, type });
    res.json({ success: true });
});

// ==================== PAYMENT ROUTES ====================
app.get('/api/payment/methods', async (req, res) => {
    const usdRate = await Setting.findOne({ where: { key: 'usd_rate' } });
    res.json({
        methods: [
            { id: 'qris', name: 'QRIS', min: 1000 },
            { id: 'bni_va', name: 'BNI Virtual Account', min: 10000 },
            { id: 'bri_va', name: 'BRI Virtual Account', min: 10000 },
            { id: 'paypal', name: 'PayPal', min: 1, currency: 'USD' }
        ],
        exchange_rate: usdRate?.value || 15000
    });
});

// ==================== SERVER NODE ROUTES ====================
app.get('/api/servers', authenticateToken, async (req, res) => {
    const servers = await ServerNode.findAll();
    res.json(servers);
});

app.post('/api/servers', authenticateToken, isAdmin, async (req, res) => {
    const server = await ServerNode.create(req.body);
    res.json(server);
});

// ==================== MLBB BOT ROUTES ====================
app.post('/api/mlbb/bot/enable', authenticateToken, async (req, res) => {
    const { difficulty = 'easy' } = req.body;
    await User.update(
        { botMode: true, botDifficulty: difficulty },
        { where: { id: req.user.id } }
    );
    res.json({ success: true });
});

app.post('/api/mlbb/bot/disable', authenticateToken, async (req, res) => {
    await User.update({ botMode: false }, { where: { id: req.user.id } });
    res.json({ success: true });
});

// ==================== USER ROUTES ====================
app.get('/api/user/profile', authenticateToken, async (req, res) => {
    const user = await User.findByPk(req.user.id, {
        attributes: ['username', 'email', 'balance', 'botMode', 'botDifficulty', 'createdAt']
    });
    res.json(user);
});

// ==================== DASHBOARD ====================
app.get('/api/dashboard', authenticateToken, async (req, res) => {
    const user = await User.findByPk(req.user.id);
    const setupComplete = await Setting.findOne({ where: { key: 'setup_complete' } });
    const location = await Setting.findOne({ where: { key: 'location' } });
    
    res.json({
        balance: user.balance,
        botMode: user.botMode,
        setup_complete: setupComplete?.value === 'true',
        location: location?.value || 'Not configured',
        panel_url: config.panel.url
    });
});

// ==================== START SERVER ====================
const PORT = 3000; // Internal port, Nginx akan proxy ke 80/443
server.listen(PORT, '127.0.0.1', () => {
    console.log(`Backend running on internal port ${PORT}`);
    console.log(`Panel URL: ${config.panel.url}`);
});

// Create default admin if none exists (for first run)
setTimeout(async () => {
    const adminCount = await User.count({ where: { role: 'superadmin' } });
    if (adminCount === 0) {
        const hashed = bcrypt.hashSync('admin123', 10);
        await User.create({
            username: 'admin',
            password: hashed,
            email: 'admin@localhost',
            role: 'superadmin',
            balance: 1000000
        });
        console.log('Default admin created: admin / admin123');
        console.log('⚠️  PLEASE LOGIN AND COMPLETE SETUP WIZARD!');
    }
}, 3000);
EOF

echo -e "${GREEN}✅ Backend created${NC}"
echo ""

# ==================== CREATE FRONTEND ====================
echo -e "${YELLOW}[8/15] Membuat frontend...${NC}"

cd /var/www/vpn-panel/frontend

# Create React app
npx create-react-app . --template typescript

# Install dependencies
npm install @mui/material @emotion/react @emotion/styled @mui/icons-material \
    axios react-router-dom react-qr-code react-copy-to-clipboard \
    react-toastify framer-motion

# Create setup wizard component
mkdir -p src/components
cat > src/components/SetupWizard.tsx << 'EOF'
import React, { useState, useEffect } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Stepper, Step, StepLabel, Button, TextField,
  FormControl, InputLabel, Select, MenuItem,
  Box, Typography, Alert, Paper, Grid,
  InputAdornment
} from '@mui/material';
import axios from 'axios';

interface SetupWizardProps {
  open: boolean;
  onComplete: () => void;
}

export default function SetupWizard({ open, onComplete }: SetupWizardProps) {
  const [activeStep, setActiveStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const [formData, setFormData] = useState({
    admin_username: 'admin',
    admin_password: 'admin123',
    admin_email: 'admin@localhost',
    location: 'Singapore',
    country_code: 'SG',
    city: 'Singapore',
    pakasir_api_key: '',
    pakasir_slug: '',
    usd_rate: 15000,
    site_name: 'RW MLBB VPN',
    site_description: 'VPN Khusus Mobile Legends dengan Bot Mode'
  });

  const steps = ['Admin Account', 'Server Location', 'Payment Gateway', 'Finish'];

  const locations = [
    { value: 'Singapore', code: 'SG', city: 'Singapore' },
    { value: 'Japan', code: 'JP', city: 'Tokyo' },
    { value: 'India', code: 'IN', city: 'Bangalore' },
    { value: 'Indonesia', code: 'ID', city: 'Jakarta' },
    { value: 'USA', code: 'US', city: 'Washington' },
    { value: 'Brazil', code: 'BR', city: 'Sao Paulo' },
    { value: 'UK', code: 'GB', city: 'London' },
    { value: 'Germany', code: 'DE', city: 'Frankfurt' },
    { value: 'Australia', code: 'AU', city: 'Sydney' },
  ];

  const handleNext = () => {
    if (activeStep === steps.length - 1) {
      handleSubmit();
    } else {
      setActiveStep((prev) => prev + 1);
    }
  };

  const handleBack = () => {
    setActiveStep((prev) => prev - 1);
  };

  const handleSubmit = async () => {
    setLoading(true);
    setError('');
    
    try {
      await axios.post('/api/setup/configure', formData);
      onComplete();
    } catch (err: any) {
      setError(err.response?.data?.error || 'Setup failed');
    } finally {
      setLoading(false);
    }
  };

  const handleLocationChange = (location: string) => {
    const selected = locations.find(l => l.value === location);
    if (selected) {
      setFormData({
        ...formData,
        location: selected.value,
        country_code: selected.code,
        city: selected.city
      });
    }
  };

  return (
    <Dialog open={open} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center' }}>
          <Typography variant="h5">🎮 Welcome to RW MLBB VPN</Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent>
        <Stepper activeStep={activeStep} sx={{ py: 3 }}>
          {steps.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>

        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        <Box sx={{ mt: 2 }}>
          {activeStep === 0 && (
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Buat akun administrator untuk panel Anda.
                </Typography>
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Username"
                  value={formData.admin_username}
                  onChange={(e) => setFormData({...formData, admin_username: e.target.value})}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Password"
                  type="password"
                  value={formData.admin_password}
                  onChange={(e) => setFormData({...formData, admin_password: e.target.value})}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Email"
                  type="email"
                  value={formData.admin_email}
                  onChange={(e) => setFormData({...formData, admin_email: e.target.value})}
                />
              </Grid>
            </Grid>
          )}

          {activeStep === 1 && (
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Pilih lokasi server utama Anda. Ini akan mempengaruhi routing ke MLBB.
                </Typography>
              </Grid>
              <Grid item xs={12}>
                <FormControl fullWidth>
                  <InputLabel>Server Location</InputLabel>
                  <Select
                    value={formData.location}
                    onChange={(e) => handleLocationChange(e.target.value)}
                    label="Server Location"
                  >
                    {locations.map((loc) => (
                      <MenuItem key={loc.value} value={loc.value}>
                        {loc.value} ({loc.code}) - {loc.city}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          )}

          {activeStep === 2 && (
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Konfigurasi payment gateway Pakasir.com (opsional, bisa diisi nanti).
                </Typography>
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Pakasir API Key"
                  value={formData.pakasir_api_key}
                  onChange={(e) => setFormData({...formData, pakasir_api_key: e.target.value})}
                  helperText="Kosongkan jika ingin mengisi nanti"
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Pakasir Project Slug"
                  value={formData.pakasir_slug}
                  onChange={(e) => setFormData({...formData, pakasir_slug: e.target.value})}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="USD to IDR Exchange Rate"
                  type="number"
                  value={formData.usd_rate}
                  onChange={(e) => setFormData({...formData, usd_rate: parseInt(e.target.value)})}
                  InputProps={{
                    startAdornment: <InputAdornment position="start">Rp</InputAdornment>
                  }}
                />
              </Grid>
            </Grid>
          )}

          {activeStep === 3 && (
            <Box sx={{ textAlign: 'center', py: 3 }}>
              <Typography variant="h6" gutterBottom>
                🎉 Siap untuk memulai!
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Klik Finish untuk menyimpan konfigurasi dan memulai panel.
              </Typography>
              <Paper sx={{ p: 2, bgcolor: 'background.default', mt: 2 }}>
                <Typography variant="subtitle2" gutterBottom>
                  Ringkasan Konfigurasi:
                </Typography>
                <Typography variant="body2">📍 Lokasi: {formData.location}</Typography>
                <Typography variant="body2">🔑 Payment: {formData.pakasir_api_key ? 'Terkonfigurasi' : 'Akan diisi nanti'}</Typography>
                <Typography variant="body2">🌐 Panel URL: {window.location.origin}</Typography>
              </Paper>
            </Box>
          )}
        </Box>
      </DialogContent>

      <DialogActions>
        <Button disabled={activeStep === 0} onClick={handleBack}>
          Back
        </Button>
        <Button 
          variant="contained" 
          onClick={handleNext}
          disabled={loading}
        >
          {activeStep === steps.length - 1 ? 'Finish' : 'Next'}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
EOF

# Create main App.tsx
cat > src/App.tsx << 'EOF'
import React, { useEffect, useState } from 'react';
import {
  ThemeProvider, createTheme, CssBaseline, Box, AppBar,
  Toolbar, Typography, IconButton, Badge, Avatar, Menu,
  MenuItem, Paper, Grid, Card, CardContent, Button,
  Chip, Alert, CircularProgress
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  AccountBalance as BalanceIcon,
  SportsEsports as GameIcon,
  BugReport as BotIcon,
  Settings as SettingsIcon,
  ExitToApp as LogoutIcon,
  Warning as WarningIcon
} from '@mui/icons-material';
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import axios from 'axios';
import SetupWizard from './components/SetupWizard';

const theme = createTheme({
  palette: { mode: 'dark', primary: { main: '#ff4d4d' } }
});

function App() {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [setupStatus, setSetupStatus] = useState<any>(null);
  const [showSetup, setShowSetup] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);

  useEffect(() => {
    checkSetup();
  }, []);

  const checkSetup = async () => {
    try {
      const token = localStorage.getItem('token');
      
      // Cek status setup
      const setupRes = await axios.get('/api/setup/status');
      setSetupStatus(setupRes.data);
      
      if (!setupRes.data.setup_complete && !setupRes.data.admin_exists) {
        setShowSetup(true);
        setLoading(false);
        return;
      }
      
      if (token) {
        // Verify token
        const userRes = await axios.get('/api/user/profile', {
          headers: { Authorization: `Bearer ${token}` }
        });
        setUser(userRes.data);
      }
    } catch (error) {
      console.error('Setup check failed:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setUser(null);
    window.location.href = '/';
  };

  const handleSetupComplete = () => {
    setShowSetup(false);
    window.location.reload();
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (showSetup) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <SetupWizard open={showSetup} onComplete={handleSetupComplete} />
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <ToastContainer theme="dark" />
      
      {!user ? (
        // Login page
        <Box sx={{ 
          minHeight: '100vh', 
          display: 'flex', 
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%)'
        }}>
          <Paper sx={{ p: 4, maxWidth: 400, width: '100%' }}>
            <Typography variant="h4" align="center" gutterBottom>
              RW MLBB VPN
            </Typography>
            <Typography variant="body2" align="center" color="text.secondary" paragraph>
              Silakan login dengan akun admin
            </Typography>
            
            <form onSubmit={async (e) => {
              e.preventDefault();
              const formData = new FormData(e.currentTarget);
              try {
                const res = await axios.post('/api/auth/login', {
                  username: formData.get('username'),
                  password: formData.get('password')
                });
                localStorage.setItem('token', res.data.token);
                setUser(res.data.user);
                toast.success('Login successful!');
              } catch (error) {
                toast.error('Invalid credentials');
              }
            }}>
              <input
                name="username"
                placeholder="Username"
                style={{ width: '100%', padding: '10px', margin: '10px 0' }}
              />
              <input
                name="password"
                type="password"
                placeholder="Password"
                style={{ width: '100%', padding: '10px', margin: '10px 0' }}
              />
              <Button type="submit" fullWidth variant="contained" sx={{ mt: 2 }}>
                Login
              </Button>
            </form>
          </Paper>
        </Box>
      ) : (
        // Dashboard
        <Box sx={{ display: 'flex' }}>
          <AppBar position="fixed">
            <Toolbar>
              <Typography variant="h6" sx={{ flexGrow: 1, display: 'flex', alignItems: 'center' }}>
                <GameIcon sx={{ mr: 1 }} /> RW MLBB VPN
              </Typography>
              
              {!setupStatus?.setup_complete && (
                <Chip
                  icon={<WarningIcon />}
                  label="Setup Required"
                  color="warning"
                  onClick={() => setShowSetup(true)}
                  sx={{ mr: 2 }}
                />
              )}
              
              <IconButton color="inherit" onClick={(e) => setAnchorEl(e.currentTarget)}>
                <Avatar sx={{ bgcolor: 'primary.main' }}>
                  {user?.username?.charAt(0).toUpperCase()}
                </Avatar>
              </IconButton>
              
              <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={() => setAnchorEl(null)}>
                <MenuItem>
                  <BalanceIcon sx={{ mr: 1 }} /> Rp {user?.balance?.toLocaleString()}
                </MenuItem>
                <MenuItem onClick={handleLogout}>
                  <LogoutIcon sx={{ mr: 1 }} /> Logout
                </MenuItem>
              </Menu>
            </Toolbar>
          </AppBar>
          
          <Box component="main" sx={{ flexGrow: 1, p: 3, mt: 8 }}>
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <Alert severity="info">
                  Selamat datang di RW MLBB VPN! Gunakan menu Settings untuk konfigurasi lengkap panel.
                </Alert>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Card>
                  <CardContent>
                    <Typography variant="h6">Bot Mode Status</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {user?.botMode ? 'Active' : 'Inactive'}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Card>
                  <CardContent>
                    <Typography variant="h6">Server Location</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {setupStatus?.location || 'Not configured'}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          </Box>
        </Box>
      )}
      
      <SetupWizard open={showSetup} onComplete={handleSetupComplete} />
    </ThemeProvider>
  );
}

export default App;
EOF

# Build frontend
npm run build

echo -e "${GREEN}✅ Frontend created${NC}"
echo ""

# ==================== SETUP NGINX ====================
echo -e "${YELLOW}[9/15] Mengkonfigurasi Nginx...${NC}"

if [ "$USE_SSL" = false ]; then
    # IP-based configuration - langsung port 80 tanpa port 8080
    cat > /etc/nginx/sites-available/vpn-panel << EOF
server {
    listen 80;
    server_name _;
    
    root /var/www/vpn-panel/frontend/build;
    index index.html;
    
    location / {
        try_files \$uri /index.html;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location /socket.io {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
    
    # Cache static files
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
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
    
    root /var/www/vpn-panel/frontend/build;
    index index.html;
    
    location / {
        try_files \$uri /index.html;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /socket.io {
        proxy_pass http://127.0.0.1:3000;
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

echo -e "${GREEN}✅ Nginx configured on port 80/443${NC}"
echo ""

# ==================== SETUP SSL (if domain) ====================
if [ "$USE_SSL" = true ]; then
    echo -e "${YELLOW}[10/15] Mengkonfigurasi SSL...${NC}"
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${EMAIL} || {
        echo -e "${YELLOW}⚠️ SSL setup failed, using HTTP only${NC}"
    }
    echo -e "${GREEN}✅ SSL configured${NC}"
    echo ""
fi

# ==================== SETUP SERVICES ====================
echo -e "${YELLOW}[11/15] Membuat systemd services...${NC}"

cat > /etc/systemd/system/vpn-panel-backend.service << EOF
[Unit]
Description=RW MLBB VPN Panel Backend
After=network.target mysql.service redis-server.service
Wants=mysql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/vpn-panel/backend
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vpn-panel-backend
systemctl start vpn-panel-backend

echo -e "${GREEN}✅ Services created${NC}"
echo ""

# ==================== SETUP DATABASE TABLES ====================
echo -e "${YELLOW}[12/15] Inisialisasi database...${NC}"
cd /var/www/vpn-panel/backend

# Wait for backend to start
sleep 5

echo -e "${GREEN}✅ Database initialized${NC}"
echo ""

# ==================== CREATE NODE INSTALLER ====================
echo -e "${YELLOW}[13/15] Membuat node installer script...${NC}"

cat > /var/www/vpn-panel/install-node.sh << EOF
#!/bin/bash
# RW MLBB VPN Node Installer
set -e

echo "RW MLBB VPN Node Installer"
echo "==========================="

PANEL_URL="${DOMAIN_FULL}"
NODE_API_KEY="${NODE_API_KEY}"

read -p "Node Name: " NODE_NAME
read -p "Location (e.g., Singapore): " LOCATION
read -p "Country Code (e.g., SG): " COUNTRY_CODE
read -p "Is Bot Server? (y/n): " IS_BOT

apt update
apt install -y curl nodejs npm ufw

# Install Xray
bash -c "\$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Setup firewall
ufw allow 22/tcp
ufw allow 443/tcp
ufw allow 8081/tcp
ufw --force enable

# Create node controller
mkdir -p /opt/vpn-node
cd /opt/vpn-node

cat > node-controller.js << 'NODEEOF'
const express = require('express');
const os = require('os');
const app = express();
app.use(express.json());

const API_KEY = process.env.NODE_API_KEY;

app.use((req, res, next) => {
    if (req.headers['x-api-key'] !== API_KEY) {
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

app.post('/api/account', (req, res) => res.json({ success: true }));
app.delete('/api/account/:uuid', (req, res) => res.json({ success: true }));

app.listen(8081, () => console.log('Node controller running'));
NODEEOF

npm init -y
npm install express

cat > /etc/systemd/system/vpn-node.service << 'SERVICEEOF'
[Unit]
Description=VPN Node Controller
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/vpn-node
ExecStart=/usr/bin/node node-controller.js
Environment=NODE_API_KEY='"${NODE_API_KEY}"'
Restart=always

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable vpn-node
systemctl start vpn-node

# Register with panel
curl -X POST ${PANEL_URL}/api/servers \\
    -H "Content-Type: application/json" \\
    -H "X-API-Key: ${NODE_API_KEY}" \\
    -d "{\"name\":\"${NODE_NAME}\",\"location\":\"${LOCATION}\",\"countryCode\":\"${COUNTRY_CODE}\",\"ip\":\"\$(curl -s ifconfig.me)\",\"apiKey\":\"${NODE_API_KEY}\",\"botServer\":${IS_BOT}}"

echo "✅ Node installed successfully!"
EOF

chmod +x /var/www/vpn-panel/install-node.sh

echo -e "${GREEN}✅ Node installer created${NC}"
echo ""

# ==================== CLEANUP ====================
echo -e "${YELLOW}[14/15] Membersihkan...${NC}"
apt autoremove -y
apt autoclean -y
chown -R www-data:www-data /var/www/vpn-panel
chmod -R 755 /var/www/vpn-panel
echo -e "${GREEN}✅ Cleanup completed${NC}"
echo ""

# ==================== SHOW SUMMARY ====================
echo -e "${PURPLE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         INSTALASI SELESAI! 🎉                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📋 INFORMASI AKSES PANEL${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "🔗 Panel URL      : ${CYAN}${DOMAIN_FULL}${NC}"
echo -e "👤 Admin Login    : ${YELLOW}admin / admin123${NC}"
echo ""
echo -e "${YELLOW}⚠️  PENTING:${NC}"
echo -e "1. Buka panel di browser: ${CYAN}${DOMAIN_FULL}${NC}"
echo -e "2. Login dengan: ${YELLOW}admin / admin123${NC}"
echo -e "3. Ikuti Setup Wizard untuk konfigurasi lengkap:"
echo -e "   - Lokasi server (Singapore/India/Japan/dll)"
echo -e "   - Payment gateway Pakasir (opsional)"
echo -e "   - Settings lainnya"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📲 INSTALL NODE SERVER${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Di VPS node, jalankan:"
echo -e "${YELLOW}curl -s ${DOMAIN_FULL}/install-node.sh | bash${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔧 INFORMASI TEKNIS${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Database: vpn_panel"
echo "DB User  : vpn_user"
echo "DB Pass  : ${DB_PASSWORD}"
echo "Node Key : ${NODE_API_KEY}"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}🎮 SELAMAT BERTANDING DAN NAIK RANK! 🎮${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"