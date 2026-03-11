#!/bin/bash
# ============================================================================
# RW MLBB VPN PANEL - ULTIMATE PREMIUM EDITION
# DENGAN MULTI PAGE (Home, Login, Register, Dashboard)
# FIX TOTAL UNTUK SEMUA ERROR
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
echo "    ╔═══════════════════════════════════════════════════════════════╗"
echo "    ║                                                               ║"
echo "    ║   ██████   ██     ██    ███    ███ ██      ██████  ██████    ║"
echo "    ║   ██   ██  ██     ██    ████  ████ ██      ██   ██ ██   ██   ║"
echo "    ║   ██████   ██  █  ██    ██ ████ ██ ██      ██████  ██████    ║"
echo "    ║   ██   ██  ██ ███ ██    ██  ██  ██ ██      ██   ██ ██   ██   ║"
echo "    ║   ██   ██   ███ ███     ██      ██ ███████ ██████  ██████    ║"
echo "    ║                                                               ║"
echo "    ║         🌟 PREMIUM EDITION - MULTI PAGE VERSION 🌟           ║"
echo "    ║                                                               ║"
echo "    ║        🎮 RW MOBILE LEGENDS BOT MATCHMAKING 🎮               ║"
echo "    ║        💰 PAYMENT GATEWAY PAKASIR.COM 💰                     ║"
echo "    ║        📱 DENGAN HALAMAN HOME, LOGIN & REGISTER 📱           ║"
echo "    ║                                                               ║"
echo "    ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==================== CEK ROOT ====================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root!${NC}" 
   exit 1
fi

# ==================== CEK OS ====================
echo -e "${CYAN}🔍 Memeriksa sistem...${NC}"
OS=$(lsb_release -is 2>/dev/null || echo "Ubuntu")
VERSION=$(lsb_release -rs 2>/dev/null || echo "22.04")
echo -e "${GREEN}✅ Sistem: $OS $VERSION${NC}"
echo ""

# ==================== INPUT KONFIGURASI ====================
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      🚀 KONFIGURASI AWAL 🚀                ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Pilih metode akses
echo -e "${CYAN}Pilih metode akses panel:${NC}"
echo "  1) 🌐 Menggunakan IP VPS (langsung akses via http://IP)"
echo "  2) 📡 Menggunakan Domain/Subdomain (https://domain.com)"
echo ""
read -p "➤ Pilih [1-2]: " ACCESS_TYPE

case $ACCESS_TYPE in
    1)
        IP_VPS=$(curl -s ifconfig.me)
        DOMAIN="$IP_VPS"
        PROTOCOL="http"
        DOMAIN_FULL="http://${IP_VPS}"
        USE_SSL=false
        echo -e "${GREEN}✅ Panel akan diakses via: ${CYAN}${DOMAIN_FULL}${NC}"
        ;;
    2)
        read -p "🔗 Masukkan domain Anda (contoh: vpn.domain.com): " DOMAIN
        PROTOCOL="https"
        DOMAIN_FULL="https://${DOMAIN}"
        USE_SSL=true
        read -p "📧 Masukkan email untuk SSL: " EMAIL
        echo -e "${GREEN}✅ Panel akan diakses via: ${CYAN}${DOMAIN_FULL}${NC}"
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
read -p "➤ Lanjutkan instalasi? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Instalasi dibatalkan.${NC}"
    exit 0
fi

# ==================== GENERATE PASSWORD ====================
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
NODE_API_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
JWT_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)

# ==================== VARIABEL ====================
PANEL_PORT=3000

# ==================== MULAI INSTALASI ====================
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🚀 MEMULAI INSTALASI 🚀                       ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""

# ==================== STEP 1: UPDATE SYSTEM ====================
echo -e "${YELLOW}[1/12] 📦 Mengupdate sistem...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}✅ Sistem diupdate${NC}"
echo ""

# ==================== STEP 2: INSTALL DEPENDENCIES ====================
echo -e "${YELLOW}[2/12] 📥 Menginstall dependencies...${NC}"

# Hapus Node.js lama jika ada
apt remove --purge -y nodejs npm libnode-dev 2>/dev/null || true
apt autoremove -y
rm -rf /etc/apt/sources.list.d/nodesource.list
rm -rf /usr/lib/node_modules
rm -rf /usr/include/node

# Install base packages
apt install -y curl wget git unzip zip nginx mysql-server \
    redis-server certbot python3-certbot-nginx build-essential \
    python3 python3-pip python3-scapy \
    tcpdump net-tools iptables-persistent \
    htop iftop vnstat jq sqlite3 \
    fail2ban cron logrotate rsyslog dnsutils \
    speedtest-cli gcc g++ make iptables

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo -e "${GREEN}✅ Dependencies terinstall${NC}"
echo ""

