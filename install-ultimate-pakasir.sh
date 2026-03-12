#!/bin/bash
# ============================================================================
# RW MLBB VPN PANEL - ULTIMATE PREMIUM EDITION
# DENGAN MYSQL + PHPMYADMIN OTOMATIS
# Support Multi Page (Home, Login, Register, Dashboard)
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
echo "    ║         🌟 PREMIUM EDITION - MYSQL VERSION 🌟                 ║"
echo "    ║         📦 DENGAN PHPMYADMIN OTOMATIS 📦                      ║"
echo "    ║                                                               ║"
echo "    ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==================== CEK ROOT ====================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Script ini harus dijalankan sebagai root!${NC}" 
   exit 1
fi

# ==================== INPUT KONFIGURASI ====================
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                      🚀 KONFIGURASI AWAL 🚀                ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

IP_VPS=$(curl -s ifconfig.me)
DOMAIN_FULL="http://${IP_VPS}"

echo -e "${GREEN}✅ IP VPS terdeteksi: ${CYAN}${IP_VPS}${NC}"
echo -e "${GREEN}✅ Panel akan diakses via: ${CYAN}${DOMAIN_FULL}${NC}"
echo ""
read -p "➤ Lanjutkan instalasi? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Instalasi dibatalkan.${NC}"
    exit 0
fi

# ==================== GENERATE PASSWORD ====================
DB_PASSWORD="root123"
MYSQL_ROOT_PASSWORD="root123"
NODE_API_KEY=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
JWT_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)

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

# Install base packages
apt install -y curl wget git unzip zip nginx \
    redis-server build-essential \
    python3 python3-pip \
    tcpdump net-tools iptables-persistent \
    htop iftop vnstat jq sqlite3 \
    fail2ban cron logrotate rsyslog dnsutils \
    speedtest-cli gcc g++ make iptables \
    software-properties-common apt-transport-https ca-certificates gnupg

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

echo -e "${GREEN}✅ Dependencies terinstall${NC}"
echo ""

# ==================== STEP 3: INSTALL MYSQL ====================
echo -e "${YELLOW}[3/12] 🗄️  Menginstall MySQL...${NC}"

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

# Set password root dengan metode yang benar
mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Cek koneksi
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ MySQL terinstall dengan password: ${MYSQL_ROOT_PASSWORD}${NC}"
else
    echo -e "${RED}❌ Gagal set password MySQL${NC}"
    exit 1
fi

echo ""

# ==================== STEP 4: INSTALL PHP & PHPMYADMIN ====================
echo -e "${YELLOW}[4/12] 📦 Menginstall PHP dan phpMyAdmin...${NC}"

# Install PHP dan extensions
apt install -y php php-cli php-mysql php-mbstring php-zip php-gd php-json php-curl \
    php-xml php-bcmath apache2 libapache2-mod-php

# Download phpMyAdmin manual (karena sering error dengan apt)
cd /tmp
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
unzip phpMyAdmin-5.2.1-all-languages.zip
rm -rf /usr/share/phpmyadmin
mv phpMyAdmin-5.2.1-all-languages /usr/share/phpmyadmin

# Konfigurasi phpMyAdmin
mkdir -p /usr/share/phpmyadmin/tmp
chmod 777 /usr/share/phpmyadmin/tmp
chown -R www-data:www-data /usr/share/phpmyadmin

# Buat config phpMyAdmin
cat > /usr/share/phpmyadmin/config.inc.php << 'EOF'
<?php
declare(strict_types=1);

$cfg['blowfish_secret'] = '$(openssl rand -base64 32)';

$i = 0;
$i++;

$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;
$cfg['Servers'][$i]['user'] = 'root';
$cfg['Servers'][$i]['password'] = 'root123';

$cfg['UploadDir'] = '';
$cfg['SaveDir'] = '';
$cfg['TempDir'] = '/tmp';
?>
EOF

# Link phpMyAdmin ke direktori web
ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Enable Apache modules
a2enmod rewrite
a2enmod headers

# Restart Apache
systemctl restart apache2

echo -e "${GREEN}✅ PHP dan phpMyAdmin terinstall${NC}"
echo ""

