set -e

sudo apt-get update -y
sudo apt-get install -y net-tools wget mysql-server

wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo apt update -y

sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent2
sudo apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

sudo mysql <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
EOF


zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | \
mysql --default-character-set=utf8mb4 -uzabbix -pvagrant zabbix

sudo mysql <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF

sudo sed -i "s/^# DBPassword=.*/DBPassword=vagrant/" /etc/zabbix/zabbix_server.conf

grep -q "^DBPassword=vagrant" /etc/zabbix/zabbix_server.conf || \
echo "DBPassword=vagrant" | sudo tee -a /etc/zabbix/zabbix_server.conf > /dev/null

sudo systemctl restart zabbix-server zabbix-agent2 apache2
sudo systemctl enable zabbix-server zabbix-agent2 apache2