# ==================== STEP 3: INSTALL XRAY ====================
echo -e "${YELLOW}[3/12] 🔧 Menginstall Xray core...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
echo -e "${GREEN}✅ Xray terinstall${NC}"
echo ""

# ==================== STEP 4: KONFIGURASI IPTABLES ====================
echo -e "${YELLOW}[4/12] 🔥 Mengkonfigurasi IPTABLES...${NC}"

# Hapus UFW jika ada
apt remove --purge -y ufw 2>/dev/null || true

# Install iptables-persistent
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt install -y iptables-persistent

# Flush semua aturan lama
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Set policy dasar
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Izinkan koneksi yang sudah established
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Izinkan loopback
iptables -A INPUT -i lo -j ACCEPT

# Izinkan SSH (port 22)
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Izinkan HTTP/HTTPS (port 80, 443)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Izinkan port untuk Node server (8081-8090)
for port in {8081..8090}; do
    iptables -A INPUT -p tcp --dport $port -j ACCEPT
done

# Izinkan port untuk MLBB game (7000-8000 UDP)
for port in {7000..8000}; do
    iptables -A INPUT -p udp --dport $port -j ACCEPT
done

# Simpan aturan
netfilter-persistent save
systemctl enable netfilter-persistent

echo -e "${GREEN}✅ IPTABLES terkonfigurasi${NC}"
echo ""

# ==================== STEP 5: KONFIGURASI DATABASE (FIX TOTAL) ====================
echo -e "${YELLOW}[5/12] 🗄️  Mengkonfigurasi database...${NC}"

# Fungsi untuk menjalankan MySQL query
run_mysql() {
    if [ -n "$DB_ROOT_PASSWORD" ]; then
        mysql -u root -p"$DB_ROOT_PASSWORD" -e "$1" 2>/dev/null
    else
        mysql -u root -e "$1" 2>/dev/null
    fi
}

# Cek dan set password root
if mysql -u root -e "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}✅ MySQL tanpa password, mengamankan...${NC}"
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    DB_ROOT_PASSWORD="${DB_PASSWORD}"
    
elif mysql -u root -p"${DB_PASSWORD}" -e "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}✅ Password MySQL sudah sesuai${NC}"
    DB_ROOT_PASSWORD="${DB_PASSWORD}"
    
else
    echo -e "${YELLOW}⚠️  Reset password MySQL...${NC}"
    systemctl stop mysql
    mysqld_safe --skip-grant-tables --skip-networking &
    sleep 5
    
    mysql -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
EOF
    
    killall mysqld_safe 2>/dev/null
    systemctl start mysql
    sleep 3
    DB_ROOT_PASSWORD="${DB_PASSWORD}"
fi

# Buat database dan user
mysql -u root -p"${DB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS vpn_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'vpn_user'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON vpn_panel.* TO 'vpn_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Verifikasi
mysql -u vpn_user -p"${DB_PASSWORD}" -e "USE vpn_panel; SELECT 1" &>/dev/null && \
    echo -e "${GREEN}✅ Database dan user berhasil dibuat${NC}" || \
    echo -e "${RED}❌ Gagal verifikasi database${NC}"

systemctl restart mysql
echo -e "${GREEN}✅ Database terkonfigurasi${NC}"
echo ""

# ==================== STEP 6: KONFIGURASI REDIS ====================
echo -e "${YELLOW}[6/12] ⚡ Mengkonfigurasi Redis...${NC}"
systemctl restart redis-server
echo -e "${GREEN}✅ Redis terkonfigurasi${NC}"
echo ""

# ==================== STEP 7: BUAT DIREKTORI ====================
echo -e "${YELLOW}[7/12] 📁 Membuat struktur direktori...${NC}"

mkdir -p /var/www/vpn-panel
mkdir -p /var/www/vpn-panel/{backend,frontend,public}
mkdir -p /etc/vpn-panel
mkdir -p /var/log/vpn-panel
mkdir -p /var/lib/vpn-panel

# Config
cat > /etc/vpn-panel/config.yml << EOF
# VPN Panel Configuration
panel:
  domain: ${DOMAIN}
  protocol: ${PROTOCOL}
  url: ${DOMAIN_FULL}
  environment: production

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
  max_nodes: 100

jwt:
  secret: ${JWT_SECRET}
EOF

cat > /etc/vpn-panel/secrets.conf << EOF
DB_PASSWORD=${DB_PASSWORD}
NODE_API_KEY=${NODE_API_KEY}
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
EOF

chmod 600 /etc/vpn-panel/secrets.conf
echo -e "${GREEN}✅ Direktori dibuat${NC}"
echo ""

