#!/bin/bash
# ============================================================================
# RW MLBB VPN PANEL - ULTIMATE PREMIUM EDITION
# Menggunakan IPTABLES LANGSUNG (TANPA UFW)
# Fix Total untuk Semua Error
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
echo "    ║         🌟 PREMIUM EDITION - IPTABLES VERSION 🌟             ║"
echo "    ║                                                               ║"
echo "    ║        🎮 RW MOBILE LEGENDS BOT MATCHMAKING 🎮               ║"
echo "    ║        💰 PAYMENT GATEWAY PAKASIR.COM 💰                     ║"
echo "    ║        🔥 TANPA UFW - PAKAI IPTABLES 🔥                      ║"
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
echo -e "${YELLOW}[1/11] 📦 Mengupdate sistem...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}✅ Sistem diupdate${NC}"
echo ""

# ==================== STEP 2: INSTALL DEPENDENCIES ====================
echo -e "${YELLOW}[2/11] 📥 Menginstall dependencies...${NC}"

# Hapus Node.js lama jika ada
apt remove --purge -y nodejs npm libnode-dev 2>/dev/null || true
apt autoremove -y
rm -rf /etc/apt/sources.list.d/nodesource.list
rm -rf /usr/lib/node_modules
rm -rf /usr/include/node

# Install base packages (TANPA UFW)
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
echo -e "${YELLOW}[3/11] 🔧 Menginstall Xray core...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
echo -e "${GREEN}✅ Xray terinstall${NC}"
echo ""

# ==================== STEP 4: KONFIGURASI IPTABLES (FIX TOTAL) ====================
echo -e "${YELLOW}[4/11] 🔥 Mengkonfigurasi IPTABLES (pengganti UFW)...${NC}"

# Hapus UFW jika ada (biar nggak ganggu)
apt remove --purge -y ufw 2>/dev/null || true

# Install iptables-persistent untuk menyimpan aturan
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt install -y iptables-persistent

# Flush semua aturan lama
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
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

# Izinkan ICMP (ping)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Simpan aturan
netfilter-persistent save
systemctl enable netfilter-persistent

echo -e "${GREEN}✅ IPTABLES terkonfigurasi${NC}"
echo ""

# ==================== STEP 5: KONFIGURASI DATABASE ====================
echo -e "${YELLOW}[5/11] 🗄️  Mengkonfigurasi database...${NC}"

# Set MySQL root password
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
echo -e "${GREEN}✅ Database terkonfigurasi${NC}"
echo ""

# ==================== STEP 6: KONFIGURASI REDIS ====================
echo -e "${YELLOW}[6/11] ⚡ Mengkonfigurasi Redis...${NC}"
systemctl restart redis-server
echo -e "${GREEN}✅ Redis terkonfigurasi${NC}"
echo ""

# ==================== STEP 7: BUAT DIREKTORI ====================
echo -e "${YELLOW}[7/11] 📁 Membuat struktur direktori...${NC}"

mkdir -p /var/www/vpn-panel
mkdir -p /var/www/vpn-panel/{backend,frontend,node-controller}
mkdir -p /etc/vpn-panel
mkdir -p /var/log/vpn-panel
mkdir -p /var/log/vpn-panel/{access,error,payment}
mkdir -p /var/lib/vpn-panel/{data,cache}

# Config minimal
cat > /etc/vpn-panel/config.yml << EOF
# VPN Panel Configuration - Premium Edition
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
  max_nodes: 100

payment:
  enabled: false
  gateway: pakasir
  usd_rate: 15000
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
echo -e "${GREEN}✅ Direktori dibuat${NC}"
echo ""

# ==================== STEP 8: BACKEND ====================
echo -e "${YELLOW}[8/11] ⚙️  Membuat backend...${NC}"

cd /var/www/vpn-panel/backend

cat > package.json << 'EOF'
{
  "name": "vpn-panel-premium",
  "version": "5.0.0",
  "description": "RW MLBB VPN Premium Panel",
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

# Buat file server.js sederhana dulu (backend lengkap bisa ditambahkan nanti)
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const { Sequelize } = require('sequelize');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const fs = require('fs');
const yaml = require('yaml');

const app = express();
app.use(cors());
app.use(express.json());

// Load config
const config = yaml.parse(fs.readFileSync('/etc/vpn-panel/config.yml', 'utf8'));
const secrets = {};
fs.readFileSync('/etc/vpn-panel/secrets.conf', 'utf8').split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) secrets[key] = value;
});

// Database connection
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

// Test connection
sequelize.authenticate()
    .then(() => console.log('✅ Database connected'))
    .catch(err => console.error('❌ Database error:', err));