# ==================== STEP 5: BUAT DATABASE PANEL ====================
echo -e "${YELLOW}[5/12] 🗄️  Membuat database untuk panel...${NC}"

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" << EOF
CREATE DATABASE IF NOT EXISTS vpn_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'vpn_user'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON vpn_panel.* TO 'vpn_user'@'localhost';
FLUSH PRIVILEGES;
USE vpn_panel;

-- Tabel users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    full_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(20) DEFAULT 'user',
    balance DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel products
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(15,2) NOT NULL,
    duration INT DEFAULT 30,
    traffic_limit BIGINT DEFAULT 107374182400,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabel transactions
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT,
    amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tabel servers
CREATE TABLE IF NOT EXISTS servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    country_code VARCHAR(2),
    ip VARCHAR(45),
    api_key VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active',
    bot_server BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin (password: admin123)
INSERT INTO users (username, password, email, full_name, role, balance) 
SELECT 'admin', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@localhost', 'Administrator', 'admin', 1000000
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- Insert default products
INSERT INTO products (name, description, price, duration, traffic_limit) VALUES
('Basic 1 Bulan', '100GB, 1 Device, Support Bot Mode', 50000, 30, 107374182400),
('Premium 3 Bulan', '300GB, 3 Device, Priority Bot', 120000, 90, 322122547200),
('VIP 1 Tahun', 'Unlimited, 5 Device, Guaranteed Bot', 400000, 365, 999999999999)
ON DUPLICATE KEY UPDATE name=name;

-- Insert default server
INSERT INTO servers (name, location, country_code, ip, api_key, bot_server) VALUES
('Singapore Server', 'Singapore', 'SG', '127.0.0.1', '${NODE_API_KEY}', TRUE)
ON DUPLICATE KEY UPDATE name=name;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database dan tabel berhasil dibuat${NC}"
else
    echo -e "${RED}❌ Gagal membuat database${NC}"
    exit 1
fi
echo ""

# ==================== STEP 6: KONFIGURASI IPTABLES ====================
echo -e "${YELLOW}[6/12] 🔥 Mengkonfigurasi firewall (iptables)...${NC}"

# Install iptables-persistent
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

# ==================== STEP 7: BUAT BACKEND NODE.JS ====================
echo -e "${YELLOW}[7/12] ⚙️  Membuat backend Node.js...${NC}"

mkdir -p /var/www/vpn-panel/backend
cd /var/www/vpn-panel/backend

cat > package.json << 'EOF'
{
  "name": "vpn-panel-backend",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "jsonwebtoken": "^9.0.1",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5"
  }
}
EOF

npm install

cat > server.js << EOF
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

// Database connection
const db = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '${MYSQL_ROOT_PASSWORD}',
    database: 'vpn_panel',
    waitForConnections: true,
    connectionLimit: 10
});

// API Status
app.get('/api/status', (req, res) => {
    db.query('SELECT 1', (err) => {
        if (err) {
            res.json({ status: 'error', message: 'Database connection failed' });
        } else {
            res.json({ status: 'online', message: 'API is running' });
        }
    });
});

// Login
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    
    db.query('SELECT * FROM users WHERE username = ?', [username], (err, results) => {
        if (err || results.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const user = results[0];
        if (!bcrypt.compareSync(password, user.password)) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const token = jwt.sign(
            { id: user.id, username: user.username, role: user.role },
            '${JWT_SECRET}',
            { expiresIn: '7d' }
        );
        
        res.json({
            success: true,
            token,
            user: {
                id: user.id,
                username: user.username,
                email: user.email,
                full_name: user.full_name,
                role: user.role,
                balance: user.balance
            }
        });
    });
});

// Register
app.post('/api/register', (req, res) => {
    const { username, password, email, full_name } = req.body;
    
    // Check if username exists
    db.query('SELECT id FROM users WHERE username = ?', [username], (err, results) => {
        if (results.length > 0) {
            return res.status(400).json({ error: 'Username already exists' });
        }
        
        const hash = bcrypt.hashSync(password, 10);
        db.query(
            'INSERT INTO users (username, password, email, full_name, role, balance) VALUES (?, ?, ?, ?, ?, ?)',
            [username, hash, email || '', full_name || '', 'user', 0],
            (err) => {
                if (err) {
                    res.status(500).json({ error: 'Registration failed' });
                } else {
                    res.json({ success: true, message: 'Registration successful' });
                }
            }
        );
    });
});

