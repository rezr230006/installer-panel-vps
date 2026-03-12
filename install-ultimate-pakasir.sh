#!/bin/bash
# ============================================================================
# RW MLBB VPN PANEL - ULTIMATE FINAL EDITION
# DENGAN UI/UX SUPER PREMIUM + FIX TOTAL NETWORK ERROR
# TANPA LINK PHPMYADMIN DI HOME & TANPA DEMO TEXT DI LOGIN
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
echo "    ║         🌟 ULTIMATE FINAL EDITION 🌟                                 ║"
echo "    ║         🎨 UI/UX SUPER PREMIUM                                      ║"
echo "    ║         🔧 FIX TOTAL NETWORK ERROR                                  ║"
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

-- Insert default settings (TANPA LINK PHPMYADMIN)
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
echo -e "${YELLOW}[7/15] ⚙️  Membuat backend API Node.js dengan FIX Network Error...${NC}"

mkdir -p /var/www/api
cd /var/www/api

cat > package.json << 'EOF'
{
  "name": "vpn-panel-ultimate-api",
  "version": "3.0.0",
  "description": "RW MLBB VPN Ultimate API - Fix Network Error",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "jsonwebtoken": "^9.0.1",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "axios": "^1.4.0",
    "socket.io": "^4.6.1",
    "node-cron": "^3.0.2",
    "qrcode": "^1.5.3",
    "multer": "^1.4.5-lts.1",
    "uuid": "^9.0.0",
    "nanoid": "^3.3.4",
    "express-validator": "^7.0.1",
    "helmet": "^7.0.0",
    "compression": "^1.7.4",
    "winston": "^3.10.0",
    "morgan": "^1.10.0",
    "redis": "^4.6.7"
  }
}
EOF

npm install

cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
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
const QRCode = require('qrcode');
const Redis = require('ioredis');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST", "PUT", "DELETE"],
        credentials: true
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
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
};

// ==================== REDIS SETUP ====================
const redis = new Redis({
    host: 'localhost',
    port: 6379,
    maxRetriesPerRequest: null,
    retryStrategy: times => Math.min(times * 50, 2000)
});

// ==================== DATABASE POOL ====================
const pool = mysql.createPool(DB_CONFIG);
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
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use('/uploads', express.static('uploads'));

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
    limits: { fileSize: 5 * 1024 * 1024 },
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
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({ error: 'No token provided' });
        }
        
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
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ error: 'Token expired' });
        }
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

// ==================== API ROUTES ====================

