#!/bin/bash
# ============================================================================
# RW MLBB VPN PANEL - ULTIMATE ENTERPRISE EDITION
# Dengan Multi Role (Admin, Reseller, User) + Fitur Super Lengkap
# Support: Payment Gateway, Bot Matchmaking, Reseller System
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
echo "    ║         🌟 ENTERPRISE EDITION - MULTI ROLE SYSTEM 🌟                  ║"
echo "    ║         👑 ADMIN | 💼 RESELLER | 👤 USER                             ║"
echo "    ║                                                                       ║"
echo "    ║         🎮 RW MOBILE LEGENDS BOT MATCHMAKING                         ║"
echo "    ║         💰 PAYMENT GATEWAY PAKASIR.COM                               ║"
echo "    ║         📊 FULL RESELLER MANAGEMENT                                  ║"
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
echo -e "${GREEN}              🚀 MEMULAI INSTALASI ENTERPRISE 🚀                        ${NC}"
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

-- ==================== TABEL USERS (MULTI ROLE) ====================
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

-- ==================== TABEL RESELLER PACKAGES ====================
CREATE TABLE IF NOT EXISTS reseller_packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(15,2) NOT NULL,
    max_resellers INT DEFAULT 0,
    max_users INT DEFAULT 0,
    commission_rate DECIMAL(5,2) DEFAULT 0.00,
    duration_days INT DEFAULT 30,
    features TEXT,
    status BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ==================== TABEL RESELLER SUBSCRIPTIONS ====================
CREATE TABLE IF NOT EXISTS reseller_subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reseller_id INT NOT NULL,
    package_id INT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    price_paid DECIMAL(15,2) NOT NULL,
    status ENUM('active', 'expired', 'cancelled') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (reseller_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (package_id) REFERENCES reseller_packages(id) ON DELETE CASCADE
);

-- ==================== TABEL USER SUBSCRIPTIONS ====================
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    reseller_id INT,
    package_name VARCHAR(100) NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    traffic_limit BIGINT DEFAULT 107374182400,
    traffic_used BIGINT DEFAULT 0,
    device_limit INT DEFAULT 1,
    connection_limit INT DEFAULT 1,
    protocol VARCHAR(50) DEFAULT 'vless',
    server_location VARCHAR(100),
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    auto_renew BOOLEAN DEFAULT FALSE,
    status ENUM('active', 'expired', 'cancelled', 'pending') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reseller_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ==================== TABEL SERVERS ====================
CREATE TABLE IF NOT EXISTS servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    country_code VARCHAR(2),
    city VARCHAR(100),
    ip VARCHAR(45) NOT NULL,
    ipv6 VARCHAR(45),
    domain VARCHAR(255),
    port INT DEFAULT 443,
    api_port INT DEFAULT 8081,
    api_key VARCHAR(255) NOT NULL,
    bandwidth_limit BIGINT DEFAULT 0,
    bandwidth_used BIGINT DEFAULT 0,
    max_users INT DEFAULT 1000,
    current_users INT DEFAULT 0,
    cpu_limit INT DEFAULT 100,
    ram_limit BIGINT DEFAULT 0,
    disk_limit BIGINT DEFAULT 0,
    status ENUM('active', 'inactive', 'maintenance', 'error') DEFAULT 'active',
    server_type ENUM('vpn', 'bot', 'mixed') DEFAULT 'mixed',
    is_bot_server BOOLEAN DEFAULT FALSE,
    priority INT DEFAULT 0,
    tags TEXT,
    notes TEXT,
    last_ping DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ==================== TABEL VPN ACCOUNTS ====================
CREATE TABLE IF NOT EXISTS vpn_accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    uuid VARCHAR(36) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    subscription_id INT,
    server_id INT NOT NULL,
    name VARCHAR(100),
    protocol ENUM('vmess', 'vless', 'trojan', 'shadowsocks', 'wireguard', 'openvpn') NOT NULL,
    port INT NOT NULL,
    password VARCHAR(255),
    encryption VARCHAR(50) DEFAULT 'aes-256-gcm',
    network VARCHAR(50) DEFAULT 'ws',
    security VARCHAR(50) DEFAULT 'tls',
    path VARCHAR(255),
    host VARCHAR(255),
    sni VARCHAR(255),
    fingerprint VARCHAR(50) DEFAULT 'random',
    public_key TEXT,
    private_key TEXT,
    pre_shared_key TEXT,
    allowed_ips VARCHAR(255) DEFAULT '0.0.0.0/0',
    dns VARCHAR(255) DEFAULT '1.1.1.1',
    mtu INT DEFAULT 1420,
    traffic_limit BIGINT DEFAULT 0,
    traffic_used BIGINT DEFAULT 0,
    traffic_upload BIGINT DEFAULT 0,
    traffic_download BIGINT DEFAULT 0,
    connection_limit INT DEFAULT 3,
    device_limit INT DEFAULT 2,
    ip_limit INT DEFAULT 1,
    speed_limit INT DEFAULT 0,
    expired_at DATETIME NOT NULL,
    last_used DATETIME,
    last_ip VARCHAR(45),
    active BOOLEAN DEFAULT TRUE,
    bot_enabled BOOLEAN DEFAULT FALSE,
    mlbb_optimized BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES user_subscriptions(id) ON DELETE SET NULL,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);

-- ==================== TABEL TRAFFIC LOGS ====================
CREATE TABLE IF NOT EXISTS traffic_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    user_id INT NOT NULL,
    server_id INT NOT NULL,
    upload BIGINT DEFAULT 0,
    download BIGINT DEFAULT 0,
    total BIGINT DEFAULT 0,
    ip_address VARCHAR(45),
    country VARCHAR(2),
    device VARCHAR(100),
    protocol VARCHAR(20),
    date DATE NOT NULL,
    hour INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_date (date),
    INDEX idx_account (account_id),
    FOREIGN KEY (account_id) REFERENCES vpn_accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);

-- ==================== TABEL TRANSACTIONS ====================
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_no VARCHAR(50) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    reseller_id INT,
    type ENUM('deposit', 'withdrawal', 'purchase', 'commission', 'refund') NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    fee DECIMAL(15,2) DEFAULT 0.00,
    total DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'IDR',
    payment_method VARCHAR(50),
    payment_provider VARCHAR(50),
    payment_details TEXT,
    status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    description TEXT,
    notes TEXT,
    invoice_id VARCHAR(100),
    pakasir_order_id VARCHAR(100),
    pakasir_response TEXT,
    approved_by INT,
    approved_at DATETIME,
    completed_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reseller_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ==================== TABEL WITHDRAWALS ====================