// Get products
app.get('/api/products', (req, res) => {
    db.query('SELECT * FROM products ORDER BY price', (err, results) => {
        if (err) {
            res.status(500).json({ error: 'Database error' });
        } else {
            res.json(results);
        }
    });
});

// Get user profile
app.get('/api/user', authenticateToken, (req, res) => {
    db.query('SELECT id, username, email, full_name, role, balance FROM users WHERE id = ?', 
        [req.user.id], 
        (err, results) => {
            if (err || results.length === 0) {
                res.status(404).json({ error: 'User not found' });
            } else {
                res.json(results[0]);
            }
        }
    );
});

// Middleware authenticate token
function authenticateToken(req, res, next) {
    const token = req.headers['authorization']?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'No token provided' });
    
    jwt.verify(token, '${JWT_SECRET}', (err, user) => {
        if (err) return res.status(403).json({ error: 'Invalid token' });
        req.user = user;
        next();
    });
}

app.listen(3000, '127.0.0.1', () => {
    console.log('✅ Backend running on port 3000');
});
EOF

echo -e "${GREEN}✅ Backend Node.js selesai${NC}"
echo ""

# ==================== STEP 8: BUAT FRONTEND WEBSITE ====================
echo -e "${YELLOW}[8/12] 🎨 Membuat frontend website...${NC}"

mkdir -p /var/www/html

