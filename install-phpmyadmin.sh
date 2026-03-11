#!/bin/bash
# INSTALL PHPMYADMIN + AUTO FIX DATABASE UNTUK RW MLBB VPN

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     📦 INSTALL PHPMYADMIN + AUTO FIX DATABASE 📦           ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# ==================== STEP 1: CEK MYSQL ====================
echo -e "${YELLOW}[1/6] 🔍 Memeriksa MySQL...${NC}"

# Cek apakah MySQL berjalan
if ! systemctl is-active --quiet mysql && ! systemctl is-active --quiet mariadb; then
    echo -e "${RED}❌ MySQL tidak berjalan!${NC}"
    echo -e "${YELLOW}🔄 Mencoba start MySQL...${NC}"
    systemctl start mysql 2>/dev/null || systemctl start mariadb 2>/dev/null || {
        echo -e "${RED}❌ Gagal start MySQL. Install ulang? (y/n)${NC}"
        read -p "➤ " INSTALL_MYSQL
        if [[ "$INSTALL_MYSQL" =~ ^[Yy]$ ]]; then
            apt remove --purge mysql* mariadb* -y
            apt autoremove -y
            rm -rf /var/lib/mysql
            apt install -y mariadb-server mariadb-client
            systemctl start mariadb
            mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root123'; FLUSH PRIVILEGES;"
        fi
    }
fi

# Test koneksi
if mysql -u root -p'root123' -e "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}✅ MySQL berjalan dengan password: root123${NC}"
    DB_PASS="root123"
elif mysql -u root -e "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}✅ MySQL tanpa password${NC}"
    DB_PASS=""
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root123'; FLUSH PRIVILEGES;"
    DB_PASS="root123"
else
    echo -e "${YELLOW}⚠️  Reset password MySQL...${NC}"
    systemctl stop mysql 2>/dev/null || systemctl stop mariadb 2>/dev/null
    mysqld_safe --skip-grant-tables &
    sleep 3
    mysql -u root << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root123';
EOF
    killall mysqld_safe 2>/dev/null
    systemctl start mysql 2>/dev/null || systemctl start mariadb 2>/dev/null
    DB_PASS="root123"
fi

echo -e "${GREEN}✅ MySQL siap dengan password: root123${NC}"
echo ""

# ==================== STEP 2: INSTALL PHP & PHPMYADMIN ====================
echo -e "${YELLOW}[2/6] 📦 Menginstall PHP dan phpMyAdmin...${NC}"

# Install PHP dan extensions
apt update
apt install -y php php-cli php-mysql php-mbstring php-zip php-gd php-json php-curl \
    phpmyadmin apache2 libapache2-mod-php wget unzip

# Konfigurasi phpMyAdmin
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password root123" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password root123" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password root123" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

apt install -y phpmyadmin

# Link phpMyAdmin ke direktori web
ln -sf /usr/share/phpmyadmin /var/www/html/phpmyadmin

echo -e "${GREEN}✅ PHP dan phpMyAdmin terinstall${NC}"
echo ""

# ==================== STEP 3: KONFIGURASI DATABASE UNTUK PANEL ====================
echo -e "${YELLOW}[3/6] 🗄️  Membuat database untuk panel...${NC}"

mysql -u root -p'root123' << EOF
CREATE DATABASE IF NOT EXISTS vpn_panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'vpn_user'@'localhost' IDENTIFIED BY 'root123';
GRANT ALL PRIVILEGES ON vpn_panel.* TO 'vpn_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Buat tabel-tabel yang diperlukan
mysql -u root -p'root123' << EOF
USE vpn_panel;

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

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(15,2) NOT NULL,
    duration INT DEFAULT 30,
    traffic_limit BIGINT DEFAULT 107374182400,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

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

-- Insert default admin
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
('Singapore Server', 'Singapore', 'SG', '127.0.0.1', 'node_key_here', TRUE)
ON DUPLICATE KEY UPDATE name=name;
EOF

echo -e "${GREEN}✅ Database dan tabel berhasil dibuat${NC}"
echo ""

# ==================== STEP 4: BUAT FILE KONFIGURASI ====================
echo -e "${YELLOW}[4/6] 📝 Membuat file konfigurasi...${NC}"

cat > /var/www/html/config.php << EOF
<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', 'root123');
define('DB_NAME', 'vpn_panel');

// Panel configuration
define('SITE_NAME', 'RW MLBB VPN');
define('SITE_URL', 'http://' . \$_SERVER['HTTP_HOST']);
define('ADMIN_EMAIL', 'admin@localhost');

// Payment configuration
define('PAKASIR_API_KEY', '');
define('PAKASIR_SLUG', '');
define('USD_RATE', 15000);

// Connect to database
\$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

// Set timezone
date_default_timezone_set('Asia/Jakarta');
?>
EOF

echo -e "${GREEN}✅ File konfigurasi dibuat${NC}"
echo ""

# ==================== STEP 5: BUAT HALAMAN DASHBOARD SEDERHANA ====================
echo -e "${YELLOW}[5/6] 🎨 Membuat halaman dashboard sederhana...${NC}"

