#!/bin/bash
# ============================================================================
# RW MLBB VPN PANEL - ULTIMATE FINAL EDITION (FIX TOTAL)
# DENGAN UI/UX SUPER PREMIUM + FIX NETWORK ERROR
# TANPA LINK PHPMYADMIN & TANPA DEMO TEXT
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
echo "    ╔═══════════════════════════════════════════════════════════════════════╗"
echo "    ║                                                                       ║"
echo "    ║   ██████   ██     ██    ███    ███ ██      ██████  ██████  ██████     ║"
echo "    ║   ██   ██  ██     ██    ████  ████ ██      ██   ██ ██   ██ ██         ║"
echo "    ║   ██████   ██  █  ██    ██ ████ ██ ██      ██████  ██████  █████      ║"
echo "    ║   ██   ██  ██ ███ ██    ██  ██  ██ ██      ██   ██ ██   ██ ██         ║"
echo "    ║   ██   ██   ███ ███     ██      ██ ███████ ██████  ██████  ██████     ║"
echo "    ║                                                                       ║"
echo "    ║         🌟 ULTIMATE FINAL EDITION - FIX TOTAL 🌟                     ║"
echo "    ║         ✅ FIX HERE-DOCUMENT ERROR                                   ║"
echo "    ║         ✅ FIX NETWORK ERROR                                         ║"
echo "    ║         ✅ TANPA LINK PHPMYADMIN                                     ║"
echo "    ║         ✅ TANPA DEMO TEXT                                           ║"
echo "    ║                                                                       ║"
echo "    ╚═══════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==================== CEK ROOT ====================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root!${NC}" 
   exit 1
fi

# ==================== INPUT KONFIGURASI ====================
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      🚀 KONFIGURASI AWAL 🚀                           ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

IP_VPS=$(curl -s ifconfig.me)
DOMAIN_FULL="http://${IP_VPS}"

echo -e "${GREEN}✅ IP VPS terdeteksi: ${CYAN}${IP_VPS}${NC}"
echo -e "${GREEN}✅ Panel akan diakses via: ${CYAN}${DOMAIN_FULL}${NC}"
echo ""
read -p "➤ Masukkan nama website (contoh: RW MLBB VPN): " SITE_NAME
SITE_NAME=${SITE_NAME:-"RW MLBB VPN"}
read -p "➤ Masukkan email admin: " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-"admin@rwmlbb.com"}
read -p "➤ Lanjutkan instalasi? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Instalasi dibatalkan.${NC}"
    exit 0
fi

# ==================== GENERATE PASSWORD ====================
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
MYSQL_ROOT_PASSWORD="root123"
NODE_API_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
JWT_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)

# ==================== MULAI INSTALASI ====================
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🚀 MEMULAI INSTALASI ULTIMATE 🚀                          ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

# ==================== STEP 1: UPDATE SYSTEM ====================
echo -e "${YELLOW}[1/15] 📦 Mengupdate sistem...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}✅ Sistem diupdate${NC}"
echo ""

# ==================== STEP 2: INSTALL DEPENDENCIES ====================
echo -e "${YELLOW}[2/15] 📥 Menginstall dependencies...${NC}"

apt install -y curl wget git unzip zip nginx \
    redis-server build-essential \
    python3 python3-pip python3-venv \
    tcpdump net-tools iptables-persistent \
    htop iftop vnstat jq sqlite3 \
    fail2ban cron logrotate rsyslog dnsutils \
    speedtest-cli gcc g++ make iptables \
    software-properties-common apt-transport-https ca-certificates gnupg \
    certbot python3-certbot-nginx

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install Apache & PHP
apt install -y apache2 php php-cli php-mysql php-mbstring php-zip php-gd php-json php-curl \
    php-xml php-bcmath libapache2-mod-php php-intl php-imagick php-xmlrpc php-soap

echo -e "${GREEN}✅ Dependencies terinstall${NC}"
echo ""

# ==================== STEP 3: INSTALL MYSQL ====================
echo -e "${YELLOW}[3/15] 🗄️  Menginstall MySQL...${NC}"

# Hapus MySQL/MariaDB lama jika ada
systemctl stop mysql mariadb 2>/dev/null || true
pkill -f mysql 2>/dev/null || true
pkill -f mysqld 2>/dev/null || true
apt remove --purge mysql* mariadb* -y 2>/dev/null || true
apt autoremove --purge -y
rm -rf /var/lib/mysql
rm -rf /etc/mysql
rm -rf /var/log/mysql
rm -rf /var/run/mysqld

# Install MySQL
apt install -y mysql-server mysql-client

# Start MySQL
systemctl start mysql
systemctl enable mysql

# Tunggu MySQL start
sleep 5

# Buat direktori socket
mkdir -p /var/run/mysqld
chown mysql:mysql /var/run/mysqld
chmod 755 /var/run/mysqld

# Set password root
mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo -e "${GREEN}✅ MySQL terinstall dengan password: ${MYSQL_ROOT_PASSWORD}${NC}"
echo ""

# ==================== STEP 4: KONFIGURASI APACHE ====================
echo -e "${YELLOW}[4/15] 🌐 Mengkonfigurasi Apache...${NC}"

# Hentikan Apache
systemctl stop apache2

# Buat konfigurasi minimal
echo "Listen 80" > /etc/apache2/ports.conf