# File index.html (Home)
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RW MLBB VPN - Home</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%);
            color: white;
            font-family: 'Segoe UI', sans-serif;
        }
        .navbar {
            background: rgba(26, 31, 53, 0.95) !important;
            backdrop-filter: blur(10px);
            border-bottom: 1px solid rgba(255,77,77,0.2);
        }
        .navbar-brand, .nav-link {
            color: white !important;
        }
        .nav-link:hover {
            color: #ff4d4d !important;
        }
        .hero {
            text-align: center;
            padding: 100px 0;
        }
        .hero h1 {
            font-size: 3.5rem;
            background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 20px;
        }
        .card {
            background: rgba(26, 31, 53, 0.8);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,77,77,0.2);
            border-radius: 15px;
            color: white;
            padding: 30px;
            text-align: center;
            transition: transform 0.3s;
        }
        .card:hover {
            transform: translateY(-10px);
            border-color: #ff4d4d;
        }
        .btn-primary {
            background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
            border: none;
            padding: 12px 30px;
            border-radius: 10px;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(255,77,77,0.3);
        }
        .footer {
            text-align: center;
            padding: 30px;
            color: rgba(255,255,255,0.5);
            border-top: 1px solid rgba(255,77,77,0.2);
            margin-top: 50px;
        }
        .phpmyadmin-btn {
            position: fixed;
            bottom: 20px;
            right: 20px;
            z-index: 1000;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="/">
                <img src="https://img.icons8.com/color/48/000000/mobile-legends.png" width="30" height="30" class="d-inline-block align-top" alt="">
                RW MLBB VPN
            </a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item"><a class="nav-link" href="/">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="/features.html">Fitur</a></li>
                    <li class="nav-item"><a class="nav-link" href="/pricing.html">Harga</a></li>
                    <li class="nav-item"><a class="nav-link" href="/about.html">Tentang</a></li>
                    <li class="nav-item"><a class="nav-link" href="/login.html">Login</a></li>
                    <li class="nav-item"><a class="nav-link" href="/register.html">Daftar</a></li>
                    <li class="nav-item"><a class="nav-link" href="/phpmyadmin" target="_blank">phpMyAdmin</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container">
        <div class="hero">
            <h1>RW MLBB VPN PREMIUM</h1>
            <p class="lead">VPN Khusus Mobile Legends dengan Teknologi Bot Matchmaking</p>
            <a href="/register.html" class="btn btn-primary btn-lg mt-3">Daftar Sekarang</a>
        </div>

        <div class="row mt-5">
            <div class="col-md-4 mb-4">
                <div class="card">
                    <h3>🌏 Server Global</h3>
                    <p>Server di Singapore, Japan, India, USA dengan ping terbaik ke MLBB</p>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="card">
                    <h3>🎮 Bot Matchmaking</h3>
                    <p>Teknologi khusus untuk meningkatkan peluang bertemu lawan bot</p>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="card">
                    <h3>🔒 Keamanan Premium</h3>
                    <p>Enkripsi TLS 1.3, proteksi DDoS, dan kebijakan no-log</p>
                </div>
            </div>
        </div>
    </div>

    <a href="/phpmyadmin" class="phpmyadmin-btn btn btn-danger btn-lg" target="_blank">
        🗄️ phpMyAdmin
    </a>

    <footer class="footer">
        <p>&copy; 2026 RW MLBB VPN. All rights reserved.</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOF

# File features.html
cat > /var/www/html/features.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fitur - RW MLBB VPN</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%); color: white; }
        .navbar { background: rgba(26,31,53,0.95) !important; border-bottom: 1px solid rgba(255,77,77,0.2); }
        .navbar-brand, .nav-link { color: white !important; }
        .card { background: rgba(26,31,53,0.8); border: 1px solid rgba(255,77,77,0.2); border-radius: 15px; color: white; padding: 30px; margin-bottom: 20px; }
        .feature-icon { font-size: 3rem; margin-bottom: 20px; }
        .btn-primary { background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%); border: none; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="/">RW MLBB VPN</a>
            <div class="collapse navbar-collapse">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item"><a class="nav-link" href="/">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="/features.html">Fitur</a></li>
                    <li class="nav-item"><a class="nav-link" href="/pricing.html">Harga</a></li>
                    <li class="nav-item"><a class="nav-link" href="/about.html">Tentang</a></li>
                    <li class="nav-item"><a class="nav-link" href="/login.html">Login</a></li>
                    <li class="nav-item"><a class="nav-link" href="/register.html">Daftar</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-5">
        <h1 class="text-center mb-5">Fitur Premium RW MLBB VPN</h1>
        
        <div class="row">
            <div class="col-md-6">
                <div class="card">
                    <div class="feature-icon">🌏</div>
                    <h3>Multi Server Locations</h3>
                    <p>Singapore (30ms), Japan (45ms), India (60ms), USA (180ms), Europe (150ms)</p>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card">
                    <div class="feature-icon">🎮</div>
                    <h3>Bot Matchmaking Technology</h3>
                    <p>Algoritma khusus untuk meningkatkan peluang bertemu lawan bot di Mobile Legends</p>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card">
                    <div class="feature-icon">⚡</div>
                    <h3>Kecepatan Tinggi</h3>
                    <p>Koneksi dedicated dengan bandwidth besar untuk ping stabil dan no lag</p>
                </div>
            </div>
            <div class="col-md-6">
                <div class="card">
                    <div class="feature-icon">🔒</div>
                    <h3>Keamanan Kelas Atas</h3>
                    <p>Enkripsi TLS 1.3, proteksi DDoS, dan kebijakan no-log untuk privasi Anda</p>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF

# File pricing.html
cat > /var/www/html/pricing.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Harga - RW MLBB VPN</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%); color: white; }
        .navbar { background: rgba(26,31,53,0.95) !important; border-bottom: 1px solid rgba(255,77,77,0.2); }
        .card { background: rgba(26,31,53,0.8); border: 1px solid rgba(255,77,77,0.2); border-radius: 15px; color: white; padding: 30px; text-align: center; height: 100%; }
        .price { font-size: 2.5rem; color: #ff4d4d; font-weight: bold; }
        .btn-primary { background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%); border: none; width: 100%; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="/">RW MLBB VPN</a>
            <div class="collapse navbar-collapse">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item"><a class="nav-link" href="/">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="/features.html">Fitur</a></li>
                    <li class="nav-item"><a class="nav-link" href="/pricing.html">Harga</a></li>
                    <li class="nav-item"><a class="nav-link" href="/about.html">Tentang</a></li>
                    <li class="nav-item"><a class="nav-link" href="/login.html">Login</a></li>
                    <li class="nav-item"><a class="nav-link" href="/register.html">Daftar</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-5">
        <h1 class="text-center mb-5">Pilih Paket Langganan</h1>
        
        <div class="row">
            <div class="col-md-4 mb-4">
                <div class="card">
                    <h3>Basic</h3>
                    <div class="price">Rp 50.000</div>
                    <p class="text-muted">/bulan</p>
                    <hr>
                    <p>✓ 100 GB Traffic</p>
                    <p>✓ 1 Device</p>
                    <p>✓ Support Bot Mode</p>
                    <p>✓ Server Singapore</p>
                    <p>✓ Support 24/7</p>
                    <a href="/register.html" class="btn btn-primary mt-3">Pilih Paket</a>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="card">
                    <h3>Premium</h3>
                    <div class="price">Rp 120.000</div>
                    <p class="text-muted">/3 bulan</p>
                    <hr>
                    <p>✓ 300 GB Traffic</p>
                    <p>✓ 3 Device</p>
                    <p>✓ Bot Mode Priority</p>
                    <p>✓ Server Singapore + Japan</p>
                    <p>✓ Support 24/7 Priority</p>
                    <a href="/register.html" class="btn btn-primary mt-3">Pilih Paket</a>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="card">
                    <h3>VIP</h3>
                    <div class="price">Rp 400.000</div>
                    <p class="text-muted">/tahun</p>
                    <hr>
                    <p>✓ Unlimited Traffic</p>
                    <p>✓ 5 Device</p>
                    <p>✓ Bot Mode Guarantee</p>
                    <p>✓ All Server Locations</p>
                    <p>✓ Support VIP 24/7</p>
                    <a href="/register.html" class="btn btn-primary mt-3">Pilih Paket</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF

# File about.html
cat > /var/www/html/about.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tentang - RW MLBB VPN</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%); color: white; }
        .navbar { background: rgba(26,31,53,0.95) !important; border-bottom: 1px solid rgba(255,77,77,0.2); }
        .card { background: rgba(26,31,53,0.8); border: 1px solid rgba(255,77,77,0.2); border-radius: 15px; padding: 40px; margin-top: 50px; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="/">RW MLBB VPN</a>
            <div class="collapse navbar-collapse">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item"><a class="nav-link" href="/">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="/features.html">Fitur</a></li>
                    <li class="nav-item"><a class="nav-link" href="/pricing.html">Harga</a></li>
                    <li class="nav-item"><a class="nav-link" href="/about.html">Tentang</a></li>
                    <li class="nav-item"><a class="nav-link" href="/login.html">Login</a></li>
                    <li class="nav-item"><a class="nav-link" href="/register.html">Daftar</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container">
        <div class="card">
            <h1 class="text-center mb-4">Tentang RW MLBB VPN</h1>
            <p class="lead">RW MLBB VPN adalah layanan VPN premium yang dikhususkan untuk para pemain Mobile Legends. Kami menyediakan koneksi cepat dan stabil dengan server yang tersebar di berbagai lokasi strategis seperti Singapore, Japan, India, dan USA untuk memastikan ping terendah ke server MLBB.</p>
            
            <p>Dengan teknologi Bot Matchmaking kami, Anda memiliki peluang lebih besar untuk bertemu lawan bot, memudahkan Anda untuk push rank dan farming skin.</p>
            
            <p>Keamanan adalah prioritas kami. Semua koneksi dienkripsi dengan TLS 1.3 dan kami menerapkan kebijakan no-log untuk menjaga privasi Anda.</p>
            
            <p>Didukung oleh payment gateway Pakasir.com, Anda dapat melakukan pembayaran dengan mudah melalui QRIS, Virtual Account, atau PayPal.</p>
            
            <hr class="my-4">
            
            <h3>Kontak Kami</h3>
            <p>Email: support@rwmlbb.com</p>
            <p>Telegram: @rwmlbb_support</p>
            <p>WhatsApp: +62 123 4567 8910</p>
        </div>
    </div>
</body>
</html>
EOF

# File login.html
cat > /var/www/html/login.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - RW MLBB VPN</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%); color: white; min-height: 100vh; display: flex; align-items: center; }
        .login-card { background: rgba(26,31,53,0.8); border: 1px solid rgba(255,77,77,0.2); border-radius: 15px; padding: 40px; }
        .btn-primary { background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%); border: none; width: 100%; }
        .form-control { background: rgba(10,14,28,0.8); border: 1px solid rgba(255,77,77,0.3); color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-6">
                <div class="login-card">
                    <h2 class="text-center mb-4">Login</h2>
                    
                    <div id="errorMessage" class="alert alert-danger" style="display: none;"></div>
                    
                    <form id="loginForm">
                        <div class="mb-3">
                            <label>Username</label>
                            <input type="text" id="username" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label>Password</label>
                            <input type="password" id="password" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-primary">Login</button>
                    </form>
                    
                    <p class="text-center mt-3">
                        Belum punya akun? <a href="/register.html" style="color: #ff4d4d;">Daftar</a>
                    </p>
                    <p class="text-center text-muted">
                        Demo: admin / admin123
                    </p>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            try {
                const res = await fetch('/api/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, password })
                });
                
                const data = await res.json();
                
                if (data.success) {
                    localStorage.setItem('token', data.token);
                    localStorage.setItem('user', JSON.stringify(data.user));
                    window.location.href = '/dashboard.html';
                } else {
                    document.getElementById('errorMessage').style.display = 'block';
                    document.getElementById('errorMessage').textContent = data.error;
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

# File register.html
cat > /var/www/html/register.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Daftar - RW MLBB VPN</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%); color: white; min-height: 100vh; display: flex; align-items: center; }
        .register-card { background: rgba(26,31,53,0.8); border: 1px solid rgba(255,77,77,0.2); border-radius: 15px; padding: 40px; }
        .btn-primary { background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%); border: none; width: 100%; }
        .form-control { background: rgba(10,14,28,0.8); border: 1px solid rgba(255,77,77,0.3); color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-6">
                <div class="register-card">
                    <h2 class="text-center mb-4">Daftar Akun Baru</h2>
                    
                    <div id="errorMessage" class="alert alert-danger" style="display: none;"></div>
                    <div id="successMessage" class="alert alert-success" style="display: none;"></div>
                    
                    <form id="registerForm">
                        <div class="mb-3">
                            <label>Username</label>
                            <input type="text" id="username" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label>Email</label>
                            <input type="email" id="email" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label>Nama Lengkap</label>
                            <input type="text" id="fullName" class="form-control">
                        </div>
                        <div class="mb-3">
                            <label>Password</label>
                            <input type="password" id="password" class="form-control" required>
                        </div>
                        <div class="mb-3">
                            <label>Konfirmasi Password</label>
                            <input type="password" id="confirmPassword" class="form-control" required>
                        </div>
                        <button type="submit" class="btn btn-primary">Daftar</button>
                    </form>
                    
                    <p class="text-center mt-3">
                        Sudah punya akun? <a href="/login.html" style="color: #ff4d4d;">Login</a>
                    </p>
                </div>
            </div>
        </div>
    </div>

    <script>
        document.getElementById('registerForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const password = document.getElementById('password').value;
            const confirm = document.getElementById('confirmPassword').value;
            
            if (password !== confirm) {
                document.getElementById('errorMessage').style.display = 'block';
                document.getElementById('errorMessage').textContent = 'Password tidak cocok';
                return;
            }
            
            const data = {
                username: document.getElementById('username').value,
                email: document.getElementById('email').value,
                full_name: document.getElementById('fullName').value,
                password: password
            };
            
            try {
                const res = await fetch('/api/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(data)
                });
                
                const result = await res.json();
                
                if (result.success) {
                    document.getElementById('successMessage').style.display = 'block';
                    document.getElementById('successMessage').textContent = 'Registrasi berhasil! Mengalihkan ke login...';
                    setTimeout(() => {
                        window.location.href = '/login.html';
                    }, 2000);
                } else {
                    document.getElementById('errorMessage').style.display = 'block';
                    document.getElementById('errorMessage').textContent = result.error;
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

# File dashboard.html
cat > /var/www/html/dashboard.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - RW MLBB VPN</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%); color: white; }
        .navbar { background: rgba(26,31,53,0.95) !important; border-bottom: 1px solid rgba(255,77,77,0.2); }
        .card { background: rgba(26,31,53,0.8); border: 1px solid rgba(255,77,77,0.2); border-radius: 15px; color: white; padding: 20px; margin-bottom: 20px; }
        .btn-logout { background: #f44336; border: none; }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="/">RW MLBB VPN</a>
            <div class="collapse navbar-collapse">
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item"><a class="nav-link" href="/">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="/dashboard.html">Dashboard</a></li>
                    <li class="nav-item"><a class="nav-link" href="#" id="logoutBtn">Logout</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container mt-5">
        <h2>Dashboard</h2>
        <div id="userInfo" class="card">
            <p>Loading...</p>
        </div>
    </div>

    <script>
        const token = localStorage.getItem('token');
        if (!token) {
            window.location.href = '/login.html';
        }

        // Fetch user data
        fetch('/api/user', {
            headers: { 'Authorization': `Bearer ${token}` }
        })
        .then(res => res.json())
        .then(user => {
            document.getElementById('userInfo').innerHTML = `
                <h3>Welcome, ${user.full_name || user.username}!</h3>
                <p>Username: ${user.username}</p>
                <p>Email: ${user.email}</p>
                <p>Role: ${user.role}</p>
                <p>Balance: Rp ${new Intl.NumberFormat('id-ID').format(user.balance)}</p>
            `;
        });

        document.getElementById('logoutBtn').addEventListener('click', (e) => {
            e.preventDefault();
            localStorage.removeItem('token');
            localStorage.removeItem('user');
            window.location.href = '/';
        });
    </script>
</body>
</html>
EOF

# File info.php
cat > /var/www/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

# File database status
cat > /var/www/html/db-status.php << 'EOF'
<?php
$host = 'localhost';
$user = 'root';
$pass = 'root123';
$db = 'vpn_panel';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("❌ Database connection failed: " . $conn->connect_error);
}

echo "✅ Database connected successfully<br>";
echo "Server: " . $conn->server_info . "<br>";
echo "Database: $db<br>";

$result = $conn->query("SHOW TABLES");
echo "<h3>Tables:</h3>";
echo "<ul>";
while($row = $result->fetch_array()) {
    echo "<li>" . $row[0] . "</li>";
}
echo "</ul>";

$conn->close();
?>
EOF

# Set permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo -e "${GREEN}✅ Frontend website selesai${NC}"
echo ""

# ==================== STEP 9: KONFIGURASI APACHE ====================
echo -e "${YELLOW}[9/12] 🌐 Mengkonfigurasi Apache...${NC}"

cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Konfigurasi phpMyAdmin
cat > /etc/apache2/conf-available/phpmyadmin.conf << EOF
Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options SymLinksIfOwnerMatch
    DirectoryIndex index.php
    Require all granted
</Directory>
EOF

a2enconf phpmyadmin
systemctl restart apache2

echo -e "${GREEN}✅ Apache terkonfigurasi${NC}"
echo ""

# ==================== STEP 10: BUAT SYSTEMD SERVICE ====================
echo -e "${YELLOW}[10/12] ⚙️  Membuat systemd service...${NC}"

cat > /etc/systemd/system/vpn-panel-backend.service << EOF
[Unit]
Description=RW MLBB VPN Panel Backend
After=network.target mysql.service
Wants=mysql.service

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

echo -e "${GREEN}✅ Systemd service dibuat${NC}"
echo ""

# ==================== STEP 11: KONFIGURASI REDIS ====================
echo -e "${YELLOW}[11/12] ⚡ Mengkonfigurasi Redis...${NC}"
systemctl restart redis-server
echo -e "${GREEN}✅ Redis terkonfigurasi${NC}"
echo ""

# ==================== STEP 12: BUAT NODE INSTALLER ====================
echo -e "${YELLOW}[12/12] 📦 Membuat node installer script...${NC}"

cat > /var/www/html/install-node.sh << EOF
#!/bin/bash
# Node Installer untuk RW MLBB VPN

echo "🚀 Node Installer untuk RW MLBB VPN"
echo "===================================="

NODE_API_KEY="${NODE_API_KEY}"
PANEL_URL="http://${IP_VPS}"

read -p "Node Name: " NODE_NAME
read -p "Location: " LOCATION
read -p "Country Code: " COUNTRY_CODE
read -p "Bot Server? (y/n): " IS_BOT

apt update
apt install -y curl nodejs npm

curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash

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
        users: 0
    });
});