cat > /var/www/html/index.php << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RW MLBB VPN - Dashboard</title>
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
        .card {
            background: rgba(26, 31, 53, 0.8);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,77,77,0.2);
            border-radius: 15px;
            color: white;
            margin-bottom: 20px;
        }
        .btn-primary {
            background: linear-gradient(135deg, #ff4d4d 0%, #9b59b6 100%);
            border: none;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(255,77,77,0.3);
        }
        .phpmyadmin-link {
            position: fixed;
            bottom: 20px;
            right: 20px;
            z-index: 1000;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="#">
                <img src="https://img.icons8.com/color/48/000000/mobile-legends.png" width="30" height="30" class="d-inline-block align-top" alt="">
                RW MLBB VPN
            </a>
            <div class="navbar-nav ms-auto">
                <a class="nav-link" href="#home">Home</a>
                <a class="nav-link" href="#features">Fitur</a>
                <a class="nav-link" href="#pricing">Harga</a>
                <a class="nav-link" href="phpmyadmin" target="_blank">phpMyAdmin</a>
            </div>
        </div>
    </nav>

    <div class="container mt-5">
        <div class="row">
            <div class="col-md-12 text-center mb-5">
                <h1 class="display-4">🚀 RW MLBB VPN PREMIUM</h1>
                <p class="lead">VPN Khusus Mobile Legends dengan Teknologi Bot Matchmaking</p>
                <a href="phpmyadmin" class="btn btn-primary btn-lg" target="_blank">🔧 Manage Database via phpMyAdmin</a>
            </div>
        </div>

        <div class="row">
            <div class="col-md-4">
                <div class="card text-center p-4">
                    <h3>📊 Database Status</h3>
                    <?php
                    require_once 'config.php';
                    $result = $conn->query("SHOW TABLES");
                    echo "<p>" . $result->num_rows . " Tables</p>";
                    
                    $users = $conn->query("SELECT COUNT(*) as total FROM users");
                    $user_count = $users->fetch_assoc();
                    echo "<p>👥 " . $user_count['total'] . " Users</p>";
                    ?>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card text-center p-4">
                    <h3>💰 Produk</h3>
                    <?php
                    $products = $conn->query("SELECT COUNT(*) as total FROM products");
                    $product_count = $products->fetch_assoc();
                    echo "<p>📦 " . $product_count['total'] . " Products</p>";
                    ?>
                    <a href="#pricing" class="btn btn-primary">Lihat Produk</a>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card text-center p-4">
                    <h3>🔑 Informasi Login</h3>
                    <p>Admin: admin / admin123</p>
                    <p>MySQL: root / root123</p>
                    <a href="phpmyadmin" class="btn btn-primary" target="_blank">Buka phpMyAdmin</a>
                </div>
            </div>
        </div>

        <div class="row mt-4">
            <div class="col-12">
                <div class="card p-4">
                    <h3>📋 Daftar Users</h3>
                    <table class="table table-dark table-hover">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Username</th>
                                <th>Email</th>
                                <th>Role</th>
                                <th>Balance</th>
                                <th>Created</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php
                            $users = $conn->query("SELECT id, username, email, role, balance, created_at FROM users LIMIT 10");
                            while($row = $users->fetch_assoc()) {
                                echo "<tr>";
                                echo "<td>" . $row['id'] . "</td>";
                                echo "<td>" . $row['username'] . "</td>";
                                echo "<td>" . $row['email'] . "</td>";
                                echo "<td>" . $row['role'] . "</td>";
                                echo "<td>Rp " . number_format($row['balance'], 0, ',', '.') . "</td>";
                                echo "<td>" . $row['created_at'] . "</td>";
                                echo "</tr>";
                            }
                            ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <a href="phpmyadmin" class="phpmyadmin-link btn btn-danger btn-lg" target="_blank">
        🗄️ phpMyAdmin
    </a>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
EOF

# Buat file info php
cat > /var/www/html/info.php << 'EOF'
<?php
phpinfo();
?>
EOF

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo -e "${GREEN}✅ Halaman dashboard dibuat${NC}"
echo ""

# ==================== STEP 6: KONFIGURASI APACHE ====================
echo -e "${YELLOW}[6/6] 🌐 Mengkonfigurasi Apache...${NC}"

# Enable mod rewrite
a2enmod rewrite

# Buat virtual host
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

# Restart Apache
systemctl restart apache2

# Buka port 80 di firewall jika pakai iptables
iptables -A INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
netfilter-persistent save 2>/dev/null || true

echo -e "${GREEN}✅ Apache terkonfigurasi${NC}"
echo ""

# ==================== SELESAI ====================
clear
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           ✅ INSTALASI SELESAI! ✅                           ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}📌 INFORMASI AKSES:${NC}"
echo "----------------------------------------"
echo -e "🌐 Website      : ${YELLOW}http://$(curl -s ifconfig.me)${NC}"
echo -e "🗄️  phpMyAdmin   : ${YELLOW}http://$(curl -s ifconfig.me)/phpmyadmin${NC}"
echo -e "ℹ️  PHP Info     : ${YELLOW}http://$(curl -s ifconfig.me)/info.php${NC}"
echo ""
echo -e "${GREEN}🔑 LOGIN DATABASE (phpMyAdmin):${NC}"
echo "----------------------------------------"
echo -e "Username: ${YELLOW}root${NC}"
echo -e "Password: ${YELLOW}root123${NC}"
echo ""
echo -e "${GREEN}👤 LOGIN ADMIN PANEL:${NC}"
echo "----------------------------------------"
echo -e "Username: ${YELLOW}admin${NC}"
echo -e "Password: ${YELLOW}admin123${NC}"
echo ""
echo -e "${GREEN}📦 DATABASE PANEL:${NC}"
echo "----------------------------------------"
echo -e "Database : ${YELLOW}vpn_panel${NC}"
echo -e "Username : ${YELLOW}vpn_user${NC}"
echo -e "Password : ${YELLOW}root123${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   🎮 GUNAKAN phpMyAdmin UNTUK NGATUR DATABASE! 🎮          ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"