CREATE TABLE IF NOT EXISTS withdrawals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    fee DECIMAL(15,2) DEFAULT 0.00,
    total DECIMAL(15,2) NOT NULL,
    bank_name VARCHAR(100),
    account_number VARCHAR(50),
    account_name VARCHAR(100),
    method ENUM('bank_transfer', 'ovo', 'gopay', 'dana', 'paypal') NOT NULL,
    status ENUM('pending', 'processing', 'completed', 'rejected') DEFAULT 'pending',
    notes TEXT,
    admin_notes TEXT,
    processed_by INT,
    processed_at DATETIME,
    completed_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (processed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ==================== TABEL PRODUCTS ====================
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    short_description VARCHAR(255),
    price DECIMAL(15,2) NOT NULL,
    price_usd DECIMAL(10,2),
    duration_days INT DEFAULT 30,
    traffic_limit BIGINT DEFAULT 107374182400,
    device_limit INT DEFAULT 1,
    connection_limit INT DEFAULT 1,
    protocol VARCHAR(50) DEFAULT 'vless',
    server_locations TEXT,
    bot_enabled BOOLEAN DEFAULT FALSE,
    priority INT DEFAULT 0,
    featured BOOLEAN DEFAULT FALSE,
    popular BOOLEAN DEFAULT FALSE,
    stock INT DEFAULT -1,
    max_purchase INT DEFAULT 0,
    category VARCHAR(50),
    tags TEXT,
    image VARCHAR(255),
    status BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ==================== TABEL INVOICES ====================
CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(50) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    reseller_id INT,
    subscription_id INT,
    transaction_id INT,
    type ENUM('subscription', 'deposit', 'withdrawal', 'commission') NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    tax DECIMAL(15,2) DEFAULT 0.00,
    discount DECIMAL(15,2) DEFAULT 0.00,
    total DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'IDR',
    status ENUM('draft', 'pending', 'paid', 'unpaid', 'cancelled', 'refunded') DEFAULT 'pending',
    due_date DATE,
    paid_at DATETIME,
    payment_method VARCHAR(50),
    payment_details TEXT,
    notes TEXT,
    pdf_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (reseller_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (subscription_id) REFERENCES user_subscriptions(id) ON DELETE SET NULL,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE SET NULL
);

-- ==================== TABEL TICKETS (SUPPORT) ====================
CREATE TABLE IF NOT EXISTS tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_no VARCHAR(20) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    assigned_to INT,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    category VARCHAR(50),
    status ENUM('open', 'in_progress', 'waiting', 'resolved', 'closed') DEFAULT 'open',
    last_reply_at DATETIME,
    last_reply_by INT,
    closed_by INT,
    closed_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (last_reply_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (closed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ==================== TABEL TICKET REPLIES ====================
CREATE TABLE IF NOT EXISTS ticket_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    attachments TEXT,
    is_staff BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ==================== TABEL ANNOUNCEMENTS ====================
CREATE TABLE IF NOT EXISTS announcements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content TEXT NOT NULL,
    excerpt VARCHAR(500),
    image VARCHAR(255),
    type ENUM('info', 'warning', 'success', 'danger', 'maintenance') DEFAULT 'info',
    target ENUM('all', 'users', 'resellers', 'admins') DEFAULT 'all',
    priority INT DEFAULT 0,
    pinned BOOLEAN DEFAULT FALSE,
    start_date DATETIME,
    end_date DATETIME,
    created_by INT NOT NULL,
    status BOOLEAN DEFAULT TRUE,
    views INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- ==================== TABEL SETTINGS ====================
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

-- ==================== TABEL PAGES ====================
CREATE TABLE IF NOT EXISTS pages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content LONGTEXT,
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    template VARCHAR(100) DEFAULT 'default',
    status BOOLEAN DEFAULT TRUE,
    published_at DATETIME,
    created_by INT NOT NULL,
    updated_by INT,
    views INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ==================== TABEL BLOG POSTS ====================
CREATE TABLE IF NOT EXISTS blog_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    content LONGTEXT,
    excerpt VARCHAR(500),
    featured_image VARCHAR(255),
    category VARCHAR(100),
    tags TEXT,
    author_id INT NOT NULL,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    published_at DATETIME,
    views INT DEFAULT 0,
    allow_comments BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ==================== TABEL BOT MATCHES ====================
CREATE TABLE IF NOT EXISTS bot_matches (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    account_id INT NOT NULL,
    server_id INT,
    match_id VARCHAR(100),
    match_type ENUM('ranked', 'classic', 'brawl') DEFAULT 'ranked',
    result ENUM('win', 'lose', 'draw') NOT NULL,
    duration INT,
    kills INT DEFAULT 0,
    deaths INT DEFAULT 0,
    assists INT DEFAULT 0,
    mvp BOOLEAN DEFAULT FALSE,
    hero_played VARCHAR(50),
    hero_role VARCHAR(50),
    rank_before VARCHAR(20),
    rank_after VARCHAR(20),
    rank_points INT DEFAULT 0,
    bot_difficulty ENUM('easy', 'medium', 'hard'),
    bots_detected INT DEFAULT 5,
    match_date DATE NOT NULL,
    match_time TIME,
    ip_address VARCHAR(45),
    country VARCHAR(2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (account_id) REFERENCES vpn_accounts(id) ON DELETE CASCADE,
    FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE SET NULL
);

-- ==================== TABEL ACTIVITY LOGS ====================
CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device VARCHAR(100),
    browser VARCHAR(100),
    os VARCHAR(100),
    location VARCHAR(100),
    referer TEXT,
    duration_ms INT,
    status VARCHAR(20),
    data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_action (action),
    INDEX idx_created (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ==================== TABEL NOTIFICATIONS ====================
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ==================== TABEL COUPONS ====================
CREATE TABLE IF NOT EXISTS coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    discount_type ENUM('percentage', 'fixed') NOT NULL,
    discount_value DECIMAL(15,2) NOT NULL,
    min_purchase DECIMAL(15,2) DEFAULT 0.00,
    max_discount DECIMAL(15,2),
    usage_limit INT DEFAULT 1,
    used_count INT DEFAULT 0,
    per_user_limit INT DEFAULT 1,
    applicable_products TEXT,
    applicable_categories TEXT,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    status BOOLEAN DEFAULT TRUE,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- ==================== INSERT DEFAULT DATA ====================

-- Insert default admin (password: admin123)
INSERT INTO users (uuid, username, password, email, full_name, role, balance) 
SELECT UUID(), 'admin', '\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '${ADMIN_EMAIL}', 'Super Administrator', 'super_admin', 1000000
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');

-- Insert default reseller package
INSERT INTO reseller_packages (name, description, price, max_resellers, max_users, commission_rate, duration_days, features) VALUES
('Reseller Basic', 'Paket Reseller Pemula', 500000, 5, 50, 10.00, 30, '["5 sub-reseller", "50 user quota", "10% commission"]'),
('Reseller Pro', 'Paket Reseller Professional', 1000000, 20, 200, 15.00, 30, '["20 sub-reseller", "200 user quota", "15% commission"]'),
('Reseller Unlimited', 'Paket Reseller Unlimited', 2000000, 999999, 999999, 20.00, 30, '["Unlimited reseller", "Unlimited users", "20% commission"]')
ON DUPLICATE KEY UPDATE name=name;

-- Insert default servers
INSERT INTO servers (name, location, country_code, city, ip, api_key, is_bot_server, priority) VALUES
('Singapore Premium', 'Singapore', 'SG', 'Singapore', '127.0.0.1', '${NODE_API_KEY}', TRUE, 1),
('Japan Premium', 'Japan', 'JP', 'Tokyo', '127.0.0.2', '${NODE_API_KEY}', TRUE, 2),
('India Premium', 'India', 'IN', 'Bangalore', '127.0.0.3', '${NODE_API_KEY}', TRUE, 3),
('USA Premium', 'USA', 'US', 'Washington', '127.0.0.4', '${NODE_API_KEY}', FALSE, 4),
('Europe Premium', 'Germany', 'DE', 'Frankfurt', '127.0.0.5', '${NODE_API_KEY}', FALSE, 5)
ON DUPLICATE KEY UPDATE name=name;

-- Insert default products
INSERT INTO products (name, slug, description, short_description, price, duration_days, traffic_limit, device_limit, protocol, bot_enabled, featured, popular) VALUES
('Basic 1 Bulan', 'basic-1-bulan', 'Paket Basic untuk pemula', '100GB, 1 Device', 50000, 30, 107374182400, 1, 'vless', TRUE, FALSE, TRUE),
('Premium 3 Bulan', 'premium-3-bulan', 'Paket Premium dengan kuota besar', '300GB, 3 Device', 120000, 90, 322122547200, 3, 'vless', TRUE, TRUE, TRUE),
('VIP 1 Tahun', 'vip-1-tahun', 'Paket VIP unlimited', 'Unlimited, 5 Device', 400000, 365, 999999999999, 5, 'vless', TRUE, TRUE, FALSE)
ON DUPLICATE KEY UPDATE name=name;

-- Insert default settings
INSERT INTO settings (setting_key, setting_value, setting_type, group_name, description) VALUES
('site_name', '${SITE_NAME}', 'text', 'general', 'Nama Website'),
('site_description', 'VPN Khusus Mobile Legends dengan Teknologi Bot Matchmaking', 'textarea', 'general', 'Deskripsi Website'),
('site_keywords', 'vpn, mobile legends, mlbb, bot, rw', 'text', 'general', 'Meta Keywords'),
('site_logo', '/assets/img/logo.png', 'image', 'general', 'Logo Website'),
('site_favicon', '/assets/img/favicon.ico', 'image', 'general', 'Favicon'),
('site_email', '${ADMIN_EMAIL}', 'email', 'general', 'Email Admin'),
('site_phone', '+6281234567890', 'text', 'general', 'Nomor Telepon'),
('site_address', 'Jakarta, Indonesia', 'text', 'general', 'Alamat'),
('site_currency', 'IDR', 'text', 'general', 'Mata Uang'),
('site_timezone', 'Asia/Jakarta', 'text', 'general', 'Timezone'),
('payment_gateway', 'pakasir', 'text', 'payment', 'Payment Gateway'),
('pakasir_api_key', '', 'text', 'payment', 'Pakasir API Key'),
('pakasir_slug', '', 'text', 'payment', 'Pakasir Project Slug'),
('usd_rate', '15000', 'number', 'payment', 'USD to IDR Rate'),
('min_deposit', '10000', 'number', 'payment', 'Minimal Deposit'),
('max_deposit', '10000000', 'number', 'payment', 'Maksimal Deposit'),
('withdrawal_fee', '5000', 'number', 'withdrawal', 'Biaya Penarikan'),
('min_withdrawal', '50000', 'number', 'withdrawal', 'Minimal Penarikan'),
('max_withdrawal', '5000000', 'number', 'withdrawal', 'Maksimal Penarikan'),
('bot_mode_enabled', '1', 'boolean', 'bot', 'Aktifkan Bot Mode'),
('bot_default_difficulty', 'easy', 'text', 'bot', 'Default Difficulty Bot'),
('bot_matchmaking_timeout', '10', 'number', 'bot', 'Timeout Matchmaking (detik)'),
('maintenance_mode', '0', 'boolean', 'system', 'Mode Maintenance'),
('registration_enabled', '1', 'boolean', 'system', 'Buka Registrasi'),
('email_verification', '0', 'boolean', 'system', 'Verifikasi Email'),
('smtp_host', '', 'text', 'email', 'SMTP Host'),
('smtp_port', '587', 'number', 'email', 'SMTP Port'),
('smtp_user', '', 'text', 'email', 'SMTP Username'),
('smtp_pass', '', 'text', 'email', 'SMTP Password'),
('smtp_encryption', 'tls', 'text', 'email', 'SMTP Encryption'),
('facebook_url', 'https://facebook.com/rwmlbb', 'url', 'social', 'Facebook URL'),
('twitter_url', 'https://twitter.com/rwmlbb', 'url', 'social', 'Twitter URL'),
('instagram_url', 'https://instagram.com/rwmlbb', 'url', 'social', 'Instagram URL'),
('telegram_url', 'https://t.me/rwmlbb', 'url', 'social', 'Telegram URL'),
('whatsapp_number', '+6281234567890', 'text', 'social', 'WhatsApp Number'),
('youtube_url', 'https://youtube.com/@rwmlbb', 'url', 'social', 'YouTube URL'),
('tiktok_url', 'https://tiktok.com/@rwmlbb', 'url', 'social', 'TikTok URL'),
('discord_url', 'https://discord.gg/rwmlbb', 'url', 'social', 'Discord URL')
ON DUPLICATE KEY UPDATE setting_key=setting_key;

-- Insert default pages
INSERT INTO pages (title, slug, content, meta_title, status, created_by) VALUES
('About Us', 'about', '<h2>Tentang Kami</h2><p>RW MLBB VPN adalah layanan VPN premium yang dikhususkan untuk para pemain Mobile Legends. Kami menyediakan koneksi cepat dan stabil dengan server yang tersebar di berbagai lokasi strategis seperti Singapore, Japan, India, dan USA untuk memastikan ping terendah ke server MLBB.</p>', 'Tentang RW MLBB VPN', TRUE, 1),
('Privacy Policy', 'privacy-policy', '<h2>Kebijakan Privasi</h2><p>Kami menjaga privasi Anda dengan serius. Kebijakan privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan melindungi informasi pribadi Anda.</p>', 'Kebijakan Privasi', TRUE, 1),
('Terms of Service', 'terms-of-service', '<h2>Syarat dan Ketentuan</h2><p>Dengan menggunakan layanan kami, Anda menyetujui syarat dan ketentuan berikut...</p>', 'Syarat dan Ketentuan', TRUE, 1),
('FAQ', 'faq', '<h2>Pertanyaan yang Sering Diajukan</h2><p>Berikut adalah pertanyaan yang sering diajukan tentang layanan kami.</p>', 'FAQ', TRUE, 1),
('Contact', 'contact', '<h2>Hubungi Kami</h2><p>Silakan hubungi kami melalui email atau media sosial.</p>', 'Kontak', TRUE, 1)
ON DUPLICATE KEY UPDATE title=title;

-- Insert default blog posts
INSERT INTO blog_posts (title, slug, content, excerpt, author_id, status, published_at) VALUES
('Cara Mendapatkan Bot di Mobile Legends', 'cara-mendapatkan-bot-mlbb', '<p>Mobile Legends adalah game yang sangat populer. Salah satu cara untuk naik rank dengan cepat adalah dengan mendapatkan lawan bot. Berikut adalah tips dan triknya...</p>', 'Pelajari cara mendapatkan lawan bot di Mobile Legends dengan mudah', 1, 'published', NOW()),
('Update Server Terbaru RW MLBB VPN', 'update-server-terbaru', '<p>Kami dengan senang hati mengumumkan penambahan server baru di India dan Eropa untuk memberikan pengalaman bermain yang lebih baik...</p>', 'Server baru di India dan Eropa telah hadir!', 1, 'published', NOW()),
('Tips Memilih Paket VPN', 'tips-memilih-paket-vpn', '<p>Memilih paket VPN yang tepat sangat penting untuk pengalaman bermain Anda. Simak panduan lengkapnya di sini...</p>', 'Panduan memilih paket VPN yang sesuai kebutuhan', 1, 'published', NOW())
ON DUPLICATE KEY UPDATE title=title;

-- Insert default announcements
INSERT INTO announcements (title, slug, content, type, target, priority, pinned, created_by) VALUES
('Welcome to RW MLBB VPN!', 'welcome', 'Selamat datang di RW MLBB VPN! Nikmati pengalaman bermain Mobile Legends dengan ping rendah dan bot matchmaking.', 'success', 'all', 1, TRUE, 1),
('Server Maintenance', 'maintenance', 'Akan ada maintenance server pada tanggal 15 setiap bulan pukul 02.00 - 04.00 WIB.', 'maintenance', 'all', 2, TRUE, 1),
('Promo Spesial', 'promo', 'Dapatkan diskon 20% untuk semua paket selama bulan ini! Gunakan kode: WELCOME20', 'info', 'users', 3, FALSE, 1)
ON DUPLICATE KEY UPDATE title=title;

-- Insert default coupons
INSERT INTO coupons (code, description, discount_type, discount_value, min_purchase, usage_limit, start_date, end_date, created_by) VALUES
('WELCOME10', 'Diskon 10% untuk pembelian pertama', 'percentage', 10.00, 50000, 100, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 1),
('WELCOME20', 'Diskon Rp20.000 untuk pembelian pertama', 'fixed', 20000, 100000, 50, NOW(), DATE_ADD(NOW(), INTERVAL 30 DAY), 1),
('BONUS50K', 'Bonus Rp50.000 untuk deposit di atas Rp500.000', 'fixed', 50000, 500000, 20, NOW(), DATE_ADD(NOW(), INTERVAL 60 DAY), 1)
ON DUPLICATE KEY UPDATE code=code;
EOF

echo -e "${GREEN}✅ Database super lengkap berhasil dibuat${NC}"
echo ""

# ==================== STEP 7: BUAT BACKEND API NODE.JS ====================
echo -e "${YELLOW}[7/15] ⚙️  Membuat backend API Node.js...${NC}"

mkdir -p /var/www/api
cd /var/www/api

cat > package.json << 'EOF'
{
  "name": "vpn-panel-enterprise-api",
  "version": "2.0.0",
  "description": "RW MLBB VPN Enterprise API dengan Multi Role System",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "worker": "node worker.js",
    "cron": "node cron.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "sequelize": "^6.32.1",
    "jsonwebtoken": "^9.0.1",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "axios": "^1.4.0",
    "socket.io": "^4.6.1",
    "node-cron": "^3.0.2",
    "qrcode": "^1.5.3",
    "multer": "^1.4.5-lts.1",
    "sharp": "^0.32.5",
    "uuid": "^9.0.0",
    "nanoid": "^3.3.4",
    "express-validator": "^7.0.1",
    "express-rate-limit": "^6.9.0",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "winston": "^3.10.0",
    "morgan": "^1.10.0",
    "nodemailer": "^6.9.4",
    "redis": "^4.6.7",
    "bull": "^4.11.3",
    "socket.io-client": "^4.6.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

npm install

cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const mysql = require('mysql2');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const { nanoid } = require('nanoid');
const { body, validationResult } = require('express-validator');
const winston = require('winston');
const morgan = require('morgan');
const http = require('http');
const socketIo = require('socket.io');
const cron = require('node-cron');
const axios = require('axios');
const QRCode = require('qrcode');
const nodemailer = require('nodemailer');
const Redis = require('ioredis');
const Queue = require('bull');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST", "PUT", "DELETE"]
    }
});

// ==================== CONFIGURATION ====================
const PORT = 3000;
const JWT_SECRET = '${JWT_SECRET}';
const DB_CONFIG = {
    host: 'localhost',
    user: 'root',
    password: '${MYSQL_ROOT_PASSWORD}',
    database: 'vpn_panel',
    waitForConnections: true,
    connectionLimit: 20,
    queueLimit: 0
};

// ==================== REDIS SETUP ====================
const redis = new Redis({
    host: 'localhost',
    port: 6379,
    maxRetriesPerRequest: null
});

// ==================== QUEUE SETUP ====================
const emailQueue = new Queue('email', 'redis://localhost:6379');
const notificationQueue = new Queue('notification', 'redis://localhost:6379');
const trafficQueue = new Queue('traffic', 'redis://localhost:6379');

// ==================== DATABASE POOL ====================
const pool = mysql.createPool(DB_CONFIG);
const promisePool = pool.promise();

// ==================== LOGGING ====================
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: '/var/log/api/error.log', level: 'error' }),
        new winston.transports.File({ filename: '/var/log/api/combined.log' }),
        new winston.transports.Console({ format: winston.format.simple() })
    ]
});

app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) } }));

// ==================== MIDDLEWARE ====================
app.use(helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false
}));
app.use(compression());
app.use(cors({
    origin: true,
    credentials: true
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use('/uploads', express.static('uploads'));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: { error: 'Too many requests, please try again later.' }
});
app.use('/api/', limiter);

// ==================== FILE UPLOAD CONFIG ====================
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads/';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`;
        cb(null, uniqueName);
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif|webp/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        if (mimetype && extname) {
            return cb(null, true);
        } else {
            cb(new Error('Only image files are allowed'));
        }
    }
});

// ==================== AUTH MIDDLEWARE ====================
const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }
    
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        const [rows] = await promisePool.query(
            'SELECT id, username, email, role, status FROM users WHERE id = ? AND status = "active"',
            [decoded.id]
        );
        
        if (rows.length === 0) {
            return res.status(401).json({ error: 'User not found or inactive' });
        }
        
        req.user = rows[0];
        next();
    } catch (err) {
        return res.status(403).json({ error: 'Invalid token' });
    }
};

const authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ error: 'Insufficient permissions' });
        }
        next();
    };
};

// ==================== HELPER FUNCTIONS ====================
const generateUUID = () => uuidv4();
const generateOrderId = (prefix = 'INV') => {
    return `${prefix}${Date.now()}${nanoid(6).toUpperCase()}`;
};

const logActivity = async (userId, action, description, req) => {
    try {
        const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
        const userAgent = req.headers['user-agent'];
        
        await promisePool.query(
            'INSERT INTO activity_logs (user_id, action, description, ip_address, user_agent) VALUES (?, ?, ?, ?, ?)',
            [userId, action, description, ip, userAgent]
        );
    } catch (err) {
        logger.error('Error logging activity:', err);
    }
};

const createNotification = async (userId, type, title, message, data = null) => {
    try {
        await promisePool.query(
            'INSERT INTO notifications (user_id, type, title, message, data) VALUES (?, ?, ?, ?, ?)',
            [userId, type, title, message, data ? JSON.stringify(data) : null]
        );
        
        // Emit socket event
        io.to(`user-${userId}`).emit('notification', { type, title, message, data });
    } catch (err) {
        logger.error('Error creating notification:', err);
    }
};

// ==================== API ROUTES ====================