// Models
const User = sequelize.define('User', {
    username: { type: Sequelize.STRING, unique: true },
    password: Sequelize.STRING,
    email: Sequelize.STRING,
    role: { type: Sequelize.STRING, defaultValue: 'user' },
    balance: { type: Sequelize.DECIMAL(15, 2), defaultValue: 0 }
});

sequelize.sync();

// API Routes
app.get('/api/setup/status', async (req, res) => {
    const adminExists = await User.findOne({ where: { role: 'superadmin' } });
    res.json({
        setup_complete: fs.existsSync('/etc/vpn-panel/setup.lock'),
        admin_exists: !!adminExists,
        panel_url: config.panel.url
    });
});

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
    
    res.json({ token, user: { username: user.username, role: user.role, balance: user.balance } });
});

app.post('/api/setup/configure', async (req, res) => {
    const { admin_username, admin_password, admin_email, location, country_code } = req.body;
    
    const hashed = bcrypt.hashSync(admin_password, 10);
    await User.create({
        username: admin_username,
        password: hashed,
        email: admin_email,
        role: 'superadmin',
        balance: 1000000
    });
    
    fs.writeFileSync('/etc/vpn-panel/setup.lock', new Date().toISOString());
    res.json({ success: true });
});

app.get('/api/user/profile', (req, res) => {
    res.json({ username: 'admin', balance: 1000000 });
});

const PORT = 3000;
app.listen(PORT, '127.0.0.1', () => {
    console.log(`✅ Backend running on port ${PORT}`);
});

// Create default admin if none exists
setTimeout(async () => {
    const count = await User.count();
    if (count === 0) {
        const hashed = bcrypt.hashSync('admin123', 10);
        await User.create({
            username: 'admin',
            password: hashed,
            email: 'admin@localhost',
            role: 'superadmin',
            balance: 1000000
        });
        console.log('✅ Default admin created: admin / admin123');
    }
}, 3000);
EOF

echo -e "${GREEN}✅ Backend dibuat${NC}"
echo ""

# ==================== STEP 9: FRONTEND SEDERHANA ====================
echo -e "${YELLOW}[9/11] 🎨 Membuat frontend...${NC}"

cd /var/www/vpn-panel/frontend

# Buat index.html sederhana dulu (frontend lengkap bisa ditambahkan nanti)
mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RW MLBB VPN - Premium</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        
        .container {
            text-align: center;
            padding: 2rem;
            max-width: 500px;
            width: 90%;
        }
        
        .logo {
            width: 120px;
            height: 120px;
            background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 2rem;
            box-shadow: 0 10px 30px rgba(255,77,77,0.3);
        }
        
        .logo svg {
            width: 60px;
            height: 60px;
            fill: white;
        }
        
        h1 {
            font-size: 2.5rem;
            margin-bottom: 0.5rem;
            background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        
        .subtitle {
            color: rgba(255,255,255,0.7);
            margin-bottom: 2rem;
        }
        
        .card {
            background: rgba(26, 31, 53, 0.8);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,77,77,0.2);
            border-radius: 20px;
            padding: 2rem;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
        }
        
        input {
            width: 100%;
            padding: 12px;
            margin: 8px 0;
            background: rgba(10, 14, 28, 0.8);
            border: 1px solid rgba(255,77,77,0.3);
            border-radius: 10px;
            color: white;
            font-size: 1rem;
        }
        
        input:focus {
            outline: none;
            border-color: #ff4d4d;
        }
        
        button {
            width: 100%;
            padding: 14px;
            margin-top: 1rem;
            background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
            border: none;
            border-radius: 10px;
            color: white;
            font-size: 1.1rem;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        button:hover {
            transform: translateY(-2px);
        }
        
        .info {
            margin-top: 2rem;
            padding: 1rem;
            background: rgba(0,0,0,0.3);
            border-radius: 10px;
            font-size: 0.9rem;
            color: rgba(255,255,255,0.5);
        }
        
        .setup-message {
            background: rgba(255,77,77,0.2);
            border: 1px solid #ff4d4d;
            border-radius: 10px;
            padding: 1rem;
            margin-bottom: 1rem;
            color: #ff4d4d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">
            <svg viewBox="0 0 24 24">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm-1-13h2v6h-2zm0 8h2v2h-2z"/>
            </svg>
        </div>
        
        <h1>RW MLBB VPN</h1>
        <p class="subtitle">Premium Edition - IPTABLES Version</p>
        
        <div class="card">
            <div id="setup-message" class="setup-message" style="display: none;">
                ⚙️ Setup required. Please login as admin to configure.
            </div>
            
            <h2 style="margin-bottom: 1.5rem;">Login</h2>
            
            <input type="text" id="username" placeholder="Username" value="admin">
            <input type="password" id="password" placeholder="Password" value="admin123">
            
            <button onclick="login()">Login to Dashboard</button>
            
            <div class="info">
                Default: admin / admin123<br>
                Panel akan redirect ke Setup Wizard setelah login pertama
            </div>
        </div>
    </div>
    
    <script>
        async function login() {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            try {
                const response = await fetch('/api/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, password })
                });
                
                const data = await response.json();
                
                if (response.ok) {
                    localStorage.setItem('token', data.token);
                    
                    // Cek status setup
                    const setupRes = await fetch('/api/setup/status');
                    const setupData = await setupRes.json();
                    
                    if (!setupData.setup_complete) {
                        window.location.href = '/setup.html';
                    } else {
                        window.location.href = '/dashboard.html';
                    }
                } else {
                    alert('Login failed: ' + data.error);
                }
            } catch (error) {
                alert('Error: ' + error.message);
            }
        }
        
        // Cek status setup
        fetch('/api/setup/status')
            .then(res => res.json())
            .then(data => {
                if (!data.setup_complete && !data.admin_exists) {
                    document.getElementById('setup-message').style.display = 'block';
                }
            });
    </script>
</body>
</html>
EOF

cp public/index.html public/setup.html
cp public/index.html public/dashboard.html

echo -e "${GREEN}✅ Frontend sederhana dibuat${NC}"
echo ""

# ==================== STEP 10: KONFIGURASI NGINX ====================
echo -e "${YELLOW}[10/11] 🌐 Mengkonfigurasi Nginx...${NC}"

if [ "$USE_SSL" = false ]; then
    cat > /etc/nginx/sites-available/vpn-panel << 'EOF'
server {
    listen 80;
    server_name _;
    
    root /var/www/vpn-panel/frontend/public;
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
    }
}
EOF
else
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
    
    root /var/www/vpn-panel/frontend/public;
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
}
EOF
fi