cat > /etc/apache2/apache2.conf << 'EOF'
ServerName localhost
DefaultRuntimeDir ${APACHE_RUN_DIR}
PidFile ${APACHE_PID_FILE}
Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
User ${APACHE_RUN_USER}
Group ${APACHE_RUN_GROUP}
HostnameLookups Off
ErrorLog ${APACHE_LOG_DIR}/error.log
LogLevel warn
IncludeOptional mods-enabled/*.load
IncludeOptional mods-enabled/*.conf
Include ports.conf
AccessFileName .htaccess
<FilesMatch "^\.ht">
    Require all denied
</FilesMatch>
IncludeOptional conf-enabled/*.conf
IncludeOptional sites-enabled/*.conf
EOF

cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable mod rewrite dan modules lain
a2enmod rewrite
a2enmod headers
a2enmod expires
a2enmod deflate

# Start Apache
systemctl start apache2
systemctl enable apache2

echo -e "${GREEN}✅ Apache terkonfigurasi${NC}"
echo ""

# ==================== STEP 5: KONFIGURASI IPTABLES ====================
echo -e "${YELLOW}[5/15] 🔥 Mengkonfigurasi firewall (iptables)...${NC}"

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt install -y iptables-persistent

# Flush aturan lama
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Set policy dasar
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Izinkan koneksi established
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Izinkan loopback
iptables -A INPUT -i lo -j ACCEPT

# Izinkan port penting
iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT  # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT # HTTPS

# Izinkan port node server
for port in {8081..8090}; do
    iptables -A INPUT -p tcp --dport $port -j ACCEPT
done

# Izinkan port game MLBB
for port in {7000..8000}; do
    iptables -A INPUT -p udp --dport $port -j ACCEPT
done

# Simpan aturan
netfilter-persistent save
systemctl enable netfilter-persistent

echo -e "${GREEN}✅ Firewall terkonfigurasi${NC}"
echo ""

# ==================== STEP 6: BUAT DATABASE SUPER LENGKAP ====================
echo -e "${YELLOW}[6/15] 🗄️  Membuat database super lengkap...${NC}"

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" << EOF
-- Create database
CREATE DATABASE IF NOT EXISTS vpn_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'vpn_user'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON vpn_panel.* TO 'vpn_user'@'localhost';
FLUSH PRIVILEGES;
USE vpn_panel;

-- Tabel users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    phone VARCHAR(20),
    avatar VARCHAR(255) DEFAULT 'default.png',
    role ENUM('super_admin', 'admin', 'reseller', 'user') DEFAULT 'user',
    parent_id INT DEFAULT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00,
    commission_rate DECIMAL(5,2) DEFAULT 0.00,
    total_deposit DECIMAL(15,2) DEFAULT 0.00,
    total_withdrawal DECIMAL(15,2) DEFAULT 0.00,
    total_commission DECIMAL(15,2) DEFAULT 0.00,
    max_resellers INT DEFAULT 0,
    max_users INT DEFAULT 0,
    bot_mode BOOLEAN DEFAULT FALSE,
    bot_difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'easy',
    status ENUM('active', 'inactive', 'banned', 'suspended') DEFAULT 'active',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    remember_token VARCHAR(100),
    last_login DATETIME,
    last_ip VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Tabel settings
CREATE TABLE IF NOT EXISTS settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type ENUM('text', 'textarea', 'number', 'boolean', 'email', 'url', 'json', 'image') DEFAULT 'text',
    group_name VARCHAR(50) DEFAULT 'general',
    description TEXT,
    options TEXT,
    priority INT DEFAULT 0,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabel products
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    short_description VARCHAR(255),
    price DECIMAL(15,2) NOT NULL,
    duration_days INT DEFAULT 30,
    traffic_limit BIGINT DEFAULT 107374182400,
    device_limit INT DEFAULT 1,
    protocol VARCHAR(50) DEFAULT 'vless',
    bot_enabled BOOLEAN DEFAULT FALSE,
    featured BOOLEAN DEFAULT FALSE,
    popular BOOLEAN DEFAULT FALSE,
    status BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Tabel servers
CREATE TABLE IF NOT EXISTS servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    country_code VARCHAR(2),
    city VARCHAR(100),
    ip VARCHAR(45) NOT NULL,
    port INT DEFAULT 443,
    api_port INT DEFAULT 8081,
    api_key VARCHAR(255) NOT NULL,
    max_users INT DEFAULT 1000,
    current_users INT DEFAULT 0,
    status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',
    is_bot_server BOOLEAN DEFAULT FALSE,
    priority INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default admin (password: admin123)
INSERT INTO users (uuid, username, password, email, full_name, role, balance) 
SELECT UUID(), 'admin', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '${ADMIN_EMAIL}', 'Super Administrator', 'super_admin', 1000000
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- Insert default settings
INSERT INTO settings (setting_key, setting_value, setting_type, group_name) VALUES
('site_name', '${SITE_NAME}', 'text', 'general'),
('site_description', 'VPN Khusus Mobile Legends dengan Teknologi Bot Matchmaking', 'textarea', 'general'),
('site_email', '${ADMIN_EMAIL}', 'email', 'general'),
('site_phone', '+6281234567890', 'text', 'general'),
('site_address', 'Jakarta, Indonesia', 'text', 'general'),
('site_currency', 'IDR', 'text', 'general'),
('site_timezone', 'Asia/Jakarta', 'text', 'general'),
('facebook_url', 'https://facebook.com/rwmlbb', 'url', 'social'),
('twitter_url', 'https://twitter.com/rwmlbb', 'url', 'social'),
('instagram_url', 'https://instagram.com/rwmlbb', 'url', 'social'),
('telegram_url', 'https://t.me/rwmlbb', 'url', 'social'),
('whatsapp_number', '+6281234567890', 'text', 'social')
ON DUPLICATE KEY UPDATE setting_key=setting_key;

-- Insert default products
INSERT INTO products (name, slug, description, short_description, price, duration_days, traffic_limit, device_limit, bot_enabled) VALUES
('Basic 1 Bulan', 'basic-1-bulan', 'Paket Basic untuk pemula', '100GB, 1 Device', 50000, 30, 107374182400, 1, TRUE),
('Premium 3 Bulan', 'premium-3-bulan', 'Paket Premium dengan kuota besar', '300GB, 3 Device', 120000, 90, 322122547200, 3, TRUE),
('VIP 1 Tahun', 'vip-1-tahun', 'Paket VIP unlimited', 'Unlimited, 5 Device', 400000, 365, 999999999999, 5, TRUE)
ON DUPLICATE KEY UPDATE name=name;

-- Insert default servers
INSERT INTO servers (name, location, country_code, city, ip, api_key, is_bot_server, priority) VALUES
('Singapore Server', 'Singapore', 'SG', 'Singapore', '127.0.0.1', '${NODE_API_KEY}', TRUE, 1),
('Japan Server', 'Japan', 'JP', 'Tokyo', '127.0.0.2', '${NODE_API_KEY}', TRUE, 2),
('India Server', 'India', 'IN', 'Bangalore', '127.0.0.3', '${NODE_API_KEY}', TRUE, 3)
ON DUPLICATE KEY UPDATE name=name;
EOF

echo -e "${GREEN}✅ Database super lengkap berhasil dibuat${NC}"
echo ""

# ==================== STEP 7: BUAT BACKEND API NODE.JS ====================
echo -e "${YELLOW}[7/15] ⚙️  Membuat backend API Node.js...${NC}"

mkdir -p /var/www/api
cd /var/www/api

cat > package.json << 'EOF'
{
  "name": "vpn-panel-api",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "jsonwebtoken": "^9.0.1",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "axios": "^1.4.0"
  }
}
EOF

npm install

cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();

// CORS configuration
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

// Database connection
const pool = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '${MYSQL_ROOT_PASSWORD}',
    database: 'vpn_panel',
    waitForConnections: true,
    connectionLimit: 10
});

const promisePool = pool.promise();

// Test database connection
pool.getConnection((err, connection) => {
    if (err) {
        console.error('❌ Database connection failed:', err.message);
    } else {
        console.log('✅ Database connected successfully');
        connection.release();
    }
});

// ==================== AUTH ROUTES ====================
app.post('/api/auth/login', async (req, res) => {
    try {
        const { username, password } = req.body;
        
        const [rows] = await promisePool.query(
            'SELECT * FROM users WHERE username = ? OR email = ?',
            [username, username]
        );
        
        if (rows.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const user = rows[0];
        
        if (user.status !== 'active') {
            return res.status(403).json({ error: 'Account is not active' });
        }
        
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const token = jwt.sign(
            { id: user.id, username: user.username, role: user.role },
            '${JWT_SECRET}',
            { expiresIn: '7d' }
        );
        
        await promisePool.query(
            'UPDATE users SET last_login = NOW(), last_ip = ? WHERE id = ?',
            [req.ip, user.id]
        );
        
        const { password: _, ...userData } = user;
        
        res.json({
            success: true,
            token,
            user: userData
        });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/auth/register', async (req, res) => {
    try {
        const { username, email, password, full_name } = req.body;
        
        const [existing] = await promisePool.query(
            'SELECT id FROM users WHERE username = ? OR email = ?',
            [username, email]
        );
        
        if (existing.length > 0) {
            return res.status(400).json({ error: 'Username or email already exists' });
        }
        
        const hashedPassword = await bcrypt.hash(password, 10);
        
        await promisePool.query(
            'INSERT INTO users (uuid, username, password, email, full_name, role) VALUES (UUID(), ?, ?, ?, ?, ?)',
            [username, hashedPassword, email, full_name || null, 'user']
        );
        
        res.json({
            success: true,
            message: 'Registration successful. Please login.'
        });
    } catch (err) {
        console.error('Registration error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== PUBLIC ROUTES ====================
app.get('/api/public/settings', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            "SELECT setting_key, setting_value FROM settings WHERE is_public = TRUE OR group_name IN ('general', 'social')"
        );
        
        const settings = {};
        rows.forEach(row => {
            settings[row.setting_key] = row.setting_value;
        });
        
        res.json(settings);
    } catch (err) {
        console.error('Get settings error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/public/products', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT * FROM products WHERE status = TRUE ORDER BY price ASC'
        );
        res.json(rows);
    } catch (err) {
        console.error('Get products error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== HEALTH CHECK ====================
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// ==================== ERROR HANDLER ====================
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// ==================== START SERVER ====================
const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ API running on port ${PORT}`);
});

process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down');
    pool.end();
    process.exit(0);
});
EOF

echo -e "${GREEN}✅ Backend API selesai${NC}"
echo ""

# ==================== STEP 8: BUAT FRONTEND WEBSITE ====================
echo -e "${YELLOW}[8/15] 🎨 Membuat frontend website...${NC}"

mkdir -p /var/www/html/{assets/{css,js,img},admin,user}

# ==================== CONFIG.PHP ====================
cat > /var/www/html/config.php << 'EOF'
<?php
session_start();
ob_start();

$host = 'localhost';
$user = 'root';
$pass = '${MYSQL_ROOT_PASSWORD}';
$db = 'vpn_panel';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$settings = [];
$result = $conn->query("SELECT setting_key, setting_value FROM settings");
while($row = $result->fetch_assoc()) {
    $settings[$row['setting_key']] = $row['setting_value'];
}

$site_url = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http") . "://{$_SERVER['HTTP_HOST']}";
$api_url = "http://localhost:3000/api";
?>
EOF

# ==================== FUNCTIONS.PHP ====================
cat > /var/www/html/functions.php << 'EOF'
<?php
require_once 'config.php';

function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

function isAdmin() {
    return isset($_SESSION['user_role']) && ($_SESSION['user_role'] === 'admin' || $_SESSION['user_role'] === 'super_admin');
}

function redirect($url) {
    header("Location: $url");
    exit;
}

function getSetting($key, $default = '') {
    global $settings;
    return $settings[$key] ?? $default;
}

function formatRupiah($number) {
    return 'Rp ' . number_format($number, 0, ',', '.');
}

function formatBytes($bytes, $precision = 2) {
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    $bytes /= pow(1024, $pow);
    return round($bytes, $precision) . ' ' . $units[$pow];
}
?>
EOF

# ==================== CSS PREMIUM ====================
cat > /var/www/html/assets/css/style.css << 'CSS_EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

:root {
    --primary: #ff4d4d;
    --secondary: #9b59b6;
    --dark: #0a0e1c;
    --darker: #05070c;
    --light: #1a1f35;
    --text: #ffffff;
    --text-muted: rgba(255, 255, 255, 0.7);
    --border: rgba(255, 77, 77, 0.2);
    --gradient: linear-gradient(135deg, var(--primary), var(--secondary));
}

body {
    font-family: 'Poppins', sans-serif;
    background: var(--dark);
    color: var(--text);
    min-height: 100vh;
    display: flex;
    flex-direction: column;
}

.main-content {
    flex: 1;
    padding-top: 80px;
}

.navbar {
    background: rgba(10, 14, 28, 0.95) !important;
    backdrop-filter: blur(10px);
    border-bottom: 1px solid var(--border);
    padding: 15px 0;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 1000;
}

.navbar-brand {
    font-weight: 700;
    font-size: 1.5rem;
    background: var(--gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.nav-link {
    color: var(--text) !important;
    font-weight: 500;
    margin: 0 10px;
    position: relative;
    transition: color 0.3s;
}

.nav-link:hover,
.nav-link.active {
    color: var(--primary) !important;
}

.nav-link::after {
    content: '';
    position: absolute;
    bottom: -5px;
    left: 0;
    width: 0;
    height: 2px;
    background: var(--gradient);
    transition: width 0.3s;
}

.nav-link:hover::after,
.nav-link.active::after {
    width: 100%;
}

.btn {
    padding: 12px 30px;
    border-radius: 10px;
    font-weight: 600;
    transition: all 0.3s;
    border: none;
    cursor: pointer;
}

.btn-primary {
    background: var(--gradient);
    box-shadow: 0 4px 15px rgba(255, 77, 77, 0.3);
}

.btn-primary:hover {
    transform: translateY(-3px);
    box-shadow: 0 10px 30px rgba(255, 77, 77, 0.4);
}

.btn-outline-light {
    background: transparent;
    border: 2px solid var(--text);
    color: var(--text);
}

.btn-outline-light:hover {
    background: var(--gradient);
    border-color: transparent;
}

.card {
    background: rgba(26, 31, 53, 0.8);
    backdrop-filter: blur(10px);
    border: 1px solid var(--border);
    border-radius: 20px;
    color: var(--text);
    overflow: hidden;
    transition: all 0.3s;
    height: 100%;
}

.card:hover {
    transform: translateY(-10px);
    border-color: var(--primary);
    box-shadow: 0 20px 40px rgba(255, 77, 77, 0.2);
}

.form-control {
    background: rgba(10, 14, 28, 0.8);
    border: 1px solid var(--border);
    border-radius: 10px;
    color: var(--text);
    padding: 12px 16px;
    transition: all 0.3s;
    width: 100%;
}

.form-control:focus {
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(255, 77, 77, 0.2);
    outline: none;
}

.hero {
    text-align: center;
    padding: 100px 0;
    position: relative;
    overflow: hidden;
}

.hero h1 {
    font-size: 3.5rem;
    font-weight: 700;
    background: var(--gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    margin-bottom: 20px;
}

.feature-box {
    text-align: center;
    padding: 40px;
    border-radius: 20px;
    background: rgba(26, 31, 53, 0.6);
    border: 1px solid var(--border);
    transition: all 0.3s;
    height: 100%;
}

.feature-box:hover {
    transform: translateY(-10px);
    border-color: var(--primary);
    background: rgba(26, 31, 53, 0.8);
}

.feature-icon {
    width: 80px;
    height: 80px;
    line-height: 80px;
    text-align: center;
    background: var(--gradient);
    border-radius: 50%;
    margin: 0 auto 20px;
    font-size: 32px;
    color: var(--text);
    box-shadow: 0 10px 20px rgba(255, 77, 77, 0.3);
}

.pricing-card {
    background: rgba(26, 31, 53, 0.8);
    border-radius: 20px;
    padding: 40px;
    text-align: center;
    border: 1px solid var(--border);
    transition: all 0.3s;
    height: 100%;
}

.pricing-card:hover {
    transform: translateY(-10px);
    border-color: var(--primary);
    box-shadow: 0 20px 40px rgba(255, 77, 77, 0.2);
}

.pricing-card .price {
    font-size: 48px;
    font-weight: 700;
    color: var(--primary);
    margin: 20px 0;
}

.footer {
    background: rgba(5, 7, 12, 0.95);
    border-top: 1px solid var(--border);
    padding: 60px 0 30px;
    margin-top: 50px;
}

.footer h5 {
    color: var(--primary);
    margin-bottom: 20px;
}

.footer ul {
    list-style: none;
    padding: 0;
}

.footer ul li {
    margin-bottom: 10px;
}

.footer ul li a {
    color: var(--text-muted);
    text-decoration: none;
    transition: color 0.3s;
}

.footer ul li a:hover {
    color: var(--primary);
    padding-left: 5px;
}

.social-links a {
    display: inline-block;
    width: 40px;
    height: 40px;
    line-height: 40px;
    text-align: center;
    background: rgba(255, 77, 77, 0.1);
    border-radius: 50%;
    margin-right: 10px;
    color: var(--text);
    transition: all 0.3s;
}

.social-links a:hover {
    background: var(--gradient);
    transform: translateY(-3px) rotate(360deg);
}

.footer-bottom {
    text-align: center;
    padding-top: 30px;
    margin-top: 30px;
    border-top: 1px solid var(--border);
    color: var(--text-muted);
}

@media (max-width: 768px) {
    .hero h1 {
        font-size: 2.5rem;
    }
}
CSS_EOF

# ==================== MAIN.JS ====================
cat > /var/www/html/assets/js/main.js << 'JS_EOF'
$(document).ready(function() {
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Auto hide alerts
    setTimeout(function() {
        $('.alert').fadeOut('slow', function() {
            $(this).remove();
        });
    }, 5000);

    // Smooth scroll
    $('a[href*="#"]:not([href="#"])').on('click', function(e) {
        if (location.pathname.replace(/^\//, '') === this.pathname.replace(/^\//, '') 
            && location.hostname === this.hostname) {
            var target = $(this.hash);
            if (target.length) {
                e.preventDefault();
                $('html, body').animate({
                    scrollTop: target.offset().top - 80
                }, 800);
            }
        }
    });

    // Form validation
    $('form.needs-validation').on('submit', function(e) {
        if (!this.checkValidity()) {
            e.preventDefault();
            e.stopPropagation();
        }
        $(this).addClass('was-validated');
    });
});

function showLoading() {
    $('#loading').remove();
    $('body').append('<div id="loading" style="position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(10,14,28,0.8);z-index:9999;display:flex;justify-content:center;align-items:center;"><div class="spinner" style="width:40px;height:40px;border:4px solid rgba(255,77,77,0.1);border-top-color:#ff4d4d;border-radius:50%;animation:spin 1s linear infinite;"></div></div>');
}

function hideLoading() {
    $('#loading').remove();
}

function showToast(message, type = 'success') {
    Swal.fire({
        text: message,
        icon: type,
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 3000
    });
}

function formatRupiah(amount) {
    return 'Rp ' + new Intl.NumberFormat('id-ID').format(amount);
}

function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    var k = 1024;
    var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
}
JS_EOF

# ==================== HEADER.PHP ====================
cat > /var/www/html/header.php << 'PHP_EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo isset($page_title) ? $page_title . ' - ' . getSetting('site_name') : getSetting('site_name'); ?></title>
    
    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome 6 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- SweetAlert2 -->
    <link href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css" rel="stylesheet">
    
    <!-- Custom CSS -->
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>

<?php
$current_page = basename($_SERVER['PHP_SELF']);
$user_role = isset($_SESSION['user_role']) ? $_SESSION['user_role'] : 'guest';
?>

<!-- Navbar -->
<nav class="navbar navbar-expand-lg navbar-dark">
    <div class="container">
        <a class="navbar-brand" href="/">
            <i class="fas fa-shield-alt me-2"></i>
            <?php echo getSetting('site_name'); ?>
        </a>
        
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item">
                    <a class="nav-link <?php echo $current_page == 'index.php' ? 'active' : ''; ?>" href="/">
                        <i class="fas fa-home me-1"></i>Home
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?php echo $current_page == 'pricing.php' ? 'active' : ''; ?>" href="/pricing.php">
                        <i class="fas fa-tag me-1"></i>Harga
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?php echo $current_page == 'about.php' ? 'active' : ''; ?>" href="/about.php">
                        <i class="fas fa-info-circle me-1"></i>Tentang
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?php echo $current_page == 'contact.php' ? 'active' : ''; ?>" href="/contact.php">
                        <i class="fas fa-envelope me-1"></i>Kontak
                    </a>
                </li>
                
                <?php if (isset($_SESSION['user_id'])): ?>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="userDropdown" role="button" data-bs-toggle="dropdown">
                            <i class="fas fa-user-circle me-1"></i>
                            <?php echo $_SESSION['user_name']; ?>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <?php if ($user_role == 'super_admin' || $user_role == 'admin'): ?>
                                <li><a class="dropdown-item" href="/admin/">
                                    <i class="fas fa-tachometer-alt me-2"></i>Admin Dashboard
                                </a></li>
                            <?php else: ?>
                                <li><a class="dropdown-item" href="/user/">
                                    <i class="fas fa-tachometer-alt me-2"></i>Dashboard
                                </a></li>
                            <?php endif; ?>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="/logout.php">
                                <i class="fas fa-sign-out-alt me-2"></i>Logout
                            </a></li>
                        </ul>
                    </li>
                <?php else: ?>
                    <li class="nav-item">
                        <a class="nav-link btn btn-outline-light me-2" href="/login.php">
                            <i class="fas fa-sign-in-alt me-1"></i>Login
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link btn btn-primary text-white" href="/register.php">
                            <i class="fas fa-user-plus me-1"></i>Daftar
                        </a>
                    </li>
                <?php endif; ?>
            </ul>
        </div>
    </div>
</nav>

<main class="main-content">
PHP_EOF

# ==================== FOOTER.PHP ====================
cat > /var/www/html/footer.php << 'PHP_EOF'
</main>

<!-- Footer -->
<footer class="footer">
    <div class="container">
        <div class="row">
            <div class="col-md-4 mb-4">
                <h5><i class="fas fa-shield-alt me-2"></i><?php echo getSetting('site_name'); ?></h5>
                <p><?php echo getSetting('site_description'); ?></p>
                <div class="social-links">
                    <?php if (getSetting('facebook_url')): ?>
                        <a href="<?php echo getSetting('facebook_url'); ?>" target="_blank"><i class="fab fa-facebook"></i></a>
                    <?php endif; ?>
                    <?php if (getSetting('twitter_url')): ?>
                        <a href="<?php echo getSetting('twitter_url'); ?>" target="_blank"><i class="fab fa-twitter"></i></a>
                    <?php endif; ?>
                    <?php if (getSetting('instagram_url')): ?>
                        <a href="<?php echo getSetting('instagram_url'); ?>" target="_blank"><i class="fab fa-instagram"></i></a>
                    <?php endif; ?>
                    <?php if (getSetting('telegram_url')): ?>
                        <a href="<?php echo getSetting('telegram_url'); ?>" target="_blank"><i class="fab fa-telegram"></i></a>
                    <?php endif; ?>
                </div>
            </div>
            <div class="col-md-2 mb-4">
                <h5>Links</h5>
                <ul class="list-unstyled">
                    <li><a href="/pricing.php"><i class="fas fa-chevron-right me-1"></i>Harga</a></li>
                    <li><a href="/about.php"><i class="fas fa-chevron-right me-1"></i>Tentang</a></li>
                    <li><a href="/contact.php"><i class="fas fa-chevron-right me-1"></i>Kontak</a></li>
                </ul>
            </div>
            <div class="col-md-3 mb-4">
                <h5>Kontak</h5>
                <ul class="list-unstyled">
                    <?php if (getSetting('site_email')): ?>
                        <li><i class="fas fa-envelope me-2"></i><?php echo getSetting('site_email'); ?></li>
                    <?php endif; ?>
                    <?php if (getSetting('site_phone')): ?>
                        <li><i class="fas fa-phone me-2"></i><?php echo getSetting('site_phone'); ?></li>
                    <?php endif; ?>
                    <?php if (getSetting('site_address')): ?>
                        <li><i class="fas fa-map-marker-alt me-2"></i><?php echo getSetting('site_address'); ?></li>
                    <?php endif; ?>
                </ul>
            </div>
        </div>
        <div class="footer-bottom">
            <p>&copy; <?php echo date('Y'); ?> <?php echo getSetting('site_name'); ?>. All rights reserved.</p>
        </div>
    </div>
</footer>

<!-- jQuery -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

<!-- Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>

<!-- SweetAlert2 -->
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<!-- Custom JS -->
<script src="/assets/js/main.js"></script>

</body>
</html>
PHP_EOF

# ==================== INDEX.PHP ====================
cat > /var/www/html/index.php << 'PHP_EOF'
<?php
require_once 'config.php';
require_once 'functions.php';

$page_title = 'Home';
include 'header.php';

$products = $conn->query("SELECT * FROM products WHERE status = TRUE ORDER BY price ASC LIMIT 3");
?>

<section class="hero">
    <div class="container">
        <h1><?php echo getSetting('site_name'); ?></h1>
        <p><?php echo getSetting('site_description'); ?></p>
        <div class="mt-4">
            <?php if (!isset($_SESSION['user_id'])): ?>
                <a href="/register.php" class="btn btn-primary btn-lg me-3">
                    <i class="fas fa-user-plus me-2"></i>Daftar Sekarang
                </a>
            <?php endif; ?>
            <a href="/pricing.php" class="btn btn-outline-light btn-lg">
                <i class="fas fa-tag me-2"></i>Lihat Harga
            </a>
        </div>
    </div>
</section>

<section class="py-5">
    <div class="container">
        <h2 class="text-center mb-5">Mengapa Memilih Kami?</h2>
        <div class="row">
            <div class="col-md-4 mb-4">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-globe"></i>
                    </div>
                    <h3>Server Global</h3>
                    <p>Server di Singapore, Japan, India dengan ping terbaik</p>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-robot"></i>
                    </div>
                    <h3>Bot Matchmaking</h3>
                    <p>Teknologi khusus untuk bertemu lawan bot</p>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-shield-alt"></i>
                    </div>
                    <h3>Keamanan Premium</h3>
                    <p>Enkripsi TLS 1.3 dan proteksi DDoS</p>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="py-5">
    <div class="container">
        <h2 class="text-center mb-5">Paket Populer</h2>
        <div class="row">
            <?php while($product = $products->fetch_assoc()): ?>
            <div class="col-md-4 mb-4">
                <div class="pricing-card">
                    <h3><?php echo $product['name']; ?></h3>
                    <div class="price">
                        <?php echo formatRupiah($product['price']); ?>
                        <small>/<?php echo $product['duration_days']; ?> hari</small>
                    </div>
                    <p><?php echo $product['short_description']; ?></p>
                    <hr>
                    <p><i class="fas fa-check text-success me-2"></i><?php echo formatBytes($product['traffic_limit']); ?></p>
                    <p><i class="fas fa-check text-success me-2"></i><?php echo $product['device_limit']; ?> Device</p>
                    <?php if($product['bot_enabled']): ?>
                        <p><i class="fas fa-check text-success me-2"></i>Bot Mode</p>
                    <?php endif; ?>
                    <a href="/register.php" class="btn btn-primary mt-3 w-100">Pilih Paket</a>
                </div>
            </div>
            <?php endwhile; ?>
        </div>
    </div>
</section>

<?php include 'footer.php'; ?>
PHP_EOF

# ==================== LOGIN.PHP ====================
cat > /var/www/html/login.php << 'PHP_EOF'
<?php
require_once 'config.php';
require_once 'functions.php';

if (isset($_SESSION['user_id'])) {
    if ($_SESSION['user_role'] == 'admin' || $_SESSION['user_role'] == 'super_admin') {
        redirect('/admin/');
    } else {
        redirect('/user/');
    }
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    
    $ch = curl_init('http://localhost:3000/api/auth/login');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['username' => $username, 'password' => $password]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    
    if (curl_error($ch)) {
        $error = 'Connection error: ' . curl_error($ch);
    } elseif ($httpCode == 200) {
        $data = json_decode($response, true);
        
        if (isset($data['success']) && $data['success']) {
            $_SESSION['user_id'] = $data['user']['id'];
            $_SESSION['user_name'] = $data['user']['full_name'] ?: $data['user']['username'];
            $_SESSION['user_role'] = $data['user']['role'];
            $_SESSION['api_token'] = $data['token'];
            
            if ($data['user']['role'] == 'admin' || $data['user']['role'] == 'super_admin') {
                redirect('/admin/');
            } else {
                redirect('/user/');
            }
        } else {
            $error = $data['error'] ?? 'Login failed';
        }
    } else {
        $error = 'Server error. Please try again.';
    }
    
    curl_close($ch);
}

$page_title = 'Login';
?>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - <?php echo getSetting('site_name'); ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
        }
        .login-card {
            background: rgba(26, 31, 53, 0.8);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 77, 77, 0.2);
            border-radius: 20px;
            padding: 40px;
            width: 100%;
            max-width: 400px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
        }
        .form-control {
            background: rgba(10, 14, 28, 0.8);
            border: 1px solid rgba(255, 77, 77, 0.3);
            color: #fff;
            padding: 12px;
        }
        .form-control:focus {
            border-color: #ff4d4d;
            box-shadow: 0 0 0 3px rgba(255, 77, 77, 0.2);
        }
        .btn-login {
            background: linear-gradient(135deg, #ff4d4d, #9b59b6);
            border: none;
            padding: 12px;
            width: 100%;
            color: #fff;
            font-weight: 600;
            border-radius: 10px;
        }
        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(255, 77, 77, 0.3);
        }
        .back-home {
            position: absolute;
            top: 20px;
            left: 20px;
        }
        .back-home a {
            color: #fff;
            text-decoration: none;
        }
        .back-home a:hover {
            color: #ff4d4d;
        }
    </style>
</head>
<body>
    <div class="back-home">
        <a href="/"><i class="fas fa-arrow-left"></i> Kembali ke Home</a>
    </div>
    
    <div class="login-card">
        <div class="text-center mb-4">
            <i class="fas fa-shield-alt fa-3x mb-3" style="color: #ff4d4d;"></i>
            <h2><?php echo getSetting('site_name'); ?></h2>
            <p class="text-muted">Silakan login ke akun Anda</p>
        </div>
        
        <?php if ($error): ?>
            <div class="alert alert-danger"><?php echo $error; ?></div>
        <?php endif; ?>
        
        <form method="POST">
            <div class="mb-3">
                <label class="form-label">Username / Email</label>
                <input type="text" name="username" class="form-control" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Password</label>
                <input type="password" name="password" class="form-control" required>
            </div>
            <button type="submit" class="btn-login">
                <i class="fas fa-sign-in-alt me-2"></i>Login
            </button>
        </form>
        
        <div class="text-center mt-3">
            <p>Belum punya akun? <a href="/register.php" style="color: #ff4d4d;">Daftar</a></p>
        </div>
    </div>
</body>
</html>
PHP_EOF

# ==================== REGISTER.PHP ====================
cat > /var/www/html/register.php << 'PHP_EOF'
<?php
require_once 'config.php';
require_once 'functions.php';

if (isset($_SESSION['user_id'])) {
    redirect('/user/');
}

$error = '';
$success = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $email = $_POST['email'] ?? '';
    $password = $_POST['password'] ?? '';
    $confirm = $_POST['confirm_password'] ?? '';
    $full_name = $_POST['full_name'] ?? '';
    
    if ($password !== $confirm) {
        $error = 'Password tidak cocok';
    } else {
        $ch = curl_init('http://localhost:3000/api/auth/register');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
            'username' => $username,
            'email' => $email,
            'password' => $password,
            'full_name' => $full_name
        ]));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_TIMEOUT, 30);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        
        if (curl_error($ch)) {
            $error = 'Connection error: ' . curl_error($ch);
        } elseif ($httpCode == 200) {
            $data = json_decode($response, true);
            
            if (isset($data['success']) && $data['success']) {
                $success = $data['message'];
            } else {
                $error = $data['error'] ?? 'Registration failed';
            }
        } else {
            $error = 'Server error. Please try again.';
        }
        
        curl_close($ch);
    }
}

$page_title = 'Register';
?>

<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daftar - <?php echo getSetting('site_name'); ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
        }
        .register-card {
            background: rgba(26, 31, 53, 0.8);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 77, 77, 0.2);
            border-radius: 20px;
            padding: 40px;
            width: 100%;
            max-width: 500px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
        }
        .form-control {
            background: rgba(10, 14, 28, 0.8);
            border: 1px solid rgba(255, 77, 77, 0.3);
            color: #fff;
            padding: 12px;
        }
        .form-control:focus {
            border-color: #ff4d4d;
            box-shadow: 0 0 0 3px rgba(255, 77, 77, 0.2);
        }
        .btn-register {
            background: linear-gradient(135deg, #ff4d4d, #9b59b6);
            border: none;
            padding: 12px;
            width: 100%;
            color: #fff;
            font-weight: 600;
            border-radius: 10px;
        }
        .btn-register:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(255, 77, 77, 0.3);
        }
        .back-home {
            position: absolute;
            top: 20px;
            left: 20px;
        }
        .back-home a {
            color: #fff;
            text-decoration: none;
        }
        .back-home a:hover {
            color: #ff4d4d;
        }
    </style>
</head>
<body>
    <div class="back-home">
        <a href="/"><i class="fas fa-arrow-left"></i> Kembali ke Home</a>
    </div>
    
    <div class="register-card">
        <div class="text-center mb-4">
            <i class="fas fa-user-plus fa-3x mb-3" style="color: #ff4d4d;"></i>
            <h2>Daftar Akun Baru</h2>
        </div>
        
        <?php if ($error): ?>
            <div class="alert alert-danger"><?php echo $error; ?></div>
        <?php endif; ?>
        
        <?php if ($success): ?>
            <div class="alert alert-success"><?php echo $success; ?></div>
            <meta http-equiv="refresh" content="2;url=/login.php">
        <?php endif; ?>
        
        <form method="POST">
            <div class="mb-3">
                <label class="form-label">Username</label>
                <input type="text" name="username" class="form-control" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Email</label>
                <input type="email" name="email" class="form-control" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Nama Lengkap</label>
                <input type="text" name="full_name" class="form-control">
            </div>
            <div class="mb-3">
                <label class="form-label">Password</label>
                <input type="password" name="password" id="password" class="form-control" required>
            </div>
            <div class="mb-3">
                <label class="form-label">Konfirmasi Password</label>
                <input type="password" name="confirm_password" class="form-control" required>
            </div>
            <button type="submit" class="btn-register">
                <i class="fas fa-user-plus me-2"></i>Daftar
            </button>
        </form>
        
        <div class="text-center mt-3">
            <p>Sudah punya akun? <a href="/login.php" style="color: #ff4d4d;">Login</a></p>
        </div>
    </div>
</body>
</html>
PHP_EOF

# ==================== LOGOUT.PHP ====================
cat > /var/www/html/logout.php << 'PHP_EOF'
<?php
session_start();
session_destroy();
header("Location: /login.php");
exit;
PHP_EOF

# ==================== SET PERMISSIONS ====================
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo -e "${GREEN}✅ Frontend website selesai${NC}"
echo ""

# ==================== STEP 9: BUAT SYSTEMD SERVICE ====================
echo -e "${YELLOW}[9/15] ⚙️  Membuat systemd service untuk API...${NC}"

cat > /etc/systemd/system/vpn-panel-api.service << 'EOF'
[Unit]
Description=RW MLBB VPN API
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/api
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vpn-panel-api
systemctl start vpn-panel-api

echo -e "${GREEN}✅ API service created${NC}"
echo ""

# ==================== STEP 10: KONFIGURASI REDIS ====================
echo -e "${YELLOW}[10/15] ⚡ Mengkonfigurasi Redis...${NC}"
systemctl restart redis-server
echo -e "${GREEN}✅ Redis terkonfigurasi${NC}"
echo ""

# ==================== STEP 11: CEK API STATUS ====================
echo -e "${YELLOW}[11/15] 🔍 Mengecek API status...${NC}"
sleep 3

if curl -s http://localhost:3000/health | grep -q "ok"; then
    echo -e "${GREEN}✅ API berjalan dengan baik${NC}"
else
    echo -e "${YELLOW}⚠️ API belum merespon, cek dengan: systemctl status vpn-panel-api${NC}"
fi
echo ""

# ==================== STEP 12: SELESAI ====================
clear
echo -e "${PURPLE}"
echo "    ╔═══════════════════════════════════════════════════════════════════════╗"
echo "    ║                                                                       ║"
echo "    ║              ✨ INSTALASI SELESAI! ✨                                 ║"
echo "    ║                                                                       ║"
echo "    ║         RW MLBB VPN PANEL - ULTIMATE FINAL EDITION                   ║"
echo "    ║         ✅ FIX HERE-DOCUMENT ERROR                                   ║"
echo "    ║         ✅ FIX NETWORK ERROR                                         ║"
echo "    ║         ✅ TANPA LINK PHPMYADMIN                                     ║"
echo "    ║         ✅ TANPA DEMO TEXT                                           ║"
echo "    ║                                                                       ║"
echo "    ╚═══════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📋 INFORMASI AKSES 📋                                     ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "🌐 ${WHITE}Website:${NC}         ${CYAN}http://${IP_VPS}${NC}"
echo -e "🔐 ${WHITE}Login:${NC}            ${CYAN}http://${IP_VPS}/login.php${NC}"
echo -e "📝 ${WHITE}Register:${NC}         ${CYAN}http://${IP_VPS}/register.php${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🔑 LOGIN AKUN 🔑                                         ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "👑 ${WHITE}Super Admin:${NC}"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🔧 INFORMASI TEKNIS 🔧                                    ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   MySQL Root Password: ${MYSQL_ROOT_PASSWORD}"
echo "   Database: vpn_panel"
echo "   API Key: ${NODE_API_KEY}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🔄 PERINTAH PENTING 🔄                                    ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   Restart API: systemctl restart vpn-panel-api"
echo "   Restart Apache: systemctl restart apache2"
echo "   View API Logs: journalctl -u vpn-panel-api -f"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}      🎮 TERIMA KASIH - SELAMAT BERTANDING! 🎮                        ${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"