// ==================== AUTH ROUTES ====================
app.post('/api/auth/login', [
    body('username').notEmpty().trim(),
    body('password').notEmpty()
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { username, password } = req.body;
    
    try {
        const [rows] = await promisePool.query(
            'SELECT * FROM users WHERE username = ? OR email = ?',
            [username, username]
        );
        
        if (rows.length === 0) {
            await logActivity(null, 'LOGIN_FAILED', `Failed login attempt for username: ${username}`, req);
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const user = rows[0];
        
        if (user.status !== 'active') {
            return res.status(403).json({ error: 'Account is not active' });
        }
        
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            await logActivity(user.id, 'LOGIN_FAILED', 'Invalid password', req);
            return res.status(401).json({ error: 'Invalid credentials' });
        }
        
        const token = jwt.sign(
            { id: user.id, username: user.username, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );
        
        await promisePool.query(
            'UPDATE users SET last_login = NOW(), last_ip = ? WHERE id = ?',
            [req.headers['x-forwarded-for'] || req.socket.remoteAddress, user.id]
        );
        
        await logActivity(user.id, 'LOGIN_SUCCESS', 'User logged in successfully', req);
        
        // Get user data without password
        const { password: _, ...userData } = user;
        
        res.json({
            success: true,
            token,
            user: userData
        });
    } catch (err) {
        logger.error('Login error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/auth/register', [
    body('username').isLength({ min: 3, max: 50 }).trim(),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('full_name').optional().trim(),
    body('phone').optional().trim()
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { username, email, password, full_name, phone } = req.body;
    
    try {
        // Check if user exists
        const [existing] = await promisePool.query(
            'SELECT id FROM users WHERE username = ? OR email = ?',
            [username, email]
        );
        
        if (existing.length > 0) {
            return res.status(400).json({ error: 'Username or email already exists' });
        }
        
        const hashedPassword = await bcrypt.hash(password, 10);
        const uuid = generateUUID();
        
        const [result] = await promisePool.query(
            'INSERT INTO users (uuid, username, password, email, full_name, phone, role) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [uuid, username, hashedPassword, email, full_name || null, phone || null, 'user']
        );
        
        await logActivity(result.insertId, 'REGISTER', 'User registered successfully', req);
        
        res.json({
            success: true,
            message: 'Registration successful. Please login.'
        });
    } catch (err) {
        logger.error('Registration error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== USER ROUTES ====================
app.get('/api/user/profile', authenticateToken, async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT id, uuid, username, email, full_name, phone, avatar, role, balance, total_deposit, total_withdrawal, total_commission, bot_mode, bot_difficulty, status, email_verified, phone_verified, two_factor_enabled, last_login, last_ip, created_at FROM users WHERE id = ?',
            [req.user.id]
        );
        
        if (rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        res.json(rows[0]);
    } catch (err) {
        logger.error('Get profile error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/user/profile', authenticateToken, [
    body('full_name').optional().trim(),
    body('email').optional().isEmail().normalizeEmail(),
    body('phone').optional().trim()
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { full_name, email, phone } = req.body;
    
    try {
        // Check if email already used by another user
        if (email) {
            const [existing] = await promisePool.query(
                'SELECT id FROM users WHERE email = ? AND id != ?',
                [email, req.user.id]
            );
            if (existing.length > 0) {
                return res.status(400).json({ error: 'Email already in use' });
            }
        }
        
        await promisePool.query(
            'UPDATE users SET full_name = COALESCE(?, full_name), email = COALESCE(?, email), phone = COALESCE(?, phone) WHERE id = ?',
            [full_name, email, phone, req.user.id]
        );
        
        await logActivity(req.user.id, 'PROFILE_UPDATE', 'User updated profile', req);
        
        res.json({ success: true, message: 'Profile updated successfully' });
    } catch (err) {
        logger.error('Update profile error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/user/change-password', authenticateToken, [
    body('current_password').notEmpty(),
    body('new_password').isLength({ min: 6 })
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { current_password, new_password } = req.body;
    
    try {
        const [rows] = await promisePool.query(
            'SELECT password FROM users WHERE id = ?',
            [req.user.id]
        );
        
        if (rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        const validPassword = await bcrypt.compare(current_password, rows[0].password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Current password is incorrect' });
        }
        
        const hashedPassword = await bcrypt.hash(new_password, 10);
        await promisePool.query(
            'UPDATE users SET password = ? WHERE id = ?',
            [hashedPassword, req.user.id]
        );
        
        await logActivity(req.user.id, 'PASSWORD_CHANGE', 'User changed password', req);
        
        res.json({ success: true, message: 'Password changed successfully' });
    } catch (err) {
        logger.error('Change password error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/user/avatar', authenticateToken, upload.single('avatar'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }
        
        // Get old avatar
        const [rows] = await promisePool.query(
            'SELECT avatar FROM users WHERE id = ?',
            [req.user.id]
        );
        
        // Delete old avatar if not default
        if (rows[0] && rows[0].avatar !== 'default.png' && fs.existsSync(`uploads/${rows[0].avatar}`)) {
            fs.unlinkSync(`uploads/${rows[0].avatar}`);
        }
        
        await promisePool.query(
            'UPDATE users SET avatar = ? WHERE id = ?',
            [req.file.filename, req.user.id]
        );
        
        res.json({
            success: true,
            avatar: req.file.filename,
            url: `/uploads/${req.file.filename}`
        });
    } catch (err) {
        logger.error('Upload avatar error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/user/notifications', authenticateToken, async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
            [req.user.id]
        );
        
        res.json(rows);
    } catch (err) {
        logger.error('Get notifications error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/user/notifications/:id/read', authenticateToken, async (req, res) => {
    try {
        await promisePool.query(
            'UPDATE notifications SET is_read = TRUE, read_at = NOW() WHERE id = ? AND user_id = ?',
            [req.params.id, req.user.id]
        );
        
        res.json({ success: true });
    } catch (err) {
        logger.error('Mark notification read error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/user/notifications/read-all', authenticateToken, async (req, res) => {
    try {
        await promisePool.query(
            'UPDATE notifications SET is_read = TRUE, read_at = NOW() WHERE user_id = ? AND is_read = FALSE',
            [req.user.id]
        );
        
        res.json({ success: true });
    } catch (err) {
        logger.error('Mark all notifications read error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== BOT MODE ROUTES ====================
app.post('/api/bot/enable', authenticateToken, async (req, res) => {
    const { difficulty = 'easy' } = req.body;
    
    try {
        await promisePool.query(
            'UPDATE users SET bot_mode = TRUE, bot_difficulty = ? WHERE id = ?',
            [difficulty, req.user.id]
        );
        
        await logActivity(req.user.id, 'BOT_ENABLE', `Bot mode enabled with difficulty: ${difficulty}`, req);
        
        res.json({
            success: true,
            message: 'Bot mode enabled successfully',
            difficulty
        });
    } catch (err) {
        logger.error('Enable bot error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/bot/disable', authenticateToken, async (req, res) => {
    try {
        await promisePool.query(
            'UPDATE users SET bot_mode = FALSE WHERE id = ?',
            [req.user.id]
        );
        
        await logActivity(req.user.id, 'BOT_DISABLE', 'Bot mode disabled', req);
        
        res.json({ success: true, message: 'Bot mode disabled' });
    } catch (err) {
        logger.error('Disable bot error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/bot/record-match', authenticateToken, async (req, res) => {
    const { match_id, result, duration, kills, deaths, assists, mvp, hero_played, hero_role, rank_points, bot_difficulty } = req.body;
    
    try {
        // Get user's active account
        const [accounts] = await promisePool.query(
            'SELECT id FROM vpn_accounts WHERE user_id = ? AND active = TRUE AND bot_enabled = TRUE LIMIT 1',
            [req.user.id]
        );
        
        const accountId = accounts.length > 0 ? accounts[0].id : null;
        
        const [result] = await promisePool.query(
            'INSERT INTO bot_matches (user_id, account_id, match_id, result, duration, kills, deaths, assists, mvp, hero_played, hero_role, rank_points, bot_difficulty, match_date, match_time, ip_address, country) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURDATE(), CURTIME(), ?, ?)',
            [
                req.user.id,
                accountId,
                match_id,
                result,
                duration,
                kills || 0,
                deaths || 0,
                assists || 0,
                mvp || false,
                hero_played,
                hero_role,
                rank_points || 0,
                bot_difficulty || 'easy',
                req.headers['x-forwarded-for'] || req.socket.remoteAddress,
                req.headers['cf-ipcountry'] || 'ID'
            ]
        );
        
        // Update user stats in Redis
        await redis.incr(`bot:matches:${req.user.id}`);
        if (result === 'win') {
            await redis.incr(`bot:wins:${req.user.id}`);
        }
        
        res.json({
            success: true,
            match_id: result.insertId,
            message: result === 'win' ? '🎉 Victory! +10 Rank Points' : '😢 Better luck next time!'
        });
    } catch (err) {
        logger.error('Record match error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/bot/stats', authenticateToken, async (req, res) => {
    try {
        const [matches] = await promisePool.query(
            'SELECT * FROM bot_matches WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
            [req.user.id]
        );
        
        const [stats] = await promisePool.query(
            'SELECT COUNT(*) as total, SUM(CASE WHEN result = "win" THEN 1 ELSE 0 END) as wins, SUM(rank_points) as total_points FROM bot_matches WHERE user_id = ?',
            [req.user.id]
        );
        
        // Get today's stats
        const [today] = await promisePool.query(
            "SELECT COUNT(*) as today_matches, SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) as today_wins FROM bot_matches WHERE user_id = ? AND DATE(created_at) = CURDATE()",
            [req.user.id]
        );
        
        // Get user
        const [user] = await promisePool.query(
            'SELECT bot_mode, bot_difficulty FROM users WHERE id = ?',
            [req.user.id]
        );
        
        res.json({
            enabled: user[0].bot_mode,
            difficulty: user[0].bot_difficulty,
            matches: matches,
            stats: {
                total: stats[0].total || 0,
                wins: stats[0].wins || 0,
                win_rate: stats[0].total > 0 ? ((stats[0].wins / stats[0].total) * 100).toFixed(2) + '%' : '0%',
                total_points: stats[0].total_points || 0,
                today_matches: today[0].today_matches || 0,
                today_wins: today[0].today_wins || 0
            }
        });
    } catch (err) {
        logger.error('Bot stats error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== PRODUCT ROUTES ====================
app.get('/api/products', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT * FROM products WHERE status = TRUE ORDER BY priority DESC, price ASC'
        );
        res.json(rows);
    } catch (err) {
        logger.error('Get products error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/products/:slug', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT * FROM products WHERE slug = ? AND status = TRUE',
            [req.params.slug]
        );
        
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        
        res.json(rows[0]);
    } catch (err) {
        logger.error('Get product error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== SERVER ROUTES ====================
app.get('/api/servers', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT id, name, location, country_code, city, ip, port, status, is_bot_server, priority, current_users, max_users FROM servers WHERE status = "active" ORDER BY priority ASC'
        );
        res.json(rows);
    } catch (err) {
        logger.error('Get servers error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== VPN ACCOUNT ROUTES ====================
app.post('/api/vpn/create', authenticateToken, async (req, res) => {
    const { product_id, server_id, name, protocol = 'vless' } = req.body;
    
    try {
        // Get product details
        const [products] = await promisePool.query(
            'SELECT * FROM products WHERE id = ? AND status = TRUE',
            [product_id]
        );
        
        if (products.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        
        const product = products[0];
        
        // Check user balance
        const [users] = await promisePool.query(
            'SELECT balance FROM users WHERE id = ?',
            [req.user.id]
        );
        
        if (users[0].balance < product.price) {
            return res.status(400).json({ error: 'Insufficient balance' });
        }
        
        // Get server
        const [servers] = await promisePool.query(
            'SELECT * FROM servers WHERE id = ? AND status = "active"',
            [server_id]
        );
        
        if (servers.length === 0) {
            return res.status(404).json({ error: 'Server not found' });
        }
        
        const server = servers[0];
        
        // Create subscription
        const startDate = new Date();
        const endDate = new Date();
        endDate.setDate(endDate.getDate() + product.duration_days);
        
        const [subResult] = await promisePool.query(
            'INSERT INTO user_subscriptions (user_id, package_name, price, traffic_limit, device_limit, protocol, server_location, start_date, end_date, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
                req.user.id,
                product.name,
                product.price,
                product.traffic_limit,
                product.device_limit,
                protocol,
                server.location,
                startDate,
                endDate,
                'active'
            ]
        );
        
        // Deduct balance
        await promisePool.query(
            'UPDATE users SET balance = balance - ? WHERE id = ?',
            [product.price, req.user.id]
        );
        
        // Create transaction
        const transactionNo = generateOrderId('TRX');
        await promisePool.query(
            'INSERT INTO transactions (transaction_no, user_id, type, amount, total, payment_method, status, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
                transactionNo,
                req.user.id,
                'purchase',
                product.price,
                product.price,
                'balance',
                'completed',
                `Purchase: ${product.name}`
            ]
        );
        
        // Create VPN account
        const uuid = generateUUID();
        const password = nanoid(16);
        
        await promisePool.query(
            'INSERT INTO vpn_accounts (uuid, user_id, subscription_id, server_id, name, protocol, port, password, traffic_limit, device_limit, expired_at, active, bot_enabled) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
                uuid,
                req.user.id,
                subResult.insertId,
                server_id,
                name || `${protocol.toUpperCase()} Account`,
                protocol,
                server.port,
                password,
                product.traffic_limit,
                product.device_limit,
                endDate,
                true,
                product.bot_enabled
            ]
        );
        
        // Generate config
        let configLink = '';
        if (protocol === 'vless') {
            configLink = `vless://${uuid}@${server.ip}:${server.port}?type=ws&path=%2Fvless&security=tls&encryption=none&host=${server.ip}&sni=${server.ip}#${name || 'VPN'}`;
        } else if (protocol === 'vmess') {
            const config = {
                v: "2",
                ps: name || 'VMESS',
                add: server.ip,
                port: server.port,
                id: uuid,
                aid: "0",
                net: "ws",
                type: "none",
                host: server.ip,
                path: "/vmess",
                tls: "tls"
            };
            configLink = `vmess://${Buffer.from(JSON.stringify(config)).toString('base64')}`;
        }
        
        const qrCode = await QRCode.toDataURL(configLink);
        
        await logActivity(req.user.id, 'CREATE_VPN', `Created VPN account: ${name}`, req);
        
        res.json({
            success: true,
            message: 'VPN account created successfully',
            config: {
                link: configLink,
                qrcode: qrCode
            },
            expired_at: endDate
        });
    } catch (err) {
        logger.error('Create VPN error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/vpn/accounts', authenticateToken, async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            `SELECT va.*, s.name as server_name, s.location, s.country_code 
             FROM vpn_accounts va 
             LEFT JOIN servers s ON va.server_id = s.id 
             WHERE va.user_id = ? 
             ORDER BY va.created_at DESC`,
            [req.user.id]
        );
        
        res.json(rows);
    } catch (err) {
        logger.error('Get VPN accounts error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/vpn/accounts/:id', authenticateToken, async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            `SELECT va.*, s.name as server_name, s.location, s.country_code, s.ip, s.port as server_port
             FROM vpn_accounts va 
             LEFT JOIN servers s ON va.server_id = s.id 
             WHERE va.id = ? AND va.user_id = ?`,
            [req.params.id, req.user.id]
        );
        
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Account not found' });
        }
        
        const account = rows[0];
        
        // Generate config
        let configLink = '';
        if (account.protocol === 'vless') {
            configLink = `vless://${account.uuid}@${account.ip}:${account.server_port}?type=ws&path=%2Fvless&security=tls&encryption=none&host=${account.ip}&sni=${account.ip}#${account.name || 'VPN'}`;
        } else if (account.protocol === 'vmess') {
            const config = {
                v: "2",
                ps: account.name || 'VMESS',
                add: account.ip,
                port: account.server_port,
                id: account.uuid,
                aid: "0",
                net: "ws",
                type: "none",
                host: account.ip,
                path: "/vmess",
                tls: "tls"
            };
            configLink = `vmess://${Buffer.from(JSON.stringify(config)).toString('base64')}`;
        }
        
        const qrCode = await QRCode.toDataURL(configLink);
        
        res.json({
            ...account,
            config: {
                link: configLink,
                qrcode: qrCode
            }
        });
    } catch (err) {
        logger.error('Get VPN account error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.delete('/api/vpn/accounts/:id', authenticateToken, async (req, res) => {
    try {
        const [result] = await promisePool.query(
            'DELETE FROM vpn_accounts WHERE id = ? AND user_id = ?',
            [req.params.id, req.user.id]
        );
        
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Account not found' });
        }
        
        await logActivity(req.user.id, 'DELETE_VPN', `Deleted VPN account ID: ${req.params.id}`, req);
        
        res.json({ success: true, message: 'Account deleted' });
    } catch (err) {
        logger.error('Delete VPN account error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== RESELLER ROUTES ====================
app.get('/api/reseller/packages', authenticateToken, authorize('reseller', 'admin', 'super_admin'), async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT * FROM reseller_packages WHERE status = TRUE ORDER BY price ASC'
        );
        res.json(rows);
    } catch (err) {
        logger.error('Get reseller packages error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/reseller/purchase', authenticateToken, authorize('reseller', 'admin', 'super_admin'), async (req, res) => {
    const { package_id } = req.body;
    
    try {
        const [packages] = await promisePool.query(
            'SELECT * FROM reseller_packages WHERE id = ? AND status = TRUE',
            [package_id]
        );
        
        if (packages.length === 0) {
            return res.status(404).json({ error: 'Package not found' });
        }
        
        const pkg = packages[0];
        
        // Check balance
        const [users] = await promisePool.query(
            'SELECT balance FROM users WHERE id = ?',
            [req.user.id]
        );
        
        if (users[0].balance < pkg.price) {
            return res.status(400).json({ error: 'Insufficient balance' });
        }
        
        // Deduct balance
        await promisePool.query(
            'UPDATE users SET balance = balance - ? WHERE id = ?',
            [pkg.price, req.user.id]
        );
        
        // Create subscription
        const startDate = new Date();
        const endDate = new Date();
        endDate.setDate(endDate.getDate() + pkg.duration_days);
        
        await promisePool.query(
            'INSERT INTO reseller_subscriptions (reseller_id, package_id, start_date, end_date, price_paid, status) VALUES (?, ?, ?, ?, ?, ?)',
            [req.user.id, package_id, startDate, endDate, pkg.price, 'active']
        );
        
        // Update reseller limits
        await promisePool.query(
            'UPDATE users SET max_resellers = max_resellers + ?, max_users = max_users + ?, commission_rate = ? WHERE id = ?',
            [pkg.max_resellers, pkg.max_users, pkg.commission_rate, req.user.id]
        );
        
        // Create transaction
        const transactionNo = generateOrderId('TRX');
        await promisePool.query(
            'INSERT INTO transactions (transaction_no, user_id, type, amount, total, payment_method, status, description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [
                transactionNo,
                req.user.id,
                'purchase',
                pkg.price,
                pkg.price,
                'balance',
                'completed',
                `Purchase Reseller Package: ${pkg.name}`
            ]
        );
        
        await logActivity(req.user.id, 'PURCHASE_RESELLER', `Purchased reseller package: ${pkg.name}`, req);
        
        res.json({
            success: true,
            message: 'Reseller package activated successfully',
            package: pkg
        });
    } catch (err) {
        logger.error('Purchase reseller package error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/reseller/commission', authenticateToken, authorize('reseller', 'admin', 'super_admin'), async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            `SELECT t.*, u.username as user_name 
             FROM transactions t 
             LEFT JOIN users u ON t.user_id = u.id 
             WHERE t.type = 'commission' AND t.reseller_id = ? 
             ORDER BY t.created_at DESC`,
            [req.user.id]
        );
        
        const [summary] = await promisePool.query(
            'SELECT SUM(amount) as total_commission FROM transactions WHERE type = "commission" AND reseller_id = ? AND status = "completed"',
            [req.user.id]
        );
        
        const [users] = await promisePool.query(
            'SELECT COUNT(*) as total_users FROM users WHERE parent_id = ?',
            [req.user.id]
        );
        
        res.json({
            commissions: rows,
            total_commission: summary[0].total_commission || 0,
            total_users: users[0].total_users
        });
    } catch (err) {
        logger.error('Get commission error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/reseller/withdraw', authenticateToken, authorize('reseller', 'admin', 'super_admin'), async (req, res) => {
    try {
        const [users] = await promisePool.query(
            'SELECT balance, total_commission FROM users WHERE id = ?',
            [req.user.id]
        );
        
        res.json({
            balance: users[0].balance,
            total_commission: users[0].total_commission,
            min_withdrawal: 50000,
            fee: 5000
        });
    } catch (err) {
        logger.error('Get withdrawal info error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/reseller/withdraw', authenticateToken, authorize('reseller', 'admin', 'super_admin'), [
    body('amount').isNumeric().custom(value => value >= 50000),
    body('bank_name').notEmpty(),
    body('account_number').notEmpty(),
    body('account_name').notEmpty()
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { amount, bank_name, account_number, account_name, method = 'bank_transfer' } = req.body;
    
    try {
        const [users] = await promisePool.query(
            'SELECT balance FROM users WHERE id = ?',
            [req.user.id]
        );
        
        if (users[0].balance < amount) {
            return res.status(400).json({ error: 'Insufficient balance' });
        }
        
        const fee = 5000;
        const total = amount - fee;
        
        await promisePool.query(
            'INSERT INTO withdrawals (user_id, amount, fee, total, bank_name, account_number, account_name, method, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [req.user.id, amount, fee, total, bank_name, account_number, account_name, method, 'pending']
        );
        
        await logActivity(req.user.id, 'WITHDRAWAL_REQUEST', `Withdrawal request: ${amount}`, req);
        
        await createNotification(
            req.user.id,
            'withdrawal',
            'Withdrawal Request Submitted',
            `Your withdrawal request of Rp ${amount.toLocaleString()} is pending approval.`
        );
        
        res.json({
            success: true,
            message: 'Withdrawal request submitted successfully'
        });
    } catch (err) {
        logger.error('Withdrawal request error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== ADMIN ROUTES ====================
app.get('/api/admin/users', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT id, uuid, username, email, full_name, phone, avatar, role, balance, total_deposit, total_withdrawal, total_commission, status, last_login, last_ip, created_at FROM users ORDER BY id DESC'
        );
        res.json(rows);
    } catch (err) {
        logger.error('Get users error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/admin/users/:id/role', authenticateToken, authorize('admin', 'super_admin'), [
    body('role').isIn(['user', 'reseller', 'admin'])
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { role } = req.body;
    const userId = req.params.id;
    
    try {
        // Prevent self-demotion
        if (userId == req.user.id && req.user.role === 'super_admin' && role !== 'super_admin') {
            return res.status(400).json({ error: 'Cannot change own super_admin role' });
        }
        
        await promisePool.query(
            'UPDATE users SET role = ? WHERE id = ?',
            [role, userId]
        );
        
        await logActivity(req.user.id, 'ADMIN_UPDATE_ROLE', `Changed user ${userId} role to ${role}`, req);
        
        res.json({ success: true, message: 'User role updated' });
    } catch (err) {
        logger.error('Update user role error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/admin/users/:id/status', authenticateToken, authorize('admin', 'super_admin'), [
    body('status').isIn(['active', 'inactive', 'banned', 'suspended'])
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { status } = req.body;
    const userId = req.params.id;
    
    try {
        // Prevent self-ban
        if (userId == req.user.id) {
            return res.status(400).json({ error: 'Cannot change own status' });
        }
        
        await promisePool.query(
            'UPDATE users SET status = ? WHERE id = ?',
            [status, userId]
        );
        
        await logActivity(req.user.id, 'ADMIN_UPDATE_STATUS', `Changed user ${userId} status to ${status}`, req);
        
        res.json({ success: true, message: 'User status updated' });
    } catch (err) {
        logger.error('Update user status error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/admin/users', authenticateToken, authorize('admin', 'super_admin'), [
    body('username').isLength({ min: 3, max: 50 }).trim(),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('role').isIn(['user', 'reseller', 'admin'])
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { username, email, password, full_name, phone, role } = req.body;
    
    try {
        const [existing] = await promisePool.query(
            'SELECT id FROM users WHERE username = ? OR email = ?',
            [username, email]
        );
        
        if (existing.length > 0) {
            return res.status(400).json({ error: 'Username or email already exists' });
        }
        
        const hashedPassword = await bcrypt.hash(password, 10);
        const uuid = generateUUID();
        
        await promisePool.query(
            'INSERT INTO users (uuid, username, password, email, full_name, phone, role) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [uuid, username, hashedPassword, email, full_name || null, phone || null, role]
        );
        
        await logActivity(req.user.id, 'ADMIN_CREATE_USER', `Created user: ${username}`, req);
        
        res.json({ success: true, message: 'User created successfully' });
    } catch (err) {
        logger.error('Create user error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.delete('/api/admin/users/:id', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    const userId = req.params.id;
    
    try {
        // Prevent self-delete
        if (userId == req.user.id) {
            return res.status(400).json({ error: 'Cannot delete own account' });
        }
        
        await promisePool.query('DELETE FROM users WHERE id = ?', [userId]);
        
        await logActivity(req.user.id, 'ADMIN_DELETE_USER', `Deleted user: ${userId}`, req);
        
        res.json({ success: true, message: 'User deleted successfully' });
    } catch (err) {
        logger.error('Delete user error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/admin/servers', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        const [rows] = await promisePool.query('SELECT * FROM servers ORDER BY priority ASC');
        res.json(rows);
    } catch (err) {
        logger.error('Get servers error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/admin/servers', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    const { name, location, country_code, city, ip, port, api_port, is_bot_server, priority } = req.body;
    
    try {
        const [result] = await promisePool.query(
            'INSERT INTO servers (name, location, country_code, city, ip, port, api_port, api_key, is_bot_server, priority) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [name, location, country_code, city, ip, port || 443, api_port || 8081, generateUUID(), is_bot_server || false, priority || 0]
        );
        
        await logActivity(req.user.id, 'ADMIN_ADD_SERVER', `Added server: ${name}`, req);
        
        res.json({ success: true, id: result.insertId });
    } catch (err) {
        logger.error('Add server error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/admin/servers/:id', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    const { name, location, country_code, city, ip, port, status, is_bot_server, priority } = req.body;
    
    try {
        await promisePool.query(
            'UPDATE servers SET name = COALESCE(?, name), location = COALESCE(?, location), country_code = COALESCE(?, country_code), city = COALESCE(?, city), ip = COALESCE(?, ip), port = COALESCE(?, port), status = COALESCE(?, status), is_bot_server = COALESCE(?, is_bot_server), priority = COALESCE(?, priority) WHERE id = ?',
            [name, location, country_code, city, ip, port, status, is_bot_server, priority, req.params.id]
        );
        
        await logActivity(req.user.id, 'ADMIN_UPDATE_SERVER', `Updated server ID: ${req.params.id}`, req);
        
        res.json({ success: true });
    } catch (err) {
        logger.error('Update server error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.delete('/api/admin/servers/:id', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        await promisePool.query('DELETE FROM servers WHERE id = ?', [req.params.id]);
        
        await logActivity(req.user.id, 'ADMIN_DELETE_SERVER', `Deleted server ID: ${req.params.id}`, req);
        
        res.json({ success: true });
    } catch (err) {
        logger.error('Delete server error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/admin/products', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        const [rows] = await promisePool.query('SELECT * FROM products ORDER BY id DESC');
        res.json(rows);
    } catch (err) {
        logger.error('Get products error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/admin/products', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    const { name, description, short_description, price, price_usd, duration_days, traffic_limit, device_limit, protocol, bot_enabled, featured, popular, status } = req.body;
    
    try {
        const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
        
        const [result] = await promisePool.query(
            'INSERT INTO products (name, slug, description, short_description, price, price_usd, duration_days, traffic_limit, device_limit, protocol, bot_enabled, featured, popular, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [name, slug, description, short_description, price, price_usd, duration_days, traffic_limit, device_limit, protocol, bot_enabled, featured, popular, status]
        );
        
        await logActivity(req.user.id, 'ADMIN_ADD_PRODUCT', `Added product: ${name}`, req);
        
        res.json({ success: true, id: result.insertId });
    } catch (err) {
        logger.error('Add product error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/admin/products/:id', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    const { name, description, short_description, price, price_usd, duration_days, traffic_limit, device_limit, protocol, bot_enabled, featured, popular, status } = req.body;
    
    try {
        const slug = name ? name.toLowerCase().replace(/[^a-z0-9]+/g, '-') : undefined;
        
        await promisePool.query(
            'UPDATE products SET name = COALESCE(?, name), slug = COALESCE(?, slug), description = COALESCE(?, description), short_description = COALESCE(?, short_description), price = COALESCE(?, price), price_usd = COALESCE(?, price_usd), duration_days = COALESCE(?, duration_days), traffic_limit = COALESCE(?, traffic_limit), device_limit = COALESCE(?, device_limit), protocol = COALESCE(?, protocol), bot_enabled = COALESCE(?, bot_enabled), featured = COALESCE(?, featured), popular = COALESCE(?, popular), status = COALESCE(?, status) WHERE id = ?',
            [name, slug, description, short_description, price, price_usd, duration_days, traffic_limit, device_limit, protocol, bot_enabled, featured, popular, status, req.params.id]
        );
        
        await logActivity(req.user.id, 'ADMIN_UPDATE_PRODUCT', `Updated product ID: ${req.params.id}`, req);
        
        res.json({ success: true });
    } catch (err) {
        logger.error('Update product error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.delete('/api/admin/products/:id', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        await promisePool.query('DELETE FROM products WHERE id = ?', [req.params.id]);
        
        await logActivity(req.user.id, 'ADMIN_DELETE_PRODUCT', `Deleted product ID: ${req.params.id}`, req);
        
        res.json({ success: true });
    } catch (err) {
        logger.error('Delete product error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/admin/transactions', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT t.*, u.username FROM transactions t LEFT JOIN users u ON t.user_id = u.id ORDER BY t.created_at DESC LIMIT 100'
        );
        res.json(rows);
    } catch (err) {
        logger.error('Get transactions error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/admin/withdrawals', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT w.*, u.username FROM withdrawals w LEFT JOIN users u ON w.user_id = u.id ORDER BY w.created_at DESC'
        );
        res.json(rows);
    } catch (err) {
        logger.error('Get withdrawals error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/admin/withdrawals/:id/process', authenticateToken, authorize('admin', 'super_admin'), [
    body('status').isIn(['processing', 'completed', 'rejected']),
    body('notes').optional()
], async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }
    
    const { status, notes } = req.body;
    const withdrawalId = req.params.id;
    
    try {
        const [withdrawals] = await promisePool.query(
            'SELECT * FROM withdrawals WHERE id = ?',
            [withdrawalId]
        );
        
        if (withdrawals.length === 0) {
            return res.status(404).json({ error: 'Withdrawal not found' });
        }
        
        const withdrawal = withdrawals[0];
        
        if (status === 'completed') {
            // Update user balance
            await promisePool.query(
                'UPDATE users SET balance = balance - ?, total_withdrawal = total_withdrawal + ? WHERE id = ?',
                [withdrawal.amount, withdrawal.amount, withdrawal.user_id]
            );
            
            // Create transaction
            await promisePool.query(
                'INSERT INTO transactions (transaction_no, user_id, type, amount, total, status, description) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [generateOrderId('WTD'), withdrawal.user_id, 'withdrawal', withdrawal.amount, withdrawal.total, 'completed', `Withdrawal processed`]
            );
            
            await createNotification(
                withdrawal.user_id,
                'withdrawal',
                'Withdrawal Completed',
                `Your withdrawal of Rp ${withdrawal.amount.toLocaleString()} has been processed.`
            );
        } else if (status === 'rejected') {
            // Refund balance
            await promisePool.query(
                'UPDATE users SET balance = balance + ? WHERE id = ?',
                [withdrawal.amount, withdrawal.user_id]
            );
            
            await createNotification(
                withdrawal.user_id,
                'withdrawal',
                'Withdrawal Rejected',
                `Your withdrawal of Rp ${withdrawal.amount.toLocaleString()} was rejected. Reason: ${notes || 'No reason provided'}`
            );
        }
        
        await promisePool.query(
            'UPDATE withdrawals SET status = ?, notes = ?, processed_by = ?, processed_at = NOW() WHERE id = ?',
            [status, notes, req.user.id, withdrawalId]
        );
        
        await logActivity(req.user.id, 'ADMIN_PROCESS_WITHDRAWAL', `Processed withdrawal ${withdrawalId} as ${status}`, req);
        
        res.json({ success: true });
    } catch (err) {
        logger.error('Process withdrawal error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/admin/settings', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        const [rows] = await promisePool.query('SELECT * FROM settings ORDER BY group_name, priority');
        
        // Group by group
        const grouped = {};
        rows.forEach(row => {
            if (!grouped[row.group_name]) {
                grouped[row.group_name] = [];
            }
            grouped[row.group_name].push(row);
        });
        
        res.json(grouped);
    } catch (err) {
        logger.error('Get settings error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.put('/api/admin/settings', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    const settings = req.body;
    
    try {
        for (const [key, value] of Object.entries(settings)) {
            await promisePool.query(
                'UPDATE settings SET setting_value = ? WHERE setting_key = ?',
                [value, key]
            );
        }
        
        await logActivity(req.user.id, 'ADMIN_UPDATE_SETTINGS', 'Updated system settings', req);
        
        res.json({ success: true });
    } catch (err) {
        logger.error('Update settings error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/admin/dashboard', authenticateToken, authorize('admin', 'super_admin'), async (req, res) => {
    try {
        const [totalUsers] = await promisePool.query('SELECT COUNT(*) as total FROM users');
        const [activeUsers] = await promisePool.query("SELECT COUNT(*) as total FROM users WHERE status = 'active'");
        const [totalResellers] = await promisePool.query("SELECT COUNT(*) as total FROM users WHERE role = 'reseller'");
        const [totalTransactions] = await promisePool.query('SELECT COUNT(*) as total, SUM(amount) as total_amount FROM transactions WHERE status = "completed"');
        const [totalWithdrawals] = await promisePool.query('SELECT COUNT(*) as total, SUM(amount) as total_amount FROM withdrawals WHERE status = "completed"');
        const [totalServers] = await promisePool.query('SELECT COUNT(*) as total FROM servers');
        const [activeServers] = await promisePool.query("SELECT COUNT(*) as total FROM servers WHERE status = 'active'");
        const [totalBotMatches] = await promisePool.query('SELECT COUNT(*) as total FROM bot_matches');
        const [botWins] = await promisePool.query("SELECT COUNT(*) as total FROM bot_matches WHERE result = 'win'");
        
        // Recent users
        const [recentUsers] = await promisePool.query(
            'SELECT id, username, email, full_name, role, created_at FROM users ORDER BY created_at DESC LIMIT 10'
        );
        
        // Recent transactions
        const [recentTransactions] = await promisePool.query(
            'SELECT t.*, u.username FROM transactions t LEFT JOIN users u ON t.user_id = u.id ORDER BY t.created_at DESC LIMIT 10'
        );
        
        // Traffic today
        const [trafficToday] = await promisePool.query(
            "SELECT SUM(total) as total FROM traffic_logs WHERE date = CURDATE()"
        );
        
        res.json({
            stats: {
                total_users: totalUsers[0].total,
                active_users: activeUsers[0].total,
                total_resellers: totalResellers[0].total,
                total_transactions: totalTransactions[0].total,
                total_revenue: totalTransactions[0].total_amount || 0,
                total_withdrawals: totalWithdrawals[0].total,
                total_withdrawal_amount: totalWithdrawals[0].total_amount || 0,
                total_servers: totalServers[0].total,
                active_servers: activeServers[0].total,
                total_bot_matches: totalBotMatches[0].total,
                bot_win_rate: totalBotMatches[0].total > 0 ? ((botWins[0].total / totalBotMatches[0].total) * 100).toFixed(2) + '%' : '0%',
                traffic_today: trafficToday[0].total || 0
            },
            recent_users: recentUsers,
            recent_transactions: recentTransactions
        });
    } catch (err) {
        logger.error('Admin dashboard error:', err);
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
        logger.error('Get public settings error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/public/pages/:slug', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT title, content FROM pages WHERE slug = ? AND status = TRUE',
            [req.params.slug]
        );
        
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Page not found' });
        }
        
        res.json(rows[0]);
    } catch (err) {
        logger.error('Get page error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/public/blog', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            "SELECT id, title, slug, excerpt, featured_image, author_id, published_at FROM blog_posts WHERE status = 'published' ORDER BY published_at DESC LIMIT 20"
        );
        res.json(rows);
    } catch (err) {
        logger.error('Get blog posts error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.get('/api/public/blog/:slug', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            "SELECT * FROM blog_posts WHERE slug = ? AND status = 'published'",
            [req.params.slug]
        );
        
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Post not found' });
        }
        
        // Update views
        await promisePool.query(
            'UPDATE blog_posts SET views = views + 1 WHERE id = ?',
            [rows[0].id]
        );
        
        res.json(rows[0]);
    } catch (err) {
        logger.error('Get blog post error:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// ==================== HEALTH CHECK ====================
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage()
    });
});

// ==================== SOCKET.IO ====================
io.on('connection', (socket) => {
    console.log('New client connected:', socket.id);
    
    socket.on('authenticate', async (token) => {
        try {
            const decoded = jwt.verify(token, JWT_SECRET);
            socket.join(`user-${decoded.id}`);
            socket.userId = decoded.id;
            console.log(`User ${decoded.id} authenticated on socket`);
        } catch (err) {
            console.log('Socket authentication failed');
        }
    });
    
    socket.on('subscribe:server', (serverId) => {
        socket.join(`server-${serverId}`);
    });
    
    socket.on('unsubscribe:server', (serverId) => {
        socket.leave(`server-${serverId}`);
    });
    
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});

// ==================== START SERVER ====================
server.listen(PORT, '127.0.0.1', () => {
    console.log(`✅ Enterprise API running on port ${PORT}`);
    logger.info(`API started on port ${PORT}`);
});

// ==================== CRON JOBS ====================
// Check expired subscriptions every hour
cron.schedule('0 * * * *', async () => {
    try {
        const [expired] = await promisePool.query(
            'UPDATE user_subscriptions SET status = "expired" WHERE end_date < NOW() AND status = "active"'
        );
        if (expired.affectedRows > 0) {
            logger.info(`Expired ${expired.affectedRows} subscriptions`);
        }
        
        const [expiredReseller] = await promisePool.query(
            'UPDATE reseller_subscriptions SET status = "expired" WHERE end_date < NOW() AND status = "active"'
        );
        if (expiredReseller.affectedRows > 0) {
            logger.info(`Expired ${expiredReseller.affectedRows} reseller subscriptions`);
        }
    } catch (err) {
        logger.error('Cron job error (expired subscriptions):', err);
    }
});

// Clean old logs daily
cron.schedule('0 0 * * *', async () => {
    try {
        await promisePool.query(
            "DELETE FROM traffic_logs WHERE date < DATE_SUB(CURDATE(), INTERVAL 30 DAY)"
        );
        await promisePool.query(
            "DELETE FROM activity_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY)"
        );
        logger.info('Cleaned old logs');
    } catch (err) {
        logger.error('Cron job error (clean logs):', err);
    }
});

// Calculate daily traffic
cron.schedule('59 23 * * *', async () => {
    try {
        await promisePool.query(
            `INSERT INTO traffic_logs (account_id, user_id, server_id, upload, download, total, date)
             SELECT account_id, user_id, server_id, SUM(traffic_upload) as upload, SUM(traffic_download) as download, SUM(traffic_used) as total, CURDATE()
             FROM vpn_accounts 
             WHERE traffic_used > 0
             GROUP BY account_id, user_id, server_id`
        );
        logger.info('Daily traffic summary created');
    } catch (err) {
        logger.error('Cron job error (daily traffic):', err);
    }
});
EOF

echo -e "${GREEN}✅ Enterprise API selesai${NC}"
echo ""

# ==================== STEP 8: BUAT FRONTEND WEBSITE ====================
echo -e "${YELLOW}[8/15] 🎨 Membuat frontend website...${NC}"

mkdir -p /var/www/html/{assets/{css,js,img,uploads},admin,user,reseller,api}

# ==================== CONFIG.PHP ====================
cat > /var/www/html/config.php << 'EOF'
<?php
session_start();

$host = 'localhost';
$user = 'root';
$pass = '${MYSQL_ROOT_PASSWORD}';
$db = 'vpn_panel';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Get settings
$settings = [];
$result = $conn->query("SELECT setting_key, setting_value FROM settings");
while($row = $result->fetch_assoc()) {
    $settings[$row['setting_key']] = $row['setting_value'];
}

// Site URL
$site_url = "http://{$_SERVER['HTTP_HOST']}";

// Timezone
date_default_timezone_set($settings['site_timezone'] ?? 'Asia/Jakarta');
?>
EOF

# ==================== FUNCTION.PHP ====================
cat > /var/www/html/functions.php << 'EOF'
<?php
require_once 'config.php';

function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

function isAdmin() {
    return isset($_SESSION['user_role']) && ($_SESSION['user_role'] === 'admin' || $_SESSION['user_role'] === 'super_admin');
}

function isSuperAdmin() {
    return isset($_SESSION['user_role']) && $_SESSION['user_role'] === 'super_admin';
}

function isReseller() {
    return isset($_SESSION['user_role']) && $_SESSION['user_role'] === 'reseller';
}

function getUserRole() {
    return $_SESSION['user_role'] ?? 'guest';
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

function timeAgo($datetime) {
    $time = strtotime($datetime);
    $now = time();
    $diff = $now - $time;
    
    if ($diff < 60) {
        return $diff . ' detik yang lalu';
    } elseif ($diff < 3600) {
        $mins = floor($diff / 60);
        return $mins . ' menit yang lalu';
    } elseif ($diff < 86400) {
        $hours = floor($diff / 3600);
        return $hours . ' jam yang lalu';
    } elseif ($diff < 2592000) {
        $days = floor($diff / 86400);
        return $days . ' hari yang lalu';
    } else {
        return date('d M Y', $time);
    }
}

function csrf_token() {
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function verify_csrf($token) {
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}

function apiRequest($endpoint, $method = 'GET', $data = null) {
    $url = "http://localhost:3000/api" . $endpoint;
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    
    $headers = ['Content-Type: application/json'];
    
    if (isset($_SESSION['api_token'])) {
        $headers[] = 'Authorization: Bearer ' . $_SESSION['api_token'];
    }
    
    if ($data) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'data' => json_decode($response, true)
    ];
}
?>
EOF

# ==================== HEADER.PHP ====================
cat > /var/www/html/header.php << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $page_title ?? getSetting('site_name'); ?></title>
    
    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome 6 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- AOS Animation -->
    <link href="https://unpkg.com/aos@2.3.1/dist/aos.css" rel="stylesheet">
    
    <!-- SweetAlert2 -->
    <link href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css" rel="stylesheet">
    
    <!-- Custom CSS -->
    <link rel="stylesheet" href="/assets/css/style.css">
    
    <!-- Favicon -->
    <link rel="shortcut icon" href="<?php echo getSetting('site_favicon', '/assets/img/favicon.ico'); ?>" type="image/x-icon">
</head>
<body>

<?php
$current_page = basename($_SERVER['PHP_SELF']);
$user_role = getUserRole();
?>

<!-- Navbar -->
<nav class="navbar navbar-expand-lg navbar-dark fixed-top">
    <div class="container">
        <a class="navbar-brand" href="/">
            <?php if (getSetting('site_logo')): ?>
                <img src="<?php echo getSetting('site_logo'); ?>" alt="<?php echo getSetting('site_name'); ?>" height="40">
            <?php else: ?>
                <i class="fas fa-shield-alt me-2"></i>
                <?php echo getSetting('site_name'); ?>
            <?php endif; ?>
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
                    <a class="nav-link <?php echo $current_page == 'features.php' ? 'active' : ''; ?>" href="/features.php">
                        <i class="fas fa-star me-1"></i>Fitur
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?php echo $current_page == 'pricing.php' ? 'active' : ''; ?>" href="/pricing.php">
                        <i class="fas fa-tag me-1"></i>Harga
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?php echo $current_page == 'blog.php' ? 'active' : ''; ?>" href="/blog.php">
                        <i class="fas fa-blog me-1"></i>Blog
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?php echo $current_page == 'about.php' ? 'active' : ''; ?>" href="/about.php">
                        <i class="fas fa-info-circle me-1"></i>Tentang
                    </a>
                </li>
                
                <?php if (isLoggedIn()): ?>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="userDropdown" role="button" data-bs-toggle="dropdown">
                            <i class="fas fa-user-circle me-1"></i>
                            <?php echo $_SESSION['user_name']; ?>
                        </a>
                        <ul class="dropdown-menu dropdown-menu-end">
                            <?php if (isSuperAdmin() || isAdmin()): ?>
                                <li><a class="dropdown-item" href="/admin/">
                                    <i class="fas fa-tachometer-alt me-2"></i>Admin Dashboard
                                </a></li>
                                <li><hr class="dropdown-divider"></li>
                            <?php elseif (isReseller()): ?>
                                <li><a class="dropdown-item" href="/reseller/">
                                    <i class="fas fa-store me-2"></i>Reseller Dashboard
                                </a></li>
                                <li><hr class="dropdown-divider"></li>
                            <?php else: ?>
                                <li><a class="dropdown-item" href="/user/">
                                    <i class="fas fa-tachometer-alt me-2"></i>Dashboard
                                </a></li>
                            <?php endif; ?>
                            
                            <li><a class="dropdown-item" href="/user/profile.php">
                                <i class="fas fa-user me-2"></i>Profile
                            </a></li>
                            <li><a class="dropdown-item" href="/user/vpn.php">
                                <i class="fas fa-vpn me-2"></i>VPN Accounts
                            </a></li>
                            <li><a class="dropdown-item" href="/user/bot.php">
                                <i class="fas fa-robot me-2"></i>Bot Mode
                            </a></li>
                            <li><a class="dropdown-item" href="/user/transactions.php">
                                <i class="fas fa-history me-2"></i>Transactions
                            </a></li>
                            <li><a class="dropdown-item" href="/user/change-password.php">
                                <i class="fas fa-key me-2"></i>Ubah Password
                            </a></li>
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

<div class="main-content">
EOF

# ==================== FOOTER.PHP ====================
cat > /var/www/html/footer.php << 'EOF'
</div>

<!-- Footer -->
<footer class="footer">
    <div class="container">
        <div class="row">
            <div class="col-md-4 mb-4">
                <h5><i class="fas fa-shield-alt me-2"></i><?php echo getSetting('site_name'); ?></h5>
                <p><?php echo getSetting('site_description'); ?></p>
                <div class="social-links mt-3">
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
                    <?php if (getSetting('youtube_url')): ?>
                        <a href="<?php echo getSetting('youtube_url'); ?>" target="_blank"><i class="fab fa-youtube"></i></a>
                    <?php endif; ?>
                    <?php if (getSetting('tiktok_url')): ?>
                        <a href="<?php echo getSetting('tiktok_url'); ?>" target="_blank"><i class="fab fa-tiktok"></i></a>
                    <?php endif; ?>
                    <?php if (getSetting('discord_url')): ?>
                        <a href="<?php echo getSetting('discord_url'); ?>" target="_blank"><i class="fab fa-discord"></i></a>
                    <?php endif; ?>
                </div>
            </div>
            <div class="col-md-2 mb-4">
                <h5>Links</h5>
                <ul class="list-unstyled">
                    <li><a href="/features.php"><i class="fas fa-chevron-right me-1"></i>Fitur</a></li>
                    <li><a href="/pricing.php"><i class="fas fa-chevron-right me-1"></i>Harga</a></li>
                    <li><a href="/blog.php"><i class="fas fa-chevron-right me-1"></i>Blog</a></li>
                    <li><a href="/about.php"><i class="fas fa-chevron-right me-1"></i>Tentang</a></li>
                    <li><a href="/contact.php"><i class="fas fa-chevron-right me-1"></i>Kontak</a></li>
                </ul>
            </div>
            <div class="col-md-3 mb-4">
                <h5>Legal</h5>
                <ul class="list-unstyled">
                    <li><a href="/page.php?slug=privacy-policy"><i class="fas fa-chevron-right me-1"></i>Kebijakan Privasi</a></li>
                    <li><a href="/page.php?slug=terms-of-service"><i class="fas fa-chevron-right me-1"></i>Syarat & Ketentuan</a></li>
                    <li><a href="/page.php?slug=faq"><i class="fas fa-chevron-right me-1"></i>FAQ</a></li>
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
                    <?php if (getSetting('whatsapp_number')): ?>
                        <li><i class="fab fa-whatsapp me-2"></i>
                            <a href="https://wa.me/<?php echo getSetting('whatsapp_number'); ?>" target="_blank">
                                <?php echo getSetting('whatsapp_number'); ?>
                            </a>
                        </li>
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

<!-- AOS Animation -->
<script src="https://unpkg.com/aos@2.3.1/dist/aos.js"></script>

<!-- SweetAlert2 -->
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<!-- Socket.io -->
<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>

<!-- Custom JS -->
<script src="/assets/js/main.js"></script>

<script>
AOS.init();

// Socket.io connection
const socket = io('http://<?php echo $_SERVER['HTTP_HOST']; ?>:3000');
<?php if (isset($_SESSION['api_token'])): ?>
socket.emit('authenticate', '<?php echo $_SESSION['api_token']; ?>');
<?php endif; ?>

// Notification listener
socket.on('notification', function(data) {
    Swal.fire({
        title: data.title,
        text: data.message,
        icon: data.type,
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 5000
    });
});
</script>

</body>
</html>
EOF

# ==================== CSS STYLE ====================
cat > /var/www/html/assets/css/style.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Poppins', sans-serif;
    background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%);
    color: #fff;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
}

.main-content {
    flex: 1;
    padding-top: 80px;
}

/* Navbar */
.navbar {
    background: rgba(26, 31, 53, 0.95) !important;
    backdrop-filter: blur(10px);
    border-bottom: 1px solid rgba(255, 77, 77, 0.2);
    padding: 15px 0;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.navbar-brand {
    font-weight: 700;
    font-size: 1.5rem;
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.nav-link {
    color: #fff !important;
    font-weight: 500;
    margin: 0 10px;
    position: relative;
    transition: color 0.3s;
}

.nav-link:hover,
.nav-link.active {
    color: #ff4d4d !important;
}

.nav-link::after {
    content: '';
    position: absolute;
    bottom: -5px;
    left: 0;
    width: 0;
    height: 2px;
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    transition: width 0.3s;
}

.nav-link:hover::after,
.nav-link.active::after {
    width: 100%;
}

/* Buttons */
.btn {
    padding: 12px 30px;
    border-radius: 10px;
    font-weight: 600;
    transition: all 0.3s;
    position: relative;
    overflow: hidden;
}

.btn::before {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 0;
    height: 0;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.3);
    transform: translate(-50%, -50%);
    transition: width 0.6s, height 0.6s;
}

.btn:hover::before {
    width: 300px;
    height: 300px;
}

.btn-primary {
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    border: none;
    box-shadow: 0 4px 15px rgba(255, 77, 77, 0.3);
}

.btn-primary:hover {
    transform: translateY(-3px);
    box-shadow: 0 10px 30px rgba(255, 77, 77, 0.4);
}

.btn-outline-light:hover {
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    border-color: transparent;
}

/* Cards */
.card {
    background: rgba(26, 31, 53, 0.8);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 77, 77, 0.2);
    border-radius: 20px;
    color: #fff;
    overflow: hidden;
    transition: all 0.3s;
    height: 100%;
}

.card:hover {
    transform: translateY(-10px);
    border-color: #ff4d4d;
    box-shadow: 0 20px 40px rgba(255, 77, 77, 0.2);
}

.card-header {
    background: rgba(255, 77, 77, 0.1);
    border-bottom: 1px solid rgba(255, 77, 77, 0.2);
    padding: 20px;
    font-weight: 600;
}

.card-body {
    padding: 20px;
}

/* Forms */
.form-control, .form-select {
    background: rgba(10, 14, 28, 0.8);
    border: 1px solid rgba(255, 77, 77, 0.3);
    border-radius: 10px;
    color: #fff;
    padding: 12px 16px;
    transition: all 0.3s;
}

.form-control:focus, .form-select:focus {
    border-color: #ff4d4d;
    box-shadow: 0 0 0 3px rgba(255, 77, 77, 0.2);
    background: rgba(10, 14, 28, 0.9);
    color: #fff;
}

.form-label {
    font-weight: 500;
    margin-bottom: 8px;
    color: rgba(255, 255, 255, 0.8);
}

/* Hero Section */
.hero {
    text-align: center;
    padding: 100px 0;
    background: linear-gradient(135deg, rgba(10, 14, 28, 0.9), rgba(26, 31, 53, 0.9));
    position: relative;
    overflow: hidden;
}

.hero::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -50%;
    width: 100%;
    height: 100%;
    background: radial-gradient(circle, rgba(255, 77, 77, 0.1) 0%, transparent 50%);
    animation: pulse 10s ease-in-out infinite;
}

@keyframes pulse {
    0%, 100% { transform: scale(1); opacity: 0.5; }
    50% { transform: scale(1.2); opacity: 0.8; }
}

.hero h1 {
    font-size: 3.5rem;
    font-weight: 700;
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    margin-bottom: 20px;
    position: relative;
}

.hero p {
    font-size: 1.2rem;
    color: rgba(255, 255, 255, 0.8);
    max-width: 700px;
    margin: 0 auto 30px;
    position: relative;
}

/* Features */
.feature-box {
    text-align: center;
    padding: 40px;
    border-radius: 20px;
    background: rgba(26, 31, 53, 0.6);
    border: 1px solid rgba(255, 77, 77, 0.2);
    transition: all 0.3s;
    height: 100%;
}

.feature-box:hover {
    transform: translateY(-10px);
    border-color: #ff4d4d;
    background: rgba(26, 31, 53, 0.8);
    box-shadow: 0 20px 40px rgba(255, 77, 77, 0.2);
}

.feature-icon {
    width: 80px;
    height: 80px;
    line-height: 80px;
    text-align: center;
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    border-radius: 50%;
    margin: 0 auto 20px;
    font-size: 32px;
    color: #fff;
    box-shadow: 0 10px 20px rgba(255, 77, 77, 0.3);
}

/* Pricing */
.pricing-card {
    background: rgba(26, 31, 53, 0.8);
    border-radius: 20px;
    padding: 40px;
    text-align: center;
    border: 1px solid rgba(255, 77, 77, 0.2);
    transition: all 0.3s;
    position: relative;
    overflow: hidden;
    height: 100%;
}

.pricing-card:hover {
    transform: translateY(-10px);
    border-color: #ff4d4d;
    box-shadow: 0 20px 40px rgba(255, 77, 77, 0.2);
}

.pricing-card .popular {
    position: absolute;
    top: 20px;
    right: -30px;
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    color: #fff;
    padding: 5px 30px;
    transform: rotate(45deg);
    font-size: 14px;
    font-weight: 600;
}

.pricing-card .price {
    font-size: 48px;
    font-weight: 700;
    color: #ff4d4d;
    margin: 20px 0;
}

.pricing-card .price small {
    font-size: 16px;
    color: rgba(255, 255, 255, 0.5);
}

/* Tables */
.table {
    color: #fff;
    margin-bottom: 0;
}

.table thead th {
    border-bottom: 2px solid rgba(255, 77, 77, 0.3);
    color: #ff4d4d;
    font-weight: 600;
    padding: 15px;
}

.table td {
    border-color: rgba(255, 77, 77, 0.1);
    padding: 15px;
    vertical-align: middle;
}

.table-hover tbody tr:hover {
    background: rgba(255, 77, 77, 0.1);
}

/* Alerts */
.alert {
    border-radius: 10px;
    border: none;
    padding: 15px 20px;
    margin-bottom: 20px;
}

.alert-success {
    background: rgba(76, 175, 80, 0.2);
    border-left: 4px solid #4caf50;
    color: #4caf50;
}

.alert-danger {
    background: rgba(244, 67, 54, 0.2);
    border-left: 4px solid #f44336;
    color: #f44336;
}

.alert-warning {
    background: rgba(255, 152, 0, 0.2);
    border-left: 4px solid #ff9800;
    color: #ff9800;
}

.alert-info {
    background: rgba(33, 150, 243, 0.2);
    border-left: 4px solid #2196f3;
    color: #2196f3;
}

/* Badges */
.badge {
    padding: 5px 10px;
    border-radius: 5px;
    font-weight: 500;
}

.badge.bg-success {
    background: #4caf50 !important;
}

.badge.bg-danger {
    background: #f44336 !important;
}

.badge.bg-warning {
    background: #ff9800 !important;
}

.badge.bg-info {
    background: #2196f3 !important;
}

.badge.bg-primary {
    background: linear-gradient(135deg, #ff4d4d, #9b59b6) !important;
}

/* Progress Bars */
.progress {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 10px;
    height: 8px;
}

.progress-bar {
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    border-radius: 10px;
}

/* Footer */
.footer {
    background: rgba(10, 14, 28, 0.95);
    border-top: 1px solid rgba(255, 77, 77, 0.2);
    padding: 60px 0 30px;
    margin-top: 50px;
}

.footer h5 {
    color: #ff4d4d;
    margin-bottom: 20px;
    font-weight: 600;
}

.footer ul {
    list-style: none;
    padding: 0;
}

.footer ul li {
    margin-bottom: 10px;
}

.footer ul li a {
    color: rgba(255, 255, 255, 0.7);
    text-decoration: none;
    transition: all 0.3s;
}

.footer ul li a:hover {
    color: #ff4d4d;
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
    color: #fff;
    transition: all 0.3s;
}

.social-links a:hover {
    background: #ff4d4d;
    transform: translateY(-3px) rotate(360deg);
}

.footer-bottom {
    text-align: center;
    padding-top: 30px;
    margin-top: 30px;
    border-top: 1px solid rgba(255, 77, 77, 0.1);
    color: rgba(255, 255, 255, 0.5);
}

/* Loading Spinner */
.spinner {
    width: 40px;
    height: 40px;
    border: 4px solid rgba(255, 77, 77, 0.3);
    border-top-color: #ff4d4d;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

/* Responsive */
@media (max-width: 768px) {
    .hero h1 {
        font-size: 2.5rem;
    }
    
    .navbar-brand {
        font-size: 1.2rem;
    }
    
    .footer {
        text-align: center;
    }
}

/* Animations */
@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translateY(30px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.fadeInUp {
    animation: fadeInUp 0.6s ease forwards;
}

/* Custom Scrollbar */
::-webkit-scrollbar {
    width: 10px;
}

::-webkit-scrollbar-track {
    background: rgba(26, 31, 53, 0.8);
}

::-webkit-scrollbar-thumb {
    background: linear-gradient(135deg, #ff4d4d, #9b59b6);
    border-radius: 5px;
}

::-webkit-scrollbar-thumb:hover {
    background: linear-gradient(135deg, #ff3333, #8e44ad);
}
EOF

# ==================== MAIN.JS ====================
cat > /var/www/html/assets/js/main.js << 'EOF'
$(document).ready(function() {
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function(popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Auto hide alerts
    setTimeout(function() {
        $('.alert').fadeOut('slow');
    }, 5000);

    // Smooth scroll
    $('a[href*="#"]').on('click', function(e) {
        if (this.hash !== '') {
            e.preventDefault();
            const hash = this.hash;
            $('html, body').animate({
                scrollTop: $(hash).offset().top - 80
            }, 800);
        }
    });

    // Copy to clipboard
    $('.copy-btn').on('click', function() {
        const text = $(this).data('copy');
        navigator.clipboard.writeText(text).then(function() {
            Swal.fire({
                icon: 'success',
                title: 'Copied!',
                text: 'Text copied to clipboard',
                toast: true,
                position: 'top-end',
                showConfirmButton: false,
                timer: 3000
            });
        });
    });

    // Form validation
    $('form.needs-validation').on('submit', function(e) {
        if (!this.checkValidity()) {
            e.preventDefault();
            e.stopPropagation();
        }
        $(this).addClass('was-validated');
    });

    // Password strength indicator
    $('#password').on('keyup', function() {
        const password = $(this).val();
        const strength = checkPasswordStrength(password);
        
        let strengthText = '';
        let strengthClass = '';
        
        if (strength < 30) {
            strengthText = 'Weak';
            strengthClass = 'danger';
        } else if (strength < 60) {
            strengthText = 'Medium';
            strengthClass = 'warning';
        } else {
            strengthText = 'Strong';
            strengthClass = 'success';
        }
        
        $('.password-strength').html(`
            <div class="progress mt-2">
                <div class="progress-bar bg-${strengthClass}" style="width: ${strength}%"></div>
            </div>
            <small class="text-${strengthClass}">${strengthText}</small>
        `);
    });

    function checkPasswordStrength(password) {
        let strength = 0;
        
        if (password.length >= 8) strength += 25;
        if (password.match(/[a-z]+/)) strength += 25;
        if (password.match(/[A-Z]+/)) strength += 25;
        if (password.match(/[0-9]+/)) strength += 25;
        if (password.match(/[$@#&!]+/)) strength += 25;
        
        return Math.min(strength, 100);
    }

    // Confirm actions
    $('.confirm-delete').on('click', function(e) {
        e.preventDefault();
        const url = $(this).attr('href');
        
        Swal.fire({
            title: 'Are you sure?',
            text: "You won't be able to revert this!",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Yes, delete it!'
        }).then((result) => {
            if (result.isConfirmed) {
                window.location.href = url;
            }
        });
    });
});

// Show loading
function showLoading() {
    $('#loading').remove();
    $('body').append('<div id="loading" style="position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.7);z-index:9999;display:flex;justify-content:center;align-items:center;"><div class="spinner"></div></div>');
}

// Hide loading
function hideLoading() {
    $('#loading').remove();
}

// AJAX setup
$.ajaxSetup({
    beforeSend: function(xhr, settings) {
        if (!/^(GET|HEAD|OPTIONS|TRACE)$/i.test(settings.type) && !this.crossDomain) {
            xhr.setRequestHeader("X-CSRF-Token", $('meta[name="csrf-token"]').attr('content'));
        }
    }
});

// Global AJAX error handler
$(document).ajaxError(function(event, xhr, settings, error) {
    console.log('AJAX Error:', error, xhr.responseText);
    
    let message = 'An error occurred';
    if (xhr.responseJSON && xhr.responseJSON.error) {
        message = xhr.responseJSON.error;
    }
    
    Swal.fire({
        icon: 'error',
        title: 'Error',
        text: message
    });
});

// Socket event handlers
if (typeof socket !== 'undefined') {
    socket.on('connect', function() {
        console.log('Socket connected');
    });
    
    socket.on('disconnect', function() {
        console.log('Socket disconnected');
    });
    
    socket.on('error', function(error) {
        console.error('Socket error:', error);
    });
}

// Format currency
function formatRupiah(amount) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0
    }).format(amount);
}

// Format bytes
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
    
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// Countdown timer
function startCountdown(elementId, endTime) {
    const countdown = setInterval(function() {
        const now = new Date().getTime();
        const distance = endTime - now;
        
        if (distance < 0) {
            clearInterval(countdown);
            document.getElementById(elementId).innerHTML = 'EXPIRED';
            return;
        }
        
        const days = Math.floor(distance / (1000 * 60 * 60 * 24));
        const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((distance % (1000 * 60)) / 1000);
        
        document.getElementById(elementId).innerHTML = days + 'd ' + hours + 'h ' + minutes + 'm ' + seconds + 's';
    }, 1000);
}

// QR Code generator
function generateQRCode(elementId, text) {
    new QRCode(document.getElementById(elementId), {
        text: text,
        width: 200,
        height: 200
    });
}
EOF

# ==================== INDEX.PHP ====================
cat > /var/www/html/index.php << 'EOF'
<?php
require_once 'config.php';
require_once 'functions.php';

$page_title = getSetting('site_name');
include 'header.php';

// Get products
$products = $conn->query("SELECT * FROM products WHERE status = TRUE ORDER BY price ASC LIMIT 3");
?>

<div class="hero">
    <div class="container">
        <h1 data-aos="fade-up"><?php echo getSetting('site_name'); ?></h1>
        <p data-aos="fade-up" data-aos-delay="100"><?php echo getSetting('site_description'); ?></p>
        <div class="mt-4" data-aos="fade-up" data-aos-delay="200">
            <?php if (!isLoggedIn()): ?>
                <a href="/register.php" class="btn btn-primary btn-lg me-3">
                    <i class="fas fa-user-plus me-2"></i>Daftar Sekarang
                </a>
            <?php endif; ?>
            <a href="/features.php" class="btn btn-outline-light btn-lg">
                <i class="fas fa-info-circle me-2"></i>Pelajari Lebih
            </a>
        </div>
    </div>
</div>

<section class="features-section py-5">
    <div class="container">
        <h2 class="text-center mb-5" data-aos="fade-up">Mengapa Memilih Kami?</h2>
        <div class="row">
            <div class="col-md-4 mb-4" data-aos="fade-up" data-aos-delay="100">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-globe"></i>
                    </div>
                    <h3>Server Global</h3>
                    <p>Server di Singapore, Japan, India, USA, Eropa dengan ping terbaik ke MLBB</p>
                </div>
            </div>
            <div class="col-md-4 mb-4" data-aos="fade-up" data-aos-delay="200">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-robot"></i>
                    </div>
                    <h3>Bot Matchmaking</h3>
                    <p>Teknologi khusus untuk meningkatkan peluang bertemu lawan bot</p>
                </div>
            </div>
            <div class="col-md-4 mb-4" data-aos="fade-up" data-aos-delay="300">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-shield-alt"></i>
                    </div>
                    <h3>Keamanan Premium</h3>
                    <p>Enkripsi TLS 1.3, proteksi DDoS, dan kebijakan no-log</p>
                </div>
            </div>
        </div>
    </div>
</section>

<section class="pricing-section py-5 bg-dark">
    <div class="container">
        <h2 class="text-center mb-5" data-aos="fade-up">Pilih Paket Anda</h2>
        <div class="row">
            <?php while($product = $products->fetch_assoc()): ?>
            <div class="col-md-4 mb-4" data-aos="fade-up" data-aos-delay="<?php echo $product['id'] * 100; ?>">
                <div class="pricing-card">
                    <?php if($product['popular']): ?>
                        <div class="popular">POPULAR</div>
                    <?php endif; ?>
                    <h3><?php echo $product['name']; ?></h3>
                    <div class="price">
                        <?php echo formatRupiah($product['price']); ?>
                        <small>/<?php echo $product['duration_days']; ?> hari</small>
                    </div>
                    <p><?php echo $product['short_description']; ?></p>
                    <hr>
                    <p><i class="fas fa-check text-success me-2"></i><?php echo formatBytes($product['traffic_limit']); ?> Traffic</p>
                    <p><i class="fas fa-check text-success me-2"></i><?php echo $product['device_limit']; ?> Device</p>
                    <?php if($product['bot_enabled']): ?>
                        <p><i class="fas fa-check text-success me-2"></i>Bot Mode Support</p>
                    <?php endif; ?>
                    <a href="/register.php" class="btn btn-primary mt-3 w-100">Pilih Paket</a>
                </div>
            </div>
            <?php endwhile; ?>
        </div>
    </div>
</section>

<section class="stats-section py-5">
    <div class="container">
        <div class="row text-center">
            <div class="col-md-3 mb-4" data-aos="fade-up">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-users"></i>
                    </div>
                    <h3>10,000+</h3>
                    <p>Pengguna Aktif</p>
                </div>
            </div>
            <div class="col-md-3 mb-4" data-aos="fade-up" data-aos-delay="100">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-server"></i>
                    </div>
                    <h3>50+</h3>
                    <p>Server Tersebar</p>
                </div>
            </div>
            <div class="col-md-3 mb-4" data-aos="fade-up" data-aos-delay="200">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-robot"></i>
                    </div>
                    <h3>100,000+</h3>
                    <p>Bot Matches</p>
                </div>
            </div>
            <div class="col-md-3 mb-4" data-aos="fade-up" data-aos-delay="300">
                <div class="feature-box">
                    <div class="feature-icon">
                        <i class="fas fa-headset"></i>
                    </div>
                    <h3>24/7</h3>
                    <p>Support</p>
                </div>
            </div>
        </div>
    </div>
</section>

<?php include 'footer.php'; ?>
EOF

# ==================== SET PERMISSIONS ====================
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo -e "${GREEN}✅ Frontend website selesai${NC}"
echo ""

# ==================== STEP 9: BUAT SYSTEMD SERVICE ====================
echo -e "${YELLOW}[9/15] ⚙️  Membuat systemd service untuk API...${NC}"

cat > /etc/systemd/system/vpn-panel-api.service << EOF
[Unit]
Description=RW MLBB VPN Enterprise API
After=network.target mysql.service redis-server.service
Wants=mysql.service redis-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/api
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000

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

# ==================== STEP 11: BUAT LOG DIRECTORY ====================
echo -e "${YELLOW}[11/15] 📁 Membuat direktori log...${NC}"
mkdir -p /var/log/api
chmod 755 /var/log/api
echo -e "${GREEN}✅ Log directory created${NC}"
echo ""

# ==================== STEP 12: BUAT NODE INSTALLER ====================
echo -e "${YELLOW}[12/15] 📦 Membuat node installer script...${NC}"

cat > /var/www/html/install-node.sh << EOF
#!/bin/bash
# Node Installer untuk RW MLBB VPN Enterprise

echo "🚀 Node Installer untuk RW MLBB VPN Enterprise"
echo "================================================"

NODE_API_KEY="${NODE_API_KEY}"
PANEL_URL="http://${IP_VPS}"

read -p "Node Name: " NODE_NAME
read -p "Location: " LOCATION
read -p "Country Code: " COUNTRY_CODE
read -p "City: " CITY
read -p "Is Bot Server? (y/n): " IS_BOT

apt update
apt install -y curl wget git unzip nodejs npm ufw

# Install Xray
curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash

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
const { exec } = require('child_process');
const fs = require('fs');

const app = express();
app.use(express.json());

const API_KEY = process.env.NODE_API_KEY;
const XRAY_CONFIG = '/usr/local/etc/xray/config.json';

app.use((req, res, next) => {
    const apiKey = req.headers['x-api-key'];
    if (apiKey !== API_KEY) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
});

app.get('/status', (req, res) => {
    const cpuUsage = os.loadavg()[0] * 100 / os.cpus().length;
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const ramUsage = ((totalMem - freeMem) / totalMem) * 100;
    
    let userCount = 0;
    try {
        const config = JSON.parse(fs.readFileSync(XRAY_CONFIG, 'utf8'));
        userCount = config.inbounds.reduce((acc, inbound) => {
            return acc + (inbound.settings?.clients?.length || 0);
        }, 0);
    } catch (err) {}
    
    res.json({
        cpu: cpuUsage.toFixed(2),
        ram: ramUsage.toFixed(2),
        users: userCount,
        uptime: os.uptime(),
        hostname: os.hostname()
    });
});

app.post('/api/account', (req, res) => {
    const { uuid, protocol, port, path, password, expiredAt, limit, botMode } = req.body;
    
    let config = { inbounds: [] };
    try {
        config = JSON.parse(fs.readFileSync(XRAY_CONFIG, 'utf8'));
    } catch (err) {}
    
    let inbound = config.inbounds.find(i => i.protocol === protocol && i.port === port);
    if (!inbound) {
        inbound = {
            port: parseInt(port) || 443,
            protocol: protocol,
            settings: { clients: [] },
            streamSettings: {
                network: "ws",
                wsSettings: { path: path || `/${protocol}` },
                security: "tls"
            }
        };
        config.inbounds.push(inbound);
    }
    
    inbound.settings.clients.push({
        id: uuid,
        password: password,
        email: `user-${uuid}`,
        level: 0,
        expiry: new Date(expiredAt).getTime() / 1000,
        limit: limit || 3
    });
    
    fs.writeFileSync(XRAY_CONFIG, JSON.stringify(config, null, 2));
    exec('systemctl restart xray');
    
    res.json({ success: true, botMode });
});

app.delete('/api/account/:uuid', (req, res) => {
    const { uuid } = req.params;
    
    try {
        const config = JSON.parse(fs.readFileSync(XRAY_CONFIG, 'utf8'));
        
        config.inbounds.forEach(inbound => {
            if (inbound.settings?.clients) {
                inbound.settings.clients = inbound.settings.clients.filter(c => c.id !== uuid && c.password !== uuid);
            }
        });
        
        fs.writeFileSync(XRAY_CONFIG, JSON.stringify(config, null, 2));
        exec('systemctl restart xray');
    } catch (err) {}
    
    res.json({ success: true });
});

app.listen(8081, '0.0.0.0', () => {
    console.log('✅ Node controller running on port 8081');
});
NODEEOF

npm init -y
npm install express

cat > /etc/systemd/system/vpn-node.service << SERVICEEOF
[Unit]
Description=VPN Node Controller Enterprise
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

echo "✅ Node installed successfully!"
echo ""
echo "Register this node in admin panel:"
echo "URL: ${PANEL_URL}/admin/servers.php"
echo "API Key: ${NODE_API_KEY}"
EOF

chmod +x /var/www/html/install-node.sh

echo -e "${GREEN}✅ Node installer script dibuat${NC}"
echo ""

# ==================== STEP 13: BUAT ADMIN PANEL ====================
echo -e "${YELLOW}[13/15] 🔧 Membuat admin panel...${NC}"

mkdir -p /var/www/html/admin

cat > /var/www/html/admin/index.php << 'EOF'
<?php
require_once '../config.php';
require_once '../functions.php';

if (!isAdmin()) {
    redirect('/login.php');
}

// Get stats
$users = $conn->query("SELECT COUNT(*) as total FROM users")->fetch_assoc()['total'];
$active_users = $conn->query("SELECT COUNT(*) as total FROM users WHERE status = 'active'")->fetch_assoc()['total'];
$resellers = $conn->query("SELECT COUNT(*) as total FROM users WHERE role = 'reseller'")->fetch_assoc()['total'];
$transactions = $conn->query("SELECT COUNT(*) as total, SUM(amount) as total_amount FROM transactions WHERE status = 'completed'")->fetch_assoc();
$servers = $conn->query("SELECT COUNT(*) as total FROM servers")->fetch_assoc()['total'];
$bot_matches = $conn->query("SELECT COUNT(*) as total FROM bot_matches")->fetch_assoc()['total'];
$bot_wins = $conn->query("SELECT COUNT(*) as total FROM bot_matches WHERE result = 'win'")->fetch_assoc()['total'];
$bot_win_rate = $bot_matches > 0 ? round(($bot_wins / $bot_matches) * 100, 2) : 0;

// Recent users
$recent_users = $conn->query("SELECT id, username, email, full_name, role, created_at FROM users ORDER BY created_at DESC LIMIT 10");

// Recent transactions
$recent_transactions = $conn->query("SELECT t.*, u.username FROM transactions t LEFT JOIN users u ON t.user_id = u.id ORDER BY t.created_at DESC LIMIT 10");

$page_title = 'Admin Dashboard';
include 'header.php';
?>

<div class="container-fluid py-4">
    <h2 class="mb-4">Admin Dashboard</h2>
    
    <!-- Stats Cards -->
    <div class="row">
        <div class="col-xl-3 col-md-6 mb-4">
            <div class="card border-left-primary shadow h-100 py-2">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col mr-2">
                            <div class="text-xs font-weight-bold text-primary text-uppercase mb-1">
                                Total Users</div>
                            <div class="h5 mb-0 font-weight-bold text-gray-800"><?php echo $users; ?></div>
                        </div>
                        <div class="col-auto">
                            <i class="fas fa-users fa-2x text-gray-300"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6 mb-4">
            <div class="card border-left-success shadow h-100 py-2">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col mr-2">
                            <div class="text-xs font-weight-bold text-success text-uppercase mb-1">
                                Active Users</div>
                            <div class="h5 mb-0 font-weight-bold text-gray-800"><?php echo $active_users; ?></div>
                        </div>
                        <div class="col-auto">
                            <i class="fas fa-user-check fa-2x text-gray-300"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6 mb-4">
            <div class="card border-left-info shadow h-100 py-2">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col mr-2">
                            <div class="text-xs font-weight-bold text-info text-uppercase mb-1">
                                Total Resellers</div>
                            <div class="h5 mb-0 font-weight-bold text-gray-800"><?php echo $resellers; ?></div>
                        </div>
                        <div class="col-auto">
                            <i class="fas fa-store fa-2x text-gray-300"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6 mb-4">
            <div class="card border-left-warning shadow h-100 py-2">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col mr-2">
                            <div class="text-xs font-weight-bold text-warning text-uppercase mb-1">
                                Revenue</div>
                            <div class="h5 mb-0 font-weight-bold text-gray-800"><?php echo formatRupiah($transactions['total_amount'] ?? 0); ?></div>
                        </div>
                        <div class="col-auto">
                            <i class="fas fa-dollar-sign fa-2x text-gray-300"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-xl-3 col-md-6 mb-4">
            <div class="card border-left-primary shadow h-100 py-2">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col mr-2">
                            <div class="text-xs font-weight-bold text-primary text-uppercase mb-1">
                                Total Servers</div>
                            <div class="h5 mb-0 font-weight-bold text-gray-800"><?php echo $servers; ?></div>
                        </div>
                        <div class="col-auto">
                            <i class="fas fa-server fa-2x text-gray-300"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6 mb-4">
            <div class="card border-left-success shadow h-100 py-2">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col mr-2">
                            <div class="text-xs font-weight-bold text-success text-uppercase mb-1">
                                Bot Matches</div>
                            <div class="h5 mb-0 font-weight-bold text-gray-800"><?php echo $bot_matches; ?></div>
                        </div>
                        <div class="col-auto">
                            <i class="fas fa-robot fa-2x text-gray-300"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6 mb-4">
            <div class="card border-left-info shadow h-100 py-2">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col mr-2">
                            <div class="text-xs font-weight-bold text-info text-uppercase mb-1">
                                Bot Win Rate</div>
                            <div class="h5 mb-0 font-weight-bold text-gray-800"><?php echo $bot_win_rate; ?>%</div>
                        </div>
                        <div class="col-auto">
                            <i class="fas fa-trophy fa-2x text-gray-300"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-xl-3 col-md-6 mb-4">
            <div class="card border-left-warning shadow h-100 py-2">
                <div class="card-body">
                    <div class="row no-gutters align-items-center">
                        <div class="col mr-2">
                            <div class="text-xs font-weight-bold text-warning text-uppercase mb-1">
                                Transactions</div>
                            <div class="h5 mb-0 font-weight-bold text-gray-800"><?php echo $transactions['total'] ?? 0; ?></div>
                        </div>
                        <div class="col-auto">
                            <i class="fas fa-credit-card fa-2x text-gray-300"></i>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <!-- Recent Users -->
        <div class="col-xl-6 col-lg-6 mb-4">
            <div class="card shadow">
                <div class="card-header py-3">
                    <h6 class="m-0 font-weight-bold text-primary">Recent Users</h6>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-bordered">
                            <thead>
                                <tr>
                                    <th>Username</th>
                                    <th>Email</th>
                                    <th>Role</th>
                                    <th>Joined</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php while($user = $recent_users->fetch_assoc()): ?>
                                <tr>
                                    <td><?php echo $user['username']; ?></td>
                                    <td><?php echo $user['email']; ?></td>
                                    <td><span class="badge bg-<?php echo $user['role'] == 'admin' ? 'danger' : ($user['role'] == 'reseller' ? 'warning' : 'info'); ?>"><?php echo $user['role']; ?></span></td>
                                    <td><?php echo timeAgo($user['created_at']); ?></td>
                                </tr>
                                <?php endwhile; ?>
                            </tbody>
                        </table>
                    </div>
                    <a href="users.php" class="btn btn-primary btn-sm mt-3">View All Users</a>
                </div>
            </div>
        </div>

        <!-- Recent Transactions -->
        <div class="col-xl-6 col-lg-6 mb-4">
            <div class="card shadow">
                <div class="card-header py-3">
                    <h6 class="m-0 font-weight-bold text-primary">Recent Transactions</h6>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-bordered">
                            <thead>
                                <tr>
                                    <th>User</th>
                                    <th>Type</th>
                                    <th>Amount</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php while($trx = $recent_transactions->fetch_assoc()): ?>
                                <tr>
                                    <td><?php echo $trx['username']; ?></td>
                                    <td><?php echo $trx['type']; ?></td>
                                    <td><?php echo formatRupiah($trx['amount']); ?></td>
                                    <td><span class="badge bg-<?php echo $trx['status'] == 'completed' ? 'success' : ($trx['status'] == 'pending' ? 'warning' : 'secondary'); ?>"><?php echo $trx['status']; ?></span></td>
                                </tr>
                                <?php endwhile; ?>
                            </tbody>
                        </table>
                    </div>
                    <a href="transactions.php" class="btn btn-primary btn-sm mt-3">View All Transactions</a>
                </div>
            </div>
        </div>
    </div>
</div>

<?php include 'footer.php'; ?>
EOF

echo -e "${GREEN}✅ Admin panel selesai${NC}"
echo ""

# ==================== STEP 14: KONFIGURASI SSL (OPSIONAL) ====================
echo -e "${YELLOW}[14/15] 🔒 Mengecek SSL (opsional)...${NC}"
read -p "Apakah Anda ingin mengkonfigurasi SSL dengan domain? (y/n): " SETUP_SSL

if [[ "$SETUP_SSL" =~ ^[Yy]$ ]]; then
    read -p "Masukkan domain Anda (contoh: domain.com): " SSL_DOMAIN
    read -p "Masukkan email Anda: " SSL_EMAIL
    
    apt install -y certbot python3-certbot-apache
    certbot --apache -d $SSL_DOMAIN --non-interactive --agree-tos -m $SSL_EMAIL
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSL berhasil dikonfigurasi untuk $SSL_DOMAIN${NC}"
    else
        echo -e "${YELLOW}⚠️ Gagal konfigurasi SSL, lanjut dengan HTTP${NC}"
    fi
fi

echo ""

# ==================== STEP 15: SELESAI ====================
clear
echo -e "${PURPLE}"
echo "    ╔═══════════════════════════════════════════════════════════════════════╗"
echo "    ║                                                                       ║"
echo "    ║              ✨ INSTALASI SELESAI! ✨                                 ║"
echo "    ║                                                                       ║"
echo "    ║         RW MLBB VPN PANEL - ENTERPRISE EDITION                       ║"
echo "    ║         MULTI ROLE: Admin | Reseller | User                          ║"
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
echo -e "⚙️  ${WHITE}Admin Panel:${NC}      ${CYAN}http://${IP_VPS}/admin/${NC}"
echo -e "💰 ${WHITE}Reseller Panel:${NC}    ${CYAN}http://${IP_VPS}/reseller/${NC}"
echo -e "👤 ${WHITE}User Panel:${NC}        ${CYAN}http://${IP_VPS}/user/${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🔑 LOGIN AKUN 🔑                                         ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "👑 ${WHITE}Super Admin:${NC}"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo -e "👤 ${WHITE}User:${NC} (daftar sendiri via register)"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🚀 FITUR SUPER LENGKAP 🚀                                 ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   ✅ Multi Role: Super Admin | Admin | Reseller | User"
echo "   ✅ Reseller System with Commission"
echo "   ✅ Withdrawal System"
echo "   ✅ Bot Matchmaking with Statistics"
echo "   ✅ VPN Account Management"
echo "   ✅ Server Management"
echo "   ✅ Product Management"
echo "   ✅ Transaction History"
echo "   ✅ Ticket Support System"
echo "   ✅ Announcements"
echo "   ✅ Blog System"
echo "   ✅ Pages Management"
echo "   ✅ Settings Management"
echo "   ✅ Activity Logs"
echo "   ✅ Notifications"
echo "   ✅ API Integration"
echo "   ✅ Real-time Updates with Socket.io"
echo "   ✅ Responsive Design"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📦 NODE INSTALLER 📦                                     ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   Untuk install node server, jalankan di VPS node:"
echo -e "   ${YELLOW}curl -s http://${IP_VPS}/install-node.sh | bash${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🔧 INFORMASI TEKNIS 🔧                                    ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   MySQL Root Password: ${MYSQL_ROOT_PASSWORD}"
echo "   Database: vpn_panel"
echo "   API Key: ${NODE_API_KEY}"
echo "   JWT Secret: ${JWT_SECRET}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              📁 LOG FILES 📁                                          ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   Apache Logs: /var/log/apache2/"
echo "   API Logs: /var/log/api/"
echo "   MySQL Logs: /var/log/mysql/"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              🔄 PERINTAH PENTING 🔄                                    ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "   Restart API: systemctl restart vpn-panel-api"
echo "   Restart Apache: systemctl restart apache2"
echo "   Restart MySQL: systemctl restart mysql"
echo "   View API Logs: journalctl -u vpn-panel-api -f"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}      🎮 TERIMA KASIH - SELAMAT BERTANDING DAN BERBISNIS! 🎮          ${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"