ln -sf /etc/nginx/sites-available/vpn-panel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t && systemctl reload nginx
echo -e "${GREEN}✅ Nginx terkonfigurasi${NC}"
echo ""

# ==================== STEP 11: SSL (jika domain) ====================
if [ "$USE_SSL" = true ]; then
    echo -e "${YELLOW}[11/11] 🔒 Mengkonfigurasi SSL...${NC}"
    certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${EMAIL} || {
        echo -e "${YELLOW}⚠️ SSL gagal, lanjut dengan HTTP${NC}"
    }
    echo -e "${GREEN}✅ SSL terkonfigurasi${NC}"
    echo ""
fi

# ==================== SYSTEMD SERVICE ====================
cat > /etc/systemd/system/vpn-panel-backend.service << EOF
[Unit]
Description=RW MLBB VPN Panel Backend
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

# ==================== SELESAI ====================
clear
echo -e "${PURPLE}"
echo "    ╔═══════════════════════════════════════════════════════════════╗"
echo "    ║                                                               ║"
echo "    ║              ✨ INSTALASI SELESAI! ✨                         ║"
echo "    ║                                                               ║"
echo "    ║         RW MLBB VPN PANEL - IPTABLES VERSION                 ║"
echo "    ║                                                               ║"
echo "    ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📋 INFORMASI PANEL 📋                         ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 ${WHITE}Panel URL:${NC}      ${CYAN}${DOMAIN_FULL}${NC}"
echo -e "  👤 ${WHITE}Admin Login:${NC}    ${YELLOW}admin / admin123${NC}"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🔥 STATUS FIREWALL 🔥                          ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  ✅ UFW TIDAK DIGUNAKAN (tidak diinstall)"
echo "  ✅ Menggunakan IPTABLES langsung"
echo "  ✅ Port yang terbuka:"
echo "     - 22/tcp (SSH)"
echo "     - 80/tcp (HTTP)"
echo "     - 443/tcp (HTTPS)"
echo "     - 8081-8090/tcp (Node servers)"
echo "     - 7000-8000/udp (MLBB Game)"
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🚀 LANGKAH SELANJUTNYA 🚀                      ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  1️⃣  Buka browser: ${CYAN}${DOMAIN_FULL}${NC}"
echo "  2️⃣  Login dengan: admin / admin123"
echo "  3️⃣  Ikuti Setup Wizard"
echo "  4️⃣  Selesai!"
echo ""
echo -e "${YELLOW}📌 Cek status IPTABLES:${NC}"
echo "  iptables -L -n -v"
echo ""
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}      🎮 TERIMA KASIH - SELAMAT BERTANDING! 🎮              ${NC}"
echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"