# ==================== STEP 8: BACKEND API (FIX TOTAL) ====================
echo -e "${YELLOW}[8/12] ⚙️  Membuat backend API...${NC}"

cd /var/www/vpn-panel/backend

cat > package.json << 'EOF'
{
  "name": "vpn-panel-backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "sequelize": "^6.32.1",
    "jsonwebtoken": "^9.0.1",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "cookie-parser": "^1.4.6",
    "express-session": "^1.17.3"
  }
}
EOF

npm install

# Buat backend server.js yang FIX
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Sequelize, DataTypes } = require('sequelize');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors({
    origin: true,
    credentials: true
}));
app.use(express.json());
app.use(cookieParser());
app.use(express.urlencoded({ extended: true }));

// Session
app.use(session({
    secret: 'vpn-secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 }
}));

// Baca konfigurasi
let DB_PASSWORD = 'root123';
try {
    const secrets = fs.readFileSync('/etc/vpn-panel/secrets.conf', 'utf8');
    const match = secrets.match(/DB_PASSWORD=(.+)/);
    if (match) DB_PASSWORD = match[1].trim();
} catch (e) {
    console.log('Using default DB password');
}

// Database connection
const sequelize = new Sequelize('vpn_panel', 'vpn_user', DB_PASSWORD, {
    host: 'localhost',
    dialect: 'mysql',
    logging: false
});

// Models
const User = sequelize.define('User', {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    username: { type: DataTypes.STRING, unique: true, allowNull: false },
    password: { type: DataTypes.STRING, allowNull: false },
    email: { type: DataTypes.STRING, allowNull: false },
    fullName: { type: DataTypes.STRING },
    phone: { type: DataTypes.STRING },
    role: { type: DataTypes.ENUM('user', 'admin'), defaultValue: 'user' },
    balance: { type: DataTypes.DECIMAL(15, 2), defaultValue: 0 },
    createdAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
});

// Sync database
sequelize.sync({ alter: true }).then(() => {
    console.log('✅ Database synced');
    
    // Create default admin jika belum ada
    User.findOrCreate({
        where: { username: 'admin' },
        defaults: {
            username: 'admin',
            password: bcrypt.hashSync('admin123', 10),
            email: 'admin@localhost',
            fullName: 'Administrator',
            role: 'admin',
            balance: 1000000
        }
    }).then(([user, created]) => {
        if (created) console.log('✅ Default admin created');
    });
}).catch(err => {
    console.error('❌ Database error:', err.message);
});

// ==================== API ROUTES ====================