// ==================== AUTH ROUTES (FIX NETWORK ERROR) ====================
app.post('/api/auth/login', [
    body('username').notEmpty().trim(),
    body('password').notEmpty()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
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
            JWT_SECRET,
            { expiresIn: '7d' }
        );
        
        await promisePool.query(
            'UPDATE users SET last_login = NOW(), last_ip = ? WHERE id = ?',
            [req.headers['x-forwarded-for'] || req.socket.remoteAddress, user.id]
        );
        
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
    body('full_name').optional().trim()
], async (req, res) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const { username, email, password, full_name } = req.body;
        
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
            'INSERT INTO users (uuid, username, password, email, full_name, role) VALUES (?, ?, ?, ?, ?, ?)',
            [uuid, username, hashedPassword, email, full_name || null, 'user']
        );
        
        res.json({
            success: true,
            message: 'Registration successful. Please login.'
        });
    } catch (err) {
        logger.error('Registration error:', err);
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

app.get('/api/public/products', async (req, res) => {
    try {
        const [rows] = await promisePool.query(
            'SELECT * FROM products WHERE status = TRUE ORDER BY price ASC'
        );
        res.json(rows);
    } catch (err) {
        logger.error('Get products error:', err);
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

// ==================== ERROR HANDLER ====================
app.use((err, req, res, next) => {
    logger.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// ==================== SOCKET.IO ====================
io.on('connection', (socket) => {
    console.log('New client connected:', socket.id);
    
    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});

// ==================== START SERVER ====================
server.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Ultimate API running on port ${PORT}`);
    console.log(`✅ Network error FIXED - CORS enabled for all origins`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    server.close(() => {
        pool.end();
        redis.quit();
        process.exit(0);
    });
});
EOF

echo -e "${GREEN}✅ Backend API dengan FIX Network Error selesai${NC}"
echo ""

# ==================== STEP 8: BUAT FRONTEND WEBSITE PREMIUM ====================
echo -e "${YELLOW}[8/15] 🎨 Membuat frontend website dengan UI/UX SUPER PREMIUM...${NC}"

mkdir -p /var/www/html/{assets/{css,js,img,uploads},admin,user,reseller,api}

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

// Get settings
$settings = [];
$result = $conn->query("SELECT setting_key, setting_value FROM settings");
while($row = $result->fetch_assoc()) {
    $settings[$row['setting_key']] = $row['setting_value'];
}

// Site URL
$site_url = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http") . "://{$_SERVER['HTTP_HOST']}";

// API URL
$api_url = "http://localhost:3000/api";

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

function apiRequest($endpoint, $method = 'GET', $data = null) {
    global $api_url;
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $api_url . $endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
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
    
    if (curl_error($ch)) {
        error_log('Curl error: ' . curl_error($ch));
        return [
            'code' => 500,
            'data' => ['error' => 'Connection error']
        ];
    }
    
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'data' => json_decode($response, true)
    ];
}
?>
EOF

# ==================== CSS PREMIUM ====================
cat > /var/www/html/assets/css/style.css << 'EOF'
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
    --lighter: #2a2f45;
    --text: #ffffff;
    --text-muted: rgba(255, 255, 255, 0.7);
    --border: rgba(255, 77, 77, 0.2);
    --shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
    --shadow-hover: 0 20px 40px rgba(255, 77, 77, 0.2);
    --gradient: linear-gradient(135deg, var(--primary), var(--secondary));
    --gradient-hover: linear-gradient(135deg, #ff3333, #8e44ad);
}

body {
    font-family: 'Poppins', sans-serif;
    background: var(--dark);
    color: var(--text);
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    position: relative;
    overflow-x: hidden;
}

body::before {
    content: '';
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: radial-gradient(circle at 20% 20%, rgba(255, 77, 77, 0.05) 0%, transparent 30%),
                radial-gradient(circle at 80% 80%, rgba(155, 89, 182, 0.05) 0%, transparent 30%);
    pointer-events: none;
    z-index: -1;
}

.main-content {
    flex: 1;
    padding-top: 80px;
    position: relative;
    z-index: 1;
}

/* Navbar Premium */
.navbar {
    background: rgba(10, 14, 28, 0.95) !important;
    backdrop-filter: blur(10px);
    border-bottom: 1px solid var(--border);
    padding: 15px 0;
    box-shadow: var(--shadow);
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 1000;
    animation: slideDown 0.5s ease;
}

@keyframes slideDown {
    from { transform: translateY(-100%); }
    to { transform: translateY(0); }
}

.navbar-brand {
    font-weight: 700;
    font-size: 1.5rem;
    background: var(--gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    position: relative;
    padding: 5px 0;
}

.navbar-brand::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 0;
    width: 0;
    height: 2px;
    background: var(--gradient);
    transition: width 0.3s ease;
}

.navbar-brand:hover::after {
    width: 100%;
}

.nav-link {
    color: var(--text) !important;
    font-weight: 500;
    margin: 0 10px;
    position: relative;
    transition: color 0.3s;
    padding: 8px 0 !important;
}

.nav-link:hover,
.nav-link.active {
    color: var(--primary) !important;
}

.nav-link::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 50%;
    width: 0;
    height: 2px;
    background: var(--gradient);
    transition: all 0.3s;
    transform: translateX(-50%);
}

.nav-link:hover::after,
.nav-link.active::after {
    width: 100%;
}

/* Buttons Premium */
.btn {
    padding: 12px 30px;
    border-radius: 10px;
    font-weight: 600;
    transition: all 0.3s;
    position: relative;
    overflow: hidden;
    border: none;
    cursor: pointer;
    z-index: 1;
}

.btn::before {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 0;
    height: 0;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.2);
    transform: translate(-50%, -50%);
    transition: width 0.6s, height 0.6s;
    z-index: -1;
}

.btn:hover::before {
    width: 300px;
    height: 300px;
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
    transform: translateY(-3px);
}

/* Cards Premium */
.card {
    background: rgba(26, 31, 53, 0.8);
    backdrop-filter: blur(10px);
    border: 1px solid var(--border);
    border-radius: 20px;
    color: var(--text);
    overflow: hidden;
    transition: all 0.3s;
    height: 100%;
    box-shadow: var(--shadow);
}

.card:hover {
    transform: translateY(-10px);
    border-color: var(--primary);
    box-shadow: var(--shadow-hover);
}

.card-header {
    background: rgba(255, 77, 77, 0.1);
    border-bottom: 1px solid var(--border);
    padding: 20px;
    font-weight: 600;
}

.card-body {
    padding: 20px;
}

/* Forms Premium */
.form-control, .form-select {
    background: rgba(10, 14, 28, 0.8);
    border: 1px solid var(--border);
    border-radius: 10px;
    color: var(--text);
    padding: 12px 16px;
    transition: all 0.3s;
    width: 100%;
}

.form-control:focus, .form-select:focus {
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(255, 77, 77, 0.2);
    background: rgba(10, 14, 28, 0.9);
    color: var(--text);
    outline: none;
}

.form-label {
    font-weight: 500;
    margin-bottom: 8px;
    color: var(--text-muted);
}

/* Hero Section Premium */
.hero {
    text-align: center;
    padding: 120px 0;
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

.hero::after {
    content: '';
    position: absolute;
    bottom: -50%;
    left: -50%;
    width: 100%;
    height: 100%;
    background: radial-gradient(circle, rgba(155, 89, 182, 0.1) 0%, transparent 50%);
    animation: pulse 10s ease-in-out infinite reverse;
}

@keyframes pulse {
    0%, 100% { transform: scale(1); opacity: 0.5; }
    50% { transform: scale(1.2); opacity: 0.8; }
}

.hero h1 {
    font-size: 4rem;
    font-weight: 700;
    background: var(--gradient);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    margin-bottom: 20px;
    position: relative;
    animation: fadeInUp 0.8s ease;
}

.hero p {
    font-size: 1.2rem;
    color: var(--text-muted);
    max-width: 700px;
    margin: 0 auto 30px;
    position: relative;
    animation: fadeInUp 1s ease;
}

/* Features Premium */
.feature-box {
    text-align: center;
    padding: 40px;
    border-radius: 20px;
    background: rgba(26, 31, 53, 0.6);
    border: 1px solid var(--border);
    transition: all 0.3s;
    height: 100%;
    backdrop-filter: blur(5px);
    animation: fadeInUp 0.8s ease;
}

.feature-box:hover {
    transform: translateY(-10px);
    border-color: var(--primary);
    background: rgba(26, 31, 53, 0.8);
    box-shadow: var(--shadow-hover);
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
    transition: all 0.3s;
}

.feature-box:hover .feature-icon {
    transform: rotate(360deg) scale(1.1);
}

/* Pricing Premium */
.pricing-card {
    background: rgba(26, 31, 53, 0.8);
    border-radius: 20px;
    padding: 40px;
    text-align: center;
    border: 1px solid var(--border);
    transition: all 0.3s;
    position: relative;
    overflow: hidden;
    height: 100%;
    backdrop-filter: blur(5px);
    animation: fadeInUp 0.8s ease;
}

.pricing-card:hover {
    transform: translateY(-10px);
    border-color: var(--primary);
    box-shadow: var(--shadow-hover);
}

.pricing-card .popular {
    position: absolute;
    top: 20px;
    right: -30px;
    background: var(--gradient);
    color: var(--text);
    padding: 5px 30px;
    transform: rotate(45deg);
    font-size: 14px;
    font-weight: 600;
    box-shadow: 0 5px 15px rgba(255, 77, 77, 0.3);
}

.pricing-card .price {
    font-size: 48px;
    font-weight: 700;
    color: var(--primary);
    margin: 20px 0;
}

.pricing-card .price small {
    font-size: 16px;
    color: var(--text-muted);
}

/* Tables Premium */
.table {
    color: var(--text);
    margin-bottom: 0;
}

.table thead th {
    border-bottom: 2px solid var(--border);
    color: var(--primary);
    font-weight: 600;
    padding: 15px;
    background: rgba(255, 77, 77, 0.05);
}

.table td {
    border-color: var(--border);
    padding: 15px;
    vertical-align: middle;
}

.table-hover tbody tr:hover {
    background: rgba(255, 77, 77, 0.1);
    transition: all 0.3s;
}

/* Alerts Premium */
.alert {
    border-radius: 10px;
    border: none;
    padding: 15px 20px;
    margin-bottom: 20px;
    animation: slideIn 0.3s ease;
}

@keyframes slideIn {
    from { transform: translateX(-100%); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
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

/* Badges Premium */
.badge {
    padding: 5px 10px;
    border-radius: 5px;
    font-weight: 500;
    font-size: 12px;
}

.badge.bg-success {
    background: #4caf50 !important;
}

.badge.bg-danger {
    background: #f44336 !important;
}

.badge.bg-warning {
    background: #ff9800 !important;
    color: var(--dark);
}

.badge.bg-info {
    background: #2196f3 !important;
}

.badge.bg-primary {
    background: var(--gradient) !important;
}

/* Progress Bars Premium */
.progress {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 10px;
    height: 8px;
    overflow: hidden;
}

.progress-bar {
    background: var(--gradient);
    border-radius: 10px;
    position: relative;
    animation: progress 1s ease;
}

@keyframes progress {
    from { width: 0; }
    to { width: 100%; }
}

/* Footer Premium */
.footer {
    background: rgba(5, 7, 12, 0.95);
    border-top: 1px solid var(--border);
    padding: 60px 0 30px;
    margin-top: 50px;
    position: relative;
    overflow: hidden;
}

.footer::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 1px;
    background: var(--gradient);
}

.footer h5 {
    color: var(--primary);
    margin-bottom: 20px;
    font-weight: 600;
    position: relative;
    display: inline-block;
}

.footer h5::after {
    content: '';
    position: absolute;
    bottom: -5px;
    left: 0;
    width: 30px;
    height: 2px;
    background: var(--gradient);
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
    transition: all 0.3s;
    position: relative;
    padding-left: 15px;
}

.footer ul li a::before {
    content: '›';
    position: absolute;
    left: 0;
    color: var(--primary);
    transition: left 0.3s;
}

.footer ul li a:hover {
    color: var(--primary);
    padding-left: 20px;
}

.social-links {
    display: flex;
    gap: 10px;
    margin-top: 20px;
}

.social-links a {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    background: rgba(255, 77, 77, 0.1);
    border-radius: 50%;
    color: var(--text);
    transition: all 0.3s;
    text-decoration: none;
    font-size: 18px;
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
    font-size: 14px;
}

/* Loading Spinner Premium */
.spinner {
    width: 40px;
    height: 40px;
    border: 4px solid rgba(255, 77, 77, 0.1);
    border-top-color: var(--primary);
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

#loading {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(10, 14, 28, 0.8);
    backdrop-filter: blur(5px);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 9999;
    animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
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
    height: 10px;
}

::-webkit-scrollbar-track {
    background: var(--lighter);
}

::-webkit-scrollbar-thumb {
    background: var(--gradient);
    border-radius: 5px;
    transition: all 0.3s;
}

::-webkit-scrollbar-thumb:hover {
    background: var(--gradient-hover);
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
    
    .footer h5::after {
        left: 50%;
        transform: translateX(-50%);
    }
    
    .footer ul li a {
        padding-left: 0;
    }
    
    .footer ul li a::before {
        display: none;
    }
}
EOF

# ==================== MAIN.JS ====================
cat > /var/www/html/assets/js/main.js << 'EOF
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
        $('.alert').fadeOut('slow', function() {
            $(this).remove();
        });
    }, 5000);

    // Smooth scroll
    $('a[href*="#"]:not([href="#"])').on('click', function(e) {
        if (location.pathname.replace(/^\//, '') === this.pathname.replace(/^\//, '') 
            && location.hostname === this.hostname) {
            var target = $(this.hash);
            target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
            if (target.length) {
                e.preventDefault();
                $('html, body').animate({
                    scrollTop: target.offset().top - 80
                }, 800);
            }
        }
    });

    // Copy to clipboard
    $('.copy-btn').on('click', function() {
        var text = $(this).data('copy');
        navigator.clipboard.writeText(text).then(function() {
            showToast('Copied to clipboard!', 'success');
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
    $('#password, #new_password').on('keyup', function() {
        var password = $(this).val();
        var strength = checkPasswordStrength(password);
        var indicator = $(this).closest('.form-group').find('.password-strength');
        
        if (indicator.length === 0) {
            $(this).closest('.form-group').append('<div class="password-strength mt-2"></div>');
            indicator = $(this).closest('.form-group').find('.password-strength');
        }
        
        var strengthText = '';
        var strengthClass = '';
        
        if (strength < 30) {
            strengthText = 'Lemah';
            strengthClass = 'danger';
        } else if (strength < 60) {
            strengthText = 'Sedang';
            strengthClass = 'warning';
        } else {
            strengthText = 'Kuat';
            strengthClass = 'success';
        }
        
        indicator.html(`
            <div class="progress" style="height: 5px;">
                <div class="progress-bar bg-${strengthClass}" style="width: ${strength}%"></div>
            </div>
            <small class="text-${strengthClass} mt-1 d-block">${strengthText}</small>
        `);
    });

    function checkPasswordStrength(password) {
        var strength = 0;
        
        if (password.length >= 8) strength += 25;
        if (password.match(/[a-z]+/)) strength += 25;
        if (password.match(/[A-Z]+/)) strength += 25;
        if (password.match(/[0-9]+/)) strength += 25;
        if (password.match(/[$@#&!]+/)) strength += 25;
        
        return Math.min(strength, 100);
    }

    // Confirm actions
    $('.confirm-delete, [data-confirm]').on('click', function(e) {
        e.preventDefault();
        var url = $(this).attr('href') || $(this).data('url');
        var message = $(this).data('confirm') || 'Apakah Anda yakin ingin menghapus item ini?';
        
        Swal.fire({
            title: 'Konfirmasi',
            text: message,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Ya, hapus!',
            cancelButtonText: 'Batal'
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
    $('body').append('<div id="loading"><div class="spinner"></div></div>');
}

// Hide loading
function hideLoading() {
    $('#loading').remove();
}

// Show toast notification
function showToast(message, type = 'success') {
    Swal.fire({
        text: message,
        icon: type,
        toast: true,
        position: 'top-end',
        showConfirmButton: false,
        timer: 3000,
        timerProgressBar: true
    });
}

// AJAX setup
$.ajaxSetup({
    beforeSend: function(xhr) {
        showLoading();
    },
    complete: function() {
        hideLoading();
    },
    error: function(xhr, status, error) {
        console.log('AJAX Error:', error, xhr.responseText);
        
        var message = 'Terjadi kesalahan';
        if (xhr.responseJSON && xhr.responseJSON.error) {
            message = xhr.responseJSON.error;
        }
        
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: message
        });
    }
});

// Socket.io connection
if (typeof socket === 'undefined' && typeof io !== 'undefined') {
    var socket = io('http://' + window.location.hostname + ':3000', {
        transports: ['websocket', 'polling'],
        reconnectionAttempts: 5
    });
    
    socket.on('connect', function() {
        console.log('Socket connected');
    });
    
    socket.on('connect_error', function(error) {
        console.log('Socket connection error:', error);
    });
    
    socket.on('disconnect', function() {
        console.log('Socket disconnected');
    });
    
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
}

// Format currency
function formatRupiah(amount) {
    return new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(amount);
}

// Format bytes
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    
    var k = 1024;
    var dm = decimals < 0 ? 0 : decimals;
    var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
    
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// Countdown timer
function startCountdown(elementId, endTime) {
    var countdown = setInterval(function() {
        var now = new Date().getTime();
        var distance = endTime - now;
        
        if (distance < 0) {
            clearInterval(countdown);
            document.getElementById(elementId).innerHTML = 'EXPIRED';
            return;
        }
        
        var days = Math.floor(distance / (1000 * 60 * 60 * 24));
        var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
        var seconds = Math.floor((distance % (1000 * 60)) / 1000);
        
        document.getElementById(elementId).innerHTML = 
            days + 'd ' + hours + 'h ' + minutes + 'm ' + seconds + 's';
    }, 1000);
}

// QR Code generator
function generateQRCode(elementId, text, size = 200) {
    new QRCode(document.getElementById(elementId), {
        text: text,
        width: size,
        height: size
    });
}
EOF

# ==================== HEADER.PHP ====================
cat > /var/www/html/header.php << 'EOF'
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
    
    <!-- AOS Animation -->
    <link href="https://unpkg.com/aos@2.3.1/dist/aos.css" rel="stylesheet">
    
    <!-- SweetAlert2 -->
    <link href="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.min.css" rel="stylesheet">
    
    <!-- Custom CSS -->
    <link rel="stylesheet" href="/assets/css/style.css">
    
    <!-- Favicon -->
    <link rel="shortcut icon" href="<?php echo getSetting('site_favicon', '/assets/img/favicon.ico'); ?>">
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
                                <li><hr class="dropdown-divider"></li>
                            <?php elseif ($user_role == 'reseller'): ?>
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

<!-- Main Content -->
<main class="main-content">
EOF

# ==================== FOOTER.PHP ====================
cat > /var/www/html/footer.php << 'EOF'
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
                    <?php if (getSetting('youtube_url')): ?>
                        <a href="<?php echo getSetting('youtube_url'); ?>" target="_blank"><i class="fab fa-youtube"></i></a>
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

<!-- QR Code -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>

<!-- Socket.io -->
<script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>

<!-- Custom JS -->
<script src="/assets/js/main.js"></script>

<script>
AOS.init({
    duration: 800,
    once: true
});
</script>

</body>
</html>
EOF

# ==================== INDEX.PHP (HOME) ====================
cat > /var/www/html/index.php << 'EOF'
<?php
require_once 'config.php';
require_once 'functions.php';

$page_title = 'Home';
include 'header.php';

// Get products
$products = $conn->query("SELECT * FROM products WHERE status = TRUE ORDER BY price ASC LIMIT 3");
?>

<!-- Hero Section -->
<section class="hero">
    <div class="container">
        <h1 data-aos="fade-up"><?php echo getSetting('site_name'); ?></h1>
        <p data-aos="fade-up" data-aos-delay="100"><?php echo getSetting('site_description'); ?></p>
        <div class="mt-4" data-aos="fade-up" data-aos-delay="200">
            <?php if (!isset($_SESSION['user_id'])): ?>
                <a href="/register.php" class="btn btn-primary btn-lg me-3">
                    <i class="fas fa-user-plus me-2"></i>Daftar Sekarang
                </a>
            <?php endif; ?>
            <a href="/features.php" class="btn btn-outline-light btn-lg">
                <i class="fas fa-info-circle me-2"></i>Pelajari Lebih
            </a>
        </div>
    </div>
</section>

<!-- Features Section -->
<section class="py-5">
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

<!-- Pricing Section -->
<section class="py-5">
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

<!-- Stats Section -->
<section class="py-5">
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

# ==================== LOGIN.PHP (TANPA DEMO TEXT) ====================
cat > /var/www/html/login.php << 'EOF'
<?php
require_once 'config.php';
require_once 'functions.php';

if (isset($_SESSION['user_id'])) {
    if ($_SESSION['user_role'] == 'admin' || $_SESSION['user_role'] == 'super_admin') {
        redirect('/admin/');
    } elseif ($_SESSION['user_role'] == 'reseller') {
        redirect('/reseller/');
    } else {
        redirect('/user/');
    }
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    
    // Panggil API
    $api_url = "http://localhost:3000/api/auth/login";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $api_url);
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
            } elseif ($data['user']['role'] == 'reseller') {
                redirect('/reseller/');
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
    
    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            position: relative;
            overflow: hidden;
        }
        
        body::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 100%;
            height: 100%;
            background: radial-gradient(circle, rgba(255, 77, 77, 0.1) 0%, transparent 50%);
            animation: pulse 10s ease-in-out infinite;
        }
        
        body::after {
            content: '';
            position: absolute;
            bottom: -50%;
            left: -50%;
            width: 100%;
            height: 100%;
            background: radial-gradient(circle, rgba(155, 89, 182, 0.1) 0%, transparent 50%);
            animation: pulse 10s ease-in-out infinite reverse;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); opacity: 0.5; }
            50% { transform: scale(1.2); opacity: 0.8; }
        }
        
        .login-container {
            width: 100%;
            max-width: 450px;
            padding: 20px;
            position: relative;
            z-index: 1;
        }
        
        .login-card {
            background: rgba(26, 31, 53, 0.8);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 77, 77, 0.2);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
            animation: fadeInUp 0.8s ease;
        }
        
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
        
        .login-header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .login-header h2 {
            font-size: 2rem;
            font-weight: 700;
            background: linear-gradient(135deg, #ff4d4d, #9b59b6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: rgba(255, 255, 255, 0.8);
            font-weight: 500;
        }
        
        .form-control {
            width: 100%;
            padding: 12px 16px;
            background: rgba(10, 14, 28, 0.8);
            border: 1px solid rgba(255, 77, 77, 0.3);
            border-radius: 10px;
            color: #fff;
            font-size: 16px;
            transition: all 0.3s;
        }
        
        .form-control:focus {
            border-color: #ff4d4d;
            box-shadow: 0 0 0 3px rgba(255, 77, 77, 0.2);
            background: rgba(10, 14, 28, 0.9);
            outline: none;
        }
        
        .btn-login {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #ff4d4d, #9b59b6);
            border: none;
            border-radius: 10px;
            color: #fff;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            position: relative;
            overflow: hidden;
        }
        
        .btn-login::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.2);
            transform: translate(-50%, -50%);
            transition: width 0.6s, height 0.6s;
        }
        
        .btn-login:hover::before {
            width: 300px;
            height: 300px;
        }
        
        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(255, 77, 77, 0.3);
        }
        
        .alert {
            padding: 12px 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            animation: slideIn 0.3s ease;
        }
        
        @keyframes slideIn {
            from {
                transform: translateX(-100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
        
        .alert-danger {
            background: rgba(244, 67, 54, 0.2);
            border-left: 4px solid #f44336;
            color: #f44336;
        }
        
        .footer-links {
            text-align: center;
            margin-top: 20px;
        }
        
        .footer-links a {
            color: #ff4d4d;
            text-decoration: none;
            transition: color 0.3s;
        }
        
        .footer-links a:hover {
            color: #9b59b6;
        }
        
        .back-home {
            position: absolute;
            top: 20px;
            left: 20px;
            z-index: 2;
        }
        
        .back-home a {
            color: #fff;
            text-decoration: none;
            font-size: 14px;
            transition: color 0.3s;
        }
        
        .back-home a:hover {
            color: #ff4d4d;
        }
        
        .back-home i {
            margin-right: 5px;
        }
    </style>
</head>
<body>
    <div class="back-home">
        <a href="/"><i class="fas fa-arrow-left"></i> Kembali ke Home</a>
    </div>
    
    <div class="login-container">
        <div class="login-card">
            <div class="login-header">
                <i class="fas fa-shield-alt fa-3x mb-3" style="color: #ff4d4d;"></i>
                <h2><?php echo getSetting('site_name'); ?></h2>
                <p class="text-muted">Silakan login ke akun Anda</p>
            </div>
            
            <?php if ($error): ?>
                <div class="alert alert-danger"><?php echo $error; ?></div>
            <?php endif; ?>
            
            <form method="POST" id="loginForm">
                <div class="form-group">
                    <label><i class="fas fa-user me-2"></i>Username / Email</label>
                    <input type="text" name="username" class="form-control" placeholder="Masukkan username atau email" required autofocus>
                </div>
                
                <div class="form-group">
                    <label><i class="fas fa-lock me-2"></i>Password</label>
                    <input type="password" name="password" class="form-control" placeholder="Masukkan password" required>
                </div>
                
                <button type="submit" class="btn-login">
                    <i class="fas fa-sign-in-alt me-2"></i>Login
                </button>
            </form>
            
            <div class="footer-links">
                <p>Belum punya akun? <a href="/register.php">Daftar Sekarang</a></p>
            </div>
        </div>
    </div>
    
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    
    <script>
    $('#loginForm').on('submit', function() {
        $(this).find('button[type="submit"]').prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-2"></i>Loading...');
    });
    </script>
</body>
</html>
EOF

# ==================== REGISTER.PHP ====================
cat > /var/www/html/register.php << 'EOF'
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
        // Panggil API
        $api_url = "http://localhost:3000/api/auth/register";
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $api_url);
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
    
    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #0a0e1c 0%, #1a1f35 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #fff;
            position: relative;
            overflow: hidden;
        }
        
        body::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 100%;
            height: 100%;
            background: radial-gradient(circle, rgba(255, 77, 77, 0.1) 0%, transparent 50%);
            animation: pulse 10s ease-in-out infinite;
        }
        
        body::after {
            content: '';
            position: absolute;
            bottom: -50%;
            left: -50%;
            width: 100%;
            height: 100%;
            background: radial-gradient(circle, rgba(155, 89, 182, 0.1) 0%, transparent 50%);
            animation: pulse 10s ease-in-out infinite reverse;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); opacity: 0.5; }
            50% { transform: scale(1.2); opacity: 0.8; }
        }
        
        .register-container {
            width: 100%;
            max-width: 500px;
            padding: 20px;
            position: relative;
            z-index: 1;
        }
        
        .register-card {
            background: rgba(26, 31, 53, 0.8);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 77, 77, 0.2);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
            animation: fadeInUp 0.8s ease;
        }
        
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
        
        .register-header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .register-header h2 {
            font-size: 2rem;
            font-weight: 700;
            background: linear-gradient(135deg, #ff4d4d, #9b59b6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 10px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: rgba(255, 255, 255, 0.8);
            font-weight: 500;
        }
        
        .form-control {
            width: 100%;
            padding: 12px 16px;
            background: rgba(10, 14, 28, 0.8);
            border: 1px solid rgba(255, 77, 77, 0.3);
            border-radius: 10px;
            color: #fff;
            font-size: 16px;
            transition: all 0.3s;
        }
        
        .form-control:focus {
            border-color: #ff4d4d;
            box-shadow: 0 0 0 3px rgba(255, 77, 77, 0.2);
            background: rgba(10, 14, 28, 0.9);
            outline: none;
        }
        
        .btn-register {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #ff4d4d, #9b59b6);
            border: none;
            border-radius: 10px;
            color: #fff;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s;
            position: relative;
            overflow: hidden;
        }
        
        .btn-register::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.2);
            transform: translate(-50%, -50%);
            transition: width 0.6s, height 0.6s;
        }
        
        .btn-register:hover::before {
            width: 300px;
            height: 300px;
        }
        
        .btn-register:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(255, 77, 77, 0.3);
        }
        
        .alert {
            padding: 12px 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            animation: slideIn 0.3s ease;
        }
        
        @keyframes slideIn {
            from {
                transform: translateX(-100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
        
        .alert-danger {
            background: rgba(244, 67, 54, 0.2);
            border-left: 4px solid #f44336;
            color: #f44336;
        }
        
        .alert-success {
            background: rgba(76, 175, 80, 0.2);
            border-left: 4px solid #4caf50;
            color: #4caf50;
        }
        
        .footer-links {
            text-align: center;
            margin-top: 20px;
        }
        
        .footer-links a {
            color: #ff4d4d;
            text-decoration: none;
            transition: color 0.3s;
        }
        
        .footer-links a:hover {
            color: #9b59b6;
        }
        
        .back-home {
            position: absolute;
            top: 20px;
            left: 20px;
            z-index: 2;
        }
        
        .back-home a {
            color: #fff;
            text-decoration: none;
            font-size: 14px;
            transition: color 0.3s;
        }
        
        .back-home a:hover {
            color: #ff4d4d;
        }
        
        .back-home i {
            margin-right: 5px;
        }
        
        .password-strength {
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <div class="back-home">
        <a href="/"><i class="fas fa-arrow-left"></i> Kembali ke Home</a>
    </div>
    
    <div class="register-container">
        <div class="register-card">
            <div class="register-header">
                <i class="fas fa-user-plus fa-3x mb-3" style="color: #ff4d4d;"></i>
                <h2>Daftar Akun Baru</h2>
                <p class="text-muted">Bergabung dengan <?php echo getSetting('site_name'); ?></p>
            </div>
            
            <?php if ($error): ?>
                <div class="alert alert-danger"><?php echo $error; ?></div>
            <?php endif; ?>
            
            <?php if ($success): ?>
                <div class="alert alert-success"><?php echo $success; ?></div>
                <meta http-equiv="refresh" content="2;url=/login.php">
            <?php endif; ?>
            
            <form method="POST" id="registerForm">
                <div class="form-group">
                    <label><i class="fas fa-user me-2"></i>Username</label>
                    <input type="text" name="username" class="form-control" placeholder="Masukkan username" required autofocus>
                </div>
                
                <div class="form-group">
                    <label><i class="fas fa-envelope me-2"></i>Email</label>
                    <input type="email" name="email" class="form-control" placeholder="Masukkan email" required>
                </div>
                
                <div class="form-group">
                    <label><i class="fas fa-user-tag me-2"></i>Nama Lengkap</label>
                    <input type="text" name="full_name" class="form-control" placeholder="Masukkan nama lengkap">
                </div>
                
                <div class="form-group">
                    <label><i class="fas fa-lock me-2"></i>Password</label>
                    <input type="password" name="password" id="password" class="form-control" placeholder="Minimal 6 karakter" required>
                </div>
                
                <div class="form-group">
                    <label><i class="fas fa-lock me-2"></i>Konfirmasi Password</label>
                    <input type="password" name="confirm_password" class="form-control" placeholder="Ulangi password" required>
                </div>
                
                <button type="submit" class="btn-register">
                    <i class="fas fa-user-plus me-2"></i>Daftar
                </button>
            </form>
            
            <div class="footer-links">
                <p>Sudah punya akun? <a href="/login.php">Login</a></p>
            </div>
        </div>
    </div>
    
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    
    <script>
    $('#registerForm').on('submit', function() {
        $(this).find('button[type="submit"]').prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-2"></i>Loading...');
    });
    
    // Password strength indicator
    $('#password').on('keyup', function() {
        var password = $(this).val();
        var strength = 0;
        
        if (password.length >= 8) strength += 25;
        if (password.match(/[a-z]+/)) strength += 25;
        if (password.match(/[A-Z]+/)) strength += 25;
        if (password.match(/[0-9]+/)) strength += 25;
        if (password.match(/[$@#&!]+/)) strength += 25;
        
        strength = Math.min(strength, 100);
        
        var indicator = $('.password-strength');
        if (indicator.length === 0) {
            $('#password').after('<div class="password-strength"></div>');
            indicator = $('.password-strength');
        }
        
        var strengthText = '';
        var strengthClass = '';
        
        if (strength < 30) {
            strengthText = 'Lemah';
            strengthClass = 'danger';
        } else if (strength < 60) {
            strengthText = 'Sedang';
            strengthClass = 'warning';
        } else {
            strengthText = 'Kuat';
            strengthClass = 'success';
        }
        
        indicator.html(`
            <div class="progress" style="height: 5px;">
                <div class="progress-bar bg-${strengthClass}" style="width: ${strength}%"></div>
            </div>
            <small class="text-${strengthClass}">${strengthText}</small>
        `);
    });
    </script>
</body>
</html>
EOF

# ==================== LOGOUT.PHP ====================
cat > /var/www/html/logout.php << 'EOF'
<?php
session_start();
session_destroy();
header("Location: /login.php");
exit;
EOF

# ==================== SET PERMISSIONS ====================
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo -e "${GREEN}✅ Frontend website dengan UI/UX SUPER PREMIUM selesai${NC}"
echo ""

# ==================== STEP 9: BUAT SYSTEMD SERVICE ====================
echo -e "${YELLOW}[9/15] ⚙️  Membuat systemd service untuk API...${NC}"

cat > /etc/systemd/system/vpn-panel-api.service << EOF
[Unit]
Description=RW MLBB VPN Ultimate API
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
# Node Installer untuk RW MLBB VPN Ultimate

echo "🚀 Node Installer untuk RW MLBB VPN Ultimate"
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
Description=VPN Node Controller Ultimate
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

# ==================== STEP 13: KONFIGURASI SSL (OPSIONAL) ====================
echo -e "${YELLOW}[13/15] 🔒 Mengecek SSL (opsional)...${NC}"
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

# ==================== STEP 14: CEK API STATUS ====================
echo -e "${YELLOW}[14/15] 🔍 Mengecek API status...${NC}"
sleep 5

API_CHECK=$(curl -s http://localhost:3000/health)
if [[ $API_CHECK == *"ok"* ]]; then
    echo -e "${GREEN}✅ API berjalan dengan baik${NC}"
else
    echo -e "${YELLOW}⚠️ API belum merespon, cek dengan: systemctl status vpn-panel-api${NC}"
fi
echo ""

# ==================== STEP 15: SELESAI ====================
clear
echo -e "${PURPLE}"
echo "    ╔═══════════════════════════════════════════════════════════════════════╗"
echo "    ║                                                                       ║"
echo "    ║              ✨ INSTALASI SELESAI! ✨                                 ║"
echo "    ║                                                                       ║"
echo "    ║         RW MLBB VPN PANEL - ULTIMATE FINAL EDITION                   ║"
echo "    ║         ✅ FIX NETWORK ERROR                                         ║"
echo "    ║         ✅ TANPA LINK PHPMYADMIN                                     ║"
echo "    ║         ✅ TANPA DEMO TEXT                                           ║"
echo "    ║         ✅ UI/UX SUPER PREMIUM                                       ║"
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
echo "   Restart MySQL: systemctl restart mysql"
echo "   View API Logs: journalctl -u vpn-panel-api -f"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}      🎮 TERIMA KASIH - SELAMAT BERTANDING DAN BERBISNIS! 🎮          ${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"