app.listen(8081, () => console.log('✅ Node controller running'));
NODEEOF

npm init -y
npm install express

cat > /etc/systemd/system/vpn-node.service << SERVICEEOF
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
SERVICEEOF

systemctl daemon-reload
systemctl enable vpn-node
systemctl start vpn-node

curl -X POST ${PANEL_URL}/api/servers/add \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${NODE_NAME}\",\"location\":\"${LOCATION}\",\"countryCode\":\"${COUNTRY_CODE}\",\"ip\":\"$(curl -s ifconfig.me)\",\"apiKey\":\"${NODE_API_KEY}\",\"botServer\":${IS_BOT}}"

echo "✅ Node installed successfully!"
EOF

chmod +x /var/www/html/install-node.sh

echo -e "${GREEN}✅ Node installer script dibuat${NC}"
echo ""

# ==================== SELESAI ====================
clear
echo -e "${PURPLE}"
echo "    ╔═══════════════════════════════════════════════════════════════╗"
echo "    ║                                                               ║"
echo "    ║              ✨ INSTALASI SELESAI! ✨                         ║"
echo "    ║                                                               ║"
echo "    ║         RW MLBB VPN PANEL - MYSQL EDITION                    ║"
echo "    ║         DENGAN PHPMYADMIN OTOMATIS                           ║"
echo "    ║                                                               ║"
echo "    ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📋 INFORMASI AKSES 📋                         ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "🌐 ${WHITE}Website Panel:${NC}     ${CYAN}http://${IP_VPS}${NC}"
echo -e "🗄️  ${WHITE}phpMyAdmin:${NC}        ${CYAN}http://${IP_VPS}/phpmyadmin${NC}"
echo -e "ℹ️  ${WHITE}PHP Info:${NC}          ${CYAN}http://${IP_VPS}/info.php${NC}"
echo -e "📊 ${WHITE}DB Status:${NC}         ${CYAN}http://${IP_VPS}/db-status.php${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🔑 LOGIN DATABASE (phpMyAdmin) 🔑             ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "👤 ${WHITE}Username:${NC} ${YELLOW}root${NC}"
echo -e "🔑 ${WHITE}Password:${NC} ${YELLOW}${MYSQL_ROOT_PASSWORD}${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              👤 LOGIN ADMIN PANEL 👤                        ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "👤 ${WHITE}Username:${NC} ${YELLOW}admin${NC}"
echo -e "🔑 ${WHITE}Password:${NC} ${YELLOW}admin123${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📦 INFORMASI DATABASE 📦                       ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "🗄️  ${WHITE}Database:${NC} ${YELLOW}vpn_panel${NC}"
echo -e "👤 ${WHITE}DB User:${NC}  ${YELLOW}vpn_user${NC}"
echo -e "🔑 ${WHITE}DB Pass:${NC}  ${YELLOW}${DB_PASSWORD}${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🚀 HALAMAN TERSEDIA 🚀                          ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   🏠 Home        : http://${IP_VPS}/"
echo "   🔐 Login       : http://${IP_VPS}/login.html"
echo "   📝 Register    : http://${IP_VPS}/register.html"
echo "   📊 Dashboard   : http://${IP_VPS}/dashboard.html"
echo "   ⭐ Features    : http://${IP_VPS}/features.html"
echo "   💰 Pricing     : http://${IP_VPS}/pricing.html"
echo "   ℹ️  About      : http://${IP_VPS}/about.html"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📦 NODE INSTALLER 📦                           ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   Untuk install node server, jalankan di VPS node:"
echo -e "   ${YELLOW}curl -s http://${IP_VPS}/install-node.sh | bash${NC}"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}      🎮 TERIMA KASIH - SELAMAT BERTANDING! 🎮              ${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"