// Home route - API status
app.get('/api/status', (req, res) => {
    res.json({
        status: 'online',
        message: 'RW MLBB VPN API is running',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

// Register
app.post('/api/register', async (req, res) => {
    try {
        const { username, password, email, fullName, phone } = req.body;
        
        // Validasi
        if (!username || !password || !email) {
            return res.status(400).json({ error: 'Username, password, and email required' });
        }
        
        // Cek existing user
        const existing = await User.findOne({ where: { username } });
        if (existing) {
            return res.status(400).json({ error: 'Username already exists' });
        }
        
        // Buat user baru
        const hashedPassword = bcrypt.hashSync(password, 10);
        const user = await User.create({
            username,
            password: hashedPassword,
            email,
            fullName: fullName || '',
            phone: phone || '',
            role: 'user',
            balance: 0
        });
        
        res.json({
            success: true,
            message: 'Registration successful',
            user: {
                id: user.id,
                username: user.username,
                email: user.email
            }
        });
    } catch (error) {
        console.error('Register error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Login
app.post('/api/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        const user = await User.findOne({ where: { username } });
        
        if (!user || !bcrypt.compareSync(password, user.password)) {
            return res.status(401).json({ error: 'Invalid username or password' });
        }
        
        // Set session
        req.session.userId = user.id;
        req.session.username = user.username;
        req.session.role = user.role;
        
        const token = jwt.sign(
            { id: user.id, username: user.username, role: user.role },
            'jwt-secret-key',
            { expiresIn: '7d' }
        );
        
        res.json({
            success: true,
            token,
            user: {
                id: user.id,
                username: user.username,
                email: user.email,
                fullName: user.fullName,
                role: user.role,
                balance: user.balance
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Logout
app.post('/api/logout', (req, res) => {
    req.session.destroy();
    res.json({ success: true, message: 'Logged out' });
});

// Get current user
app.get('/api/user', (req, res) => {
    if (!req.session.userId) {
        return res.status(401).json({ error: 'Not logged in' });
    }
    
    User.findByPk(req.session.userId, {
        attributes: { exclude: ['password'] }
    }).then(user => {
        res.json(user);
    }).catch(err => {
        res.status(500).json({ error: err.message });
    });
});

// Get all users (admin only)
app.get('/api/admin/users', async (req, res) => {
    if (!req.session.userId || req.session.role !== 'admin') {
        return res.status(403).json({ error: 'Admin only' });
    }
    
    const users = await User.findAll({
        attributes: { exclude: ['password'] }
    });
    res.json(users);
});

// Dashboard stats
app.get('/api/dashboard', async (req, res) => {
    if (!req.session.userId) {
        return res.status(401).json({ error: 'Not logged in' });
    }
    
    const totalUsers = await User.count();
    const recentUsers = await User.findAll({
        limit: 5,
        order: [['createdAt', 'DESC']],
        attributes: { exclude: ['password'] }
    });
    
    res.json({
        totalUsers,
        recentUsers,
        timestamp: new Date().toISOString()
    });
});

// Start server
app.listen(PORT, '127.0.0.1', () => {
    console.log(`✅ Backend running on port ${PORT}`);
});
EOF

echo -e "${GREEN}✅ Backend API dibuat${NC}"
echo ""

# ==================== STEP 9: FRONTEND MULTI PAGE ====================
echo -e "${YELLOW}[9/12] 🎨 Membuat frontend multi page...${NC}"

cd /var/www/vpn-panel/frontend

# Buat struktur direktori
mkdir -p css js images pages

# ==================== CSS GLOBAL ====================
cat > css/style.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

body {
    background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%);
    min-height: 100vh;
    color: white;
}

/* Navbar */
.navbar {
    background: rgba(26, 31, 53, 0.95);
    backdrop-filter: blur(10px);
    padding: 1rem 2rem;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 1000;
    border-bottom: 1px solid rgba(255, 77, 77, 0.2);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.logo {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 1.5rem;
    font-weight: bold;
    background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.nav-links {
    display: flex;
    gap: 20px;
}

.nav-links a {
    color: white;
    text-decoration: none;
    padding: 8px 16px;
    border-radius: 8px;
    transition: all 0.3s;
}

.nav-links a:hover {
    background: rgba(255, 77, 77, 0.2);
}

.btn-login {
    background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
    color: white !important;
}

.btn-login:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 20px rgba(255, 77, 77, 0.3);
}

/* Container */
.container {
    max-width: 1200px;
    margin: 80px auto 40px;
    padding: 0 20px;
}

/* Cards */
.card {
    background: rgba(26, 31, 53, 0.8);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 77, 77, 0.2);
    border-radius: 20px;
    padding: 30px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
}

/* Forms */
.form-group {
    margin-bottom: 20px;
}

.form-group label {
    display: block;
    margin-bottom: 8px;
    color: rgba(255, 255, 255, 0.8);
}

.form-control {
    width: 100%;
    padding: 12px 16px;
    background: rgba(10, 14, 28, 0.8);
    border: 1px solid rgba(255, 77, 77, 0.3);
    border-radius: 10px;
    color: white;
    font-size: 16px;
    transition: all 0.3s;
}

.form-control:focus {
    outline: none;
    border-color: #ff4d4d;
    box-shadow: 0 0 0 3px rgba(255, 77, 77, 0.2);
}

/* Buttons */
.btn {
    display: inline-block;
    padding: 12px 30px;
    border: none;
    border-radius: 10px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s;
    text-decoration: none;
}

.btn-primary {
    background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
    color: white;
    width: 100%;
}

.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 20px rgba(255, 77, 77, 0.3);
}

.btn-secondary {
    background: transparent;
    border: 2px solid #ff4d4d;
    color: white;
}

.btn-secondary:hover {
    background: rgba(255, 77, 77, 0.1);
}

/* Alert */
.alert {
    padding: 15px;
    border-radius: 10px;
    margin-bottom: 20px;
}

.alert-error {
    background: rgba(244, 67, 54, 0.2);
    border: 1px solid #f44336;
    color: #f44336;
}

.alert-success {
    background: rgba(76, 175, 80, 0.2);
    border: 1px solid #4caf50;
    color: #4caf50;
}

/* Grid */
.grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 30px;
    margin-top: 40px;
}

/* Footer */
.footer {
    text-align: center;
    padding: 20px;
    color: rgba(255, 255, 255, 0.5);
    border-top: 1px solid rgba(255, 77, 77, 0.2);
    margin-top: 60px;
}

/* Responsive */
@media (max-width: 768px) {
    .navbar {
        flex-direction: column;
        gap: 10px;
    }
    
    .nav-links {
        flex-wrap: wrap;
        justify-content: center;
    }
}
EOF

# ==================== INDEX.HTML (HALAMAN HOME) ====================
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RW MLBB VPN - Home</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        .hero {
            text-align: center;
            padding: 80px 0;
        }
        
        .hero h1 {
            font-size: 3.5rem;
            background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 20px;
        }
        
        .hero p {
            font-size: 1.2rem;
            color: rgba(255, 255, 255, 0.8);
            max-width: 700px;
            margin: 0 auto 30px;
        }
        
        .features {
            margin-top: 60px;
        }
        
        .feature-card {
            background: rgba(26, 31, 53, 0.6);
            padding: 30px;
            border-radius: 15px;
            text-align: center;
            transition: transform 0.3s;
        }
        
        .feature-card:hover {
            transform: translateY(-10px);
        }
        
        .feature-card h3 {
            color: #ff4d4d;
            margin: 15px 0;
        }
        
        .cta-buttons {
            display: flex;
            gap: 20px;
            justify-content: center;
            margin-top: 40px;
        }
        
        .cta-buttons a {
            padding: 15px 40px;
            font-size: 1.2rem;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="logo">
            <svg width="30" height="30" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"/>
            </svg>
            RW MLBB VPN
        </div>
        <div class="nav-links">
            <a href="/">Home</a>
            <a href="/features.html">Fitur</a>
            <a href="/pricing.html">Harga</a>
            <a href="/about.html">Tentang</a>
            <a href="/login.html" class="btn-login">Login</a>
            <a href="/register.html">Daftar</a>
        </div>
    </nav>

    <div class="container">
        <div class="hero">
            <h1>RW MLBB VPN Premium</h1>
            <p>VPN Khusus Mobile Legends dengan teknologi Bot Matchmaking. 
               Dapatkan pengalaman bermain yang lebih menyenangkan dengan ping rendah dan koneksi stabil.</p>
            
            <div class="cta-buttons">
                <a href="/register.html" class="btn btn-primary">Daftar Sekarang</a>
                <a href="/features.html" class="btn btn-secondary">Pelajari Lebih</a>
            </div>
        </div>

        <div class="features">
            <h2 style="text-align: center; margin-bottom: 40px;">Mengapa Memilih Kami?</h2>
            <div class="grid">
                <div class="feature-card">
                    <svg width="50" height="50" viewBox="0 0 24 24" fill="#ff4d4d">
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
                    </svg>
                    <h3>Server Global</h3>
                    <p>Server di Singapore, Japan, India, USA, dan Eropa dengan ping terbaik ke MLBB.</p>
                </div>
                
                <div class="feature-card">
                    <svg width="50" height="50" viewBox="0 0 24 24" fill="#9b59b6">
                        <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z"/>
                    </svg>
                    <h3>Keamanan Premium</h3>
                    <p>Enkripsi TLS 1.3, proteksi DDoS, dan kebijakan no-log untuk privasi Anda.</p>
                </div>
                
                <div class="feature-card">
                    <svg width="50" height="50" viewBox="0 0 24 24" fill="#4caf50">
                        <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 14.5v-9l6 4.5-6 4.5z"/>
                    </svg>
                    <h3>Bot Matchmaking</h3>
                    <p>Teknologi khusus untuk meningkatkan peluang bertemu lawan bot di Mobile Legends.</p>
                </div>
            </div>
        </div>
    </div>

    <footer class="footer">
        <p>&copy; 2026 RW MLBB VPN. All rights reserved.</p>
    </footer>
</body>
</html>
EOF

# ==================== LOGIN.HTML ====================
cat > login.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - RW MLBB VPN</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">RW MLBB VPN</div>
        <div class="nav-links">
            <a href="/">Home</a>
            <a href="/features.html">Fitur</a>
            <a href="/pricing.html">Harga</a>
            <a href="/login.html" class="btn-login">Login</a>
            <a href="/register.html">Daftar</a>
        </div>
    </nav>

    <div class="container" style="max-width: 450px;">
        <div class="card">
            <h2 style="text-align: center; margin-bottom: 30px;">Login</h2>
            
            <div id="errorMessage" class="alert alert-error" style="display: none;"></div>
            
            <form id="loginForm">
                <div class="form-group">
                    <label>Username</label>
                    <input type="text" id="username" class="form-control" required>
                </div>
                
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" id="password" class="form-control" required>
                </div>
                
                <button type="submit" class="btn btn-primary">Login</button>
            </form>
            
            <p style="text-align: center; margin-top: 20px;">
                Belum punya akun? <a href="/register.html" style="color: #ff4d4d;">Daftar di sini</a>
            </p>
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const errorDiv = document.getElementById('errorMessage');
            
            try {
                const response = await fetch('/api/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, password })
                });
                
                const data = await response.json();
                
                if (response.ok && data.success) {
                    localStorage.setItem('token', data.token);
                    localStorage.setItem('user', JSON.stringify(data.user));
                    window.location.href = '/dashboard.html';
                } else {
                    errorDiv.style.display = 'block';
                    errorDiv.textContent = data.error || 'Login failed';
                }
            } catch (error) {
                errorDiv.style.display = 'block';
                errorDiv.textContent = 'Network error';
            }
        });
    </script>
</body>
</html>
EOF

# ==================== REGISTER.HTML ====================
cat > register.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daftar - RW MLBB VPN</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">RW MLBB VPN</div>
        <div class="nav-links">
            <a href="/">Home</a>
            <a href="/features.html">Fitur</a>
            <a href="/pricing.html">Harga</a>
            <a href="/login.html" class="btn-login">Login</a>
            <a href="/register.html">Daftar</a>
        </div>
    </nav>

    <div class="container" style="max-width: 500px;">
        <div class="card">
            <h2 style="text-align: center; margin-bottom: 30px;">Daftar Akun Baru</h2>
            
            <div id="errorMessage" class="alert alert-error" style="display: none;"></div>
            <div id="successMessage" class="alert alert-success" style="display: none;"></div>
            
            <form id="registerForm">
                <div class="form-group">
                    <label>Username *</label>
                    <input type="text" id="username" class="form-control" required>
                </div>
                
                <div class="form-group">
                    <label>Email *</label>
                    <input type="email" id="email" class="form-control" required>
                </div>
                
                <div class="form-group">
                    <label>Nama Lengkap</label>
                    <input type="text" id="fullName" class="form-control">
                </div>
                
                <div class="form-group">
                    <label>Nomor Telepon</label>
                    <input type="tel" id="phone" class="form-control">
                </div>
                
                <div class="form-group">
                    <label>Password *</label>
                    <input type="password" id="password" class="form-control" required>
                </div>
                
                <div class="form-group">
                    <label>Konfirmasi Password *</label>
                    <input type="password" id="confirmPassword" class="form-control" required>
                </div>
                
                <button type="submit" class="btn btn-primary">Daftar</button>
            </form>
            
            <p style="text-align: center; margin-top: 20px;">
                Sudah punya akun? <a href="/login.html" style="color: #ff4d4d;">Login di sini</a>
            </p>
        </div>
    </div>

    <script>
        document.getElementById('registerForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const password = document.getElementById('password').value;
            const confirmPassword = document.getElementById('confirmPassword').value;
            
            if (password !== confirmPassword) {
                document.getElementById('errorMessage').style.display = 'block';
                document.getElementById('errorMessage').textContent = 'Password tidak cocok';
                return;
            }
            
            const data = {
                username: document.getElementById('username').value,
                email: document.getElementById('email').value,
                fullName: document.getElementById('fullName').value,
                phone: document.getElementById('phone').value,
                password: password
            };
            
            try {
                const response = await fetch('/api/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                });
                
                const result = await response.json();
                
                if (response.ok && result.success) {
                    document.getElementById('successMessage').style.display = 'block';
                    document.getElementById('successMessage').textContent = 'Registrasi berhasil! Mengalihkan ke login...';
                    setTimeout(() => {
                        window.location.href = '/login.html';
                    }, 2000);
                } else {
                    document.getElementById('errorMessage').style.display = 'block';
                    document.getElementById('errorMessage').textContent = result.error || 'Registrasi gagal';
                }
            } catch (error) {
                document.getElementById('errorMessage').style.display = 'block';
                document.getElementById('errorMessage').textContent = 'Network error';
            }
        });
    </script>
</body>
</html>
EOF

# ==================== DASHBOARD.HTML ====================
cat > dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - RW MLBB VPN</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">RW MLBB VPN</div>
        <div class="nav-links">
            <a href="/">Home</a>
            <a href="/dashboard.html">Dashboard</a>
            <a href="/profile.html">Profile</a>
            <a href="#" id="logoutBtn">Logout</a>
        </div>
    </nav>

    <div class="container">
        <div class="card">
            <h2>Dashboard</h2>
            <div id="userInfo"></div>
        </div>
    </div>

    <script>
        const token = localStorage.getItem('token');
        if (!token) {
            window.location.href = '/login.html';
        }

        document.getElementById('logoutBtn').addEventListener('click', async (e) => {
            e.preventDefault();
            await fetch('/api/logout', { method: 'POST' });
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            window.location.href = '/';
        });

        // Display user info
        const user = JSON.parse(localStorage.getItem('user') || '{}');
        document.getElementById('userInfo').innerHTML = `
            <p>Welcome, ${user.fullName || user.username}!</p>
            <p>Balance: Rp ${user.balance?.toLocaleString() || 0}</p>
        `;
    </script>
</body>
</html>
EOF

# ==================== FEATURES.HTML ====================
cat > features.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fitur - RW MLBB VPN</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">RW MLBB VPN</div>
        <div class="nav-links">
            <a href="/">Home</a>
            <a href="/features.html">Fitur</a>
            <a href="/pricing.html">Harga</a>
            <a href="/login.html" class="btn-login">Login</a>
            <a href="/register.html">Daftar</a>
        </div>
    </nav>

    <div class="container">
        <h1 style="text-align: center; margin-bottom: 40px;">Fitur Premium</h1>
        
        <div class="grid">
            <div class="feature-card">
                <h3>🌏 Multi Server</h3>
                <p>Server di Singapore, Japan, India, USA, Eropa</p>
            </div>
            <div class="feature-card">
                <h3>🎮 Bot Matchmaking</h3>
                <p>Teknologi khusus untuk RW MLBB</p>
            </div>
            <div class="feature-card">
                <h3>🔒 Keamanan</h3>
                <p>Enkripsi TLS 1.3, No-log policy</p>
            </div>
            <div class="feature-card">
                <h3>⚡ Kecepatan</h3>
                <p>Ping 30-40ms ke server MLBB</p>
            </div>
            <div class="feature-card">
                <h3>📱 Multi Platform</h3>
                <p>Support Android, iOS, Windows</p>
            </div>
            <div class="feature-card">
                <h3>💰 Payment</h3>
                <p>QRIS, Virtual Account, PayPal</p>
            </div>
        </div>
    </div>
</body>
</html>
EOF

# ==================== PRICING.HTML ====================
cat > pricing.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Harga - RW MLBB VPN</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">RW MLBB VPN</div>
        <div class="nav-links">
            <a href="/">Home</a>
            <a href="/features.html">Fitur</a>
            <a href="/pricing.html">Harga</a>
            <a href="/login.html" class="btn-login">Login</a>
            <a href="/register.html">Daftar</a>
        </div>
    </nav>

    <div class="container">
        <h1 style="text-align: center; margin-bottom: 40px;">Pilih Paket Anda</h1>
        
        <div class="grid">
            <div class="feature-card">
                <h3>Basic</h3>
                <h2 style="color: #ff4d4d;">Rp 50.000</h2>
                <p>/bulan</p>
                <hr style="margin: 20px 0; border-color: rgba(255,77,77,0.2);">
                <p>✓ 100 GB Traffic</p>
                <p>✓ 1 Device</p>
                <p>✓ Bot Mode</p>
                <p>✓ Support 24/7</p>
                <a href="/register.html" class="btn btn-primary" style="margin-top: 20px;">Pilih</a>
            </div>
            
            <div class="feature-card">
                <h3>Premium</h3>
                <h2 style="color: #9b59b6;">Rp 120.000</h2>
                <p>/3 bulan</p>
                <hr style="margin: 20px 0; border-color: rgba(155,89,182,0.2);">
                <p>✓ 300 GB Traffic</p>
                <p>✓ 3 Device</p>
                <p>✓ Bot Mode Priority</p>
                <p>✓ Support 24/7</p>
                <a href="/register.html" class="btn btn-primary" style="margin-top: 20px;">Pilih</a>
            </div>
            
            <div class="feature-card">
                <h3>VIP</h3>
                <h2 style="color: #ffd700;">Rp 400.000</h2>
                <p>/tahun</p>
                <hr style="margin: 20px 0; border-color: rgba(255,215,0,0.2);">
                <p>✓ Unlimited Traffic</p>
                <p>✓ 5 Device</p>
                <p>✓ Bot Mode Guarantee</p>
                <p>✓ Priority Support</p>
                <a href="/register.html" class="btn btn-primary" style="margin-top: 20px;">Pilih</a>
            </div>
        </div>
    </div>
</body>
</html>
EOF

# ==================== ABOUT.HTML ====================
cat > about.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tentang - RW MLBB VPN</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <nav class="navbar">
        <div class="logo">RW MLBB VPN</div>
        <div class="nav-links">
            <a href="/">Home</a>
            <a href="/features.html">Fitur</a>
            <a href="/pricing.html">Harga</a>
            <a href="/login.html" class="btn-login">Login</a>
            <a href="/register.html">Daftar</a>
        </div>
    </nav>

    <div class="container">
        <div class="card">
            <h1 style="text-align: center; margin-bottom: 30px;">Tentang RW MLBB VPN</h1>
            
            <p style="margin-bottom: 20px; line-height: 1.8;">
                RW MLBB VPN adalah layanan VPN premium yang dikhususkan untuk para pemain Mobile Legends. 
                Kami menyediakan koneksi cepat dan stabil dengan server yang tersebar di berbagai lokasi 
                strategis seperti Singapore, Japan, India, dan USA untuk memastikan ping terendah ke server MLBB.
            </p>
            
            <p style="margin-bottom: 20px; line-height: 1.8;">
                Dengan teknologi Bot Matchmaking kami, Anda memiliki peluang lebih besar untuk bertemu 
                lawan bot, memudahkan Anda untuk push rank dan farming skin.
            </p>
            
            <p style="margin-bottom: 20px; line-height: 1.8;">
                Keamanan adalah prioritas kami. Semua koneksi dienkripsi dengan TLS 1.3 dan kami 
                menerapkan kebijakan no-log untuk menjaga privasi Anda.
            </p>
            
            <p style="margin-bottom: 20px; line-height: 1.8;">
                Didukung oleh payment gateway Pakasir.com, Anda dapat melakukan pembayaran dengan mudah 
                melalui QRIS, Virtual Account, atau PayPal.
            </p>
        </div>
    </div>
</body>
</html>
EOF

# Copy semua file ke root
cp *.html /var/www/vpn-panel/frontend/
cp -r css /var/www/vpn-panel/frontend/

echo -e "${GREEN}✅ Frontend multi page dibuat${NC}"
echo ""

# ==================== STEP 10: KONFIGURASI NGINX ====================
echo -e "${YELLOW}[10/12] 🌐 Mengkonfigurasi Nginx...${NC}"

if [ "$USE_SSL" = false ]; then
    cat > /etc/nginx/sites-available/vpn-panel << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    root /var/www/vpn-panel/frontend;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /css/ {
        alias /var/www/vpn-panel/frontend/css/;
        expires 30d;
    }
}
EOF
else
    cat > /etc/nginx/sites-available/vpn-panel << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN};
    
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    
    root /var/www/vpn-panel/frontend;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ /index.html;
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
    
    location /css/ {
        alias /var/www/vpn-panel/frontend/css/;
        expires 30d;
    }
}
EOF
fi

ln -sf /etc/nginx/sites-available/vpn-panel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx
echo -e "${GREEN}✅ Nginx terkonfigurasi${NC}"
echo ""

# ==================== STEP 11: SSL ====================
if [ "$USE_SSL" = true ]; then
    echo -e "${YELLOW}[11/12] 🔒 Mengkonfigurasi SSL...${NC}"
    certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${EMAIL} || true
    echo -e "${GREEN}✅ SSL terkonfigurasi${NC}"
    echo ""
fi

# ==================== STEP 12: SYSTEMD SERVICE ====================
echo -e "${YELLOW}[12/12] ⚙️  Membuat systemd service...${NC}"

cat > /etc/systemd/system/vpn-panel-backend.service << 'EOF'
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
systemctl restart vpn-panel-backend

echo -e "${GREEN}✅ Systemd service dibuat${NC}"
echo ""

# ==================== SELESAI ====================
clear
echo -e "${PURPLE}"
echo "    ╔═══════════════════════════════════════════════════════════════╗"
echo "    ║                                                               ║"
echo "    ║              ✨ INSTALASI SELESAI! ✨                         ║"
echo "    ║                                                               ║"
echo "    ║         RW MLBB VPN PANEL - MULTI PAGE VERSION               ║"
echo "    ║                                                               ║"
echo "    ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📋 INFORMASI PANEL 📋                         ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 ${WHITE}Panel URL:${NC}      ${CYAN}${DOMAIN_FULL}${NC}"
echo -e "  👤 ${WHITE}Admin Default:${NC}  ${YELLOW}admin / admin123${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📱 HALAMAN YANG TERSEDIA 📱                    ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  🏠 Home        : ${DOMAIN_FULL}/"
echo "  🔐 Login       : ${DOMAIN_FULL}/login.html"
echo "  📝 Register    : ${DOMAIN_FULL}/register.html"
echo "  📊 Dashboard   : ${DOMAIN_FULL}/dashboard.html"
echo "  ⭐ Features    : ${DOMAIN_FULL}/features.html"
echo "  💰 Pricing     : ${DOMAIN_FULL}/pricing.html"
echo "  ℹ️  About      : ${DOMAIN_FULL}/about.html"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🚀 CARA MENGGUNAKAN 🚀                         ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  1️⃣  Buka browser: ${CYAN}${DOMAIN_FULL}${NC}"
echo "  2️⃣  Jelajahi halaman Home"
echo "  3️⃣  Daftar akun baru di Register"
echo "  4️⃣  Login dengan akun yang didaftarkan"
echo "  5️⃣  Atau login sebagai admin: admin / admin123"
echo ""
echo -e "${YELLOW}📌 Cek status backend:${NC}"
echo "  systemctl status vpn-panel-backend"
echo "  curl ${DOMAIN_FULL}/api/status"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}      🎮 TERIMA KASIH - SELAMAT BERTANDING! 🎮              ${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"