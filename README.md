Projekt spustíme pomocí příkazu:

vagrant up


Po krátké chvíli se virtuální stroj vytvoří, nainstaluje a automaticky nakonfiguruje celý Zabbix server včetně Zabbix Agent2.

Jakmile instalace skončí, otevřeme webový prohlížeč a přejdeme na adresu:

http://localhost:8007/zabbix


Zobrazí se přihlašovací stránka Zabbixu.
Přihlásíme se pomocí výchozích údajů:

Uživatel: Admin

Heslo: zabbix

A tím máme plně funkční Zabbix server připravený k použití.




📝 Popis skriptu (co přesně dělá)
set -e

Pokud jakýkoliv příkaz skončí chybou, skript se okamžitě zastaví.

1️⃣ Instalace základních balíků
sudo apt-get update -y
sudo apt-get install -y net-tools wget mysql-server


Aktualizuje seznam balíků.

Instaluje:

net-tools — příkazy jako ifconfig, netstat.

wget — stahování souborů.

mysql-server — databáze, kterou Zabbix potřebuje.

2️⃣ Přidání Zabbix repozitáře
wget https://repo.zabbix.com/.../zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo apt update -y


Stáhne oficiální Zabbix repo.

Nainstaluje ho.

Aktualizuje balíčky, aby systém věděl o Zabbix balících.

3️⃣ Instalace Zabbix serveru, frontendů a agentů
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent2
sudo apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql


Instaluje:

Zabbix server (backend)

PHP frontend + Apache (webové rozhraní)

SQL skripty (databázová schémata)

Agent2 a jeho pluginy (monitorování MongoDB, MSSQL, PostgreSQL)

4️⃣ Vytvoření MySQL databáze a uživatele
sudo mysql <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
EOF


Vytvoří databázi zabbix.

Vytvoří uživatele zabbix s heslem vagrant.

Povolí mu přístup ke všemu v této databázi.

Dočasně zapne možnost vytvářet funkce a triggery (nutné pro import Zabbix schématu).

5️⃣ Import Zabbix SQL schématu
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | \
mysql --default-character-set=utf8mb4 -uzabbix -pvagrant zabbix


Rozbalí SQL schéma.

Importuje ho do MySQL databáze zabbix.

Tím se vytvoří tabulky, indexy, uložené funkce atd.

6️⃣ Vypnutí funkce log_bin_trust_function_creators
sudo mysql <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF


Vrátí původní nastavení MySQL, aby nebylo příliš otevřené.

7️⃣ Nastavení hesla v Zabbix server configu
sudo sed -i "s/^# DBPassword=.*/DBPassword=vagrant/" /etc/zabbix/zabbix_server.conf


Aktivuje řádek DBPassword a přidá heslo vagrant.

Zálohovací kontrola:

grep -q "^DBPassword=vagrant" /etc/zabbix/zabbix_server.conf || \
echo "DBPassword=vagrant" | sudo tee -a /etc/zabbix/zabbix_server.conf > /dev/null


Pokud řádek v souboru ještě není, přidá ho.

8️⃣ Restart a povolení služeb
sudo systemctl restart zabbix-server zabbix-agent2 apache2
sudo systemctl enable zabbix-server zabbix-agent2 apache2


Restartuje služby, aby načetly konfiguraci.

Povolit služby při startu systému.

✔️ Stručně: Co skript dělá?

Nainstaluje MySQL, Zabbix server, agent a webové rozhraní.

Vytvoří databázi a uživatele pro Zabbix.

Importuje kompletní Zabbix databázové schéma.

Nastaví Zabbix server, aby mohl používat heslo.

Spustí všechny služby a nastaví je, aby se automaticky zapínaly.





V konfiguračním souboru zabbix.conf.php bylo potřeba upravit několik hodnot, aby se Zabbix frontend správně připojil k databázi a zobrazoval správné jméno serveru. Konkrétně byly nastaveny tyto položky:

$DB['TYPE']     = 'MYSQL';
$DB['SERVER']   = 'localhost';
$DB['PORT']     = '0';
$DB['DATABASE'] = 'zabbix';
$DB['USER']     = 'zabbix';
$DB['PASSWORD'] = 'vagrant';

$ZBX_SERVER_NAME = 'Jirout';


část $DB[...] definuje připojení k MySQL databázi vytvořené ve skriptu

$ZBX_SERVER_NAME určuje název Zabbix serveru viditelný v horní části webového rozhraní

Díky tomu se frontend správně připojí a zobrazí server pod zvoleným jménem.







🖥️ Přidání hosta do Zabbixu

V levém menu otevři Data collection → Hosts.

Vpravo klikni na Import.

Nahraj svůj exportovaný soubor s hostem a potvrď import.
Tím se host přidá do Zabbixu.

🔍 Otestování, zda host správně funguje

Otevři seznam hostů a klikni na hosta, kterého jsi právě naimportoval.

Přejdi na záložku Items (položky).

Najdi položku:

Website certificate by Zabbix agent 2: Get
web.certificate.get[{$CERT.WEBSITE.HOSTNAME},{$CERT.WEBSITE.PORT},{$CERT.WEBSITE.IP}]


Klikni na Get → poté Test → a poté Get value and test.

Tím ověříš, že položka funguje a Zabbix je schopný získat data.

📊 Zobrazení dat v Monitoring

V levém menu otevři Monitoring → Hosts.

Najdi svého hosta, klikni na něj pravým tlačítkem myši.

Zvol Latest data.

Zobrazí se aktuální hodnoty, které Zabbix z hosta získává.